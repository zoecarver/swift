#ifndef TEST_INTEROP_CXX_TEMPLATES_INPUTS_SUBST_SWIFT_TYPE_H
#define TEST_INTEROP_CXX_TEMPLATES_INPUTS_SUBST_SWIFT_TYPE_H

struct CxxEmpty { };
template<class T>
void testEmpty(T) {
  static_assert(alignof(T) == alignof(CxxEmpty));
  static_assert(sizeof(T) == sizeof(CxxEmpty));
}

// TODO: test with swift struct with computed props.
struct CxxHasX { int x; };
template<class T>
int testHasX(T arg) {
  static_assert(alignof(T) == alignof(CxxHasX));
  static_assert(sizeof(T) == sizeof(CxxHasX));
  return arg.x;
}

// TODO: test with swift struct with middle member that is unimportable.
struct CxxHasXY { int x; int y; };
template<class T>
int testHasXY(T arg) {
  static_assert(alignof(T) == alignof(CxxHasXY));
  static_assert(sizeof(T) == sizeof(CxxHasXY));
  return arg.x + arg.y;
}

struct CxxTripleChar { char x; char y; char z; };
template<class T>
char testTripleChar(T arg) {
  static_assert(alignof(T) == alignof(CxxTripleChar));
  static_assert(sizeof(T) == sizeof(CxxTripleChar));
  return arg.x + arg.y + arg.z;
}

struct IsMember { long value; };

// TODO: nested types

// TODO: pointer types

// TODO: reference types (objc)

#endif // TEST_INTEROP_CXX_TEMPLATES_INPUTS_SUBST_SWIFT_TYPE_H
