#ifndef TEST_INTEROP_CXX_CLASS_INPUTS_LINKED_RECORDS_H
#define TEST_INTEROP_CXX_CLASS_INPUTS_LINKED_RECORDS_H

namespace Space {

class C;

struct A {
  struct B {
    B(int) {}
    B(char) {}
  };
};

struct C {
  struct D {
    A::B B;
  };
};

struct E {
  static void test(const C*);
};

} // Space

struct M { };

struct F {
  union {
    struct { } c;
    M m;
  };
  M m2;
};

#endif // TEST_INTEROP_CXX_CLASS_INPUTS_LINKED_RECORDS_H
