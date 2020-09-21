// RUN: %target-typecheck-verify-swift -verify-ignore-unknown -I %S/Inputs -enable-cxx-interop

import CxxConstructors

let explicit = ExplicitDefaultConstructor()

let implicit = ImplicitDefaultConstructor()

let deletedImplicitly = ConstructorWithParam() // expected-error {{missing argument for parameter #1 in call}}

let deletedExplicitly = DefaultConstructorDeleted() // expected-error {{cannot be constructed because it has no accessible initializers}}

let withArg = ConstructorWithParam(42)
