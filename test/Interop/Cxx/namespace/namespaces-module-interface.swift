// RUN: %target-swift-ide-test -print-module -module-to-print=Namespaces -I %S/Inputs -source-filename=x -enable-cxx-interop | %FileCheck %s

// CHECK-NOT: extension
// CHECK: extension Space.Ship {
// CHECK:   static func test1()
// CHECK: }

// CHECK-NOT: extension
// CHECK: extension Space.Ship {
// CHECK:   static func test3()
// CHECK: }

// CHECK-NOT: extension
// CHECK: extension Space.Ship {
// CHECK:   static func test4()
// CHECK: }

// CHECK-NOT: extension
// CHECK: extension Space.Ship.Foo {
// CHECK:   static func test6()
// CHECK: }

// CHECK-NOT: extension
// CHECK: extension N0.N1 {
// CHECK:   static func test1()
// CHECK: }

// CHECK-NOT: extension
// CHECK: extension N2.N1 {
// CHECK:   static func test1()
// CHECK: }

// CHECK-NOT: extension
// CHECK: extension N3 {
// CHECK:   struct S0 {
// CHECK:     init()
// CHECK:     mutating func test1()
// CHECK:   }
// CHECK:   struct S1 {
// CHECK:     init()
// CHECK:   }
// CHECK: }

// CHECK-NOT: extension
// CHECK: extension N4.N5 {
// CHECK:   struct S2 {
// CHECK:     init()
// CHECK:     mutating func test()
// CHECK:   }
// CHECK: }

// CHECK-NOT: extension
// CHECK: extension N6.N7 {
// CHECK:   static func test1()
// CHECK: }

// CHECK-NOT: extension
