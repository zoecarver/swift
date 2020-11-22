// RUN: %target-swift-ide-test -print-module -module-to-print=MemberInline -I %S/Inputs -source-filename=x -enable-cxx-interop | %FileCheck %s

// CHECK: struct LoadableIntWrapper {
// CHECK:   static func - (lhs: inout LoadableIntWrapper, rhs: LoadableIntWrapper) -> LoadableIntWrapper
// CHECK: }

// CHECK: struct HasDeletedOperator {
// CHECK: }

// CHECK: struct AddressOnlyIntWrapper {
// CHECK:   static func - (lhs: inout AddressOnlyIntWrapper, rhs: AddressOnlyIntWrapper) -> AddressOnlyIntWrapper
// CHECK: }
