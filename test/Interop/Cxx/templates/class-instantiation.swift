// RUN: %target-run-simple-swift(-I %S/Inputs -Xfrontend -enable-cxx-interop -Xcc -std=c++17)
//
// REQUIRES: executable_test

import ClassTemplates
import StdlibUnittest

var TemplatesTestSuite = TestSuite("TemplatesTestSuite")

TemplatesTestSuite.test("nonexisting-specialization") {
//   let myInt = IntWrapper(value: 18)
//   var magicInt = MagicWrapper<IntWrapper>(t: myInt)
//   expectEqual(magicInt.getValuePlusArg(12), 30)
}

TemplatesTestSuite.test("swift-template-arg-not-supported") {
//   var magicInt = MagicWrapper<String>(t: "asdf")
}

TemplatesTestSuite.test("clang-errors-reported-on-instantiation") {
    // var _ = CannotBeInstantianted<IntWrapper>()
}

runAllTests()