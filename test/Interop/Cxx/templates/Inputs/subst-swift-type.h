#ifndef TEST_INTEROP_CXX_TEMPLATES_INPUTS_SUBST_SWIFT_TYPE_H
#define TEST_INTEROP_CXX_TEMPLATES_INPUTS_SUBST_SWIFT_TYPE_H

// This header is for testing Swift -> Clang type conversions. These are tested
// using function templates.

struct CxxEmpty { };
template<class T>
void testEmpty(T) {
  static_assert(alignof(T) == alignof(CxxEmpty), "");
  static_assert(sizeof(T) == sizeof(CxxEmpty), "");
}

template<class T>
void testEmptyPointer(T*) {
  static_assert(alignof(T) == alignof(CxxEmpty), "");
  static_assert(sizeof(T) == sizeof(CxxEmpty), "");
}

struct CxxHasX { int x; };
template<class T>
int testHasX(T arg) {
  static_assert(alignof(T) == alignof(CxxHasX), "");
  static_assert(sizeof(T) == sizeof(CxxHasX), "");
  return arg.x;
}

struct CxxHasXY { int x; int y; };
template<class T>
int testHasXY(T arg) {
  static_assert(alignof(T) == alignof(CxxHasXY), "");
  static_assert(sizeof(T) == sizeof(CxxHasXY), "");
  return arg.x + arg.y;
}

struct CxxTripleChar { char x; char y; char z; };
template<class T>
char testTripleChar(T arg) {
  static_assert(alignof(T) == alignof(CxxTripleChar), "");
  static_assert(sizeof(T) == sizeof(CxxTripleChar), "");
  return arg.x + arg.y + arg.z;
}

struct CxxMember { long value; };
struct CxxHasStructMember {
  CxxMember member;
};
template<class T>
long testHasStructMember(T arg) {
  static_assert(alignof(T) == alignof(CxxHasStructMember), "");
  static_assert(sizeof(T) == sizeof(CxxHasStructMember), "");
  static_assert(alignof(decltype(arg.member)) == alignof(CxxMember), "");
  static_assert(sizeof(decltype(arg.member)) == sizeof(CxxMember), "");
  return arg.member.value;
}

struct CxxHasCxxMember {
  CxxMember member;
};
template<class T>
long testHasCxxMember(T arg) {
  static_assert(alignof(T) == alignof(CxxHasCxxMember), "");
  static_assert(sizeof(T) == sizeof(CxxHasCxxMember), "");
  // static_assert(__is_same(decltype(arg.member), CxxMember), "");
  return arg.member.value;
}

// TODO: reference types (objc)

#endif // TEST_INTEROP_CXX_TEMPLATES_INPUTS_SUBST_SWIFT_TYPE_H
