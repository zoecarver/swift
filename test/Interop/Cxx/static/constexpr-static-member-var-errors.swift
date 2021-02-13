// RUN: %target-swift-ide-test -print-module -module-to-print=ConstexprStaticMemberVarErrors -I %S/Inputs -source-filename=x -enable-cxx-interop 2>&1 | %FileCheck %s

// Clang does not properly mark decls as invalid on Windows, so we won't get an
// error here.
// XFAIL: OS=windows-msvc

// Check that we properly report the error and don't crash when importing an
// invalid decl.

// CHECK: error: type 'int' cannot be used prior to '::' because it has no members
