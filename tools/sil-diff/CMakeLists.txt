add_swift_host_tool(sil-diff
  SILDiff.cpp
  SWIFT_COMPONENT tools
)
target_link_libraries(sil-diff
                      PRIVATE
                        swiftFrontend
                        swiftSIL
                        # Clang libraries included to appease the linker on linux.
                        clangBasic
                        clangCodeGen)
