// RUN: %target-run-simple-swift(-I %S/Inputs -Xfrontend -enable-cxx-interop)
//
// REQUIRES: executable_test

import CustomDestructorTypes
import StdlibUnittest

var CXXDestructorTestSuite = TestSuite("CXXDestructor")

protocol InitWithPtr {
  init(value: UnsafeMutablePointer<Int32>!)
}

extension HasUserProvidedDestructor : InitWithPtr { }

protocol InitWithMember {
  init(member: HasUserProvidedDestructor)
}

extension HasEmptyDestructorAndMemberWithUserDefinedConstructor
  : InitWithMember { }

// These are all maked as "@inline(never)" so that the destructor is invoked in
// this function and not in the caller (after being inlined).
@inline(never)
func createTypeWithUserProvidedDestructor(_ ptr: UnsafeMutablePointer<Int32>) {
  var obj = HasUserProvidedDestructor(value: ptr)
}

@inline(never)
func createTypeWithEmptyDestructorAndMemberWithUserDefinedConstructor(
  _ ptr: UnsafeMutablePointer<Int32>
) {
  var obj = HasUserProvidedDestructor(value: ptr)
  let empty = HasEmptyDestructorAndMemberWithUserDefinedConstructor(
    member: obj)
}

@inline(never)
func createTypeWithNonTrivialImplicitDestructor(
  _ ptr: UnsafeMutablePointer<Int32>
) {
  var obj = HasUserProvidedDestructor(value: ptr)
  let implicit = HasNonTrivialImplicitDestructor(member: obj)
}

@inline(never)
func createTypeWithNonTrivialDefaultDestructor(
  _ ptr: UnsafeMutablePointer<Int32>
) {
  var obj = HasUserProvidedDestructor(value: ptr)
  let def = HasNonTrivialDefaultedDestructor(member: obj)
}

@inline(never)
func createTypeWithGeneric<T : InitWithPtr>(
  _ ptr: UnsafeMutablePointer<Int32>,
  type: T.Type
) {
  let obj = T(value: ptr)
}

@inline(never)
func createTypeWithProtocol(
  _ ptr: UnsafeMutablePointer<Int32>,
  type: InitWithPtr.Type
) {
  let obj = type.self.init(value: ptr)
}

@inline(never)
func createTypeWithProtocol(
  _ ptr: UnsafeMutablePointer<Int32>,
  type: InitWithPtr.Type,
  holder: InitWithMember.Type
) {
  let obj = type.self.init(value: ptr)
  let empty = holder.self.init(member: obj as! HasUserProvidedDestructor)
}

CXXDestructorTestSuite.test("Basic object with destructor") {
  let ptr = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
  ptr.pointee = 0
  createTypeWithUserProvidedDestructor(ptr)
  expectEqual(ptr.pointee, 42)
  ptr.deallocate()
}

CXXDestructorTestSuite.test("Nested objects with destructors") {
  let ptr = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
  ptr.pointee = 0
  createTypeWithEmptyDestructorAndMemberWithUserDefinedConstructor(ptr)
  expectEqual(ptr.pointee, 42)
  ptr.deallocate()
}

CXXDestructorTestSuite.test("Implicit destructor, member with user-defined destructor") {
  let ptr = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
  ptr.pointee = 0
  createTypeWithNonTrivialImplicitDestructor(ptr)
  expectEqual(ptr.pointee, 42)
  ptr.deallocate()
}

CXXDestructorTestSuite.test("Default destructor, member with user-defined destructor") {
  let ptr = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
  ptr.pointee = 0
  createTypeWithNonTrivialDefaultDestructor(ptr)
  expectEqual(ptr.pointee, 42)
  ptr.deallocate()
}

CXXDestructorTestSuite.test("Generic with destructor") {
  let ptr = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
  ptr.pointee = 0
  createTypeWithProtocol(ptr, type: HasUserProvidedDestructor.self)
  expectEqual(ptr.pointee, 42)
  ptr.deallocate()
}

CXXDestructorTestSuite.test("Protocol with destructor") {
  let ptr = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
  ptr.pointee = 0
  createTypeWithProtocol(ptr, type: HasUserProvidedDestructor.self)
  expectEqual(ptr.pointee, 42)
  ptr.deallocate()
}

CXXDestructorTestSuite.test("Protocol with member with destructor") {
  let ptr = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
  ptr.pointee = 0
  createTypeWithProtocol(
    ptr,
    type: HasUserProvidedDestructor.self,
    holder: HasEmptyDestructorAndMemberWithUserDefinedConstructor.self)
  expectEqual(ptr.pointee, 42)
  ptr.deallocate()
}

runAllTests()
