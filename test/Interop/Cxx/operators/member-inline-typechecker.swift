// RUN: %target-typecheck-verify-swift -I %S/Inputs -enable-cxx-interop

import MemberInline

var lhsLoadable = IntBox(value: 42)
let rhsLoadable = IntBox(value: 23)
let resultPlusLoadable = lhsLoadable + rhsLoadable

var lhsAddressOnly = AddressOnlyIntWrapper(value: 42)
var rhsAddressOnly = AddressOnlyIntWrapper(value: 23)
let resultMinusAddressOnly = lhsAddressOnly - rhsAddressOnly
