// RUN: %target-run-simple-swift(-I %S/Inputs -Xfrontend -enable-cxx-interop -Xcc -std=c++17)
//
// REQUIRES: executable_test

import DeclWithoutDefinition
import StdlibUnittest

var TemplatesTestSuite = TestSuite("TemplatesTestSuite")

TemplatesTestSuite.test("typedef-without-definition") {
  let myInt = IntWrapper(value: 17)
  var magicInt = MagicallyWrappedIntWithoutDefinition(t: myInt)
  expectEqual(magicInt.getValuePlusArg(11), 28)
}

TemplatesTestSuite.test("existing-specialization") {
  let myInt = IntWrapper(value: 18)
  var magicInt = MagicWrapper<IntWrapper>(t: myInt)
  expectEqual(magicInt.getValuePlusArg(12), 30)
}

runAllTests()
