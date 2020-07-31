#ifndef TEST_INTEROP_CXX_TEMPLATES_INPUTS_DECL_WITHOUT_DEFINITION_H
#define TEST_INTEROP_CXX_TEMPLATES_INPUTS_DECL_WITHOUT_DEFINITION_H

template<class T>
struct MagicWrapper {
  T t;
  int getValuePlusArg(int arg) const { return t.getValue() + arg; }
};

struct IntWrapper {
  int value;
  int getValue() const { return value; }
};

// MagicWrapper<IntWrapper> ClassTemplateSpecializationDecl doesn't have a
// definition in Clang because nothing in this header required the
// instantiation. Therefore we have to construct the definition on the swift
// side.
typedef MagicWrapper<IntWrapper> MagicallyWrappedIntWithoutDefinition;

#endif // TEST_INTEROP_CXX_TEMPLATES_INPUTS_DECL_WITHOUT_DEFINITION_H
