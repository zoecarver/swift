import Transforms

fileprivate struct FooPass {
  
}

func createFooPass() -> UnsafeMutablePointer<SILTransform> {
  let pass = FooPass()
  var cxxPass = unsafeBitCast(pass, to: SILTransform.self)
  let passPtr = UnsafeMutablePointer<SILTransform>.allocate(capacity: 1)
  passPtr.pointee = cxxPass
  return passPtr
}

