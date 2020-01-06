//===--- ConstantPropagation.cpp - Constant fold and diagnose overflows ---===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "constant-propagation"
#include "swift/Basic/LLVM.h"
#include "swift/Basic/STLExtras.h"
#include "swift/SIL/SILInstructionWorklist.h"
#include "swift/SIL/SILVisitor.h"
#include "swift/SIL/SILConstants.h"
#include "swift/SILOptimizer/PassManager/Passes.h"
#include "swift/SILOptimizer/PassManager/Transforms.h"
#include "swift/SILOptimizer/Utils/SILOptFunctionBuilder.h"
#include "swift/SILOptimizer/Utils/ConstantFolding.h"
#include "swift/SILOptimizer/Utils/ConstExpr.h"

using namespace swift;

//===----------------------------------------------------------------------===//
//                        ArrayConstantFolder Interface
//===----------------------------------------------------------------------===//

namespace {

class ArrayConstantFolder final
    : public SILInstructionVisitor<ArrayConstantFolder> {

  using Worklist = SmallSILInstructionWorklist<256>;

  /// The list of instructions remaining to visit, perhaps to combine.
  Worklist worklist;

  /// Whether any changes have been made.
  bool madeChange;

  InstModCallbacks instModCallbacks;
  SmallVector<SILInstruction *, 16> instructionsPendingDeletion;

  ConstExprEvaluator constantEvaluator;

public:
  ArrayConstantFolder(ConstExprEvaluator &constantEvaluator)
      : worklist("MC"), madeChange(false),
        instModCallbacks(
            [&](SILInstruction *instruction) {
              worklist.erase(instruction);
              instructionsPendingDeletion.push_back(instruction);
            },
            [&](SILInstruction *instruction) { worklist.add(instruction); },
            [this](SILValue oldValue, SILValue newValue) {
              worklist.replaceValueUsesWith(oldValue, newValue);
          }),
        constantEvaluator(constantEvaluator) { }

  void addReachableCodeToWorklist(SILFunction &function);

  void clear() {
    worklist.resetChecked();
    madeChange = false;
  }

  /// Applies the MandatoryCombiner to the provided function.
  ///
  /// \param function the function to which to apply the MandatoryCombiner.
  ///
  /// \return whether a change was made.
  bool runOnFunction(SILFunction &function);

  /// Base visitor that does not do anything.
  void visitSILInstruction(SILInstruction *) { }
  void visitApplyInst(ApplyInst *instruction);
};

} // end anonymous namespace

void ArrayConstantFolder::addReachableCodeToWorklist(SILFunction &function) {
  SmallVector<SILBasicBlock *, 32> blockWorklist;
  SmallPtrSet<SILBasicBlock *, 32> blockAlreadyAddedToWorklist;
  SmallVector<SILInstruction *, 128> initialInstructionWorklist;

  {
    auto *firstBlock = &*function.begin();
    blockWorklist.push_back(firstBlock);
    blockAlreadyAddedToWorklist.insert(firstBlock);
  }

  while (!blockWorklist.empty()) {
    auto *block = blockWorklist.pop_back_val();

    for (auto iterator = block->begin(), end = block->end(); iterator != end;) {
      auto *instruction = &*iterator;
      ++iterator;

      if (isInstructionTriviallyDead(instruction)) {
        continue;
      }

      initialInstructionWorklist.push_back(instruction);
    }

    llvm::copy_if(block->getSuccessorBlocks(),
                  std::back_inserter(blockWorklist),
                  [&](SILBasicBlock *block) -> bool {
                    return blockAlreadyAddedToWorklist.insert(block).second;
                  });
  }

  worklist.addInitialGroup(initialInstructionWorklist);
}

bool ArrayConstantFolder::runOnFunction(SILFunction &function) {
  madeChange = false;

  addReachableCodeToWorklist(function);

  while (!worklist.isEmpty()) {
    auto *instruction = worklist.pop_back_val();
    if (instruction == nullptr) {
      continue;
    }
    
    visit(instruction);

    for (SILInstruction *instruction : instructionsPendingDeletion) {
      worklist.eraseInstFromFunction(*instruction);
    }
    instructionsPendingDeletion.clear();
  }

  worklist.resetChecked();
  return madeChange;
}

void ArrayConstantFolder::visitApplyInst(ApplyInst *apply) {
  ArraySemanticsCall call(apply);
  Array
  
  switch (call.getKind()) {
    case swift::ArrayCallKind::kAppendElement:
      
    default:
      break;
  }
}

//===----------------------------------------------------------------------===//
//                              Top Level Driver
//===----------------------------------------------------------------------===//

namespace {

struct ArrayConstantFolding : public SILFunctionTransform {
  void run() override {
    SymbolicValueBumpAllocator allocator;
    ConstExprEvaluator constantEvaluator(allocator,
                                         getOptions().AssertConfig);
    ArrayConstantFolder folder(constantEvaluator);
  }
};

} // end anonymous namespace

SILTransform *swift::createArrayConstantFolding() {
  return new ArrayConstantFolding();
}
