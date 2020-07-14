// RUN: %target-swift-emit-ir %s -I %S/Inputs -enable-cxx-interop | %FileCheck %s
//
// We can't yet call member functions correctly on Windows (SR-13129).
// XFAIL: OS=windows-msvc

import MemberInline

// CHECK-LABEL: define {{.*i32|i64}} @"$s4main3addySo6IntBoxVADz_ADtF"
// CHECK: call [[RES:i32|i64]] [[NAME:@(_ZN6IntBoxplES_|"\?\?HIntBox@@QEAA\?AU0@U0@@Z")]](%struct.IntBox* {{%[0-9]+}}, {{i32|\[1 x i32\]|i64|%struct.IntBox\* byval align 4}} {{%[0-9]+}})
// CHECK: ret [[RES]]

// CHECK: define linkonce_odr [[RES]] [[NAME]](%struct.IntBox* %this, {{i32 %rhs.coerce|\[1 x i32\] %rhs.coerce|i64 %rhs.coerce|%struct.IntBox\* byval\(%struct.IntBox\) align 4 %rhs}})
public func add(_ lhs: inout IntBox, _ rhs: IntBox) -> IntBox { lhs + rhs }

// CHECK-LABEL: define {{.*}}void @"$s4main24subAddressOnlyIntWrapperySo0cdeF0VADz_ADtF"
// CHECK: call void [[NAME:@(_ZN21AddressOnlyIntWrappermiES_|"\?\?GAddressOnlyIntWrapper@@QEAA\?AU0@U0@@Z")]](%struct.AddressOnlyIntWrapper* {{%[0-9]+}}, %struct.AddressOnlyIntWrapper* {{%[0-9]+}}, %struct.AddressOnlyIntWrapper* {{%[0-9]+}})
// CHECK: ret void

// CHECK: define linkonce_odr void [[NAME]](%struct.AddressOnlyIntWrapper* {{.*}}%agg.result, %struct.AddressOnlyIntWrapper* %this, %struct.AddressOnlyIntWrapper* %rhs)

public func subAddressOnlyIntWrapper(_ lhs: inout AddressOnlyIntWrapper, _ rhs: AddressOnlyIntWrapper) -> AddressOnlyIntWrapper { lhs - rhs }
