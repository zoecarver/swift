// RUN: %target-typecheck-verify-swift -enable-experimental-concurrency
// REQUIRES: concurrency

import _Concurrency

let immutableGlobal: String = "hello"
var mutableGlobal: String = "can't touch this" // expected-note 2{{var declared here}}

func globalFunc() { }
func acceptClosure<T>(_: () -> T) { }
func acceptEscapingClosure<T>(_: @escaping () -> T) { }

func acceptAsyncClosure<T>(_: () async -> T) { }
func acceptEscapingAsyncClosure<T>(_: @escaping () async -> T) { }

// ----------------------------------------------------------------------
// Actor state isolation restrictions
// ----------------------------------------------------------------------
actor class MySuperActor {
  var superState: Int = 25 // expected-note {{mutable state is only available within the actor instance}}

  func superMethod() { } // expected-note 3 {{only asynchronous methods can be used outside the actor instance; do you want to add 'async'?}}
  func superAsyncMethod() async { }

  subscript (index: Int) -> String { // expected-note 3{{subscript declared here}}
    "\(index)"
  }
}

actor class MyActor: MySuperActor {
  let immutable: Int = 17
  var text: [String] = [] // expected-note 9{{mutable state is only available within the actor instance}}

  class func synchronousClass() { }
  static func synchronousStatic() { }

  func synchronous() -> String { text.first ?? "nothing" } // expected-note 21{{only asynchronous methods can be used outside the actor instance; do you want to add 'async'?}}
  func asynchronous() async -> String { synchronous() }
}

extension MyActor {
  @actorIndependent var actorIndependentVar: Int {
    get { 5 }
    set { }
  }

  @actorIndependent func actorIndependentFunc(otherActor: MyActor) -> Int {
    _ = immutable
    _ = text[0] // expected-error{{actor-isolated property 'text' can not be referenced from an '@actorIndependent' context}}
    _ = synchronous() // expected-error{{actor-isolated instance method 'synchronous()' can not be referenced from an '@actorIndependent' context}}

    // @actorIndependent
    _ = actorIndependentFunc(otherActor: self)
    _ = actorIndependentVar

    actorIndependentVar = 17
    _ = self.actorIndependentFunc(otherActor: self)
    _ = self.actorIndependentVar
    self.actorIndependentVar = 17

    // @actorIndependent on another actor
    _ = otherActor.actorIndependentFunc(otherActor: self)
    _ = otherActor.actorIndependentVar
    otherActor.actorIndependentVar = 17

    // Global actors
    syncGlobalActorFunc() /// expected-error{{global function 'syncGlobalActorFunc()' isolated to global actor 'SomeGlobalActor' can not be referenced from an '@actorIndependent' context}}

    // Global data is okay if it is immutable.
    _ = immutableGlobal
    _ = mutableGlobal // expected-warning{{reference to var 'mutableGlobal' is not concurrency-safe because it involves shared mutable state}}

    // Partial application
    _ = synchronous  // expected-error{{actor-isolated instance method 'synchronous()' can not be referenced from an '@actorIndependent' context}}
    _ = super.superMethod // expected-error{{actor-isolated instance method 'superMethod()' can not be referenced from an '@actorIndependent' context}}
    acceptClosure(synchronous) // expected-error{{actor-isolated instance method 'synchronous()' can not be referenced from an '@actorIndependent' context}}
    acceptClosure(self.synchronous) // expected-error{{actor-isolated instance method 'synchronous()' can not be referenced from an '@actorIndependent' context}}
    acceptClosure(otherActor.synchronous) // expected-error{{actor-isolated instance method 'synchronous()' can only be referenced on 'self'}}
    acceptEscapingClosure(synchronous) // expected-error{{actor-isolated instance method 'synchronous()' can not be referenced from an '@actorIndependent' context}}}}
    acceptEscapingClosure(self.synchronous) // expected-error{{actor-isolated instance method 'synchronous()' can not be referenced from an '@actorIndependent'}}
    acceptEscapingClosure(otherActor.synchronous) // expected-error{{actor-isolated instance method 'synchronous()' can only be referenced on 'self'}}

    return 5
  }

  func testAsynchronous(otherActor: MyActor) async {
    _ = immutable
    _ = synchronous()
    _ = text[0]

    // Accesses on 'self' are okay.
    _ = self.immutable
    _ = self.synchronous()
    _ = await self.asynchronous()
    _ = self.text[0]
    _ = self[0]

    // Accesses on 'super' are okay.
    _ = super.superState
    super.superMethod()
    await super.superAsyncMethod()
    _ = super[0]

    // Accesses on other actors can only reference immutable data or
    // call asychronous methods
    _ = otherActor.immutable // okay
    _ = otherActor.synchronous() // expected-error{{actor-isolated instance method 'synchronous()' can only be referenced on 'self'}}
    _ = await otherActor.asynchronous()
    _ = otherActor.text[0] // expected-error{{actor-isolated property 'text' can only be referenced on 'self'}}

    // Global data is okay if it is immutable.
    _ = immutableGlobal
    _ = mutableGlobal // expected-warning{{reference to var 'mutableGlobal' is not concurrency-safe because it involves shared mutable state}}

    // Global functions are not actually safe, but we allow them for now.
    globalFunc()

    // Class methods are okay.
    Self.synchronousClass()
    Self.synchronousStatic()

    // Global actors
    syncGlobalActorFunc() // expected-error{{global function 'syncGlobalActorFunc()' isolated to global actor 'SomeGlobalActor' can not be referenced from actor 'MyActor'}}
    await asyncGlobalActorFunc()

    // Closures.
    let localConstant = 17
    var localVar = 17 // expected-note 3{{var declared here}}

    // Non-escaping closures are okay.
    acceptClosure {
      _ = text[0]
      _ = self.synchronous()
      _ = localVar
      _ = localConstant
    }

    // Escaping closures might run concurrently.
    acceptEscapingClosure {
      _ = self.text[0] // expected-error{{actor-isolated property 'text' is unsafe to reference in code that may execute concurrently}}
      _ = self.synchronous() // expected-error{{actor-isolated instance method 'synchronous()' is unsafe to reference in code that may execute concurrently}}
      _ = localVar // expected-warning{{local var 'localVar' is unsafe to reference in code that may execute concurrently}}
      _ = localConstant
    }

    // Local functions might run concurrently.
    func localFn1() {
      _ = self.text[0] // expected-error{{actor-isolated property 'text' is unsafe to reference in code that may execute concurrently}}
      _ = self.synchronous() // expected-error{{actor-isolated instance method 'synchronous()' is unsafe to reference in code that may execute concurrently}}
      _ = localVar // expected-warning{{local var 'localVar' is unsafe to reference in code that may execute concurrently}}
      _ = localConstant
    }

    func localFn2() {
      acceptClosure {
        _ = text[0]  // expected-error{{actor-isolated property 'text' is unsafe to reference in code that may execute concurrently}}
        _ = self.synchronous() // expected-error{{actor-isolated instance method 'synchronous()' is unsafe to reference in code that may execute concurrently}}
        _ = localVar // expected-warning{{local var 'localVar' is unsafe to reference in code that may execute concurrently}}
        _ = localConstant
      }
    }

    localVar = 0

    // Partial application
    _ = synchronous  // expected-error{{actor-isolated instance method 'synchronous()' can not be partially applied}}
    _ = super.superMethod // expected-error{{actor-isolated instance method 'superMethod()' is unsafe to reference in code that may execute concurrently}}
    acceptClosure(synchronous)
    acceptClosure(self.synchronous)
    acceptClosure(otherActor.synchronous) // expected-error{{actor-isolated instance method 'synchronous()' can only be referenced on 'self'}}
    acceptEscapingClosure(synchronous) // expected-error{{actor-isolated instance method 'synchronous()' can not be partially applied}}
    acceptEscapingClosure(self.synchronous) // expected-error{{actor-isolated instance method 'synchronous()' can not be partially applied}}
    acceptEscapingClosure(otherActor.synchronous) // expected-error{{actor-isolated instance method 'synchronous()' can only be referenced on 'self'}}

    acceptAsyncClosure(self.asynchronous)
    acceptEscapingAsyncClosure(self.asynchronous)
  }
}

// ----------------------------------------------------------------------
// Global actor isolation restrictions
// ----------------------------------------------------------------------
actor class SomeActor { }

@globalActor
struct SomeGlobalActor {
  static let shared = SomeActor()
}

@globalActor
struct SomeOtherGlobalActor {
  static let shared = SomeActor()
}

@globalActor
struct GenericGlobalActor<T> {
  static var shared: SomeActor { SomeActor() }
}

@SomeGlobalActor func syncGlobalActorFunc() { } // expected-note 3{{only asynchronous methods can be used outside the actor instance; do you want to add 'async'?}}
@SomeGlobalActor func asyncGlobalActorFunc() async { }

@SomeOtherGlobalActor func syncOtherGlobalActorFunc() { } // expected-note {{only asynchronous methods can be used outside the actor instance; do you want to add 'async'?}}

@SomeOtherGlobalActor func asyncOtherGlobalActorFunc() async {
  syncGlobalActorFunc() // expected-error{{global function 'syncGlobalActorFunc()' isolated to global actor 'SomeGlobalActor' can not be referenced from different global actor 'SomeOtherGlobalActor'}}
  await asyncGlobalActorFunc()
}

extension MyActor {
  @SomeGlobalActor func onGlobalActor(otherActor: MyActor) async {
    // Access to other functions in this actor are okay.
    syncGlobalActorFunc()
    await asyncGlobalActorFunc()

    // Other global actors are not okay
    syncOtherGlobalActorFunc() // expected-error{{global function 'syncOtherGlobalActorFunc()' isolated to global actor 'SomeOtherGlobalActor' can not be referenced from different global actor 'SomeGlobalActor'}}
    await asyncOtherGlobalActorFunc()

    _ = immutable
    _ = synchronous() // expected-error{{actor-isolated instance method 'synchronous()' can not be referenced from context of global actor 'SomeGlobalActor'}}
    _ = text[0] // expected-error{{actor-isolated property 'text' can not be referenced from context of global actor 'SomeGlobalActor'}}

    // Accesses on 'self' are only okay for immutable and asynchronous, because
    // we are outside of the actor instance.
    _ = self.immutable
    _ = self.synchronous() // expected-error{{actor-isolated instance method 'synchronous()' can not be referenced from context of global actor 'SomeGlobalActor'}}
    _ = await self.asynchronous()
    _ = self.text[0] // expected-error{{actor-isolated property 'text' can not be referenced from context of global actor 'SomeGlobalActor'}}
    _ = self[0] // expected-error{{actor-isolated subscript 'subscript(_:)' can not be referenced from context of global actor 'SomeGlobalActor'}}

    // Accesses on 'super' are not okay; we're outside of the actor.
    _ = super.superState // expected-error{{actor-isolated property 'superState' can not be referenced from context of global actor 'SomeGlobalActor'}}
    super.superMethod() // expected-error{{actor-isolated instance method 'superMethod()' can not be referenced from context of global actor 'SomeGlobalActor'}}
    await super.superAsyncMethod()
    _ = super[0] // expected-error{{actor-isolated subscript 'subscript(_:)' can not be referenced from context of global actor 'SomeGlobalActor'}}

    // Accesses on other actors can only reference immutable data or
    // call asychronous methods
    _ = otherActor.immutable // okay
    _ = otherActor.synchronous() // expected-error{{actor-isolated instance method 'synchronous()' can only be referenced on 'self'}}
    _ = await otherActor.asynchronous()
    _ = otherActor.text[0] // expected-error{{actor-isolated property 'text' can only be referenced on 'self'}}
  }
}

struct GenericStruct<T> {
  @GenericGlobalActor<T> func f() { } // expected-note{{only asynchronous methods can be used outside the actor instance; do you want to add 'async'?}}

  @GenericGlobalActor<T> func g() {
    f() // okay
  }

  @GenericGlobalActor<String> func h() {
    f() // expected-error{{instance method 'f()' isolated to global actor 'GenericGlobalActor<T>' can not be referenced from different global actor 'GenericGlobalActor<String>'}}
  }
}

extension GenericStruct where T == String {
  @GenericGlobalActor<T>
  func h2() {
    f()
    g()
    h()
  }
}


// ----------------------------------------------------------------------
// Non-actor code isolation restrictions
// ----------------------------------------------------------------------
func testGlobalRestrictions(actor: MyActor) async {
  let _ = MyActor()

  // Asynchronous functions and immutable state are permitted.
  _ = await actor.asynchronous()
  _ = actor.immutable

  // Synchronous operations and mutable state references are not.
  _ = actor.synchronous() // expected-error{{actor-isolated instance method 'synchronous()' can only be referenced inside the actor}}
  _ = actor.text[0] // expected-error{{actor-isolated property 'text' can only be referenced inside the actor}}
  _ = actor[0] // expected-error{{actor-isolated subscript 'subscript(_:)' can only be referenced inside the actor}}

  // @actorIndependent declarations are permitted.
  _ = actor.actorIndependentFunc(otherActor: actor)
  _ = actor.actorIndependentVar
  actor.actorIndependentVar = 5

  // Operations on non-instances are permitted.
  MyActor.synchronousStatic()
  MyActor.synchronousClass()
}
