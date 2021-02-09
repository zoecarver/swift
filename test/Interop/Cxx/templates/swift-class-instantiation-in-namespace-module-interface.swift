// RUN: %empty-directory(%t)
// RUN: %target-swiftxx-frontend -emit-module -o %t/SwiftClassTemplateInNamespaceModule.swiftmodule %S/Inputs/SwiftClassTemplateInNamespaceModule.swift -I %S/Inputs -enable-library-evolution -swift-version 5
// RUN: %target-swift-ide-test -print-module -module-to-print=SwiftClassTemplateInNamespaceModule -I %t/ -source-filename=x -enable-cxx-interop | %FileCheck %s

// We need to be able to properly serialize the __ObjC module holding the "Space" enum.
// REQUIRES: SR-XXXXX

// CHECK: import ClassTemplateInNamespaceForSwiftModule
// CHECK: func receiveShip(_ i: inout Space.__CxxTemplateInstN5Space4ShipIbEE)
// CHECK: func receiveShipWithEngine(_ i: inout Space.__CxxTemplateInstN5Space4ShipIN6Engine8TurbojetEEE)

// CHECK: func returnShip() -> Space.__CxxTemplateInstN5Space4ShipIbEE
// CHECK: func returnShipWithEngine() -> Space.__CxxTemplateInstN5Space4ShipIN6Engine8TurbojetEEE

