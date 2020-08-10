//===--- OptRemarkGenerator.cpp -------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
///
/// \file
///
/// In this pass, we define the opt-remark-generator, a simple SILVisitor that
/// attempts to infer opt-remarks for the user using heuristics.
///
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "sil-opt-remark-gen"

#include "swift/AST/SemanticAttrs.h"
#include "swift/SIL/MemAccessUtils.h"
#include "swift/SIL/OptimizationRemark.h"
#include "swift/SIL/Projection.h"
#include "swift/SIL/SILFunction.h"
#include "swift/SIL/SILInstruction.h"
#include "swift/SIL/SILModule.h"
#include "swift/SIL/SILVisitor.h"
#include "swift/SILOptimizer/Analysis/RCIdentityAnalysis.h"
#include "swift/SILOptimizer/PassManager/Passes.h"
#include "swift/SILOptimizer/PassManager/Transforms.h"
#include "llvm/Support/raw_ostream.h"

using namespace swift;

//===----------------------------------------------------------------------===//
//                                  Utility
//===----------------------------------------------------------------------===//

namespace {

struct ValueToDeclInferrer {
  using Argument = OptRemark::Argument;
  using ArgumentKeyKind = OptRemark::ArgumentKeyKind;

  RCIdentityFunctionInfo &rcfi;
  SmallVector<std::pair<SILType, Projection>, 32> accessPath;

  ValueToDeclInferrer(RCIdentityFunctionInfo &rcfi) : rcfi(rcfi) {}

  /// Given a value, attempt to infer a conservative list of decls that the
  /// passed in value could be referring to. This is done just using heuristics
  bool infer(ArgumentKeyKind keyKind, SILValue value,
             SmallVectorImpl<Argument> &resultingInferredDecls);

  /// Print out a note to \p stream that beings at decl and then consumes the
  /// accessPath we computed for decl producing a segmented access path, e.x.:
  /// "of 'x.lhs.ivar'".
  void printNote(llvm::raw_string_ostream &stream, const ValueDecl *decl);
};

} // anonymous namespace

void ValueToDeclInferrer::printNote(llvm::raw_string_ostream &stream,
                                    const ValueDecl *decl) {
  stream << "of '" << decl->getBaseName();
  for (auto &pair : accessPath) {
    auto baseType = pair.first;
    auto &proj = pair.second;
    stream << ".";

    // WARNING: This must be kept insync with isSupportedProjection!
    switch (proj.getKind()) {
    case ProjectionKind::Upcast:
      stream << "upcast<" << proj.getCastType(baseType) << ">";
      continue;
    case ProjectionKind::RefCast:
      stream << "refcast<" << proj.getCastType(baseType) << ">";
      continue;
    case ProjectionKind::BitwiseCast:
      stream << "bitwise_cast<" << proj.getCastType(baseType) << ">";
      continue;
    case ProjectionKind::Struct:
      stream << proj.getVarDecl(baseType)->getBaseName();
      continue;
    case ProjectionKind::Tuple:
      stream << proj.getIndex();
      continue;
    case ProjectionKind::Enum:
      stream << proj.getEnumElementDecl(baseType)->getBaseName();
      continue;
    // Object -> Address projections can never be looked through.
    case ProjectionKind::Class:
    case ProjectionKind::Box:
    case ProjectionKind::Index:
    case ProjectionKind::TailElems:
      llvm_unreachable(
          "Object -> Address projection should never be looked through!");
    }

    llvm_unreachable("Covered switch is not covered?!");
  }

  accessPath.clear();
  stream << "'";
}

// WARNING: This must be kept insync with ValueToDeclInferrer::printNote(...).
static SingleValueInstruction *isSupportedProjection(Projection p, SILValue v) {
  switch (p.getKind()) {
  case ProjectionKind::Upcast:
  case ProjectionKind::RefCast:
  case ProjectionKind::BitwiseCast:
  case ProjectionKind::Struct:
  case ProjectionKind::Tuple:
  case ProjectionKind::Enum:
    return cast<SingleValueInstruction>(v);
    // Object -> Address projections can never be looked through.
  case ProjectionKind::Class:
  case ProjectionKind::Box:
  case ProjectionKind::Index:
  case ProjectionKind::TailElems:
    return nullptr;
  }
  llvm_unreachable("Covered switch is not covered?!");
}

bool ValueToDeclInferrer::infer(
    ArgumentKeyKind keyKind, SILValue value,
    SmallVectorImpl<Argument> &resultingInferredDecls) {
  // This is a linear IR traversal using a 'falling while loop'. That means
  // every time through the loop we are trying to handle a case before we hit
  // the bottom of the while loop where we always return true (since we did not
  // hit a could not compute case). Reassign value and continue to go to the
  // next step.
  while (true) {
    // First check for "identified values" like arguments and global_addr.
    if (auto *arg = dyn_cast<SILArgument>(value))
      if (auto *decl = arg->getDecl()) {
        std::string msg;
        {
          llvm::raw_string_ostream stream(msg);
          printNote(stream, decl);
        }
        resultingInferredDecls.push_back(
            Argument({keyKind, "InferredValue"}, std::move(msg), decl));
        return true;
      }

    if (auto *ga = dyn_cast<GlobalAddrInst>(value))
      if (auto *decl = ga->getReferencedGlobal()->getDecl()) {
        std::string msg;
        {
          llvm::raw_string_ostream stream(msg);
          printNote(stream, decl);
        }
        resultingInferredDecls.push_back(
            Argument({keyKind, "InferredValue"}, std::move(msg), decl));
        return true;
      }

    // Then visit our users and see if we can find a debug_value that provides
    // us with a decl we can use to construct an argument.
    bool foundDeclFromUse = false;
    for (auto *use : value->getUses()) {
      // Skip type dependent uses.
      if (use->isTypeDependent())
        continue;

      if (auto *dvi = dyn_cast<DebugValueInst>(use->getUser())) {
        if (auto *decl = dvi->getDecl()) {
          std::string msg;
          {
            llvm::raw_string_ostream stream(msg);
            printNote(stream, decl);
          }
          resultingInferredDecls.push_back(
              Argument({keyKind, "InferredValue"}, std::move(msg), decl));
          foundDeclFromUse = true;
        }
      }
    }
    if (foundDeclFromUse)
      return true;

    // At this point, we could not infer any argument. See if we can look
    // through loads.
    //
    // TODO: Add GEPs to construct a ProjectionPath.

    // Finally, see if we can look through a load...
    if (auto *li = dyn_cast<LoadInst>(value)) {
      value = stripAccessMarkers(li->getOperand());
      continue;
    }

    if (auto proj = Projection(value)) {
      if (auto *projInst = isSupportedProjection(proj, value)) {
        value = projInst->getOperand(0);
        accessPath.emplace_back(value->getType(), proj);
        continue;
      }
    }

    // If we reached this point, we finished falling through the loop and return
    // true.
    return true;
  }
}

//===----------------------------------------------------------------------===//
//                        Opt Remark Generator Visitor
//===----------------------------------------------------------------------===//

namespace {

struct OptRemarkGeneratorInstructionVisitor
    : public SILInstructionVisitor<OptRemarkGeneratorInstructionVisitor> {
  SILModule &mod;
  OptRemark::Emitter ORE;

  /// A class that we use to infer the decl that is associated with a
  /// miscellaneous SIL value. This is just a heuristic that is to taste.
  ValueToDeclInferrer valueToDeclInferrer;

  OptRemarkGeneratorInstructionVisitor(SILFunction &fn,
                                       RCIdentityFunctionInfo &rcfi)
      : mod(fn.getModule()), ORE(DEBUG_TYPE, fn), valueToDeclInferrer(rcfi) {}

  void visitStrongRetainInst(StrongRetainInst *sri);
  void visitStrongReleaseInst(StrongReleaseInst *sri);
  void visitRetainValueInst(RetainValueInst *rvi);
  void visitReleaseValueInst(ReleaseValueInst *rvi);
  void visitSILInstruction(SILInstruction *) {}
};

} // anonymous namespace

void OptRemarkGeneratorInstructionVisitor::visitStrongRetainInst(
    StrongRetainInst *sri) {
  ORE.emit([&]() {
    using namespace OptRemark;
    SmallVector<Argument, 8> inferredArgs;
    bool foundArgs = valueToDeclInferrer.infer(ArgumentKeyKind::Note,
                                               sri->getOperand(), inferredArgs);
    (void)foundArgs;

    // Retains begin a lifetime scope so we infer scan forward.
    auto remark = RemarkMissed("memory", *sri,
                               SourceLocInferenceBehavior::ForwardScanOnly)
                  << "retain of type '"
                  << NV("ValueType", sri->getOperand()->getType()) << "'";
    for (auto arg : inferredArgs) {
      remark << arg;
    }
    return remark;
  });
}

void OptRemarkGeneratorInstructionVisitor::visitStrongReleaseInst(
    StrongReleaseInst *sri) {
  ORE.emit([&]() {
    using namespace OptRemark;
    // Releases end a lifetime scope so we infer scan backward.
    SmallVector<Argument, 8> inferredArgs;
    bool foundArgs = valueToDeclInferrer.infer(ArgumentKeyKind::Note,
                                               sri->getOperand(), inferredArgs);
    (void)foundArgs;

    auto remark = RemarkMissed("memory", *sri,
                               SourceLocInferenceBehavior::BackwardScanOnly)
                  << "release of type '"
                  << NV("ValueType", sri->getOperand()->getType()) << "'";
    for (auto arg : inferredArgs) {
      remark << arg;
    }
    return remark;
  });
}

void OptRemarkGeneratorInstructionVisitor::visitRetainValueInst(
    RetainValueInst *rvi) {
  ORE.emit([&]() {
    using namespace OptRemark;
    SmallVector<Argument, 8> inferredArgs;
    bool foundArgs = valueToDeclInferrer.infer(ArgumentKeyKind::Note,
                                               rvi->getOperand(), inferredArgs);
    (void)foundArgs;
    // Retains begin a lifetime scope, so we infer scan forwards.
    auto remark = RemarkMissed("memory", *rvi,
                               SourceLocInferenceBehavior::ForwardScanOnly)
                  << "retain of type '"
                  << NV("ValueType", rvi->getOperand()->getType()) << "'";
    for (auto arg : inferredArgs) {
      remark << arg;
    }
    return remark;
  });
}

void OptRemarkGeneratorInstructionVisitor::visitReleaseValueInst(
    ReleaseValueInst *rvi) {
  ORE.emit([&]() {
    using namespace OptRemark;
    SmallVector<Argument, 8> inferredArgs;
    bool foundArgs = valueToDeclInferrer.infer(ArgumentKeyKind::Note,
                                               rvi->getOperand(), inferredArgs);
    (void)foundArgs;

    // Releases end a lifetime scope so we infer scan backward.
    auto remark = RemarkMissed("memory", *rvi,
                               SourceLocInferenceBehavior::BackwardScanOnly)
                  << "release of type '"
                  << NV("ValueType", rvi->getOperand()->getType()) << "'";
    for (auto arg : inferredArgs) {
      remark << arg;
    }
    return remark;
  });
}

//===----------------------------------------------------------------------===//
//                            Top Level Entrypoint
//===----------------------------------------------------------------------===//

namespace {

class OptRemarkGenerator : public SILFunctionTransform {
  ~OptRemarkGenerator() override {}

  bool isOptRemarksEnabled() {
    auto *fn = getFunction();
    // TODO: Put this on LangOpts as a helper.
    auto &langOpts = fn->getASTContext().LangOpts;

    return bool(langOpts.OptimizationRemarkMissedPattern) ||
           bool(langOpts.OptimizationRemarkPassedPattern) ||
           fn->getModule().getSILRemarkStreamer() ||
           fn->hasSemanticsAttrThatStartsWith(
               semantics::FORCE_EMIT_OPT_REMARK_PREFIX);
  }

  /// The entry point to the transformation.
  void run() override {
    if (!isOptRemarksEnabled())
      return;

    auto *fn = getFunction();
    LLVM_DEBUG(llvm::dbgs() << "Visiting: " << fn->getName() << "\n");
    auto &rcfi = *getAnalysis<RCIdentityAnalysis>()->get(fn);
    OptRemarkGeneratorInstructionVisitor visitor(*fn, rcfi);
    for (auto &block : *fn) {
      for (auto &inst : block) {
        visitor.visit(&inst);
      }
    }
  }
};

} // end anonymous namespace

SILTransform *swift::createOptRemarkGenerator() {
  return new OptRemarkGenerator();
}
