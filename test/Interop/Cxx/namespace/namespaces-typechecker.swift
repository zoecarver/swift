// RUN: %target-typecheck-verify-swift -I %S/Inputs -enable-cxx-interop

import NamespaceDefs
import Namespaces

Space.Ship.test1()
Space.test2()
Space.Ship.test4()
Space.Ship.test5()

var s3 = N4.N5.S3()
s3.test()

N6.N7.test2()

