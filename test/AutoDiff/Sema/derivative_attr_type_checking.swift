// RUN: %target-swift-frontend-typecheck -verify %s

import _Differentiation

// Dummy `Differentiable`-conforming type.
struct DummyTangentVector: Differentiable & AdditiveArithmetic {
  static var zero: Self { Self() }
  static func + (_: Self, _: Self) -> Self { Self() }
  static func - (_: Self, _: Self) -> Self { Self() }
  typealias TangentVector = Self
}

// Test top-level functions.

func id(_ x: Float) -> Float {
  return x
}
@derivative(of: id)
func jvpId(x: Float) -> (value: Float, differential: (Float) -> (Float)) {
  return (x, { $0 })
}
@derivative(of: id, wrt: x)
func vjpIdExplicitWrt(x: Float) -> (value: Float, pullback: (Float) -> Float) {
  return (x, { $0 })
}

func generic<T: Differentiable>(_ x: T, _ y: T) -> T {
  return x
}
@derivative(of: generic)
func jvpGeneric<T: Differentiable>(x: T, y: T) -> (
  value: T, differential: (T.TangentVector, T.TangentVector) -> T.TangentVector
) {
  return (x, { $0 + $1 })
}
@derivative(of: generic)
func vjpGenericExtraGenericRequirements<T: Differentiable & FloatingPoint>(
  x: T, y: T
) -> (value: T, pullback: (T) -> (T, T)) where T == T.TangentVector {
  return (x, { ($0, $0) })
}

// Test `wrt` parameter clauses.

func add(x: Float, y: Float) -> Float {
  return x + y
}
@derivative(of: add, wrt: x) // ok
func vjpAddWrtX(x: Float, y: Float) -> (value: Float, pullback: (Float) -> (Float)) {
  return (x + y, { $0 })
}
@derivative(of: add, wrt: (x, y)) // ok
func vjpAddWrtXY(x: Float, y: Float) -> (value: Float, pullback: (Float) -> (Float, Float)) {
  return (x + y, { ($0, $0) })
}

// Test index-based `wrt` parameters.

func subtract(x: Float, y: Float) -> Float {
  return x - y
}
@derivative(of: subtract, wrt: (0, y)) // ok
func vjpSubtractWrt0Y(x: Float, y: Float) -> (value: Float, pullback: (Float) -> (Float, Float)) {
  return (x - y, { ($0, $0) })
}
@derivative(of: subtract, wrt: (1)) // ok
func vjpSubtractWrt1(x: Float, y: Float) -> (value: Float, pullback: (Float) -> Float) {
  return (x - y, { $0 })
}

// Test invalid original function.

// expected-error @+1 {{cannot find 'nonexistentFunction' in scope}}
@derivative(of: nonexistentFunction)
func vjpOriginalFunctionNotFound(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

// Test `@derivative` attribute where `value:` result does not conform to `Differentiable`.
// Invalid original function should be diagnosed first.
// expected-error @+1 {{cannot find 'nonexistentFunction' in scope}}
@derivative(of: nonexistentFunction)
func vjpOriginalFunctionNotFound2(_ x: Float) -> (value: Int, pullback: (Float) -> Float) {
  fatalError()
}

// Test incorrect `@derivative` declaration type.

// expected-note @+1 {{'incorrectDerivativeType' defined here}}
func incorrectDerivativeType(_ x: Float) -> Float {
  return x
}

// expected-error @+1 {{'@derivative(of:)' attribute requires function to return a two-element tuple; first element must have label 'value:' and second element must have label 'pullback:' or 'differential:'}}
@derivative(of: incorrectDerivativeType)
func jvpResultIncorrect(x: Float) -> Float {
  return x
}
// expected-error @+1 {{'@derivative(of:)' attribute requires function to return a two-element tuple; first element must have label 'value:'}}
@derivative(of: incorrectDerivativeType)
func vjpResultIncorrectFirstLabel(x: Float) -> (Float, (Float) -> Float) {
  return (x, { $0 })
}
// expected-error @+1 {{'@derivative(of:)' attribute requires function to return a two-element tuple; second element must have label 'pullback:' or 'differential:'}}
@derivative(of: incorrectDerivativeType)
func vjpResultIncorrectSecondLabel(x: Float) -> (value: Float, (Float) -> Float) {
  return (x, { $0 })
}
// expected-error @+1 {{could not find function 'incorrectDerivativeType' with expected type '(Int) -> Int'}}
@derivative(of: incorrectDerivativeType)
func vjpResultNotDifferentiable(x: Int) -> (
  value: Int, pullback: (Int) -> Int
) {
  return (x, { $0 })
}
// expected-error @+2 {{function result's 'pullback' type does not match 'incorrectDerivativeType'}}
// expected-note @+3 {{'pullback' does not have expected type '(Float.TangentVector) -> Float.TangentVector' (aka '(Float) -> Float')}}
@derivative(of: incorrectDerivativeType)
func vjpResultIncorrectPullbackType(x: Float) -> (
  value: Float, pullback: (Double) -> Double
) {
  return (x, { $0 })
}

// Test invalid `wrt:` differentiation parameters.

func invalidWrtParam(_ x: Float, _ y: Float) -> Float {
  return x
}

// expected-error @+1 {{unknown parameter name 'z'}}
@derivative(of: add, wrt: z)
func vjpUnknownParam(x: Float, y: Float) -> (value: Float, pullback: (Float) -> (Float)) {
  return (x + y, { $0 })
}
// expected-error @+1 {{parameters must be specified in original order}}
@derivative(of: invalidWrtParam, wrt: (y, x))
func vjpParamOrderNotIncreasing(x: Float, y: Float) -> (value: Float, pullback: (Float) -> (Float, Float)) {
  return (x + y, { ($0, $0) })
}
// expected-error @+1 {{'self' parameter is only applicable to instance methods}}
@derivative(of: invalidWrtParam, wrt: self)
func vjpInvalidSelfParam(x: Float, y: Float) -> (value: Float, pullback: (Float) -> (Float, Float)) {
  return (x + y, { ($0, $0) })
}
// expected-error @+1 {{parameter index is larger than total number of parameters}}
@derivative(of: invalidWrtParam, wrt: 2)
func vjpSubtractWrt2(x: Float, y: Float) -> (value: Float, pullback: (Float) -> (Float, Float)) {
  return (x - y, { ($0, $0) })
}
// expected-error @+1 {{parameters must be specified in original order}}
@derivative(of: invalidWrtParam, wrt: (1, x))
func vjpSubtractWrt1x(x: Float, y: Float) -> (value: Float, pullback: (Float) -> (Float, Float)) {
  return (x - y, { ($0, $0) })
}
// expected-error @+1 {{parameters must be specified in original order}}
@derivative(of: invalidWrtParam, wrt: (1, 0))
func vjpSubtractWrt10(x: Float, y: Float) -> (value: Float, pullback: (Float) -> (Float, Float)) {
  return (x - y, { ($0, $0) })
}

func noParameters() -> Float {
  return 1
}
// expected-error @+1 {{'vjpNoParameters()' has no parameters to differentiate with respect to}}
@derivative(of: noParameters)
func vjpNoParameters() -> (value: Float, pullback: (Float) -> Float) {
  return (1, { $0 })
}

func noDifferentiableParameters(x: Int) -> Float {
  return 1
}
// expected-error @+1 {{no differentiation parameters could be inferred; must differentiate with respect to at least one parameter conforming to 'Differentiable'}}
@derivative(of: noDifferentiableParameters)
func vjpNoDifferentiableParameters(x: Int) -> (
  value: Float, pullback: (Float) -> Int
) {
  return (1, { _ in 0 })
}

func functionParameter(_ fn: (Float) -> Float) -> Float {
  return fn(1)
}
// expected-error @+1 {{can only differentiate with respect to parameters that conform to 'Differentiable', but '(Float) -> Float' does not conform to 'Differentiable'}}
@derivative(of: functionParameter, wrt: fn)
func vjpFunctionParameter(_ fn: (Float) -> Float) -> (
  value: Float, pullback: (Float) -> Float
) {
  return (functionParameter(fn), { $0 })
}

// Test static methods.

protocol StaticMethod: Differentiable {
  static func foo(_ x: Float) -> Float
  static func generic<T: Differentiable>(_ x: T) -> T
}

extension StaticMethod {
  static func foo(_ x: Float) -> Float { x }
  static func generic<T: Differentiable>(_ x: T) -> T { x }
}

extension StaticMethod {
  @derivative(of: foo)
  static func jvpFoo(x: Float) -> (value: Float, differential: (Float) -> Float)
  {
    return (x, { $0 })
  }

  // Test qualified declaration name.
  @derivative(of: StaticMethod.foo)
  static func vjpFoo(x: Float) -> (value: Float, pullback: (Float) -> Float) {
    return (x, { $0 })
  }

  @derivative(of: generic)
  static func vjpGeneric<T: Differentiable>(_ x: T) -> (
    value: T, pullback: (T.TangentVector) -> (T.TangentVector)
  ) {
    return (x, { $0 })
  }

  // expected-error @+1 {{'self' parameter is only applicable to instance methods}}
  @derivative(of: foo, wrt: (self, x))
  static func vjpFooWrtSelf(x: Float) -> (value: Float, pullback: (Float) -> Float) {
    return (x, { $0 })
  }
}

// Test instance methods.

protocol InstanceMethod: Differentiable {
  func foo(_ x: Self) -> Self
  func generic<T: Differentiable>(_ x: T) -> Self
}

extension InstanceMethod {
  // expected-note @+1 {{'foo' defined here}}
  func foo(_ x: Self) -> Self { x }

  // expected-note @+1 {{'generic' defined here}}
  func generic<T: Differentiable>(_ x: T) -> Self { self }
}

extension InstanceMethod {
  @derivative(of: foo)
  func jvpFoo(x: Self) -> (
    value: Self, differential: (TangentVector, TangentVector) -> (TangentVector)
  ) {
    return (x, { $0 + $1 })
  }

  // Test qualified declaration name.
  @derivative(of: InstanceMethod.foo, wrt: x)
  func jvpFooWrtX(x: Self) -> (
    value: Self, differential: (TangentVector) -> (TangentVector)
  ) {
    return (x, { $0 })
  }

  @derivative(of: generic)
  func vjpGeneric<T: Differentiable>(_ x: T) -> (
    value: Self, pullback: (TangentVector) -> (TangentVector, T.TangentVector)
  ) {
    return (self, { ($0, .zero) })
  }

  @derivative(of: generic, wrt: (self, x))
  func jvpGenericWrt<T: Differentiable>(_ x: T) -> (value: Self, differential: (TangentVector, T.TangentVector) -> TangentVector) {
    return (self, { dself, dx in dself })
  }

  // expected-error @+1 {{'self' parameter must come first in the parameter list}}
  @derivative(of: generic, wrt: (x, self))
  func jvpGenericWrtSelf<T: Differentiable>(_ x: T) -> (value: Self, differential: (TangentVector, T.TangentVector) -> TangentVector) {
    return (self, { dself, dx in dself })
  }
}

extension InstanceMethod {
  // If `Self` conforms to `Differentiable`, then `Self` is inferred to be a differentiation parameter.
  // expected-error @+2 {{function result's 'pullback' type does not match 'foo'}}
  // expected-note @+3 {{'pullback' does not have expected type '(Self.TangentVector) -> (Self.TangentVector, Self.TangentVector)'}}
  @derivative(of: foo)
  func vjpFoo(x: Self) -> (
    value: Self, pullback: (TangentVector) -> TangentVector
  ) {
    return (x, { $0 })
  }

  // If `Self` conforms to `Differentiable`, then `Self` is inferred to be a differentiation parameter.
  // expected-error @+2 {{function result's 'pullback' type does not match 'generic'}}
  // expected-note @+3 {{'pullback' does not have expected type '(Self.TangentVector) -> (Self.TangentVector, T.TangentVector)'}}
  @derivative(of: generic)
  func vjpGeneric<T: Differentiable>(_ x: T) -> (
    value: Self, pullback: (TangentVector) -> T.TangentVector
  ) {
    return (self, { _ in .zero })
  }
}

// Test `@derivative` declaration with more constrained generic signature.

func req1<T>(_ x: T) -> T {
  return x
}
@derivative(of: req1)
func vjpExtraConformanceConstraint<T: Differentiable>(_ x: T) -> (
  value: T, pullback: (T.TangentVector) -> T.TangentVector
) {
  return (x, { $0 })
}

func req2<T, U>(_ x: T, _ y: U) -> T {
  return x
}
@derivative(of: req2)
func vjpExtraConformanceConstraints<T: Differentiable, U: Differentiable>( _ x: T, _ y: U) -> (
  value: T, pullback: (T) -> (T, U)
) where T == T.TangentVector, U == U.TangentVector, T: CustomStringConvertible {
  return (x, { ($0, .zero) })
}

// Test `@derivative` declaration with extra same-type requirements.
func req3<T>(_ x: T) -> T {
  return x
}
@derivative(of: req3)
func vjpSameTypeRequirementsGenericParametersAllConcrete<T>(_ x: T) -> (
  value: T, pullback: (T.TangentVector) -> T.TangentVector
) where T: Differentiable, T.TangentVector == Float {
  return (x, { $0 })
}

struct Wrapper<T: Equatable>: Equatable {
  var x: T
  init(_ x: T) { self.x = x }
}
extension Wrapper: AdditiveArithmetic where T: AdditiveArithmetic {
  static var zero: Self { .init(.zero) }
  static func + (lhs: Self, rhs: Self) -> Self { .init(lhs.x + rhs.x) }
  static func - (lhs: Self, rhs: Self) -> Self { .init(lhs.x - rhs.x) }
}
extension Wrapper: Differentiable where T: Differentiable, T == T.TangentVector {
  typealias TangentVector = Wrapper<T.TangentVector>
}
extension Wrapper where T: Differentiable, T == T.TangentVector {
  @derivative(of: init(_:))
  static func vjpInit(_ x: T) -> (value: Self, pullback: (Wrapper<T>.TangentVector) -> (T)) {
    fatalError()
  }
}

// Test class methods.

class Super {
  @differentiable
  func foo(_ x: Float) -> Float {
    return x
  }

  @derivative(of: foo)
  func vjpFoo(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
    return (foo(x), { v in v })
  }
}

class Sub: Super {
  // TODO(TF-649): Enable `@derivative` to override derivatives for original
  // declaration defined in superclass.
  // expected-error @+1 {{'foo' is not defined in the current type context}}
  @derivative(of: foo)
  override func vjpFoo(_ x: Float) -> (value: Float, pullback: (Float) -> Float)
  {
    return (foo(x), { v in v })
  }
}

// Test non-`func` original declarations.

struct Struct<T> {
  var x: T
}
extension Struct: Equatable where T: Equatable {}
extension Struct: Differentiable & AdditiveArithmetic
where T: Differentiable & AdditiveArithmetic {
  static var zero: Self {
    fatalError()
  }
  static func + (lhs: Self, rhs: Self) -> Self {
    fatalError()
  }
  static func - (lhs: Self, rhs: Self) -> Self {
    fatalError()
  }
  typealias TangentVector = Struct<T.TangentVector>
  mutating func move(along direction: TangentVector) {
    x.move(along: direction.x)
  }
}

// Test computed properties.

extension Struct {
  var computedProperty: T { x }
}
extension Struct where T: Differentiable & AdditiveArithmetic {
  @derivative(of: computedProperty)
  func vjpProperty() -> (value: T, pullback: (T.TangentVector) -> TangentVector) {
    return (x, { v in .init(x: v) })
  }
}

// Test initializers.

extension Struct {
  init(_ x: Float) {}
  init(_ x: T, y: Float) {}
}
extension Struct where T: Differentiable & AdditiveArithmetic {
  @derivative(of: init)
  static func vjpInit(_ x: Float) -> (
    value: Struct, pullback: (TangentVector) -> Float
  ) {
    return (.init(x), { _ in .zero })
  }

  @derivative(of: init(_:y:))
  static func vjpInit2(_ x: T, _ y: Float) -> (
    value: Struct, pullback: (TangentVector) -> (T.TangentVector, Float)
  ) {
    return (.init(x, y: y), { _ in (.zero, .zero) })
  }
}

// Test subscripts.

extension Struct {
  subscript() -> Float {
    get { 1 }
    set {}
  }
  subscript(float float: Float) -> Float { 1 }
  subscript<T: Differentiable>(x: T) -> T { x }
}
extension Struct where T: Differentiable & AdditiveArithmetic {
  @derivative(of: subscript)
  func vjpSubscript() -> (value: Float, pullback: (Float) -> TangentVector) {
    return (1, { _ in .zero })
  }

  @derivative(of: subscript(float:), wrt: self)
  func vjpSubscriptLabelled(float: Float) -> (value: Float, pullback: (Float) -> TangentVector) {
    return (1, { _ in .zero })
  }

  @derivative(of: subscript(_:), wrt: self)
  func vjpSubscriptGeneric<T: Differentiable>(x: T) -> (value: T, pullback: (T.TangentVector) -> TangentVector) {
    return (x, { _ in .zero })
  }
}

// Test duplicate `@derivative` attribute.

func duplicate(_ x: Float) -> Float { x }
// expected-note @+1 {{other attribute declared here}}
@derivative(of: duplicate)
func jvpDuplicate1(_ x: Float) -> (value: Float, differential: (Float) -> Float) {
  return (duplicate(x), { $0 })
}
// expected-error @+1 {{a derivative already exists for 'duplicate'}}
@derivative(of: duplicate)
func jvpDuplicate2(_ x: Float) -> (value: Float, differential: (Float) -> Float) {
  return (duplicate(x), { $0 })
}

// Test invalid original declaration kind.

var globalVariable: Float
// expected-error @+1 {{'globalVariable' is not a 'func', 'init', 'subscript', or 'var' computed property declaration}}
@derivative(of: globalVariable)
func invalidOriginalDeclaration(x: Float) -> (
  value: Float, differential: (Float) -> (Float)
) {
  return (x, { $0 })
}

// Test ambiguous original declaration.

protocol P1 {}
protocol P2 {}
func ambiguous<T: P1>(_ x: T) -> T { x }
func ambiguous<T: P2>(_ x: T) -> T { x }

// expected-error @+1 {{ambiguous reference to 'ambiguous' in '@derivative' attribute}}
@derivative(of: ambiguous)
func jvpAmbiguous<T: P1 & P2 & Differentiable>(x: T)
  -> (value: T, differential: (T.TangentVector) -> (T.TangentVector))
{
  return (x, { $0 })
}

// Test no valid original declaration.
// Original declarations are invalid because they have extra generic
// requirements unsatisfied by the `@derivative` function.

func invalid<T: BinaryFloatingPoint>(x: T) -> T { x }
func invalid<T: CustomStringConvertible>(x: T) -> T { x }
func invalid<T: FloatingPoint>(x: T) -> T { x }

// expected-error @+1 {{could not find function 'invalid' with expected type '<T where T : Differentiable> (x: T) -> T'}}
@derivative(of: invalid)
func jvpInvalid<T: Differentiable>(x: T) -> (
  value: T, differential: (T.TangentVector) -> T.TangentVector
) {
  return (x, { $0 })
}

// Test invalid derivative type context: instance vs static method mismatch.

struct InvalidTypeContext<T: Differentiable> {
  static func staticMethod(_ x: T) -> T { x }

  // expected-error @+1 {{could not find function 'staticMethod' with expected type '<T where T : Differentiable> (InvalidTypeContext<T>) -> (T) -> T'}}
  @derivative(of: staticMethod)
  func jvpStatic(_ x: T) -> (
    value: T, differential: (T.TangentVector) -> (T.TangentVector)
  ) {
    return (x, { $0 })
  }
}

// Test stored property original declaration.

struct HasStoredProperty {
  // expected-note @+1 {{'stored' declared here}}
  var stored: Float
}
extension HasStoredProperty: Differentiable & AdditiveArithmetic {
  static var zero: Self {
    fatalError()
  }
  static func + (lhs: Self, rhs: Self) -> Self {
    fatalError()
  }
  static func - (lhs: Self, rhs: Self) -> Self {
    fatalError()
  }
  typealias TangentVector = Self
}
extension HasStoredProperty {
  // expected-error @+1 {{cannot register derivative for stored property 'stored'}}
  @derivative(of: stored)
  func vjpStored() -> (value: Float, pullback: (Float) -> TangentVector) {
    return (stored, { _ in .zero })
  }
}

// Test derivative registration for protocol requirements. Currently unsupported.
// TODO(TF-982): Lift this restriction and add proper support.

protocol ProtocolRequirementDerivative {
  func requirement(_ x: Float) -> Float
}
extension ProtocolRequirementDerivative {
  // NOTE: the error is misleading because `findAbstractFunctionDecl` in
  // TypeCheckAttr.cpp is not setup to show customized error messages for
  // invalid original function candidates.
  // expected-error @+1 {{could not find function 'requirement' with expected type '<Self where Self : ProtocolRequirementDerivative> (Self) -> (Float) -> Float'}}
  @derivative(of: requirement)
  func vjpRequirement(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
    fatalError()
  }
}

// Test `inout` parameters.

func multipleSemanticResults(_ x: inout Float) -> Float {
  return x
}
// expected-error @+1 {{cannot differentiate functions with both an 'inout' parameter and a result}}
@derivative(of: multipleSemanticResults)
func vjpMultipleSemanticResults(x: inout Float) -> (
  value: Float, pullback: (Float) -> Float
) {
  return (multipleSemanticResults(&x), { $0 })
}

struct InoutParameters: Differentiable {
  typealias TangentVector = DummyTangentVector
  mutating func move(along _: TangentVector) {}
}

extension InoutParameters {
  // expected-note @+1 4 {{'staticMethod(_:rhs:)' defined here}}
  static func staticMethod(_ lhs: inout Self, rhs: Self) {}

  // Test wrt `inout` parameter.

  @derivative(of: staticMethod)
  static func vjpWrtInout(_ lhs: inout Self, _ rhs: Self) -> (
    value: Void, pullback: (inout TangentVector) -> TangentVector
  ) { fatalError() }

  // expected-error @+1 {{function result's 'pullback' type does not match 'staticMethod(_:rhs:)'}}
  @derivative(of: staticMethod)
  static func vjpWrtInoutMismatch(_ lhs: inout Self, _ rhs: Self) -> (
    // expected-note @+1 {{'pullback' does not have expected type '(inout InoutParameters.TangentVector) -> InoutParameters.TangentVector' (aka '(inout DummyTangentVector) -> DummyTangentVector')}}
    value: Void, pullback: (TangentVector) -> TangentVector
  ) { fatalError() }

  @derivative(of: staticMethod)
  static func jvpWrtInout(_ lhs: inout Self, _ rhs: Self) -> (
    value: Void, differential: (inout TangentVector, TangentVector) -> Void
  ) { fatalError() }

  // expected-error @+1 {{function result's 'differential' type does not match 'staticMethod(_:rhs:)'}}
  @derivative(of: staticMethod)
  static func jvpWrtInoutMismatch(_ lhs: inout Self, _ rhs: Self) -> (
    // expected-note @+1 {{'differential' does not have expected type '(inout InoutParameters.TangentVector, InoutParameters.TangentVector) -> ()' (aka '(inout DummyTangentVector, DummyTangentVector) -> ()')}}
    value: Void, differential: (TangentVector, TangentVector) -> Void
  ) { fatalError() }

  // Test non-wrt `inout` parameter.

  @derivative(of: staticMethod, wrt: rhs)
  static func vjpNotWrtInout(_ lhs: inout Self, _ rhs: Self) -> (
    value: Void, pullback: (TangentVector) -> TangentVector
  ) { fatalError() }

  // expected-error @+1 {{function result's 'pullback' type does not match 'staticMethod(_:rhs:)'}}
  @derivative(of: staticMethod, wrt: rhs)
  static func vjpNotWrtInoutMismatch(_ lhs: inout Self, _ rhs: Self) -> (
    // expected-note @+1 {{'pullback' does not have expected type '(InoutParameters.TangentVector) -> InoutParameters.TangentVector' (aka '(DummyTangentVector) -> DummyTangentVector')}}
    value: Void, pullback: (inout TangentVector) -> TangentVector
  ) { fatalError() }

  @derivative(of: staticMethod, wrt: rhs)
  static func jvpNotWrtInout(_ lhs: inout Self, _ rhs: Self) -> (
    value: Void, differential: (TangentVector) -> TangentVector
  ) { fatalError() }

  // expected-error @+1 {{function result's 'differential' type does not match 'staticMethod(_:rhs:)'}}
  @derivative(of: staticMethod, wrt: rhs)
  static func jvpNotWrtInout(_ lhs: inout Self, _ rhs: Self) -> (
    // expected-note @+1 {{'differential' does not have expected type '(InoutParameters.TangentVector) -> InoutParameters.TangentVector' (aka '(DummyTangentVector) -> DummyTangentVector')}}
    value: Void, differential: (inout TangentVector) -> TangentVector
  ) { fatalError() }
}

extension InoutParameters {
  // expected-note @+1 4 {{'mutatingMethod' defined here}}
  mutating func mutatingMethod(_ other: Self) {}

  // Test wrt `inout` `self` parameter.

  @derivative(of: mutatingMethod)
  mutating func vjpWrtInout(_ other: Self) -> (
    value: Void, pullback: (inout TangentVector) -> TangentVector
  ) { fatalError() }

  // expected-error @+1 {{function result's 'pullback' type does not match 'mutatingMethod'}}
  @derivative(of: mutatingMethod)
  mutating func vjpWrtInoutMismatch(_ other: Self) -> (
    // expected-note @+1 {{'pullback' does not have expected type '(inout InoutParameters.TangentVector) -> InoutParameters.TangentVector' (aka '(inout DummyTangentVector) -> DummyTangentVector')}}
    value: Void, pullback: (TangentVector) -> TangentVector
  ) { fatalError() }

  @derivative(of: mutatingMethod)
  mutating func jvpWrtInout(_ other: Self) -> (
    value: Void, differential: (inout TangentVector, TangentVector) -> Void
  ) { fatalError() }

  // expected-error @+1 {{function result's 'differential' type does not match 'mutatingMethod'}}
  @derivative(of: mutatingMethod)
  mutating func jvpWrtInoutMismatch(_ other: Self) -> (
    // expected-note @+1 {{'differential' does not have expected type '(inout InoutParameters.TangentVector, InoutParameters.TangentVector) -> ()' (aka '(inout DummyTangentVector, DummyTangentVector) -> ()')}}
    value: Void, differential: (TangentVector, TangentVector) -> Void
  ) { fatalError() }

  // Test non-wrt `inout` `self` parameter.

  @derivative(of: mutatingMethod, wrt: other)
  mutating func vjpNotWrtInout(_ other: Self) -> (
    value: Void, pullback: (TangentVector) -> TangentVector
  ) { fatalError() }

  // expected-error @+1 {{function result's 'pullback' type does not match 'mutatingMethod'}}
  @derivative(of: mutatingMethod, wrt: other)
  mutating func vjpNotWrtInoutMismatch(_ other: Self) -> (
    // expected-note @+1 {{'pullback' does not have expected type '(InoutParameters.TangentVector) -> InoutParameters.TangentVector' (aka '(DummyTangentVector) -> DummyTangentVector')}}
    value: Void, pullback: (inout TangentVector) -> TangentVector
  ) { fatalError() }

  @derivative(of: mutatingMethod, wrt: other)
  mutating func jvpNotWrtInout(_ other: Self) -> (
    value: Void, differential: (TangentVector) -> TangentVector
  ) { fatalError() }

  // expected-error @+1 {{function result's 'differential' type does not match 'mutatingMethod'}}
  @derivative(of: mutatingMethod, wrt: other)
  mutating func jvpNotWrtInoutMismatch(_ other: Self) -> (
    // expected-note @+1 {{'differential' does not have expected type '(InoutParameters.TangentVector) -> InoutParameters.TangentVector' (aka '(DummyTangentVector) -> DummyTangentVector')}}
    value: Void, differential: (TangentVector, TangentVector) -> Void
  ) { fatalError() }
}

// Test multiple semantic results.

extension InoutParameters {
  func multipleSemanticResults(_ x: inout Float) -> Float { x }
  // expected-error @+1 {{cannot differentiate functions with both an 'inout' parameter and a result}}
  @derivative(of: multipleSemanticResults)
  func vjpMultipleSemanticResults(_ x: inout Float) -> (
    value: Float, pullback: (inout Float) -> Void
  ) { fatalError() }

  func inoutVoid(_ x: Float, _ void: inout Void) -> Float {}
  // expected-error @+1 {{cannot differentiate functions with both an 'inout' parameter and a result}}
  @derivative(of: inoutVoid)
  func vjpInoutVoidParameter(_ x: Float, _ void: inout Void) -> (
    value: Float, pullback: (inout Float) -> Void
  ) { fatalError() }
}

// Test original/derivative function `inout` parameter mismatches.

extension InoutParameters {
  func inoutParameterMismatch(_ x: Float) {}
  // expected-error @+1 {{could not find function 'inoutParameterMismatch' with expected type '(InoutParameters) -> (inout Float) -> Void'}}
  @derivative(of: inoutParameterMismatch)
  func vjpInoutParameterMismatch(_ x: inout Float) -> (value: Void, pullback: (inout Float) -> Void) {
    fatalError()
  }

  func mutatingMismatch(_ x: Float) {}
  // expected-error @+1 {{could not find function 'mutatingMismatch' with expected type '(inout InoutParameters) -> (Float) -> Void'}}
  @derivative(of: mutatingMismatch)
  mutating func vjpMutatingMismatch(_ x: Float) -> (value: Void, pullback: (inout Float) -> Void) {
    fatalError()
  }
}

// Test cross-file derivative registration.

extension FloatingPoint where Self: Differentiable {
  @usableFromInline
  @derivative(of: rounded)
  func vjpRounded() -> (
    value: Self,
    pullback: (Self.TangentVector) -> (Self.TangentVector)
  ) {
    fatalError()
  }
}

extension Differentiable where Self: AdditiveArithmetic {
  // expected-error @+1 {{'+' is not defined in the current type context}}
  @derivative(of: +)
  static func vjpPlus(x: Self, y: Self) -> (
    value: Self,
    pullback: (Self.TangentVector) -> (Self.TangentVector, Self.TangentVector)
  ) {
    return (x + y, { v in (v, v) })
  }
}

extension AdditiveArithmetic
where Self: Differentiable, Self == Self.TangentVector {
  // expected-error @+1 {{could not find function '+' with expected type '<Self where Self : Differentiable, Self == Self.TangentVector> (Self) -> (Self, Self) -> Self'}}
  @derivative(of: +)
  func vjpPlusInstanceMethod(x: Self, y: Self) -> (
    value: Self, pullback: (Self) -> (Self, Self)
  ) {
    return (x + y, { v in (v, v) })
  }
}

// Test derivatives of default implementations.
protocol HasADefaultImplementation {
  func req(_ x: Float) -> Float
}
extension HasADefaultImplementation {
  func req(_ x: Float) -> Float { x }
  // ok
  @derivative(of: req)
  func req(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
    (x, { 10 * $0 })
  }
}

// Test default derivatives of requirements.
protocol HasADefaultDerivative {
  func req(_ x: Float) -> Float
}
extension HasADefaultDerivative {
  // TODO(TF-982): Make this ok.
  // expected-error @+1 {{could not find function 'req'}}
  @derivative(of: req)
  func req(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
    (x, { 10 * $0 })
  }
}

// MARK: - Original function visibility = derivative function visibility

public func public_original_public_derivative(_ x: Float) -> Float { x }
@derivative(of: public_original_public_derivative)
public func _public_original_public_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

public func public_original_usablefrominline_derivative(_ x: Float) -> Float { x }
@usableFromInline
@derivative(of: public_original_usablefrominline_derivative)
func _public_original_usablefrominline_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

func internal_original_internal_derivative(_ x: Float) -> Float { x }
@derivative(of: internal_original_internal_derivative)
func _internal_original_internal_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

private func private_original_private_derivative(_ x: Float) -> Float { x }
@derivative(of: private_original_private_derivative)
private func _private_original_private_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

fileprivate func fileprivate_original_fileprivate_derivative(_ x: Float) -> Float { x }
@derivative(of: fileprivate_original_fileprivate_derivative)
fileprivate func _fileprivate_original_fileprivate_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

func internal_original_usablefrominline_derivative(_ x: Float) -> Float { x }
@usableFromInline
@derivative(of: internal_original_usablefrominline_derivative)
func _internal_original_usablefrominline_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

func internal_original_inlinable_derivative(_ x: Float) -> Float { x }
@inlinable
@derivative(of: internal_original_inlinable_derivative)
func _internal_original_inlinable_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

func internal_original_alwaysemitintoclient_derivative(_ x: Float) -> Float { x }
@_alwaysEmitIntoClient
@derivative(of: internal_original_alwaysemitintoclient_derivative)
func _internal_original_alwaysemitintoclient_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

// MARK: - Original function visibility < derivative function visibility

@usableFromInline
func usablefrominline_original_public_derivative(_ x: Float) -> Float { x }
// expected-error @+1 {{derivative function must have same access level as original function; derivative function '_usablefrominline_original_public_derivative' is public, but original function 'usablefrominline_original_public_derivative' is internal}}
@derivative(of: usablefrominline_original_public_derivative)
// expected-note @+1 {{mark the derivative function as 'internal' to match the original function}} {{1-7=internal}}
public func _usablefrominline_original_public_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

func internal_original_public_derivative(_ x: Float) -> Float { x }
// expected-error @+1 {{derivative function must have same access level as original function; derivative function '_internal_original_public_derivative' is public, but original function 'internal_original_public_derivative' is internal}}
@derivative(of: internal_original_public_derivative)
// expected-note @+1 {{mark the derivative function as 'internal' to match the original function}} {{1-7=internal}}
public func _internal_original_public_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

private func private_original_usablefrominline_derivative(_ x: Float) -> Float { x }
// expected-error @+1 {{derivative function must have same access level as original function; derivative function '_private_original_usablefrominline_derivative' is internal, but original function 'private_original_usablefrominline_derivative' is private}}
@derivative(of: private_original_usablefrominline_derivative)
@usableFromInline
// expected-note @+1 {{mark the derivative function as 'private' to match the original function}} {{1-1=private }}
func _private_original_usablefrominline_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

private func private_original_public_derivative(_ x: Float) -> Float { x }
// expected-error @+1 {{derivative function must have same access level as original function; derivative function '_private_original_public_derivative' is public, but original function 'private_original_public_derivative' is private}}
@derivative(of: private_original_public_derivative)
// expected-note @+1 {{mark the derivative function as 'private' to match the original function}} {{1-7=private}}
public func _private_original_public_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

private func private_original_internal_derivative(_ x: Float) -> Float { x }
// expected-error @+1 {{derivative function must have same access level as original function; derivative function '_private_original_internal_derivative' is internal, but original function 'private_original_internal_derivative' is private}}
@derivative(of: private_original_internal_derivative)
// expected-note @+1 {{mark the derivative function as 'private' to match the original function}}
func _private_original_internal_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

fileprivate func fileprivate_original_private_derivative(_ x: Float) -> Float { x }
// expected-error @+1 {{derivative function must have same access level as original function; derivative function '_fileprivate_original_private_derivative' is private, but original function 'fileprivate_original_private_derivative' is fileprivate}}
@derivative(of: fileprivate_original_private_derivative)
// expected-note @+1 {{mark the derivative function as 'fileprivate' to match the original function}} {{1-8=fileprivate}}
private func _fileprivate_original_private_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

private func private_original_fileprivate_derivative(_ x: Float) -> Float { x }
// expected-error @+1 {{derivative function must have same access level as original function; derivative function '_private_original_fileprivate_derivative' is fileprivate, but original function 'private_original_fileprivate_derivative' is private}}
@derivative(of: private_original_fileprivate_derivative)
// expected-note @+1 {{mark the derivative function as 'private' to match the original function}} {{1-12=private}}
fileprivate func _private_original_fileprivate_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

// MARK: - Original function visibility > derivative function visibility

public func public_original_private_derivative(_ x: Float) -> Float { x }
// expected-error @+1 {{derivative function must have same access level as original function; derivative function '_public_original_private_derivative' is fileprivate, but original function 'public_original_private_derivative' is public}}
@derivative(of: public_original_private_derivative)
// expected-note @+1 {{mark the derivative function as '@usableFromInline' to match the original function}} {{1-1=@usableFromInline }}
fileprivate func _public_original_private_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

public func public_original_internal_derivative(_ x: Float) -> Float { x }
// expected-error @+1 {{derivative function must have same access level as original function; derivative function '_public_original_internal_derivative' is internal, but original function 'public_original_internal_derivative' is public}}
@derivative(of: public_original_internal_derivative)
// expected-note @+1 {{mark the derivative function as '@usableFromInline' to match the original function}} {{1-1=@usableFromInline }}
func _public_original_internal_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}

func internal_original_fileprivate_derivative(_ x: Float) -> Float { x }
// expected-error @+1 {{derivative function must have same access level as original function; derivative function '_internal_original_fileprivate_derivative' is fileprivate, but original function 'internal_original_fileprivate_derivative' is internal}}
@derivative(of: internal_original_fileprivate_derivative)
// expected-note @+1 {{mark the derivative function as 'internal' to match the original function}} {{1-12=internal}}
fileprivate func _internal_original_fileprivate_derivative(_ x: Float) -> (value: Float, pullback: (Float) -> Float) {
  fatalError()
}
