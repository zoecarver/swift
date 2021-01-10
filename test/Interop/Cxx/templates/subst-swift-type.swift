// RUN: %target-run-simple-swift(-I %S/Inputs -Xfrontend -enable-cxx-interop)
//
// REQUIRES: executable_test

import SubstSwiftType
import StdlibUnittest

var TemplatesTestSuite = TestSuite("Swift -> C++ type conversions")

struct Empty { }

struct HasX {
  let x: CInt
}

struct HasComputedX {
  var x: CInt {
    get { 0 }
    set { }
  }
}
struct HasXY {
  let x: CInt
  let y: CInt
}

protocol UnConvertible { }
struct IsUnConvertible : UnConvertible { }
struct HasXMemberY {
  let x: CInt = 0
  let member: UnConvertible = IsUnConvertible()
  let y: CInt = 0
}

struct HasTripleChar {
  let x: CChar
  let y: CChar
  let z: CChar
}

struct StructMember { let value: Int64 }
struct HasStructMember { let member: StructMember }
struct HasCxxMember { let member: CxxMember }

TemplatesTestSuite.test("Empty") {
  testEmpty(Empty())
  // TODO(SR-14031): testEmptyPointer
}

TemplatesTestSuite.test("HasX") {
  let result = testHasX(HasX(x: 42))
  expectEqual(result, 42)
  expectEqual(testHasX(HasComputedX()), 0)
}

TemplatesTestSuite.test("HasXY") {
  let result = testHasXY(HasXY(x: 42, y: 42))
  expectEqual(result, 84)
//  testHasXY(HasXMemberY())
}

TemplatesTestSuite.test("HasTripleChar") {
  let result = testTripleChar(HasTripleChar(x: 1, y: 2, z: 3))
  expectEqual(result, 6)
}

TemplatesTestSuite.test("HasStructMember + HasCxxMember") {
  let result = testHasStructMember(HasStructMember(member: StructMember(value: 42)))
  expectEqual(result, 42)
  let resultCxxMember = testHasCxxMember(HasCxxMember(member: CxxMember(value: 42)))
  expectEqual(resultCxxMember, 42)
}

runAllTests()
