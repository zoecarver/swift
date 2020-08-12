// RUN: %target-run-simple-swift(-I %S/Inputs -Xfrontend -enable-cxx-interop -Xcc -std=c++17)
//
// REQUIRES: executable_test

import TemplateTemplateParameter
import StdlibUnittest

var TemplatesTestSuite = TestSuite("TemplatesTestSuite")

TemplatesTestSuite.test("variadic-class-template") {
  let myInt = IntWrapper(value: 42)
  var magicInt = WrappedMagicInt(t: myInt)
  var templatedWrappedMagicInt = TemplatedWrappedMagicInt(i: magicInt)
  expectEqual(templatedWrappedMagicInt.getValuePlusTwiceTheArg(10), 62)
}

runAllTests()