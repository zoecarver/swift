// RUN: %target-swift-frontend -typecheck -verify %s -enable-experimental-concurrency

func globalAsyncFunction() async -> Int { 0 }

@asyncHandler func asyncHandler1() {
  // okay, it's an async context
  let _ = await globalAsyncFunction()
}

@asyncHandler func asyncHandler2(fn: @autoclosure () async -> Int ) {
  // okay, it's an async context
}

@asyncHandler
func asyncHandlerBad1() -> Int { 0 }
// expected-error@-1{{'@asyncHandler' function can only return 'Void'}}

@asyncHandler
func asyncHandlerBad2() async { }
// expected-error@-1{{'@asyncHandler' function cannot be 'async' itself}}{{25-31=}}

@asyncHandler
func asyncHandlerBad3() throws { }
// expected-error@-1{{'@asyncHandler' function cannot throw}}{{25-32=}}

@asyncHandler
func asyncHandlerBad4(result: inout Int) { }
// expected-error@-1{{'inout' parameter is not allowed in '@asyncHandler' function}}

actor class X {
  @asyncHandler func asyncHandlerMethod() { }

  @asyncHandler init() { }
  // expected-error@-1{{@asyncHandler may only be used on 'func' declarations}}
}

// Inference of @asyncHandler
protocol P {
  @asyncHandler func callback()
}

extension X: P {
  func callback() {
    // okay, it's an async context
    let _ = await globalAsyncFunction()
 }
}

class Y: P {
  // @asyncHandler is not inferred for classes

  func callback() {
    // expected-note@-1{{add 'async' to function 'callback()' to make it asynchronous}}
    // expected-note@-2{{add '@asyncHandler' to function 'callback()' to create an implicit asynchronous context}}

    // okay, it's an async context
    let _ = await globalAsyncFunction() // expected-error{{'async' in a function that does not support concurrency}}
 }
}

struct Z {
  @asyncHandler
  mutating func asyncHandlerMethodBad1() { }
  // expected-error@-1{{'@asyncHandler' function cannot be 'mutating'}}{{3-12=}}
}
