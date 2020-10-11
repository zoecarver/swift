cmake_policy(SET CMP0079 NEW)

add_swift_host_library(swiftSwiftPasses SHARED SWIFT_SOURCE SwiftPasses.swift)
set_target_properties(swiftSwiftPasses PROPERTIES BUILD_WITH_INSTALL_RPATH TRUE)
target_link_options(swiftSwiftPasses PUBLIC "LINKER:-install_name,@rpath/libswiftSwiftPasses.dylib")
target_include_directories(swiftSwiftPasses PRIVATE
  "/Users/zoe/Developer/swift-source/swift/include/swift/SILOptimizer/PassManager"
  "/Users/zoe/Developer/swift-source/llvm-project/libcxx/include")
target_compile_options(swiftSwiftPasses PRIVATE
  "-Xfrontend"
  "-enable-cxx-interop")

set_swift_llvm_is_available()
add_swift_host_library(swiftSILOptimizer STATIC
  SILOptimizer.cpp)
target_link_libraries(swiftSILOptimizer PRIVATE
  swiftSIL
  swiftSwiftPasses)

add_subdirectory(ARC)
add_subdirectory(Analysis)
add_subdirectory(Differentiation)
add_subdirectory(FunctionSignatureTransforms)
add_subdirectory(IPO)
add_subdirectory(LoopTransforms)
add_subdirectory(Mandatory)
add_subdirectory(PassManager)
add_subdirectory(SILCombiner)
add_subdirectory(SemanticARC)
add_subdirectory(Transforms)
add_subdirectory(UtilityPasses)
add_subdirectory(Utils)
