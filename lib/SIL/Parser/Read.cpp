//===--- Read.cpp - SIL File Parsing logic --------------------------------===//
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

#include "swift/AST/ASTWalker.h"
#include "swift/AST/TypeRepr.h"
#include "swift/SIL/SILParser.h"
#include "swift/Subsystems.h"

using namespace swift;
using namespace swift::syntax;

//===----------------------------------------------------------------------===//
// ReadSIL implementation
//===----------------------------------------------------------------------===//

namespace swift {

//===----------------------------------------------------------------------===//
// SILType parsing
//===----------------------------------------------------------------------===//

// TODO: move this to CheckSIL.
bool ReadSIL::performTypeLocChecking(TypeLoc &T, bool IsSILType,
                                     GenericEnvironment *GenericEnv,
                                     DeclContext *DC) {
  if (GenericEnv == nullptr)
    GenericEnv = ContextGenericEnv;

  if (!DC)
    DC = &SF;
  else if (!GenericEnv)
    GenericEnv = DC->getGenericEnvironmentOfContext();

  return swift::performTypeLocChecking(Context, T,
                                       /*isSILMode=*/true, IsSILType,
                                       GenericEnv, DC);
}

///   sil-type:
///     '$' '*'? attribute-list (generic-params)? type
///
bool ReadSIL::parseSILType(SILType &Result,
                           GenericEnvironment *&ParsedGenericEnv,
                           bool IsFuncDecl,
                           GenericEnvironment *OuterGenericEnv) {
  ParsedGenericEnv = nullptr;

  if (parseToken(tok::sil_dollar, diag::expected_sil_type))
    return true;

  // If we have a '*', then this is an address type.
  SILValueCategory category = SILValueCategory::Object;
  if (Tok.isAnyOperator() && Tok.getText().startswith("*")) {
    category = SILValueCategory::Address;
    consumeStartingCharacterOfCurrentToken();
  }

  // Parse attributes.
  ParamDecl::Specifier specifier;
  SourceLoc specifierLoc;
  TypeAttributes attrs;
  parseTypeAttributeList(specifier, specifierLoc, attrs);

  // Global functions are implicitly @convention(thin) if not specified
  // otherwise.
  if (IsFuncDecl && !attrs.has(TAK_convention)) {
    // Use a random location.
    attrs.setAttr(TAK_convention, PreviousLoc);
    attrs.ConventionArguments =
        TypeAttributes::Convention::makeSwiftConvention("thin");
  }

  ParserResult<TypeRepr> TyR = parseType(diag::expected_sil_type,
                                         /*handleCodeCompletion*/ true,
                                         /*isSILFuncDecl*/ IsFuncDecl);

  if (TyR.isNull())
    return true;

  // Resolve the generic environments for parsed generic function and box types.
  class HandleSILGenericParamsWalker : public ASTWalker {
    SourceFile *SF;

  public:
    HandleSILGenericParamsWalker(SourceFile *SF) : SF(SF) {}

    bool walkToTypeReprPre(TypeRepr *T) override {
      if (auto fnType = dyn_cast<FunctionTypeRepr>(T)) {
        if (auto generics = fnType->getGenericParams()) {
          auto env = handleSILGenericParams(generics, SF);
          fnType->setGenericEnvironment(env);
        }
        if (auto generics = fnType->getPatternGenericParams()) {
          auto env = handleSILGenericParams(generics, SF);
          fnType->setPatternGenericEnvironment(env);
        }
      }
      if (auto boxType = dyn_cast<SILBoxTypeRepr>(T)) {
        if (auto generics = boxType->getGenericParams()) {
          auto env = handleSILGenericParams(generics, SF);
          boxType->setGenericEnvironment(env);
        }
      }
      return true;
    }
  };

  TyR.get()->walk(HandleSILGenericParamsWalker(&SF));

  // Save the top-level function generic environment if there was one.
  if (auto fnType = dyn_cast<FunctionTypeRepr>(TyR.get()))
    if (auto env = fnType->getGenericEnvironment())
      ParsedGenericEnv = env;

  // Apply attributes to the type.
  TypeLoc Ty = applyAttributeToType(TyR.get(), attrs, specifier, specifierLoc);

  if (performTypeLocChecking(Ty, /*IsSILType=*/true, OuterGenericEnv))
    return true;

  Result =
      SILType::getPrimitiveType(Ty.getType()->getCanonicalType(), category);

  // Invoke the callback on the parsed type.
  // TODO: remove this
  ParsedTypeCallback(Ty.getType());

  return false;
}

bool ReadSIL::parseSILType(SILType &Result) {
  GenericEnvironment *IgnoredEnv;
  return parseSILType(Result, IgnoredEnv);
}
bool ReadSIL::parseSILType(SILType &Result, SourceLoc &TypeLoc) {
  TypeLoc = Tok.getLoc();
  return parseSILType(Result);
}
bool ReadSIL::parseSILType(SILType &Result, SourceLoc &TypeLoc,
                           GenericEnvironment *&parsedGenericEnv,
                           GenericEnvironment *parentGenericEnv) {
  TypeLoc = Tok.getLoc();
  return parseSILType(Result, parsedGenericEnv, false, parentGenericEnv);
}

//===----------------------------------------------------------------------===//
// SILInstruction reading
//===----------------------------------------------------------------------===//

bool ReadSIL::readSingleID(SILParserValues &instResults) {
  if (!Tok.is(tok::sil_local_name))
    return false;
  instResults.push_back(Tok.getRawText());
  consumeToken();
  return true;
}

bool ReadSIL::readSingleOperand(SILParserOperands &instOperands) {
  if (!Tok.is(tok::sil_local_name))
    return false;
  StringRef valId = Tok.getRawText();
  consumeToken();
  if (!consumeIf(tok::colon))
    return false;
  SILType type;
  if (parseSILType(type))
    return false;
  instOperands.emplace_back(valId, type);
  return true;
}

SILParserResult ReadSIL::read() {
  ParserPosition start = getParserPosition();
  SILParserResult readingResult;
  readingResult.loc.begin = Tok.getLoc();
  readingResult.loc.end = Tok.getLoc();

  // Read the results, if any:
  // (%x, ...) | %x
  SILParserValues instResults;
  if (consumeIf(tok::l_paren)) {
    while (!consumeIf(tok::r_paren)) {
      readingResult.loc.end = Tok.getLoc();

      if (!readSingleID(instResults)) {
        return {};
      }

      if (Tok.is(tok::comma)) {
        consumeToken();
      } else if (!Tok.is(tok::r_paren)) {
        return {};
      }
    }
  } else if (Tok.is(tok::sil_local_name)) {
    if (!readSingleID(instResults)) {
      return {};
    }
  }

  // Parse the '='
  if (!consumeIf(tok::equal) && !instResults.empty()) {
    diagnose(Tok.getLoc(), diag::expected_equal_in_sil_instr);
    return {};
  }

  // Read the SILInstruction Kind. We don't check if it's an identifier because
  // it may not be (i.e. struct).
  auto instStr = Tok.getRawText();
  consumeToken();
  readingResult.loc.end = Tok.getLoc();

  if (false) {
  }
#define FULL_INST(ID, NAME, PARENT, MEMBEHAVIOR, MAYRELEASE)                   \
  else if (instStr == #NAME) {                                                 \
    readingResult.kind = SILInstructionKind::ID;                               \
    read##ID(readingResult);                                                   \
  }
#include "swift/SIL/SILNodes.def"
  else
    llvm_unreachable("Unhandled SILNode");
  readingResult.results = instResults;

  // If we couldn't read the instruction, reset the parser position for the old
  // parser (which we will bail out to).
  if (unsigned(readingResult.kind) == 0) {
    backtrackToPosition(start);
  }

  return readingResult;
}

//===----------------------------------------------------------------------===//
// ReadSIL visitors
//===----------------------------------------------------------------------===//

void ReadSIL::readCopyValueInst(SILParserResult &out) {
  readSingleOperand(out.operands);
}

} // namespace swift
