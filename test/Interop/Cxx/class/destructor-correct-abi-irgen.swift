// RUN: %swift -module-name Swift -target x86_64-apple-macosx10.9 -I %S/Inputs -enable-cxx-interop -emit-ir %s -parse-stdlib -parse-as-library | %FileCheck %s -check-prefix=ITANIUM_X64
// RUN: %swift -module-name Swift -target armv7-none-linux-androideabi -dump-clang-diagnostics -I %S/Inputs -enable-cxx-interop -emit-ir %s -parse-stdlib -parse-as-library -disable-legacy-type-info | %FileCheck %s -check-prefix=ITANIUM_ARM
// RUN: %swift -module-name Swift -target x86_64-unknown-windows-msvc -dump-clang-diagnostics -I %S/Inputs -enable-cxx-interop -emit-ir %s -parse-stdlib -parse-as-library -disable-legacy-type-info | %FileCheck %s -check-prefix=MICROSOFT_X64

import TypeClassification

// ITANIUM_X64-LABEL: define swiftcc void @"$ss4testyyF"
// ITANIUM_X64: [[H:%.*]] = alloca %TSo33HasUserProvidedDestructorAndDummyV
// ITANIUM_X64: [[CXX_THIS:%.*]] = bitcast %TSo33HasUserProvidedDestructorAndDummyV* [[H]] to %struct.HasUserProvidedDestructorAndDummy*
// ITANIUM_X64: call void @_ZN33HasUserProvidedDestructorAndDummyD1Ev(%struct.HasUserProvidedDestructorAndDummy* [[CXX_THIS]])
// ITANIUM_X64: ret void

// ITANIUM_ARM-LABEL: define protected swiftcc void @"$ss4testyyF"
// ITANIUM_ARM: [[H:%.*]] = alloca %TSo33HasUserProvidedDestructorAndDummyV
// ITANIUM_ARM: [[CXX_THIS:%.*]] = bitcast %TSo33HasUserProvidedDestructorAndDummyV* [[H]] to %struct.HasUserProvidedDestructorAndDummy*
// ITANIUM_ARM: call %struct.HasUserProvidedDestructorAndDummy* @_ZN33HasUserProvidedDestructorAndDummyD2Ev(%struct.HasUserProvidedDestructorAndDummy* [[CXX_THIS]])
// ITANIUM_ARM: ret void

// MICROSOFT_X64-LABEL: define dllexport swiftcc void @"$ss4testyyF"
// MICROSOFT_X64: [[H:%.*]] = alloca %TSo33HasUserProvidedDestructorAndDummyV
// MICROSOFT_X64: [[CXX_THIS:%.*]] = bitcast %TSo33HasUserProvidedDestructorAndDummyV* [[H]] to %struct.HasUserProvidedDestructorAndDummy*
// MICROSOFT_X64: call void @"??1HasUserProvidedDestructorAndDummy@@QEAA@XZ"(%struct.HasUserProvidedDestructorAndDummy* [[CXX_THIS]])
// MICROSOFT_X64: ret void

public func test() {
  let d = DummyStruct()
  let h = HasUserProvidedDestructorAndDummy(dummy: d)
}
