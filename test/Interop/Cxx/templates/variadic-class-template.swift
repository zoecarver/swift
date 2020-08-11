// RUN: %target-run-simple-swift(-I %S/Inputs -Xfrontend -enable-cxx-interop -Xcc -std=c++17)
//
// REQUIRES: executable_test

import VariadicClassTemplate
import StdlibUnittest

var TemplatesTestSuite = TestSuite("TemplatesTestSuite")

TemplatesTestSuite.test("variadic-class-template") {
  let a = IntWrapper(value: 10)
  let b = IntWrapper(value: 20)
  let pair = Pair(a, b)
  expectEqual(pair.get(), 10)
  expectEqual(pair.rest().get(), 20)
}

runAllTests()
