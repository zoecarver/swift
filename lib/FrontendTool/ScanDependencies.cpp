//===--- ScanDependencies.cpp -- Scans the dependencies of a module -------===//
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
#include "ScanDependencies.h"
#include "swift/AST/ASTContext.h"
#include "swift/AST/Decl.h"
#include "swift/AST/DiagnosticEngine.h"
#include "swift/AST/DiagnosticsFrontend.h"
#include "swift/AST/Module.h"
#include "swift/AST/ModuleDependencies.h"
#include "swift/AST/ModuleLoader.h"
#include "swift/AST/SourceFile.h"
#include "swift/ClangImporter/ClangImporter.h"
#include "swift/Basic/Defer.h"
#include "swift/Basic/LLVM.h"
#include "swift/Basic/STLExtras.h"
#include "swift/Frontend/Frontend.h"
#include "swift/Frontend/FrontendOptions.h"
#include "swift/Frontend/ModuleInterfaceLoader.h"
#include "swift/Strings.h"
#include "clang/Basic/Module.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/Support/FileSystem.h"
#include <set>

using namespace swift;

namespace {

}

/// Find all of the imported Clang modules starting with the given module name.
static void findAllImportedClangModules(ASTContext &ctx, StringRef moduleName,
                                        ModuleDependenciesCache &cache,
                                        std::vector<std::string> &allModules,
                                        llvm::StringSet<> &knownModules) {
  if (!knownModules.insert(moduleName).second)
    return;
  allModules.push_back(moduleName.str());

  auto dependencies = cache.findDependencies(
      moduleName, ModuleDependenciesKind::Clang);
  if (!dependencies)
    return;

  for (const auto &dep : dependencies->getModuleDependencies()) {
    findAllImportedClangModules(ctx, dep, cache, allModules, knownModules);
  }
}

struct InterfaceSubASTContextDelegate: SubASTContextDelegate {
  bool runInSubContext(ASTContext &ctx, StringRef interfacePath,
                       llvm::function_ref<bool(ASTContext&)> action) override {
    // Parse the interface file using the current context to get the additional
    // compiler arguments we should use when creating a sub-ASTContext.
    // These arguments are in "swift-module-flags:"
    version::Version Vers;
    StringRef CompilerVersion;
    llvm::BumpPtrAllocator Allocator;
    llvm::StringSaver SubArgSaver(Allocator);
    SmallVector<const char *, 64> SubArgs;
    if (extractSwiftInterfaceVersionAndArgs(ctx.SourceMgr, ctx.Diags,
                                            interfacePath, Vers, CompilerVersion,
                                            SubArgSaver, SubArgs)) {
      return true;
    }
    CompilerInvocation invok;

    // Inherit options from the parent ASTContext so we have all search paths, etc.
    inheritOptionsForBuildingInterface(invok, ctx.SearchPathOpts, ctx.LangOpts);
    CompilerInstance inst;
    // Use the additional flags to setup the compiler instance.
    if (invok.parseArgs(SubArgs, ctx.Diags)) {
      return true;
    }
    if (inst.setup(invok)) {
      return true;
    }
    // Add the diag consumers to the sub context to make sure we don't lose
    // diagnostics.
    for (auto *consumer: ctx.Diags.getConsumers()) {
      inst.getDiags().addConsumer(*consumer);
    }
    // Run the action under the sub-ASTContext.
    return action(inst.getASTContext());
  }
};

/// Resolve the direct dependencies of the given module.
static std::vector<ModuleDependencyID> resolveDirectDependencies(
    ASTContext &ctx, ModuleDependencyID module,
    ModuleDependenciesCache &cache) {
  auto knownDependencies = *cache.findDependencies(module.first, module.second);
  auto isSwift = knownDependencies.isSwiftModule();
  InterfaceSubASTContextDelegate ASTDelegate;
  // Find the dependencies of every module this module directly depends on.
  std::vector<ModuleDependencyID> result;
  for (auto dependsOn : knownDependencies.getModuleDependencies()) {
    // Figure out what kind of module we need.
    bool onlyClangModule = !isSwift || module.first == dependsOn;

    // Retrieve the dependencies for this module.
    if (auto found = ctx.getModuleDependencies(
            dependsOn, onlyClangModule, cache, ASTDelegate)) {
      result.push_back({dependsOn, found->getKind()});
    }
  }

  if (isSwift) {
    // A record of all of the Clang modules referenced from this Swift module.
    std::vector<std::string> allClangModules;
    llvm::StringSet<> knownModules;

    // If the Swift module has a bridging header, add those dependencies.
    if (knownDependencies.getBridgingHeader()) {
      auto clangImporter =
          static_cast<ClangImporter *>(ctx.getClangModuleLoader());
      if (!clangImporter->addBridgingHeaderDependencies(module.first, cache)) {
        // Grab the updated module dependencies.
        // FIXME: This is such a hack.
        knownDependencies = *cache.findDependencies(module.first, module.second);

        // Add the Clang modules referenced from the bridging header to the
        // set of Clang modules we know about.
        auto swiftDeps = knownDependencies.getAsSwiftModule();
        for (const auto &clangDep : swiftDeps->bridgingModuleDependencies) {
          findAllImportedClangModules(ctx, clangDep, cache, allClangModules,
                                      knownModules);
        }
      }
    }

    // Find all of the Clang modules this Swift module depends on.
    for (const auto &dep : result) {
      if (dep.second != ModuleDependenciesKind::Clang)
        continue;

      findAllImportedClangModules(ctx, dep.first, cache, allClangModules,
                                  knownModules);
    }

    // Look for overlays for each of the Clang modules. The Swift module
    // directly depends on these.
    for (const auto &clangDep : allClangModules) {
      if (auto found = ctx.getModuleDependencies(
              clangDep, /*onlyClangModule=*/false, cache, ASTDelegate)) {
        if (found->getKind() == ModuleDependenciesKind::Swift)
          result.push_back({clangDep, found->getKind()});
      }
    }
  }

  return result;
}

/// Write a single JSON field.
namespace {
  template<typename T>
  void writeJSONSingleField(llvm::raw_ostream &out,
                            StringRef fieldName,
                            const T &value,
                            unsigned indentLevel,
                            bool trailingComma);

  /// Write a string value as JSON.
  void writeJSONValue(llvm::raw_ostream &out,
                      StringRef value,
                      unsigned indentLevel) {
    out << "\"";
    out.write_escaped(value);
    out << "\"";
  }

  /// Write a module identifier.
  void writeJSONValue(llvm::raw_ostream &out,
                      const ModuleDependencyID &module,
                      unsigned indentLevel) {
    out << "{\n";

    writeJSONSingleField(
        out,
        module.second == ModuleDependenciesKind::Swift ? "swift" : "clang",
        module.first,
        indentLevel + 1,
        /*trailingComma=*/false);

    out.indent(indentLevel * 2);
    out << "}";
  }

  /// Write a JSON array.
  template<typename T>
  void writeJSONValue(llvm::raw_ostream &out,
                      ArrayRef<T> values,
                      unsigned indentLevel) {
    out << "[\n";

    for (const auto &value: values) {

      out.indent((indentLevel + 1) * 2);

      writeJSONValue(out, value, indentLevel + 1);

      if (&value != &values.back()) {
        out << ",";
      }
      out << "\n";
    }

    out.indent(indentLevel * 2);
    out << "]";
  }

  /// Write a JSON array.
  template<typename T>
  void writeJSONValue(llvm::raw_ostream &out,
                      const std::vector<T> &values,
                      unsigned indentLevel) {
    writeJSONValue(out, llvm::makeArrayRef(values), indentLevel);
  }

  /// Write a single JSON field.
  template<typename T>
  void writeJSONSingleField(llvm::raw_ostream &out,
                            StringRef fieldName,
                            const T &value,
                            unsigned indentLevel,
                            bool trailingComma) {
    out.indent(indentLevel * 2);
    writeJSONValue(out, fieldName, indentLevel);
    out << ": ";
    writeJSONValue(out, value, indentLevel);
    if (trailingComma)
      out << ",";
    out << "\n";
  }
}

static void writeJSON(llvm::raw_ostream &out,
                      ASTContext &ctx,
                      ModuleDependenciesCache &cache,
                      ArrayRef<ModuleDependencyID> allModules) {
  // Write out a JSON description of all of the dependencies.
  out << "{\n";
  SWIFT_DEFER {
    out << "}\n";
  };

  // Name of the main module.
  writeJSONSingleField(out, "mainModuleName", allModules.front().first,
                       /*indentLevel=*/1, /*trailingComma=*/true);

  // Write out all of the modules.
  out << "  \"modules\": [\n";
  SWIFT_DEFER {
    out << "  ]\n";
  };
  for (const auto &module : allModules) {
    auto directDependencies = resolveDirectDependencies(
        ctx, ModuleDependencyID(module.first, module.second), cache);

    // Grab the completed module dependencies.
    auto moduleDeps = *cache.findDependencies(module.first, module.second);

    // The module we are describing.
    out.indent(2 * 2);
    writeJSONValue(out, module, 2);
    out << ",\n";

    out.indent(2 * 2);
    out << "{\n";

    // Module path.
    const char *modulePathSuffix =
        moduleDeps.isSwiftModule() ? ".swiftmodule" : ".pcm";
    std::string modulePath = module.first + modulePathSuffix;
    writeJSONSingleField(out, "modulePath", modulePath, /*indentLevel=*/3,
                         /*trailingComma=*/true);

    // Source files.
    auto swiftDeps = moduleDeps.getAsSwiftModule();
    auto clangDeps = moduleDeps.getAsClangModule();
    if (swiftDeps) {
      writeJSONSingleField(out, "sourceFiles", swiftDeps->sourceFiles, 3,
                     /*trailingComma=*/true);
    } else {
      writeJSONSingleField(out, "sourceFiles", clangDeps->fileDependencies, 3,
                           /*trailingComma=*/true);
    }

    // Direct dependencies.
    writeJSONSingleField(out, "directDependencies", directDependencies,
                         3, /*trailingComma=*/true);

    // Swift and Clang-specific details.
    out.indent(3 * 2);
    out << "\"details\": {\n";
    out.indent(4 * 2);
    if (swiftDeps) {
      out << "\"swift\": {\n";

      /// Swift interface file, if any.
      if (swiftDeps->swiftInterfaceFile) {
        writeJSONSingleField(
            out, "moduleInterfacePath",
            *swiftDeps->swiftInterfaceFile, 5,
            /*trailingComma=*/swiftDeps->bridgingHeaderFile.hasValue());
      }

      /// Bridging header and its source file dependencies, if any.
      if (swiftDeps->bridgingHeaderFile) {
        out.indent(5 * 2);
        out << "\"bridgingHeader\": {\n";
        writeJSONSingleField(out, "path",
                             *swiftDeps->bridgingHeaderFile, 6,
                             /*trailingComma=*/true);
        writeJSONSingleField(out, "sourceFiles",
                             swiftDeps->bridgingSourceFiles, 6,
                             /*trailingComma=*/true);
        writeJSONSingleField(out, "moduleDependencies",
                             swiftDeps->bridgingModuleDependencies, 6,
                             /*trailingComma=*/false);
        out.indent(5 * 2);
        out << "}\n";
      }
    } else {
      out << "\"clang\": {\n";

      // Module map file.
      writeJSONSingleField(out, "moduleMapPath",
                           clangDeps->moduleMapFile, 5,
                           /*trailingComma=*/true);

      // Context hash.
      writeJSONSingleField(out, "contextHash",
                           clangDeps->contextHash, 5,
                           /*trailingComma=*/true);

      // Command line.
      writeJSONSingleField(out, "commandLine",
                           clangDeps->nonPathCommandLine, 5,
                           /*trailingComma=*/false);
    }

    out.indent(4 * 2);
    out << "}\n";
    out.indent(3 * 2);
    out << "}\n";

    out.indent(2 * 2);
    out << "}";

    if (&module != &allModules.back())
      out << ",";
    out << "\n";
  }
}

bool swift::scanDependencies(CompilerInstance &instance) {
  ASTContext &Context = instance.getASTContext();
  ModuleDecl *mainModule = instance.getMainModule();
  const CompilerInvocation &invocation = instance.getInvocation();
  const FrontendOptions &opts = invocation.getFrontendOptions();

  std::string path = opts.InputsAndOutputs.getSingleOutputFilename();
  std::error_code EC;
  llvm::raw_fd_ostream out(path, EC, llvm::sys::fs::F_None);

  if (out.has_error() || EC) {
    Context.Diags.diagnose(SourceLoc(), diag::error_opening_output, path,
                           EC.message());
    out.clear_error();
    return true;
  }

  // Main module file name.
  auto newExt = file_types::getExtension(file_types::TY_SwiftModuleFile);
  llvm::SmallString<32> mainModulePath = mainModule->getName().str();
  llvm::sys::path::replace_extension(mainModulePath, newExt);

  // Compute the dependencies of the main module.
  auto mainDependencies =
      ModuleDependencies::forSwiftModule(mainModulePath.str().str());
  {
    llvm::StringSet<> alreadyAddedModules;
    for (auto fileUnit : mainModule->getFiles()) {
      auto sf = dyn_cast<SourceFile>(fileUnit);
      if (!sf)
        continue;

      mainDependencies.addModuleDependencies(*sf, alreadyAddedModules);
    }

    const auto &importInfo = mainModule->getImplicitImportInfo();

    // Swift standard library.
    switch (importInfo.StdlibKind) {
    case ImplicitStdlibKind::None:
    case ImplicitStdlibKind::Builtin:
      break;

    case ImplicitStdlibKind::Stdlib:
      mainDependencies.addModuleDependency("Swift", alreadyAddedModules);
      break;
    }

    // Swift -Onone support library.
    if (invocation.shouldImportSwiftONoneSupport()) {
      mainDependencies.addModuleDependency(
          SWIFT_ONONE_SUPPORT, alreadyAddedModules);
    }

    // Add any implicit module names.
    for (const auto &moduleName : importInfo.ModuleNames) {
      mainDependencies.addModuleDependency(moduleName.str(), alreadyAddedModules);
    }

    // Already-loaded, implicitly imported module names.
    for (const auto &module : importInfo.AdditionalModules) {
      mainDependencies.addModuleDependency(module.first->getNameStr(), alreadyAddedModules);
    }

    // Add the bridging header.
    if (!importInfo.BridgingHeaderPath.empty()) {
      mainDependencies.addBridgingHeader(importInfo.BridgingHeaderPath);
    }

    // If we are to import the underlying Clang module of the same name,
    // add a dependency with the same name to trigger the search.
    if (importInfo.ShouldImportUnderlyingModule) {
      mainDependencies.addModuleDependency(mainModule->getName().str(),
                                           alreadyAddedModules);
    }
  }

  // Add the main module.
  StringRef mainModuleName = mainModule->getNameStr();
  llvm::SetVector<ModuleDependencyID, std::vector<ModuleDependencyID>,
                  std::set<ModuleDependencyID>> allModules;
  
  allModules.insert({mainModuleName.str(), mainDependencies.getKind()});

  // Create the module dependency cache.
  ModuleDependenciesCache cache;
  cache.recordDependencies(mainModuleName, std::move(mainDependencies),
                           ModuleDependenciesKind::Swift);

  // Explore the dependencies of every module.
  for (unsigned currentModuleIdx = 0;
       currentModuleIdx < allModules.size();
       ++currentModuleIdx) {
    auto module = allModules[currentModuleIdx];
    auto discoveredModules =
        resolveDirectDependencies(Context, module, cache);
    allModules.insert(discoveredModules.begin(), discoveredModules.end());
  }

  // Write out the JSON description.
  writeJSON(out, Context, cache, allModules.getArrayRef());

  // Update the dependency tracker.
  if (auto depTracker = instance.getDependencyTracker()) {
    for (auto module : allModules) {
      auto deps = cache.findDependencies(module.first, module.second);
      if (!deps)
        continue;

      if (auto swiftDeps = deps->getAsSwiftModule()) {
        if (auto swiftInterfaceFile = swiftDeps->swiftInterfaceFile)
          depTracker->addDependency(*swiftInterfaceFile, /*IsSystem=*/false);
        for (const auto &sourceFile : swiftDeps->sourceFiles)
          depTracker->addDependency(sourceFile, /*IsSystem=*/false);
        for (const auto &bridgingSourceFile : swiftDeps->bridgingSourceFiles)
          depTracker->addDependency(bridgingSourceFile, /*IsSystem=*/false);
      } else {
        auto clangDeps = deps->getAsClangModule();
        if (!clangDeps->moduleMapFile.empty())
          depTracker->addDependency(clangDeps->moduleMapFile, /*IsSystem=*/false);
        for (const auto &sourceFile : clangDeps->fileDependencies)
          depTracker->addDependency(sourceFile, /*IsSystem=*/false);
      }
    }
  }

  // This process succeeds regardless of whether any errors occurred.
  // FIXME: We shouldn't need this, but it's masking bugs in our scanning
  // logic where we don't create a fresh context when scanning Swift interfaces
  // that includes their own command-line flags.
  Context.Diags.resetHadAnyError();
  return false;
}
