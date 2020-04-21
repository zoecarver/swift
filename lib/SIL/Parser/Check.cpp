//===--- Check.cpp - SIL File Parsing logic -------------------------------===//
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

#include "swift/SIL/SILModule.h"
#include "swift/SIL/SILParser.h"

using namespace swift;
using namespace swift::syntax;

//===----------------------------------------------------------------------===//
// CheckSIL implementation
//===----------------------------------------------------------------------===//

namespace swift {

template <class... DiagArgs, class... Args>
InFlightDiagnostic CheckSIL::diagnose(SourceLoc loc, Diag<DiagArgs...> diagID,
                                     Args &&... args) {
  return DiagnosticEngine(module.getSourceManager())
    .diagnose(loc, Diagnostic(diagID, std::forward<Args>(args)...));
}


bool CheckSIL::check(SILParserResult toCheck) {
  // If the kind is `0` then we don't suppor this instruction yet. Bail but,
  // don't error because the old parser will handle this case.
  if (unsigned(toCheck.kind) == 0)
    return true;

  switch (toCheck.kind) {
#define INST(CLASS, PARENT)                                                    \
  case SILInstructionKind::CLASS:                                              \
    return check##CLASS(toCheck);
#include "swift/SIL/SILNodes.def"
  }
}

//===----------------------------------------------------------------------===//
// CheckSIL visitors
//===----------------------------------------------------------------------===//

bool CheckSIL::checkCopyValueInst(SILParserResult result) {
  if (result.operands.size() != 1) {
    diagnose(result.loc.begin, diag::wrong_result_count_in_sil_instr, 1);
    return false;
  }
  if (result.results.size() != 1) {
    diagnose(result.loc.begin, diag::wrong_operand_count_in_sil_instr, 1);
    return false;
  }
  return true;
}

} // namespace swift
