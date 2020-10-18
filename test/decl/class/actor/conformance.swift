// RUN: %target-typecheck-verify-swift -enable-experimental-concurrency

protocol AsyncProtocol {
  func asyncMethod() async -> Int
}

actor class MyActor {
}

// Actors conforming to asynchronous program.
extension MyActor: AsyncProtocol {
  func asyncMethod() async -> Int { return 0 }
}

protocol SyncProtocol {
  var propertyA: Int { get }
  var propertyB: Int { get set }

  func syncMethodA()

  func syncMethodB()

  func syncMethodC() -> Int

  subscript (index: Int) -> String { get }

  static func staticMethod()
  static var staticProperty: Int { get }
}


actor class OtherActor: SyncProtocol {
  var propertyB: Int = 17
  // expected-error@-1{{actor-isolated property 'propertyB' cannot be used to satisfy a protocol requirement}}

  var propertyA: Int { 17 }
  // expected-error@-1{{actor-isolated property 'propertyA' cannot be used to satisfy a protocol requirement}}

  func syncMethodA() { }
  // expected-error@-1{{actor-isolated instance method 'syncMethodA()' cannot be used to satisfy a protocol requirement; did you mean to make it an asychronous handler?}}{{3-3=@asyncHandler }}

  // Async handlers are okay.
  @asyncHandler
  func syncMethodB() { }

  // @actorIndependent methods are okay.
  // FIXME: Consider suggesting @actorIndependent if this didn't match.
  @actorIndependent func syncMethodC() -> Int { 5 }

  subscript (index: Int) -> String { "\(index)" }
  // expected-error@-1{{actor-isolated subscript 'subscript(_:)' cannot be used to satisfy a protocol requirement}}

  // Static methods and properties are okay.
  static func staticMethod() { }
  static var staticProperty: Int = 17
}
