import _Differentiation

// expected-note @+1 2 {{type declared here}}
struct OtherFileNonconforming {}

// expected-note @+1 2 {{type declared here}}
struct GenericOtherFileNonconforming<T: Differentiable> {
  var x: T
}
