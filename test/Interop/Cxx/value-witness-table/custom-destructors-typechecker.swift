// RUN: %target-typecheck-verify-swift -I %S/Inputs -enable-cxx-interop

import CustomDestructorTypes

let a = HasUserProvidedDestructor()
let b = HasEmptyDestructorAndMemberWithUserDefinedConstructor()
let c = HasNonTrivialImplicitDestructor()
let d = HasNonTrivialDefaultedDestructor()
