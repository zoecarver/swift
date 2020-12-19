namespace Space {
namespace Ship {
void test1() {}
void test4();
void test5();
} // namespace Ship
} // namespace Space

namespace Space {
namespace Ship {
void test3() {}
} // namespace Ship
} // namespace Space

namespace Space {
namespace Ship {
void test4() {}
} // namespace Ship
} // namespace Space

namespace Space {
namespace Ship {
namespace Foo {
void test6() {}
} // namespace Foo
} // namespace Ship
} // namespace Space

namespace N0 {
namespace N1 {
void test1() {}
} // namespace N1
} // namespace N0

namespace N2 {
namespace N1 {
void test1() {}
} // namespace N1
} // namespace N2

namespace N3 {
struct S0 {
  void test1() {}
};
struct S1;
} // namespace N3

struct N3::S1 {};

namespace N4 {
namespace N5 {
struct S2;
struct S3;
} // namespace N5
} // namespace N4

namespace N4 {
struct N5::S2 {
  void test() {}
};
} // namespace N4

namespace N6 {
namespace N7 {
void test1();
void test2();
} // namespace N7
} // namespace N6

namespace N6 {
void N7::test1(){};
}
