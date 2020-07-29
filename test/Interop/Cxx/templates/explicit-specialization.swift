// RUN: %target-run-simple-swift(-I %S/Inputs -Xfrontend -enable-cxx-interop -Xcc -std=c++17)
//
// REQUIRES: executable_test

import ExplicitSpecialization
import StdlibUnittest

var TemplatesTestSuite = TestSuite("TemplatesTestSuite")

TemplatesTestSuite.test("explicit-specialization") {
  let specializedInt = SpecializedIntWrapper(value: 7)
  var specializedMagicInt = WrapperWithSpecialization(t: specializedInt)
  expectEqual(specializedMagicInt.getValuePlusAConstant(), 10)

	let nonSpecializedInt = NonSpecializedIntWrapper(value: 7)
	var nonSpecializedMagicInt = WrapperWithoutSpecialization(t: nonSpecializedInt)
	expectEqual(nonSpecializedMagicInt.getValuePlusAConstant(), 20)
}

runAllTests()
