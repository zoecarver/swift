struct ConformsToProtocol {
  int return42() { return 42; }
};

struct DoesNotConformToProtocol {
  int returnFortyTwo() { return 42; }
};

struct DummyStruct { };

struct NonTrivial {
  ~NonTrivial() { }
  NonTrivial(DummyStruct) { }
  NonTrivial() { }
  void test1() { }
  void test2(int) { }
  char test3(int, unsigned) { return 42; }
//  template<class T>
//  char test4(T) { }
};

struct Trivial {
  Trivial(DummyStruct) { }
  Trivial() { }
  void test1() { }
  void test2(int) { }
  char test3(int, unsigned) { return 42; }
//  template<class T>
//  char test4(T) { }
};
