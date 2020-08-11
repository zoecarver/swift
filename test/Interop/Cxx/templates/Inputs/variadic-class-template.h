#ifndef TEST_INTEROP_CXX_TEMPLATES_INPUTS_VARIADIC_CLASS_TEMPLATE_H
#define TEST_INTEROP_CXX_TEMPLATES_INPUTS_VARIADIC_CLASS_TEMPLATE_H

template <class... Ts> struct Tuple {};

template <class T, class... Ts>
struct Tuple<T, Ts...> : Tuple<Ts...> {
  Tuple(T t, Ts... ts) : Tuple<Ts...>(ts...), t(t) {}

  T get() { return t; }
  T rest() { return Tuple<Ts...>::get(); }

  T t;
};

struct IntWrapper {
  int value;
  int getValue() const { return value; }
};

typedef Tuple<IntWrapper, IntWrapper> Pair;

#endif // TEST_INTEROP_CXX_TEMPLATES_INPUTS_VARIADIC_CLASS_TEMPLATE_H