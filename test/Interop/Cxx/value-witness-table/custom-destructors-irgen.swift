// RUN: %target-swift-frontend -enable-cxx-interop -I %S/Inputs %s -emit-ir | %FileCheck %s

import CustomDestructorTypes

protocol InitWithDummy {
  init(dummy: DummyStruct)
}

extension HasUserProvidedDestructorAndDummy : InitWithDummy { }

// Make sure the destructor is added as a witness.
// CHECK: @"$sSo33HasUserProvidedDestructorAndDummyVWV" = linkonce_odr hidden constant %swift.vwtable
// CHECK-SAME: i8* bitcast (void (%swift.opaque*, %swift.type*)* @"$sSo33HasUserProvidedDestructorAndDummyVwxx" to i8*)

// CHECK-LABEL: define swiftcc void @"$s4main4testyyF"
// CHECK: [[OBJ:%.*]] = alloca %TSo33HasUserProvidedDestructorAndDummyV
// Make sure we bitcast it from the Swift type to the C++ type.
// CHECK: [[CXX_OBJ:%.*]] = bitcast %TSo33HasUserProvidedDestructorAndDummyV* %0 to %struct.HasUserProvidedDestructorAndDummy*
// Make sure we call the destructor.
// CHECK: call void @_ZN33HasUserProvidedDestructorAndDummyD1Ev(%struct.HasUserProvidedDestructorAndDummy* [[CXX_OBJ]])
// CHECK: ret void
public func test() {
  _ = HasUserProvidedDestructorAndDummy(dummy: DummyStruct())
}

// Make sure the destroy value witness calls the destructor.
// CHECK-LABEL: define linkonce_odr hidden void @"$sSo33HasUserProvidedDestructorAndDummyVwxx"
// CHECK: call void @_ZN33HasUserProvidedDestructorAndDummyD1Ev(%struct.HasUserProvidedDestructorAndDummy*
// CHECK: ret void

// Make sure we not only declare but define the destructor.
// CHECK-LABEL: define linkonce_odr void  @_ZN33HasUserProvidedDestructorAndDummyD2Ev(%struct.HasUserProvidedDestructorAndDummy* %this)
// CHECK: ret void
