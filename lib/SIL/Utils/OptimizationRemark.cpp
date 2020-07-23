//===--- OptimizationRemark.cpp - Optimization diagnostics ------*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
/// \file
/// This file defines the remark type and the emitter class that passes can use
/// to emit optimization diagnostics.
//
//===----------------------------------------------------------------------===//

#include "swift/SIL/OptimizationRemark.h"
#include "swift/AST/DiagnosticEngine.h"
#include "swift/AST/DiagnosticsSIL.h"
#include "swift/Demangling/Demangler.h"
#include "swift/SIL/DebugUtils.h"
#include "swift/SIL/InstructionUtils.h"
#include "swift/SIL/MemAccessUtils.h"
#include "swift/SIL/SILArgument.h"
#include "swift/SIL/SILInstruction.h"
#include "swift/SIL/SILRemarkStreamer.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"

using namespace swift;
using namespace OptRemark;

Argument::Argument(StringRef key, int n)
    : key(ArgumentKeyKind::Default, key), val(llvm::itostr(n)) {}

Argument::Argument(StringRef key, long n)
    : key(ArgumentKeyKind::Default, key), val(llvm::itostr(n)) {}

Argument::Argument(StringRef key, long long n)
    : key(ArgumentKeyKind::Default, key), val(llvm::itostr(n)) {}

Argument::Argument(StringRef key, unsigned n)
    : key(ArgumentKeyKind::Default, key), val(llvm::utostr(n)) {}

Argument::Argument(StringRef key, unsigned long n)
    : key(ArgumentKeyKind::Default, key), val(llvm::utostr(n)) {}

Argument::Argument(StringRef key, unsigned long long n)
    : key(ArgumentKeyKind::Default, key), val(llvm::utostr(n)) {}

Argument::Argument(ArgumentKey key, SILFunction *f) : key(key) {
  auto options = Demangle::DemangleOptions::SimplifiedUIDemangleOptions();
  // Enable module names so that we have a way of filtering out
  // stdlib-related remarks.
  options.DisplayModuleNames = true;

  val = (Twine("\"") + Demangle::demangleSymbolAsString(f->getName(), options) +
         "\"")
            .str();

  if (f->hasLocation())
    loc = f->getLocation().getSourceLoc();
}

Argument::Argument(StringRef key, SILType ty)
    : key(ArgumentKeyKind::Default, key) {
  llvm::raw_string_ostream stream(val);
  ty.print(stream);
}

Argument::Argument(StringRef key, CanType ty)
    : key(ArgumentKeyKind::Default, key) {
  llvm::raw_string_ostream stream(val);
  ty.print(stream);
}

bool Argument::inferArgumentsForValue(
    ArgumentKeyKind keyKind, StringRef msg, SILValue value,
    function_ref<bool(Argument)> funcPassedInferedArgs) {

  while (true) {
    // If we have an argument, just use that.
    if (auto *arg = dyn_cast<SILArgument>(value))
      if (auto *decl = arg->getDecl())
        return funcPassedInferedArgs(
            Argument({keyKind, "InferredValue"}, msg, decl));

    // Otherwise, look for debug_values.
    for (auto *use : getDebugUses(value))
      if (auto *dvi = dyn_cast<DebugValueInst>(use->getUser()))
        if (auto *decl = dvi->getDecl())
          if (!funcPassedInferedArgs(
                  Argument({keyKind, "InferredValue"}, msg, decl)))
            return false;

    // If we have a load, look through it and continue. We may have a global or
    // a function argument.
    if (auto *li = dyn_cast<LoadInst>(value)) {
      value = stripAccessMarkers(li->getOperand());
      continue;
    }

    if (auto *ga = dyn_cast<GlobalAddrInst>(value))
      if (auto *decl = ga->getReferencedGlobal()->getDecl())
        if (!funcPassedInferedArgs(
                Argument({keyKind, "InferredValue"}, msg, decl)))
          return false;

    return true;
  }
}

template <typename DerivedT>
std::string Remark<DerivedT>::getMsg() const {
  std::string str;
  llvm::raw_string_ostream stream(str);
  // Go through our args and if we are not emitting for diagnostics *OR* we are
  // emitting for diagnostics and this argument is not intended to be emitted as
  // a diagnostic separate from our main remark, emit the arg value here.
  for (const Argument &arg : args) {
    if (arg.key.kind.isSeparateDiagnostic())
      continue;
    stream << arg.val;
  }

  return stream.str();
}

template <typename DerivedT>
std::string Remark<DerivedT>::getDebugMsg() const {
  std::string str;
  llvm::raw_string_ostream stream(str);

  if (indentDebugWidth)
    stream << std::string(" ", indentDebugWidth);

  for (const Argument &arg : args)
    stream << arg.val;

  stream << "\n";
  return stream.str();
}

Emitter::Emitter(StringRef passName, SILModule &m)
    : module(m), passName(passName),
      passedEnabled(
          m.getASTContext().LangOpts.OptimizationRemarkPassedPattern &&
          m.getASTContext().LangOpts.OptimizationRemarkPassedPattern->match(
              passName)),
      missedEnabled(
          m.getASTContext().LangOpts.OptimizationRemarkMissedPattern &&
          m.getASTContext().LangOpts.OptimizationRemarkMissedPattern->match(
              passName)) {}

/// The user has passed us an instruction that for some reason has a source loc
/// that can not be used. Search down the current block for an instruction with
/// a valid source loc and use that instead.
static SourceLoc inferOptRemarkSearchForwards(SILInstruction &i) {
  for (auto &inst :
       llvm::make_range(std::next(i.getIterator()), i.getParent()->end())) {
    auto newLoc = inst.getLoc().getSourceLoc();
    if (newLoc.isValid())
      return newLoc;
  }

  return SourceLoc();
}

/// The user has passed us an instruction that for some reason has a source loc
/// that can not be used. Search up the current block for an instruction with
/// a valid SILLocation and use the end SourceLoc of the SourceRange for the
/// instruction.
static SourceLoc inferOptRemarkSearchBackwards(SILInstruction &i) {
  for (auto &inst : llvm::make_range(std::next(i.getReverseIterator()),
                                     i.getParent()->rend())) {
    auto loc = inst.getLoc();
    if (!bool(loc))
      continue;

    auto range = loc.getSourceRange();
    if (range.isValid())
      return range.End;
  }

  return SourceLoc();
}

SourceLoc swift::OptRemark::inferOptRemarkSourceLoc(
    SILInstruction &i, SourceLocInferenceBehavior inferBehavior) {
  auto loc = i.getLoc().getSourceLoc();

  // Do a quick check if we already have a valid loc. In such a case, just
  // return. Otherwise, we try to infer using one of our heuristics below.
  if (loc.isValid())
    return loc;

  // Otherwise, try to handle the individual behavior cases, returning loc at
  // the end of each case (its invalid, so it will get ignored). If loc is not
  // returned, we hit an assert at the end to make it easy to identify a case
  // was missed.
  switch (inferBehavior) {
  case SourceLocInferenceBehavior::None:
    return loc;
  case SourceLocInferenceBehavior::ForwardScanOnly: {
    SourceLoc newLoc = inferOptRemarkSearchForwards(i);
    if (newLoc.isValid())
      return newLoc;
    return loc;
  }
  case SourceLocInferenceBehavior::BackwardScanOnly: {
    SourceLoc newLoc = inferOptRemarkSearchBackwards(i);
    if (newLoc.isValid())
      return newLoc;
    return loc;
  }
  case SourceLocInferenceBehavior::ForwardThenBackward: {
    SourceLoc newLoc = inferOptRemarkSearchForwards(i);
    if (newLoc.isValid())
      return newLoc;
    newLoc = inferOptRemarkSearchBackwards(i);
    if (newLoc.isValid())
      return newLoc;
    return loc;
  }
  case SourceLocInferenceBehavior::BackwardThenForward: {
    SourceLoc newLoc = inferOptRemarkSearchBackwards(i);
    if (newLoc.isValid())
      return newLoc;
    newLoc = inferOptRemarkSearchForwards(i);
    if (newLoc.isValid())
      return newLoc;
    return loc;
  }
  }

  llvm_unreachable("Covered switch isn't covered?!");
}

template <typename RemarkT, typename... ArgTypes>
static void emitRemark(SILModule &module, const Remark<RemarkT> &remark,
                       Diag<ArgTypes...> id, bool diagEnabled) {
  if (remark.getLocation().isInvalid())
    return;
  if (auto *remarkStreamer = module.getSILRemarkStreamer())
    remarkStreamer->emit(remark);

  // If diagnostics are enabled, first emit the main diagnostic and then loop
  // through our arguments and allow the arguments to add additional diagnostics
  // if they want.
  if (!diagEnabled)
    return;

  auto &de = module.getASTContext().Diags;
  de.diagnoseWithNotes(
      de.diagnose(remark.getLocation(), id, remark.getMsg()), [&]() {
        for (auto &arg : remark.getArgs()) {
          switch (arg.key.kind) {
          case ArgumentKeyKind::Default:
            continue;
          case ArgumentKeyKind::Note:
            de.diagnose(arg.loc, diag::opt_remark_note, arg.val);
            continue;
          case ArgumentKeyKind::ParentLocNote:
            de.diagnose(remark.getLocation(), diag::opt_remark_note, arg.val);
            continue;
          }
          llvm_unreachable("Unhandled case?!");
        }
      });
}

void Emitter::emit(const RemarkPassed &remark) {
  emitRemark(module, remark, diag::opt_remark_passed,
             isEnabled<RemarkPassed>());
}

void Emitter::emit(const RemarkMissed &remark) {
  emitRemark(module, remark, diag::opt_remark_missed,
             isEnabled<RemarkMissed>());
}

void Emitter::emitDebug(const RemarkPassed &remark) {
  llvm::dbgs() << remark.getDebugMsg();
}

void Emitter::emitDebug(const RemarkMissed &remark) {
  llvm::dbgs() << remark.getDebugMsg();
}
