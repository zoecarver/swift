// RUN: %target-run-simple-swift(-I %S/Inputs -Xfrontend -enable-cxx-interop -Xcc -std=c++17)
//
// REQUIRES: executable_test

import NonTypeParameter
import StdlibUnittest

var TemplatesTestSuite = TestSuite("TemplatesTestSuite")

TemplatesTestSuite.test("variadic-class-template") {
  let pair = MagicIntPair()
  pair.t = [10, 20]
  expectEqual(pair.t, [10, 20])
}

runAllTests()
