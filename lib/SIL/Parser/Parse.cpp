//===--- Parse.cpp - SIL File Parsing logic -------------------------------===//
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

#include "swift/SIL/SILBuilder.h"
#include "swift/SIL/SILParser.h"
#include "swift/SIL/SILUndef.h"

using namespace swift;
using namespace swift::syntax;

//===----------------------------------------------------------------------===//
// EmitSIL implementation
//===----------------------------------------------------------------------===//

namespace swift {

SILValue EmitSIL::getLocalValue(SILParserOperand name, SILBuilder &builder,
                                SILLocation loc) {
  return vault.getLocalValue(name, builder, loc);
}

void EmitSIL::setLocalValue(ValueBase *val, StringRef name, SourceLoc loc) {
  vault.setLocalValue(val, name, loc);
}

template <class... DiagArgs, class... Args>
InFlightDiagnostic EmitSIL::diagnose(SourceLoc loc, Diag<DiagArgs...> diagID,
                                     Args &&... args) {
  return DiagnosticEngine(module.getSourceManager())
    .diagnose(loc, Diagnostic(diagID, std::forward<Args>(args)...));
}

SILInstruction *EmitSIL::emit(SILBuilder &builder, SILParserResult instData) {
  // If we don't know what the kind is that is because this parser doesn't yet
  // suppor that instruction. Return nullptr so that the old parser knows it
  // needs to parse this instruction. This is the only time this method should
  // ever return a null instruction.
  if (unsigned(instData.kind) == 0)
    return nullptr;

  switch (instData.kind) {
#define INST(CLASS, PARENT)                                                    \
  case SILInstructionKind::CLASS:                                              \
    return emit##CLASS(builder, instData);
#include "swift/SIL/SILNodes.def"
  }
}

//===----------------------------------------------------------------------===//
// EmitSIL visitors
//===----------------------------------------------------------------------===//

SILInstruction *EmitSIL::emitCopyValueInst(SILBuilder &builder,
                                           SILParserResult result) {
  auto operand = getLocalValue(result.operands.front(), builder);
  return builder.createCopyValue(RegularLocation(result.loc.begin), operand);
}

} // namespace swift
