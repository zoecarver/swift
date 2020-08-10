//===-- LocalizationFormat.cpp - Format for Diagnostic Messages -*- C++ -*-===//
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
//
// This file implements the format for localized diagnostic messages.
//
//===----------------------------------------------------------------------===//

#include "swift/AST/LocalizationFormat.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Bitstream/BitstreamReader.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/YAMLParser.h"
#include "llvm/Support/YAMLTraits.h"
#include <cstdint>
#include <string>
#include <system_error>
#include <type_traits>

namespace {
enum LocalDiagID : uint32_t {
#define DIAG(KIND, ID, Options, Text, Signature) ID,
#include "swift/AST/DiagnosticsAll.def"
  NumDiags
};

struct DiagnosticNode {
  uint32_t id;
  std::string msg;
};
} // namespace

namespace llvm {
namespace yaml {

template <> struct ScalarEnumerationTraits<LocalDiagID> {
  static void enumeration(IO &io, LocalDiagID &value) {
#define DIAG(KIND, ID, Options, Text, Signature)                               \
  io.enumCase(value, #ID, LocalDiagID::ID);
#include "swift/AST/DiagnosticsAll.def"
    // Ignore diagnostic IDs that are available in the YAML file and not
    // available in the `.def` file.
    if (io.matchEnumFallback())
      value = LocalDiagID::NumDiags;
  }
};

template <> struct MappingTraits<DiagnosticNode> {
  static void mapping(IO &io, DiagnosticNode &node) {
    LocalDiagID diagID;
    io.mapRequired("id", diagID);
    io.mapRequired("msg", node.msg);
    node.id = static_cast<uint32_t>(diagID);
  }
};

} // namespace yaml
} // namespace llvm

namespace swift {
namespace diag {

void SerializedLocalizationWriter::insert(swift::DiagID id,
                                          llvm::StringRef translation) {
  generator.insert(static_cast<uint32_t>(id), translation);
}

bool SerializedLocalizationWriter::emit(llvm::StringRef filePath) {
  assert(llvm::sys::path::extension(filePath) == ".db");
  std::error_code error;
  llvm::raw_fd_ostream OS(filePath, error, llvm::sys::fs::F_None);
  if (OS.has_error()) {
    return true;
  }

  offset_type offset;
  {
    llvm::support::endian::write<offset_type>(OS, 0, llvm::support::little);
    offset = generator.Emit(OS);
  }
  OS.seek(0);
  llvm::support::endian::write(OS, offset, llvm::support::little);
  OS.close();

  return OS.has_error();
}

SerializedLocalizationProducer::SerializedLocalizationProducer(
    std::unique_ptr<llvm::MemoryBuffer> buffer)
    : Buffer(std::move(buffer)) {
  auto base =
      reinterpret_cast<const unsigned char *>(Buffer.get()->getBufferStart());
  auto tableOffset = endian::read<offset_type>(base, little);
  SerializedTable.reset(SerializedLocalizationTable::Create(
      base + tableOffset, base + sizeof(offset_type), base));
}

llvm::StringRef SerializedLocalizationProducer::getMessageOr(
    swift::DiagID id, llvm::StringRef defaultMessage) const {
  auto value = SerializedTable.get()->find(id);
  llvm::StringRef diagnosticMessage((const char *)value.getDataPtr(),
                                    value.getDataLen());
  if (diagnosticMessage.empty())
    return defaultMessage;

  return diagnosticMessage;
}

YAMLLocalizationProducer::YAMLLocalizationProducer(llvm::StringRef filePath) {
  auto FileBufOrErr = llvm::MemoryBuffer::getFileOrSTDIN(filePath);
  llvm::MemoryBuffer *document = FileBufOrErr->get();
  diag::LocalizationInput yin(document->getBuffer());
  yin >> diagnostics;
}

llvm::StringRef
YAMLLocalizationProducer::getMessageOr(swift::DiagID id,
                                       llvm::StringRef defaultMessage) const {
  if (diagnostics.empty())
    return defaultMessage;
  const std::string &diagnosticMessage = diagnostics[(unsigned)id];
  if (diagnosticMessage.empty())
    return defaultMessage;
  return diagnosticMessage;
}

void YAMLLocalizationProducer::forEachAvailable(
    llvm::function_ref<void(swift::DiagID, llvm::StringRef)> callback) const {
  for (uint32_t i = 0, n = diagnostics.size(); i != n; ++i) {
    auto translation = diagnostics[i];
    if (!translation.empty())
      callback(static_cast<swift::DiagID>(i), translation);
  }
}

template <typename T, typename Context>
typename std::enable_if<llvm::yaml::has_SequenceTraits<T>::value, void>::type
readYAML(llvm::yaml::IO &io, T &Seq, bool, Context &Ctx) {
  unsigned count = io.beginSequence();
  if (count)
    Seq.resize(LocalDiagID::NumDiags);
  for (unsigned i = 0; i < count; ++i) {
    void *SaveInfo;
    if (io.preflightElement(i, SaveInfo)) {
      DiagnosticNode current;
      yamlize(io, current, true, Ctx);
      io.postflightElement(SaveInfo);

      // A diagnostic ID might be present in YAML and not in `.def` file,
      // if that's the case ScalarEnumerationTraits will assign the diagnostic ID
      // to `LocalDiagID::NumDiags`. Since the diagnostic ID isn't available
      // in `.def` it shouldn't be stored in the diagnostics array.
      if (current.id != LocalDiagID::NumDiags) {
        // YAML file isn't guaranteed to have diagnostics in order of their
        // declaration in `.def` files, to accommodate that we need to leave
        // holes in diagnostic array for diagnostics which haven't yet been
        // localized and for the ones that have `DiagnosticNode::id`
        // indicates their position.
        Seq[static_cast<unsigned>(current.id)] = std::move(current.msg);
      }
    }
  }
  io.endSequence();
}

template <typename T>
typename std::enable_if<llvm::yaml::has_SequenceTraits<T>::value,
                        LocalizationInput &>::type
operator>>(LocalizationInput &yin, T &diagnostics) {
  llvm::yaml::EmptyContext Ctx;
  if (yin.setCurrentDocument()) {
    // If YAML file's format doesn't match the current format in
    // DiagnosticMessageFormat, will throw an error.
    readYAML(yin, diagnostics, true, Ctx);
  }
  return yin;
}

} // namespace diag
} // namespace swift
