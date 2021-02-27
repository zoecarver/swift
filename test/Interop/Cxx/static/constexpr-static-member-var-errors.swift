// RUN: %target-swift-ide-test -print-module -module-to-print=ConstexprStaticMemberVarErrors -I %S/Inputs -source-filename=x -enable-cxx-interop 2>&1 | %FileCheck %s

// This test is simply testing that we properly report the error and don't crash
// when importing an invalid decl.

// CHECK: error: type 'int' cannot be used prior to '::' because it has no members
