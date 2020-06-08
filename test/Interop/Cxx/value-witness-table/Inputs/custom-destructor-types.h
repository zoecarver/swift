struct HasUserProvidedDestructor {
  int *value;
  ~HasUserProvidedDestructor() { *value = 42; }
};

struct HasEmptyDestructorAndMemberWithUserDefinedConstructor {
  HasUserProvidedDestructor member;
  ~HasEmptyDestructorAndMemberWithUserDefinedConstructor() { /* empty */
  }
};

struct HasNonTrivialImplicitDestructor {
  HasUserProvidedDestructor member;
};

struct HasNonTrivialDefaultedDestructor {
  HasUserProvidedDestructor member;
  HasNonTrivialDefaultedDestructor() = default;
};

struct DummyStruct {};

struct HasUserProvidedDestructorAndDummy {
  DummyStruct dummy;
  ~HasUserProvidedDestructorAndDummy() {}
};

// Make sure that we don't crash on struct templates with destructors.
template <typename T> struct S {
  ~S() {}
};
