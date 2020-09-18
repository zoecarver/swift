#ifndef TEST_INTEROP_CXX_TEMPLATES_INPUTS_NON_TYPE_PARAMETER_H
#define TEST_INTEROP_CXX_TEMPLATES_INPUTS_NON_TYPE_PARAMETER_H

template<class T, auto Size>
struct TypedeffedMagicArray {
    T data[Size];
};

typedef TypedeffedMagicArray<int, 2> MagicIntPair;

template<class T, auto Size>
struct MagicArray {
    T data[Size.getValue()];
};

struct IntWrapper {
  int value;
  int getValue() const { return value; }
};

struct Element {
    int id;
};

#endif  // TEST_INTEROP_CXX_TEMPLATES_INPUTS_NON_TYPE_PARAMETER_H
