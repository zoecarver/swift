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

/// getLocalValue - Get a reference to a local value with the specified name
/// and type.
SILValue EmitSIL::getLocalValue(UnresolvedValueName name, SILType type,
                                SILLocation loc, SILBuilder &builder) {
  SILFunction &function = builder.getFunction();

  if (name.isUndef())
    return SILUndef::get(type, builder.getFunction());

  // Check to see if a value with this name already exists.
  ValueBase *&val = localValues[name.Name];

  if (val) {
    // If this value has already been defined, make sure it has the type we're
    // expecting.
    SILType valType = val->getType();

    if (valType != type) {
      diagnose(valType.getASTContext(), name.NameLoc,
               diag::sil_value_use_type_mismatch, name.Name,
               valType.getASTType(), type.getASTType());
      llvm_unreachable("See emitted diagnostic");
    }

    return SILValue(val);
  }

  // Otherwise, this is a forward reference. Create a dummy global to represent
  // it.
  forwardRefs[name.Name] = name.NameLoc;

  val = new (module)
      GlobalAddrInst(SILDebugLocation(loc, function.getDebugScope()), type);
  return val;
}

/// setLocalValue - When an instruction or block argument is defined, this
/// method is used to register it and update our symbol table.
void EmitSIL::setLocalValue(ValueBase *val, StringRef name, SourceLoc loc) {
  ValueBase *&oldValue = localValues[name];

  // If this value was already defined then it must be the definition of a
  // forward referenced value.
  if (oldValue) {
    // If no forward reference exists for it, then it's a redefinition so,
    // emit an error.
    if (!forwardRefs.erase(name)) {
      diagnose(oldValue->getType().getASTContext(), loc,
               diag::sil_value_redefinition, name);
      llvm_unreachable("See emitted diagnostic");
    }

    // If the forward reference was of the wrong type, diagnose this now.
    if (oldValue->getType() != val->getType()) {
      diagnose(oldValue->getType().getASTContext(), loc,
               diag::sil_value_def_type_mismatch, name,
               oldValue->getType().getASTType(), val->getType().getASTType());
      llvm_unreachable("See emitted diagnostic");
    } else {
      // Forward references only live here if they have a single result.
      oldValue->replaceAllUsesWith(val);
    }
  }

  // Otherwise, just store it in our map.
  oldValue = val;
}

template <class... DiagArgs, class... Args>
InFlightDiagnostic EmitSIL::diagnose(ASTContext &ctx, SourceLoc loc,
                                     Diag<DiagArgs...> diagID,
                                     Args &&... args) {
  return ctx.Diags.diagnose(loc,
                            Diagnostic(diagID, std::forward<Args>(args)...));
}

llvm::StringMap<SourceLoc> EmitSIL::getForwardRefs() { return forwardRefs; }

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

} // namespace swift
