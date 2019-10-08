//===--- ConstExpr.h - Constant expression evaluator -----------*- C++ -*-===//
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
// This defines an interface to evaluate Swift language level constant
// expressions.  Its model is intended to be general and reasonably powerful,
// with the goal of standardization in a future version of Swift.
//
// Constant expressions are functions without side effects that take constant
// values and return constant values.  These constants may be integer, and
// floating point values.   We allow abstractions to be built out of fragile
// structs and tuples.
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_SILOPTIMIZER_CONSTEXPR_H
#define SWIFT_SILOPTIMIZER_CONSTEXPR_H

#include "swift/Basic/LLVM.h"
#include "swift/Basic/SourceLoc.h"
#include "swift/SIL/SILBasicBlock.h"
#include "swift/SIL/SILFunction.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/Optional.h"

namespace swift {
class ASTContext;
class Operand;
class SILFunction;
class SILModule;
class SILNode;
class SymbolicValue;
class SymbolicValueAllocator;
class ConstExprFunctionState;
enum class UnknownReason;

class StringLiteralInfo {
  StringLiteralInfo() = default;
  
public:
  bool isAscii;
  StringRef value;
  
  static Optional<StringLiteralInfo> create(SILValue v) {
    if (auto *inst = dyn_cast<ApplyInst>(v))
      return create(inst);
    return {};
  }
  
  static Optional<StringLiteralInfo> create(SILInstruction *inst) {
    ApplyInst *makeStr = getStringMakeUTF8Apply(inst);
    if (!makeStr) return {};
    
    auto strVal = getUTF8String(makeStr);
    if (!makeStr) return {};
    
    StringLiteralInfo info;
    info.value = strVal.getValue();
    info.isAscii = getIsAscii(makeStr);
    return info;
  }
  
  /// If the given instruction is a call to the compiler-intrinsic initializer
  /// of String that accepts string literals, return the called function.
  /// Otherwise, return nullptr.
  static SILFunction *getStringMakeUTF8Init(SILInstruction *inst)  {
    auto *apply = dyn_cast<ApplyInst>(inst);
    if (!apply)
      return nullptr;

    SILFunction *callee = apply->getCalleeFunction();
    if (!callee || !callee->hasSemanticsAttr("string.makeUTF8"))
      return nullptr;
    return callee;
  }
  
  /// Similar to getStringMakeUTF8Init but, gets the apply instruction instead.
  static ApplyInst *getStringMakeUTF8Apply(SILInstruction *inst) {
    auto *apply = dyn_cast<ApplyInst>(inst);
    if (!apply)
      return nullptr;

    SILFunction *callee = apply->getCalleeFunction();
    if (!callee || !callee->hasSemanticsAttr("string.makeUTF8"))
      return nullptr;
    return apply;
  }
  
  /// Gets an optional StringRef from a string init function.
  static Optional<StringRef> getUTF8String(ApplyInst *makeStr) {
    if (makeStr->getNumArguments() < 1) return {};
    
    if (auto *SL = dyn_cast<StringLiteralInst>(makeStr->getOperand(1)))
      return SL->getValue();
    return {};
  }
  
  /// Gets is string ascii from string init function.
  static bool getIsAscii(ApplyInst *makeStr) {
    if (makeStr->getNumArguments() < 3) return false;
    
    if (auto *isAscii = dyn_cast<IntegerLiteralInst>(makeStr->getOperand(3)))
      return isAscii->getValue().getBoolValue();
    return false;
  }
};

/// This class is the main entrypoint for evaluating constant expressions.  It
/// also handles caching of previously computed constexpr results.
class ConstExprEvaluator {
  SymbolicValueAllocator &allocator;

  /// The current call stack, used for providing accurate diagnostics.
  llvm::SmallVector<SourceLoc, 4> callStack;

  void operator=(const ConstExprEvaluator &) = delete;

public:
  explicit ConstExprEvaluator(SymbolicValueAllocator &alloc);
  ~ConstExprEvaluator();

  explicit ConstExprEvaluator(const ConstExprEvaluator &other);

  SymbolicValueAllocator &getAllocator() { return allocator; }

  void pushCallStack(SourceLoc loc) { callStack.push_back(loc); }

  void popCallStack() {
    assert(!callStack.empty());
    callStack.pop_back();
  }

  const llvm::SmallVector<SourceLoc, 4> &getCallStack() { return callStack; }

  // As SymbolicValue::getUnknown(), but handles passing the call stack and
  // allocator.
  SymbolicValue getUnknown(SILNode *node, UnknownReason reason);

  /// Analyze the specified values to determine if they are constant values.
  /// This is done in code that is not necessarily itself a constexpr
  /// function.  The results are added to the results list which is a parallel
  /// structure to the input values.
  ///
  /// TODO: Return information about which callees were found to be
  /// constexprs, which would allow the caller to delete dead calls to them
  /// that occur after after folding them.
  void computeConstantValues(ArrayRef<SILValue> values,
                             SmallVectorImpl<SymbolicValue> &results);
};

/// A constant-expression evaluator that can be used to step through a control
/// flow graph (SILFunction body) by evaluating one instruction at a time.
/// This evaluator can also "skip" instructions without evaluating them and
/// only track constant values of variables whose values could be computed.
class ConstExprStepEvaluator {
private:
  ConstExprEvaluator evaluator;

  ConstExprFunctionState *internalState;

  unsigned stepsEvaluated = 0;

  /// Targets of branches that were visited. This is used to detect loops during
  /// evaluation.
  SmallPtrSet<SILBasicBlock *, 8> visitedBlocks;

  ConstExprStepEvaluator(const ConstExprStepEvaluator &) = delete;
  void operator=(const ConstExprStepEvaluator &) = delete;

public:
  /// Constructs a step evaluator given an allocator and a non-null pointer to a
  /// SILFunction.
  explicit ConstExprStepEvaluator(SymbolicValueAllocator &alloc,
                                  SILFunction *fun);
  ~ConstExprStepEvaluator();

  /// Evaluate an instruction in the current interpreter state.
  /// \param instI instruction to be evaluated in the current interpreter state.
  /// \returns a pair where the first and second elements are defined as
  /// follows:
  ///   The first element is the iterator to the next instruction from where
  ///   the evaluation can continue, if the evaluation is successful.
  ///   Otherwise, it is None.
  ///
  ///   Second element is None, if the evaluation is successful.
  ///   Otherwise, is an unknown symbolic value that contains the error.
  std::pair<Optional<SILBasicBlock::iterator>, Optional<SymbolicValue>>
  evaluate(SILBasicBlock::iterator instI);

  /// Skip the instruction without evaluating it and conservatively account for
  /// the effects of the instruction on the internal state. This operation
  /// resets to an unknown symbolic value any portion of a
  /// SymbolicValueMemoryObject that could possibly be mutated by the given
  /// instruction. This function preserves the soundness of the interpretation.
  /// \param instI instruction to be skipped.
  /// \returns a pair where the first and second elements are defined as
  /// follows:
  ///   The first element, if is not None, is the iterator to the next
  ///   instruction from the where the evaluation must continue.
  ///   The first element is None if the next instruction from where the
  ///   evaluation must continue cannot be determined.
  ///   This would be the case if `instI` is a branch like a `condbr`.
  ///
  ///   Second element is None if skipping the instruction is successful.
  ///   Otherwise, it is an unknown symbolic value containing the error.
  std::pair<Optional<SILBasicBlock::iterator>, Optional<SymbolicValue>>
  skipByMakingEffectsNonConstant(SILBasicBlock::iterator instI);

  /// Try evaluating an instruction and if the evaluation fails, skip the
  /// instruction and make it effects non constant. Note that it may not always
  /// be possible to skip an instruction whose evaluation failed and
  /// continue evalution (e.g. a conditional branch).
  /// See `evaluate` and `skipByMakingEffectsNonConstant` functions for their
  /// semantics.
  /// \param instI instruction to be evaluated in the current interpreter state.
  /// \returns a pair where the first and second elements are defined as
  /// follows:
  ///   The first element, if is not None, is the iterator to the next
  ///   instruction from the where the evaluation must continue.
  ///   The first element is None iff both `evaluate` and `skip` functions
  ///   failed to determine the next instruction to continue evaluation from.
  ///
  ///   Second element is None if the evaluation is successful.
  ///   Otherwise, it is an unknown symbolic value containing the error.
  std::pair<Optional<SILBasicBlock::iterator>, Optional<SymbolicValue>>
  tryEvaluateOrElseMakeEffectsNonConstant(SILBasicBlock::iterator instI);

  Optional<SymbolicValue> lookupConstValue(SILValue value);

  bool isKnownFunction(SILFunction *fun);

  /// Returns true if and only if `errorVal` denotes an error that requires
  /// aborting interpretation and returning the error. Skipping an instruction
  /// that produces such errors is not a valid behavior.
  bool isFailStopError(SymbolicValue errorVal);

  /// Return the number of instructions evaluated for the last `evaluate`
  /// operation. This could be used by the clients to limit the number of
  /// instructions that should be evaluated by the step-wise evaluator.
  /// Note that 'skipByMakingEffectsNonConstant' operation is not considered
  /// as an evaluation.
  unsigned instructionsEvaluatedByLastEvaluation() { return stepsEvaluated; }
};

} // end namespace swift
#endif
