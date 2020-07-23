#ifndef TEST_INTEROP_CXX_TEMPLATES_INPUTS_MAGIC_WRAPPER_H
#define TEST_INTEROP_CXX_TEMPLATES_INPUTS_MAGIC_WRAPPER_H

template<class T>
struct MagicWrapper {
  T t;
  int callGetInt() const {
    return t.getInt() + 5;
  }
};

struct MagicNumber {
  int getInt() const { return 12; }
};

using WrappedMagicNumber = MagicWrapper<MagicNumber>;

#endif // TEST_INTEROP_CXX_TEMPLATES_INPUTS_MAGIC_WRAPPER_H
