// RUN: %empty-directory(%t)
// RUN: %clang -c -v %target-cc-options -g -O0 -isysroot %sdk %S/Inputs/isPrespecialized.cpp -o %t/isPrespecialized.o -I %clang-include-dir -I %swift_src_root/include/ -I %swift_src_root/../llvm-project/llvm/include -I %clang-include-dir/../../llvm-macosx-x86_64/include -L %clang-include-dir/../lib/swift/macosx

// RUN: %target-build-swift %S/Inputs/struct-public-nonfrozen-1argument.swift -emit-module -emit-library -module-name Module -Xfrontend -prespecialize-generic-metadata -target %module-target-future -emit-module-path %t/Module.swiftmodule -o %t/%target-library-name(Module)

// RUN: %target-build-swift -v %mcp_opt %s %S/Inputs/main.swift %S/Inputs/consume-logging-metadata-value.swift %t/isPrespecialized.o -import-objc-header %S/Inputs/isPrespecialized.h -Xfrontend -prespecialize-generic-metadata -target %module-target-future -lc++ -I %t -L %t -lModule -L %clang-include-dir/../lib/swift/macosx -sdk %sdk -o %t/main
// RUN: %target-codesign %t/main
// RUN: %target-run %t/main | %FileCheck %s


// REQUIRES: OS=macosx
// REQUIRES: executable_test
// UNSUPPORTED: use_os_stdlib
// UNSUPPORTED: swift_test_mode_optimize
// UNSUPPORTED: swift_test_mode_optimize_size

import Module

func ptr<T>(to ty: T.Type) -> UnsafeMutableRawPointer {
    UnsafeMutableRawPointer(mutating: unsafePointerToMetadata(of: ty))!
}

struct FirstUsageDynamic {}
struct FirstUsageStatic {}

@inline(never)
func consumeType<T>(oneArgument: Module.OneArgument<T>.Type, line: UInt = #line) {
  consumeType(oneArgument, line: line)
}

@inline(never)
func consumeType_OneArgumentAtFirstUsageStatic_Static(line: UInt = #line) {
  consumeType(OneArgument<FirstUsageStatic>.self, line: line)
}

@inline(never)
func consumeType_OneArgumentAtFirstUsageStatic_Dynamic(line: UInt = #line) {
  consumeType(oneArgument: OneArgument<FirstUsageStatic>.self, line: line)
}

@inline(never)
func consumeType_OneArgumentAtFirstUsageDynamic_Static(line: UInt = #line) {
  consumeType(OneArgument<FirstUsageDynamic>.self, line: line)
}

@inline(never)
func consumeType_OneArgumentAtFirstUsageDynamic_Dynamic(line: UInt = #line) {
  consumeType(oneArgument: OneArgument<FirstUsageDynamic>.self, line: line)
}

@inline(never)
func doit() {
  // CHECK: [[STATIC_METADATA_ADDRESS:[0-9a-f]+]] @ 54
  consumeType_OneArgumentAtFirstUsageStatic_Static()
  // CHECK: [[STATIC_METADATA_ADDRESS]] @ 56
  consumeType_OneArgumentAtFirstUsageStatic_Dynamic()
  // CHECK: [[STATIC_METADATA_ADDRESS]] @ 58
  consumeType_OneArgumentAtFirstUsageStatic_Dynamic()
  // CHECK: [[DYNAMIC_METADATA_ADDRESS:[0-9a-f]+]] @ 60
  consumeType_OneArgumentAtFirstUsageDynamic_Dynamic()
  // CHECK: [[DYNAMIC_METADATA_ADDRESS:[0-9a-f]+]] @ 62
  consumeType_OneArgumentAtFirstUsageDynamic_Dynamic()
  // CHECK: [[DYNAMIC_METADATA_ADDRESS]] @ 64
  consumeType_OneArgumentAtFirstUsageDynamic_Static()

  let staticMetadata = ptr(to: OneArgument<FirstUsageStatic>.self)
  // CHECK: [[STATIC_METADATA_ADDRESS]] @ 68
  print(staticMetadata, "@", #line)
  assert(isStaticallySpecializedGenericMetadata(staticMetadata))
  assert(!isCanonicalStaticallySpecializedGenericMetadata(staticMetadata))

  let dynamicMetadata = ptr(to: OneArgument<FirstUsageDynamic>.self)
  // CHECK: [[DYNAMIC_METADATA_ADDRESS]] @ 74
  print(dynamicMetadata, "@", #line)
  assert(!isStaticallySpecializedGenericMetadata(dynamicMetadata))
  assert(!isCanonicalStaticallySpecializedGenericMetadata(dynamicMetadata))
}
