//===--- SemaFixture.cpp - Helper for setting up Sema context --------------===//
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

#include "SemaFixture.h"
#include "swift/AST/Decl.h"
#include "swift/AST/Import.h"
#include "swift/AST/Module.h"
#include "swift/AST/ParseRequests.h"
#include "swift/AST/SourceFile.h"
#include "swift/AST/Type.h"
#include "swift/AST/Types.h"
#include "swift/Basic/LLVMInitialize.h"
#include "swift/ClangImporter/ClangImporter.h"
#include "swift/Serialization/SerializedModuleLoader.h"
#include "swift/Subsystems.h"

using namespace swift;
using namespace swift::unittest;

SemaTest::SemaTest()
    : Context(*ASTContext::get(LangOpts, TypeCheckerOpts, SearchPathOpts,
                               ClangImporterOpts, SourceMgr, Diags)) {
  INITIALIZE_LLVM();

  registerParseRequestFunctions(Context.evaluator);
  registerTypeCheckerRequestFunctions(Context.evaluator);

  Context.addModuleLoader(ImplicitSerializedModuleLoader::create(Context));
  Context.addModuleLoader(ClangImporter::create(Context), /*isClang=*/true);

  auto *stdlib = Context.getStdlibModule(/*loadIfAbsent=*/true);
  assert(stdlib && "Failed to load standard library");

  auto *module =
      ModuleDecl::create(Context.getIdentifier("SemaTests"), Context);

  MainFile = new (Context) SourceFile(*module, SourceFileKind::Main,
                                      /*buffer=*/None);

  AttributedImport<ImportedModule> stdlibImport{{ImportPath::Access(), stdlib},
                                                /*options=*/{}};

  MainFile->setImports(stdlibImport);
  module->addFile(*MainFile);

  DC = module;
}

Type SemaTest::getStdlibType(StringRef name) const {
  auto typeName = Context.getIdentifier(name);

  auto *stdlib = Context.getStdlibModule();

  llvm::SmallVector<ValueDecl *, 4> results;
  stdlib->lookupValue(typeName, NLKind::UnqualifiedLookup, results);

  if (results.size() != 1)
    return Type();

  if (auto *decl = dyn_cast<TypeDecl>(results.front())) {
    if (auto *NTD = dyn_cast<NominalTypeDecl>(decl))
      return NTD->getDeclaredType();
    return decl->getDeclaredInterfaceType();
  }

  return Type();
}
