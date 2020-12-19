namespace Space {
void test2() {}
} // namespace Space

namespace Space {
namespace Ship {
void test5() {}
} // namespace Ship
} // namespace Space

namespace N4 {
namespace N5 {
struct S3;
}
} // namespace N4

namespace N4 {
struct N5::S3 {
  void test() {}
};
} // namespace N4

namespace N6 {
namespace N7 {
void test2();
}
} // namespace N6

namespace N6 {
void N7::test2(){};
}
