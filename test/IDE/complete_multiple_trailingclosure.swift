// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=GLOBALFUNC_SAMELINE | %FileCheck %s -check-prefix=GLOBALFUNC_SAMELINE
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=GLOBALFUNC_NEWLINE | %FileCheck %s -check-prefix=GLOBALFUNC_NEWLINE
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=GLOBALFUNC_AFTERLABEL | %FileCheck %s -check-prefix=GLOBALFUNC_AFTERLABEL
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=METHOD_SAMELINE | %FileCheck %s -check-prefix=METHOD_SAMELINE
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=METHOD_NEWLINE | %FileCheck %s -check-prefix=METHOD_NEWLINE
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=INIT_OVERLOADED_SAMELINE | %FileCheck %s -check-prefix=INIT_OVERLOADED_SAMELINE
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=INIT_OVERLOADED_NEWLINE | %FileCheck %s -check-prefix=INIT_OVERLOADED_NEWLINE
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=INIT_OPTIONAL_SAMELINE | %FileCheck %s -check-prefix=INIT_OPTIONAL_SAMELINE
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=INIT_OPTIONAL_NEWLINE | %FileCheck %s -check-prefix=INIT_OPTIONAL_NEWLINE
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=INIT_REQUIRED_SAMELINE_1 | %FileCheck %s -check-prefix=INIT_REQUIRED_SAMELINE_1
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=INIT_REQUIRED_NEWLINE_1 | %FileCheck %s -check-prefix=INIT_REQUIRED_NEWLINE_1
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=INIT_REQUIRED_SAMELINE_2 | %FileCheck %s -check-prefix=INIT_REQUIRED_SAMELINE_2
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=INIT_REQUIRED_NEWLINE_2 | %FileCheck %s -check-prefix=INIT_REQUIRED_NEWLINE_2
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=INIT_REQUIRED_SAMELINE_3 | %FileCheck %s -check-prefix=INIT_REQUIRED_SAMELINE_3
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=INIT_REQUIRED_NEWLINE_3 | %FileCheck %s -check-prefix=INIT_REQUIRED_NEWLINE_3

func globalFunc1(fn1: () -> Int, fn2: () -> String) {}
func testGlobalFunc() {
  globalFunc1()
    { 1 } #^GLOBALFUNC_SAMELINE^#
    #^GLOBALFUNC_NEWLINE^#
// GLOBALFUNC_SAMELINE: Begin completions, 1 items
// GLOBALFUNC_SAMELINE-DAG: Pattern/ExprSpecific:               {#fn2: () -> String {() -> String in|}#}[#() -> String#];
// GLOBALFUNC_SAMELINE: End completions

// GLOBALFUNC_NEWLINE: Begin completions, 1 items
// GLOBALFUNC_NEWLINE-DAG: Pattern/ExprSpecific:               {#fn2: () -> String {() -> String in|}#}[#() -> String#];
// GLOBALFUNC_NEWLINE: End completions

  globalFunc1()
    { 1 } fn2: #^GLOBALFUNC_AFTERLABEL^#
// FIXME: Closure literal completion.
// GLOBALFUNC_AFTERLABEL-NOT: Begin completions
}

struct SimpleEnum {
  case foo, bar

  func enumFunc() {}
  static func + (lhs: SimpleEnum, rhs: SimpleEnum) -> SimpleEnum {}
}

struct MyStruct {
  func method1(fn1: () -> Int, fn2: (() -> String)? = nil) -> SimpleEnum {}
  func method1(fn1: () -> Int, fn2: Int = nil) -> SimpleEnum {}
}
func testMethod(value: MyStruct) {
  value.method1 {
  } #^METHOD_SAMELINE^#
  #^METHOD_NEWLINE^#
// METHOD_SAMELINE: Begin completions, 4 items
// METHOD_SAMELINE-DAG: Pattern/ExprSpecific:               {#fn2: (() -> String)? {() -> String in|}#}[#(() -> String)?#];
// METHOD_SAMELINE-DAG: Decl[InstanceMethod]/CurrNominal:   .enumFunc()[#Void#];
// METHOD_SAMELINE-DAG: Decl[InfixOperatorFunction]/OtherModule[Swift]/IsSystem: [' ']+ {#SimpleEnum#}[#SimpleEnum#];
// METHOD_SAMELINE-DAG: Keyword[self]/CurrNominal:          .self[#SimpleEnum#];
// METHOD_SAMELINE: End completions

// METHOD_NEWLINE: Begin completions
// METHOD_NEWLINE-DAG: Pattern/ExprSpecific:               {#fn2: (() -> String)? {() -> String in|}#}[#(() -> String)?#];
// METHOD_NEWLINE-DAG: Keyword[class]/None:                class;
// METHOD_NEWLINE-DAG: Keyword[if]/None:                   if;
// METHOD_NEWLINE-DAG: Keyword[try]/None:                  try;
// METHOD_NEWLINE-DAG: Decl[LocalVar]/Local:               value[#MyStruct#]; name=value
// METHOD_NEWLINE: End completions
}

struct TestStruct {
  init(fn1: () -> Int, fn2: () -> String, fn3: () -> String) {}
  init(fn1: () -> Int) {}
  init(fn1: () -> Int, fn2: () -> String) {}
  init(fn1: () -> Int, fn3: () -> String) {}

  func testStructMethod() {}
}

func testOverloadedInit() {
  TestStruct {
    1
  } #^INIT_OVERLOADED_SAMELINE^#
  #^INIT_OVERLOADED_NEWLINE^#

// INIT_OVERLOADED_SAMELINE: Begin completions, 4 items
// INIT_OVERLOADED_SAMELINE-DAG: Pattern/ExprSpecific:               {#fn2: () -> String {() -> String in|}#}[#() -> String#];
// INIT_OVERLOADED_SAMELINE-DAG: Pattern/ExprSpecific:               {#fn3: () -> String {() -> String in|}#}[#() -> String#];
// INIT_OVERLOADED_SAMELINE-DAG: Decl[InstanceMethod]/CurrNominal:   .testStructMethod()[#Void#];
// INIT_OVERLOADED_SAMELINE-DAG: Keyword[self]/CurrNominal:          .self[#TestStruct#];
// INIT_OVERLOADED_SAMELINE: End completions

// INIT_OVERLOADED_NEWLINE: Begin completions
// INIT_OVERLOADED_NEWLINE-DAG: Pattern/ExprSpecific:               {#fn2: () -> String {() -> String in|}#}[#() -> String#];
// INIT_OVERLOADED_NEWLINE-DAG: Pattern/ExprSpecific:               {#fn3: () -> String {() -> String in|}#}[#() -> String#];
// INIT_OVERLOADED_NEWLINE-DAG: Keyword[class]/None:                class;
// INIT_OVERLOADED_NEWLINE-DAG: Keyword[if]/None:                   if;
// INIT_OVERLOADED_NEWLINE-DAG: Keyword[try]/None:                  try;
// INIT_OVERLOADED_NEWLINE-DAG: Decl[Struct]/CurrModule:            MyStruct[#MyStruct#]; name=MyStruct
// INIT_OVERLOADED_NEWLINE: End completions
}

struct TestStruct2 {
  init(fn1: () -> Int, fn2: () -> String = {}, fn3: () -> String = {}) {}
  func testStructMethod() {}
}
func testOptionalInit() {
  TestStruct2 {
    2
  } #^INIT_OPTIONAL_SAMELINE^#
  #^INIT_OPTIONAL_NEWLINE^#

// INIT_OPTIONAL_SAMELINE: Begin completions, 4 items
// INIT_OPTIONAL_SAMELINE-DAG: Pattern/ExprSpecific:               {#fn2: () -> String {() -> String in|}#}[#() -> String#];
// INIT_OPTIONAL_SAMELINE-DAG: Pattern/ExprSpecific:               {#fn3: () -> String {() -> String in|}#}[#() -> String#];
// INIT_OPTIONAL_SAMELINE-DAG: Decl[InstanceMethod]/CurrNominal:   .testStructMethod()[#Void#];
// INIT_OPTIONAL_SAMELINE-DAG: Keyword[self]/CurrNominal:          .self[#TestStruct2#];
// INIT_OPTIONAL_SAMELINE: End completions

// INIT_OPTIONAL_NEWLINE: Begin completions
// INIT_OPTIONAL_NEWLINE-DAG: Pattern/ExprSpecific:               {#fn2: () -> String {() -> String in|}#}[#() -> String#];
// INIT_OPTIONAL_NEWLINE-DAG: Pattern/ExprSpecific:               {#fn3: () -> String {() -> String in|}#}[#() -> String#];
// INIT_OPTIONAL_NEWLINE-DAG: Keyword[class]/None:                class;
// INIT_OPTIONAL_NEWLINE-DAG: Keyword[if]/None:                   if;
// INIT_OPTIONAL_NEWLINE-DAG: Keyword[try]/None:                  try;
// INIT_OPTIONAL_NEWLINE-DAG: Decl[Struct]/CurrModule:            MyStruct[#MyStruct#]; name=MyStruct
// INIT_OPTIONAL_NEWLINE: End completions
}

struct TestStruct3 {
  init(fn1: () -> Int, fn2: () -> String, fn3: () -> String) {}
  func testStructMethod() {}
}
func testOptionalInit() {
  // missing 'fn2' and 'fn3'.
  TestStruct3 {
    2
  } #^INIT_REQUIRED_SAMELINE_1^#
  #^INIT_REQUIRED_NEWLINE_1^#

// INIT_REQUIRED_SAMELINE_1: Begin completions, 1 items
// INIT_REQUIRED_SAMELINE_1-DAG: Pattern/ExprSpecific:               {#fn2: () -> String {() -> String in|}#}[#() -> String#];
// INIT_REQUIRED_SAMELINE_1: End completions

// INIT_REQUIRED_NEWLINE_1: Begin completions, 1 items
// INIT_REQUIRED_NEWLINE_1-DAG: Pattern/ExprSpecific:               {#fn2: () -> String {() -> String in|}#}[#() -> String#];
// INIT_REQUIRED_NEWLINE_1: End completions

  // missing 'fn3'.
  TestStruct3 {
    2
  } fn2: {
    "test"
  } #^INIT_REQUIRED_SAMELINE_2^#
  #^INIT_REQUIRED_NEWLINE_2^#

// INIT_REQUIRED_SAMELINE_2: Begin completions, 1 items
// INIT_REQUIRED_SAMELINE_2-DAG: Pattern/ExprSpecific:               {#fn3: () -> String {() -> String in|}#}[#() -> String#];
// INIT_REQUIRED_SAMELINE_2: End completions

// INIT_REQUIRED_NEWLINE_2: Begin completions, 1 items
// INIT_REQUIRED_NEWLINE_2-DAG: Pattern/ExprSpecific:               {#fn3: () -> String {() -> String in|}#}[#() -> String#];
// INIT_REQUIRED_NEWLINE_2: End completions

  // Call is completed.
  TestStruct3 {
    2
  } fn2: {
    "test"
  } fn3: {
    "test"
  } #^INIT_REQUIRED_SAMELINE_3^#
  #^INIT_REQUIRED_NEWLINE_3^#

// INIT_REQUIRED_SAMELINE_3: Begin completions, 2 items
// INIT_REQUIRED_SAMELINE_3-DAG: Decl[InstanceMethod]/CurrNominal:   .testStructMethod()[#Void#];
// INIT_REQUIRED_SAMELINE_3-DAG: Keyword[self]/CurrNominal:          .self[#TestStruct3#];
// INIT_REQIORED_SAMELINE_3: End completions

// INIT_REQUIRED_NEWLINE_3: Begin completions
// INIT_REQUIRED_NEWLINE_3-NOT: name=fn2
// INIT_REQUIRED_NEWLINE_3-NOT: name=fn3
// INIT_REQUIRED_NEWLINE_3-DAG: Keyword[class]/None:                class;
// INIT_REQUIRED_NEWLINE_3-DAG: Keyword[if]/None:                   if;
// INIT_REQUIRED_NEWLINE_3-DAG: Keyword[try]/None:                  try;
// INIT_REQUIRED_NEWLINE_3-DAG: Decl[Struct]/CurrModule:            MyStruct[#MyStruct#]; name=MyStruct
// INIT_REQUIRED_NEWLINE_3-NOT: name=fn2
// INIT_REQUIRED_NEWLINE_3-NOT: name=fn3
// INIT_REQUIRED_NEWLINE_3: End completions
}
