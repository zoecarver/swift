//===--- SILOpt.cpp - SIL Optimization Driver -----------------------------===//
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
// This is a tool for reading sil files and running sil passes on them. The
// targeted usecase is debugging and testing SIL passes.
//
//===----------------------------------------------------------------------===//

#include "swift/AST/DiagnosticsFrontend.h"
#include "swift/AST/SILOptions.h"
#include "swift/Basic/FileTypes.h"
#include "swift/Basic/LLVMContext.h"
#include "swift/Basic/LLVMInitialize.h"
#include "swift/Frontend/DiagnosticVerifier.h"
#include "swift/Frontend/Frontend.h"
#include "swift/Frontend/PrintingDiagnosticConsumer.h"
#include "swift/IRGen/IRGenPublic.h"
#include "swift/IRGen/IRGenSILPasses.h"
#include "swift/SIL/SILRemarkStreamer.h"
#include "swift/SILOptimizer/Analysis/Analysis.h"
#include "swift/SILOptimizer/PassManager/PassManager.h"
#include "swift/SILOptimizer/PassManager/Passes.h"
#include "swift/Serialization/SerializationOptions.h"
#include "swift/Serialization/SerializedModuleLoader.h"
#include "swift/Serialization/SerializedSILLoader.h"
#include "swift/Subsystems.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/ManagedStatic.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/Signals.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/YAMLTraits.h"
#include <cstdio>
#include <sstream>
using namespace swift;

namespace cl = llvm::cl;

namespace {

enum class OptGroup { Unknown, Diagnostics, Performance, Lowering };

} // end anonymous namespace

static llvm::cl::opt<std::string>
    InputFilename1(llvm::cl::desc("first input file"), llvm::cl::init("-"),
                   llvm::cl::Positional);

static llvm::cl::opt<std::string>
    InputFilename2(llvm::cl::desc("second input file"), llvm::cl::init("-"),
                   llvm::cl::Positional);

static llvm::cl::opt<std::string>
    OutputFilename1("o1", llvm::cl::desc("first output filename"));

static llvm::cl::opt<std::string>
    OutputFilename2("o2", llvm::cl::desc("second output filename"));

static llvm::cl::list<std::string>
    ImportPaths("I",
                llvm::cl::desc("add a directory to the import search path"));

static llvm::cl::list<std::string> FrameworkPaths(
    "F", llvm::cl::desc("add a directory to the framework search path"));

static llvm::cl::opt<std::string>
    ModuleName("module-name",
               llvm::cl::desc("The name of the module if processing"
                              " a module. Necessary for processing "
                              "stdin."));

static llvm::cl::opt<bool> EnableLibraryEvolution(
    "enable-library-evolution",
    llvm::cl::desc("Compile the module to export resilient "
                   "interfaces for all public declarations by "
                   "default"));

static llvm::cl::opt<bool> DisableSILOwnershipVerifier(
    "disable-sil-ownership-verifier",
    llvm::cl::desc(
        "Do not verify SIL ownership invariants during SIL verification"));

static llvm::cl::opt<bool> EnableOwnershipLoweringAfterDiagnostics(
    "enable-ownership-lowering-after-diagnostics",
    llvm::cl::desc("Enable ownership lowering after diagnostics"),
    llvm::cl::init(false));

static llvm::cl::opt<bool> EnableSILOpaqueValues(
    "enable-sil-opaque-values",
    llvm::cl::desc("Compile the module with sil-opaque-values enabled."));

static llvm::cl::opt<bool>
    EnableObjCInterop("enable-objc-interop",
                      llvm::cl::desc("Enable Objective-C interoperability."));

static llvm::cl::opt<bool>
    DisableObjCInterop("disable-objc-interop",
                       llvm::cl::desc("Disable Objective-C interoperability."));

static llvm::cl::opt<bool> VerifyExclusivity(
    "enable-verify-exclusivity",
    llvm::cl::desc("Verify the access markers used to enforce exclusivity."));

static llvm::cl::opt<bool> EnableSpeculativeDevirtualization(
    "enable-spec-devirt",
    llvm::cl::desc("Enable Speculative Devirtualization pass."));

namespace {
enum EnforceExclusivityMode {
  Unchecked, // static only
  Checked,   // static and dynamic
  DynamicOnly,
  None
};
} // end anonymous namespace

static cl::opt<EnforceExclusivityMode> EnforceExclusivity(
    "enforce-exclusivity",
    cl::desc("Enforce law of exclusivity "
             "(and support memory access markers)."),
    cl::init(EnforceExclusivityMode::Checked),
    cl::values(clEnumValN(EnforceExclusivityMode::Unchecked, "unchecked",
                          "Static checking only."),
               clEnumValN(EnforceExclusivityMode::Checked, "checked",
                          "Static and dynamic checking."),
               clEnumValN(EnforceExclusivityMode::DynamicOnly, "dynamic-only",
                          "Dynamic checking only."),
               clEnumValN(EnforceExclusivityMode::None, "none",
                          "No exclusivity checking.")));

static llvm::cl::opt<std::string> ResourceDir(
    "resource-dir",
    llvm::cl::desc("The directory that holds the compiler resource files"));

static llvm::cl::opt<std::string>
    SDKPath("sdk",
            llvm::cl::desc("The path to the SDK for use with the clang "
                           "importer."),
            llvm::cl::init(""));

static llvm::cl::opt<std::string>
    Target("target", llvm::cl::desc("target triple"),
           llvm::cl::init(llvm::sys::getDefaultTargetTriple()));

static llvm::cl::list<PassKind> Passes(llvm::cl::desc("Passes:"),
                                       llvm::cl::values(
#define PASS(ID, TAG, NAME) clEnumValN(PassKind::ID, TAG, NAME),
#include "swift/SILOptimizer/PassManager/Passes.def"
                                           clEnumValN(0, "", "")));

static llvm::cl::opt<bool>
    PrintStats("print-stats", llvm::cl::desc("Print various statistics"));

static llvm::cl::opt<unsigned> AssertConfId("assert-conf-id", llvm::cl::Hidden,
                                            llvm::cl::init(0));

static llvm::cl::opt<bool>
    DisableSILLinking("disable-sil-linking",
                      llvm::cl::desc("Disable SIL linking"));

static llvm::cl::opt<int> SILInlineThreshold("sil-inline-threshold",
                                             llvm::cl::Hidden,
                                             llvm::cl::init(-1));

static llvm::cl::opt<bool> EnableSILVerifyAll(
    "enable-sil-verify-all", llvm::cl::Hidden, llvm::cl::init(true),
    llvm::cl::desc("Run sil verifications after every pass."));

static llvm::cl::opt<bool> RemoveRuntimeAsserts(
    "remove-runtime-asserts", llvm::cl::Hidden, llvm::cl::init(false),
    llvm::cl::desc("Remove runtime assertions (cond_fail)."));

static llvm::cl::opt<bool>
    EmitVerboseSIL("emit-verbose-sil",
                   llvm::cl::desc("Emit locations during sil emission."));

static llvm::cl::opt<std::string>
    ModuleCachePath("module-cache-path",
                    llvm::cl::desc("Clang module cache path"));

static llvm::cl::opt<bool> EnableSILSortOutput(
    "emit-sorted-sil", llvm::cl::Hidden, llvm::cl::init(false),
    llvm::cl::desc("Sort Functions, VTables, Globals, "
                   "WitnessTables by name to ease diffing."));

static llvm::cl::opt<bool> DisableASTDump("sil-disable-ast-dump",
                                          llvm::cl::Hidden,
                                          llvm::cl::init(false),
                                          llvm::cl::desc("Do not dump AST."));

static llvm::cl::opt<bool>
    PerformWMO("wmo", llvm::cl::desc("Enable whole-module optimizations"));

static llvm::cl::opt<bool> EnableExperimentalStaticAssert(
    "enable-experimental-static-assert", llvm::cl::Hidden,
    llvm::cl::init(false), llvm::cl::desc("Enable experimental #assert"));

static llvm::cl::opt<bool> EnableExperimentalDifferentiableProgramming(
    "enable-experimental-differentiable-programming", llvm::cl::Hidden,
    llvm::cl::init(false),
    llvm::cl::desc("Enable experimental differentiable programming"));

static cl::opt<std::string> PassRemarksPassed(
    "sil-remarks", cl::value_desc("pattern"),
    cl::desc(
        "Enable performed optimization remarks from passes whose name match "
        "the given regular expression"),
    cl::Hidden);

static cl::opt<std::string> PassRemarksMissed(
    "sil-remarks-missed", cl::value_desc("pattern"),
    cl::desc("Enable missed optimization remarks from passes whose name match "
             "the given regular expression"),
    cl::Hidden);

static cl::opt<std::string>
    RemarksFilename("save-optimization-record-path",
                    cl::desc("YAML output filename for pass remarks"),
                    cl::value_desc("filename"));

static cl::opt<std::string> RemarksPasses(
    "save-optimization-record-passes",
    cl::desc("Only include passes which match a specified regular expression "
             "in the generated optimization record (by default, include all "
             "passes)"),
    cl::value_desc("regex"));

// sil-opt doesn't have the equivalent of -save-optimization-record=<format>.
// Instead, use -save-optimization-record-format <format>.
static cl::opt<std::string> RemarksFormat(
    "save-optimization-record-format",
    cl::desc("The format used for serializing remarks (default: YAML)"),
    cl::value_desc("format"), cl::init("yaml"));

// This function isn't referenced outside its translation unit, but it
// can't use the "static" keyword because its address is used for
// getMainExecutable (since some platforms don't support taking the
// address of main, and some platforms can't implement getMainExecutable
// without being given the address of a function in the main executable).
void anchorForGetMainExecutable() {}

static unsigned getCompilerInstanceForFile(std::string fileName,
                                           CompilerInvocation &invocation,
                                           CompilerInstance &instance) {
  serialization::ExtendedValidationInfo extendedInfo;
  llvm::ErrorOr<std::unique_ptr<llvm::MemoryBuffer>> FileBufOrErr =
      invocation.setUpInputForSILTool(fileName, ModuleName,
                                      /*alwaysSetModuleToMain*/ false,
                                      /*bePrimary*/ !PerformWMO, extendedInfo);
  if (!FileBufOrErr) {
    fprintf(stderr, "Error! Failed to open file: %s\n", InputFilename1.c_str());
    exit(-1);
  }

  if (instance.setup(invocation))
    return 1;

  instance.performSema();

  // If parsing produced an error, don't run any passes.
  if (instance.getASTContext().hadError())
    return 1;

  return 0;
}

static void setupInvocation(char *firstArg, CompilerInvocation &invocation) {
  invocation.setMainExecutablePath(llvm::sys::fs::getMainExecutable(
      firstArg, reinterpret_cast<void *>(&anchorForGetMainExecutable)));

  // Give the context the list of search paths to use for modules.
  invocation.setImportSearchPaths(ImportPaths);
  std::vector<SearchPathOptions::FrameworkSearchPath> FramePaths;
  for (const auto &path : FrameworkPaths) {
    FramePaths.push_back({path, /*isSystem=*/false});
  }
  invocation.setFrameworkSearchPaths(FramePaths);
  // Set the SDK path and target if given.
  if (SDKPath.getNumOccurrences() == 0) {
    const char *SDKROOT = getenv("SDKROOT");
    if (SDKROOT)
      SDKPath = SDKROOT;
  }
  if (!SDKPath.empty())
    invocation.setSDKPath(SDKPath);
  if (!Target.empty())
    invocation.setTargetTriple(Target);
  if (!ResourceDir.empty())
    invocation.setRuntimeResourcePath(ResourceDir);
  invocation.getFrontendOptions().EnableLibraryEvolution =
      EnableLibraryEvolution;
  // Set the module cache path. If not passed in we use the default swift module
  // cache.
  invocation.getClangImporterOptions().ModuleCachePath = ModuleCachePath;
  invocation.setParseStdlib();
  invocation.getLangOptions().DisableAvailabilityChecking = true;
  invocation.getLangOptions().EnableAccessControl = false;
  invocation.getLangOptions().EnableObjCAttrRequiresFoundation = false;
  invocation.getLangOptions().EnableObjCInterop =
      EnableObjCInterop
          ? true
          : DisableObjCInterop ? false : llvm::Triple(Target).isOSDarwin();

  invocation.getLangOptions().EnableSILOpaqueValues = EnableSILOpaqueValues;

  invocation.getLangOptions().EnableExperimentalStaticAssert =
      EnableExperimentalStaticAssert;

  invocation.getLangOptions().EnableExperimentalDifferentiableProgramming =
      EnableExperimentalDifferentiableProgramming;

  invocation.getDiagnosticOptions().VerifyMode = DiagnosticOptions::NoVerify;

  // Setup the SIL Options.
  SILOptions &options = invocation.getSILOptions();
  options.InlineThreshold = SILInlineThreshold;
  options.VerifyAll = EnableSILVerifyAll;
  options.RemoveRuntimeAsserts = RemoveRuntimeAsserts;
  options.AssertConfig = AssertConfId;
  options.VerifySILOwnership = !DisableSILOwnershipVerifier;
  options.StripOwnershipAfterSerialization =
      EnableOwnershipLoweringAfterDiagnostics;

  options.VerifyExclusivity = VerifyExclusivity;
  if (EnforceExclusivity.getNumOccurrences() != 0) {
    switch (EnforceExclusivity) {
    case EnforceExclusivityMode::Unchecked:
      // This option is analogous to the -Ounchecked optimization setting.
      // It will disable dynamic checking but still diagnose statically.
      options.EnforceExclusivityStatic = true;
      options.EnforceExclusivityDynamic = false;
      break;
    case EnforceExclusivityMode::Checked:
      options.EnforceExclusivityStatic = true;
      options.EnforceExclusivityDynamic = true;
      break;
    case EnforceExclusivityMode::DynamicOnly:
      // This option is intended for staging purposes. The intent is that
      // it will eventually be removed.
      options.EnforceExclusivityStatic = false;
      options.EnforceExclusivityDynamic = true;
      break;
    case EnforceExclusivityMode::None:
      // This option is for staging purposes.
      options.EnforceExclusivityStatic = false;
      options.EnforceExclusivityDynamic = false;
      break;
    }
  }

  options.EnableSpeculativeDevirtualization = EnableSpeculativeDevirtualization;
}

int main(int argc, char **argv) {
  PROGRAM_START(argc, argv);
  INITIALIZE_LLVM();

  llvm::cl::ParseCommandLineOptions(argc, argv, "Swift SIL Diff Utility\n");

  if (PrintStats)
    llvm::EnableStatistics();

  CompilerInvocation invocation1;
  setupInvocation(argv[0], invocation1);
  CompilerInvocation invocation2;
  setupInvocation(argv[0], invocation2);

  CompilerInstance instance1;
  CompilerInstance instance2;
  PrintingDiagnosticConsumer diags;
  instance1.addDiagnosticConsumer(&diags);
  instance2.addDiagnosticConsumer(&diags);

  auto finishDiagProcessingWithError = [&](int retValue) -> int {
    diags.setSuppressOutput(false);
    bool diagnosticsError1 = instance1.getDiags().finishProcessing();
    bool diagnosticsError2 = instance2.getDiags().finishProcessing();
    // If the verifier is enabled and did not encounter any verification errors,
    // return 0 even if the compile failed. This behavior isn't ideal, but large
    // parts of the test suite are reliant on it.
    if (!diagnosticsError1 && !diagnosticsError2) {
      return 0;
    }
    return retValue
               ? retValue
               : (diagnosticsError1 ? diagnosticsError1 : diagnosticsError2);
  };

  int err = getCompilerInstanceForFile(InputFilename1, invocation1, instance1);
  if (err)
    return finishDiagProcessingWithError(err);
  err = getCompilerInstanceForFile(InputFilename2, invocation2, instance2);
  if (err)
    return finishDiagProcessingWithError(err);

  std::string out1, out2;
  llvm::raw_string_ostream os1(out1);
  SILPrintContext printerCtx1(os1);
  llvm::raw_string_ostream os2(out2);
  SILPrintContext printerCtx2(os2);

  unsigned uniqueId = 100000000;

  auto cmpInsts = [](auto a, auto b) -> bool {
    return a->getKind() == b->getKind() &&
           a->getResults().size() == b->getResults().size() &&
           a->getAllOperands().size() == b->getAllOperands().size();
  };

  auto makeIDUnique = [&uniqueId](auto nodeIter, SILPrintContext &printerCtx) {
    auto node = &*nodeIter;
    if (node->getResults().empty()) {
      unsigned &id = printerCtx.getIDNumberRef(node);
      id = uniqueId++;
      return;
    }
    for (auto result : node->getResults()) {
      unsigned &id = printerCtx.getIDNumberRef(result);
      id = uniqueId++;
    }
  };

  auto pushBackIDs = [](unsigned n, auto from, auto to,
                        SILPrintContext &printerCtx) {
    for (; from != to; ++from) {
      auto node = &*from;
      unsigned &id = printerCtx.getIDNumberRef(node);
      id -= n;
      for (auto result : node->getResults()) {
        unsigned &id = printerCtx.getIDNumberRef(result);
        id -= n;
      }
    }
  };

  auto begin1 = instance1.getSILModule()->getFunctions().begin();
  auto end1 = instance1.getSILModule()->getFunctions().end();
  auto begin2 = instance2.getSILModule()->getFunctions().begin();
  auto end2 = instance2.getSILModule()->getFunctions().end();
  for (; begin1 != end1 && begin2 != end2; ++begin1, ++begin2) {
    if (begin1->getName() == begin2->getName())
      llvm::errs() << "Warning: found function signatures that do not match.\n";

    // Print the declaration for the functions.
    begin1->print(printerCtx1, /*declOnly*/ true);
    begin2->print(printerCtx2, /*declOnly*/ true);
    os1 << "{\n";
    os2 << "{\n";

    auto bbBegin1 = begin1->begin();
    auto bbEnd1 = begin1->end();
    auto bbBegin2 = begin2->begin();
    auto bbEnd2 = begin2->end();
    for (; bbBegin1 != bbEnd1 && bbBegin2 != bbEnd2; ++bbBegin1, ++bbBegin2) {
      // Print the label and arugments of both blocks.
      os1 << printerCtx1.getID(&*bbBegin1);
      bbBegin1->printArguments(printerCtx1);
      os1 << ":\n";
      os2 << printerCtx1.getID(&*bbBegin2);
      bbBegin2->printArguments(printerCtx2);
      os2 << ":\n";

      auto instBegin1 = bbBegin1->begin();
      auto instEnd1 = bbBegin1->end();
      auto instBegin2 = bbBegin2->begin();
      auto instEnd2 = bbBegin2->end();
      for (; instBegin1 != instEnd1 && instBegin2 != instEnd2;
           ++instBegin1, ++instBegin2) {
        if (instBegin1 == instEnd1) {
          for (; instBegin2 != instEnd2; ++instBegin2) {
            instBegin2->print(printerCtx2, /*printContextInfo*/false);
          }
          break;
        } else if (instBegin2 == instEnd2) {
          for (; instBegin1 != instEnd1; ++instBegin1) {
            instBegin1->print(printerCtx1, /*printContextInfo*/false);
          }
          break;
        }

        if (cmpInsts(instBegin1, instBegin2)) {
          instBegin1->print(printerCtx1, /*printContextInfo*/false);
          instBegin2->print(printerCtx2, /*printContextInfo*/false);
          continue;
        }
        bool foundMatchLater = false;
        auto tmpIter = instBegin1;
        for (; tmpIter != instEnd1; ++tmpIter) {
          if (cmpInsts(tmpIter, instBegin2)) {
            foundMatchLater = true;
            break;
          }
        }
        if (foundMatchLater) {
          for (; instBegin1 != tmpIter; ++instBegin1) {
            makeIDUnique(instBegin1, printerCtx1);
            pushBackIDs(1, instBegin1, instEnd1, printerCtx1);
            instBegin1->print(printerCtx1, /*printContextInfo*/false);
          }
          instBegin1->print(printerCtx1, /*printContextInfo*/false);
          instBegin2->print(printerCtx2, /*printContextInfo*/false);
          continue;
        }
        // Move the second iterator forward and keep the first one still.
        if (instBegin1 == bbBegin1->begin()) {
          // If this is the first instruction, we can't move it back.
          // TODO: resolve this edge case.
          makeIDUnique(instBegin1, printerCtx1);
          pushBackIDs(1, instBegin1, instEnd1, printerCtx1);
          instBegin1->print(printerCtx1, /*printContextInfo*/false);
        } else {
          // Move this iterator back so it's in the same place next time.
          (void)--instBegin1;
        }
        makeIDUnique(instBegin2, printerCtx2);
        pushBackIDs(1, instBegin2, instEnd2, printerCtx2);
        instBegin2->print(printerCtx2, /*printContextInfo*/false);
      }
    }
    os1 << "}\n";
    os2 << "}\n";
  }

  const StringRef outputFile1 = StringRef(OutputFilename1);
  const StringRef outputFile2 = StringRef(OutputFilename2);
  if (outputFile1.empty() || outputFile2.empty()) {
    llvm::errs() << "Exactly two output files must be selected.\n";
    return finishDiagProcessingWithError(1);
  }

  auto outputOptions = SILOptions();
  outputOptions.EmitVerboseSIL = EmitVerboseSIL;
  outputOptions.EmitSortedSIL = EnableSILSortOutput;

  std::error_code errCode;
  llvm::raw_fd_ostream outStream1(outputFile1, errCode, llvm::sys::fs::F_None);
  if (errCode) {
    llvm::errs() << "while opening '" << outputFile1
                 << "': " << errCode.message() << '\n';
    return finishDiagProcessingWithError(1);
  }

  errCode = std::error_code();
  llvm::raw_fd_ostream outStream2(outputFile2, errCode, llvm::sys::fs::F_None);
  if (errCode) {
    llvm::errs() << "while opening '" << outputFile2
                 << "': " << errCode.message() << '\n';
    return finishDiagProcessingWithError(1);
  }

  // TODO: print to the file instead.
  os1.flush();
  os2.flush();
  llvm::errs() << out1 << "\n\n\n" << out2;

  bool hadError = (instance1.getASTContext().hadError() ||
                   instance2.getASTContext().hadError());
  return finishDiagProcessingWithError(hadError);
}
