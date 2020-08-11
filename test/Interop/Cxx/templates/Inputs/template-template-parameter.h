#ifndef TEST_INTEROP_CXX_TEMPLATES_INPUTS_TEMPLATE_TEMPLATE_PARAMETER_H
#define TEST_INTEROP_CXX_TEMPLATES_INPUTS_TEMPLATE_TEMPLATE_PARAMETER_H

template<template <class> class V>
struct Asdf {
  V<IntWrapper> i;
};

struct IntWrapper {
  int value;
  int getValue() const { return value; }
};

template <class T>
struct MagicWrapper {
  T t;
  int getValuePlusArg(int arg) const { return t.getValue() + arg; }
};

typedef Asdf<MagicWrapper> Hohoho;
#endif // TEST_INTEROP_CXX_TEMPLATES_INPUTS_TEMPLATE_TEMPLATE_PARAMETER_H