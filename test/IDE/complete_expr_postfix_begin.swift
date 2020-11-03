// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=EXPR_POSTFIX_BEGIN_1 | %FileCheck %s -check-prefix=COMMON
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=EXPR_POSTFIX_BEGIN_2 | %FileCheck %s -check-prefix=COMMON
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=EXPR_POSTFIX_BEGIN_3 | %FileCheck %s -check-prefix=COMMON
// RUN-FIXME: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=EXPR_POSTFIX_BEGIN_4 | %FileCheck %s -check-prefix=COMMON
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=EXPR_POSTFIX_BEGIN_5 | %FileCheck %s -check-prefix=COMMON
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=EXPR_POSTFIX_BEGIN_6 | %FileCheck %s -check-prefix=COMMON

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=EXPR_POSTFIX_BEGIN_IGNORED_1 | %FileCheck %s -check-prefix=COMMON
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=EXPR_POSTFIX_BEGIN_IGNORED_2 | %FileCheck %s -check-prefix=COMMON
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=EXPR_POSTFIX_BEGIN_IGNORED_3 | %FileCheck %s -check-prefix=COMMON

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_FUNC_PARAM_1 > %t.param.txt
// RUN: %FileCheck %s -check-prefix=COMMON < %t.param.txt
// RUN: %FileCheck %s -check-prefix=FIND_FUNC_PARAM_1 < %t.param.txt
// RUN: %FileCheck %s -check-prefix=NO_SELF < %t.param.txt

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_FUNC_PARAM_2 > %t.param.txt
// RUN: %FileCheck %s -check-prefix=COMMON < %t.param.txt
// RUN: %FileCheck %s -check-prefix=FIND_FUNC_PARAM_2 < %t.param.txt
// RUN: %FileCheck %s -check-prefix=NO_SELF < %t.param.txt

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_FUNC_PARAM_3 | %FileCheck %s -check-prefix=FIND_FUNC_PARAM_3
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_FUNC_PARAM_4 | %FileCheck %s -check-prefix=FIND_FUNC_PARAM_4
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_FUNC_PARAM_5 | %FileCheck %s -check-prefix=FIND_FUNC_PARAM_5
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_FUNC_PARAM_6 | %FileCheck %s -check-prefix=FIND_FUNC_PARAM_6
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_FUNC_PARAM_7 | %FileCheck %s -check-prefix=FIND_FUNC_PARAM_7

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_FUNC_PARAM_SELECTOR_1 > %t.param.txt
// RUN: %FileCheck %s -check-prefix=COMMON < %t.param.txt
// RUN: %FileCheck %s -check-prefix=FIND_FUNC_PARAM_SELECTOR_1 < %t.param.txt
// RUN: %FileCheck %s -check-prefix=NO_SELF < %t.param.txt

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_CONSTRUCTOR_PARAM_1 | %FileCheck %s -check-prefix=FIND_CONSTRUCTOR_PARAM_1
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_CONSTRUCTOR_PARAM_2 | %FileCheck %s -check-prefix=FIND_CONSTRUCTOR_PARAM_2
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_CONSTRUCTOR_PARAM_3 | %FileCheck %s -check-prefix=FIND_CONSTRUCTOR_PARAM_3
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_CONSTRUCTOR_PARAM_4 | %FileCheck %s -check-prefix=FIND_CONSTRUCTOR_PARAM_4
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_CONSTRUCTOR_PARAM_5 | %FileCheck %s -check-prefix=FIND_CONSTRUCTOR_PARAM_5

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_CONSTRUCTOR_PARAM_SELECTOR_1 | %FileCheck %s -check-prefix=FIND_CONSTRUCTOR_PARAM_SELECTOR_1

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_DESTRUCTOR_PARAM_1 > %t.param.txt
// RUN: %FileCheck %s -check-prefix=FIND_DESTRUCTOR_PARAM_1 < %t.param.txt

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=FIND_DESTRUCTOR_PARAM_2 > %t.param.txt
// RUN: %FileCheck %s -check-prefix=FIND_DESTRUCTOR_PARAM_2 < %t.param.txt

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=NO_PLACEHOLDER_NAMES_1 | %FileCheck %s -check-prefix=NO_PLACEHOLDER_NAMES_1

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_INVALID_1 | %FileCheck %s -check-prefix=COMMON
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_INVALID_2 | %FileCheck %s -check-prefix=COMMON
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_INVALID_3 | %FileCheck %s -check-prefix=COMMON
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_INVALID_5 | %FileCheck %s -check-prefix=COMMON
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_INVALID_6 | %FileCheck %s -check-prefix=COMMON
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_INVALID_7 | %FileCheck %s -check-prefix=COMMON
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_INVALID_8 | %FileCheck %s -check-prefix=COMMON

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=GENERIC_TYPEALIAS_1 | %FileCheck %s -check-prefix=MY_ALIAS_1
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=GENERIC_TYPEALIAS_2 | %FileCheck %s -check-prefix=MY_ALIAS_2

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_FOR_EACH_1 | %FileCheck %s -check-prefix=IN_FOR_EACH_1
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_FOR_EACH_2 | %FileCheck %s -check-prefix=IN_FOR_EACH_2
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_FOR_EACH_3 | %FileCheck %s -check-prefix=IN_FOR_EACH_3
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_FOR_EACH_4 | %FileCheck %s -check-prefix=IN_FOR_EACH_3
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_FOR_EACH_5 | %FileCheck %s -check-prefix=IN_FOR_EACH_1
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_FOR_EACH_6 | %FileCheck %s -check-prefix=IN_FOR_EACH_2
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_FOR_EACH_7 | %FileCheck %s -check-prefix=IN_FOR_EACH_1
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_FOR_EACH_8 | %FileCheck %s -check-prefix=IN_FOR_EACH_4
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_FOR_EACH_9 | %FileCheck %s -check-prefix=IN_FOR_EACH_4
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_FOR_EACH_10 | %FileCheck %s -check-prefix=IN_FOR_EACH_1
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_FOR_EACH_11 | %FileCheck %s -check-prefix=IN_FOR_EACH_2
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_FOR_EACH_12 | %FileCheck %s -check-prefix=IN_FOR_EACH_2

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=DEPRECATED_1 | %FileCheck %s -check-prefix=DEPRECATED_1

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_TUPLE_1 | %FileCheck %s -check-prefix=IN_TUPLE_1
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=IN_TUPLE_2 | %FileCheck %s -check-prefix=IN_TUPLE_2

// RUN-FIXME(rdar56755598): %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_INIT_1 | %FileCheck %s -check-prefix=OWN_INIT_1
// RUN-FIXME(rdar56755598): %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_INIT_2 | %FileCheck %s -check-prefix=OWN_INIT_2
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_INIT_3 | %FileCheck %s -check-prefix=OWN_INIT_3
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_INIT_4 | %FileCheck %s -check-prefix=OWN_INIT_4
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_INIT_5 | %FileCheck %s -check-prefix=OWN_INIT_5
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_INIT_6 | %FileCheck %s -check-prefix=OWN_INIT_6
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_INIT_7 | %FileCheck %s -check-prefix=OWN_INIT_7
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_INIT_8 | %FileCheck %s -check-prefix=OWN_INIT_8
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_INIT_9 | %FileCheck %s -check-prefix=OWN_INIT_9
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_INIT_10 | %FileCheck %s -check-prefix=OWN_INIT_10

// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_1 | %FileCheck %s -check-prefix=OWN_ACCESSOR_1
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_2 | %FileCheck %s -check-prefix=OWN_ACCESSOR_2
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_3 | %FileCheck %s -check-prefix=OWN_ACCESSOR_3
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_4 | %FileCheck %s -check-prefix=OWN_ACCESSOR_3
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_5 | %FileCheck %s -check-prefix=OWN_ACCESSOR_5
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_6 | %FileCheck %s -check-prefix=OWN_ACCESSOR_6
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_7 | %FileCheck %s -check-prefix=OWN_ACCESSOR_7
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_8 | %FileCheck %s -check-prefix=OWN_ACCESSOR_7
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_9 | %FileCheck %s -check-prefix=OWN_ACCESSOR_9
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_10 | %FileCheck %s -check-prefix=OWN_ACCESSOR_10
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_11 | %FileCheck %s -check-prefix=OWN_ACCESSOR_11
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_12 | %FileCheck %s -check-prefix=OWN_ACCESSOR_11
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_13 | %FileCheck %s -check-prefix=OWN_ACCESSOR_13
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_14 | %FileCheck %s -check-prefix=OWN_ACCESSOR_13
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_15 | %FileCheck %s -check-prefix=OWN_ACCESSOR_13
// RUN: %target-swift-ide-test -code-completion -source-filename %s -code-completion-token=OWN_ACCESSOR_16 | %FileCheck %s -check-prefix=OWN_ACCESSOR_13

//
// Test code completion at the beginning of expr-postfix.
//

//===--- Helper types that are used in this test

struct FooStruct {
}

var fooObject : FooStruct

func fooFunc() -> FooStruct {
  return fooObject
}

enum FooEnum {
}

class FooClass {
}

protocol FooProtocol {
}

typealias FooTypealias = Int

// COMMON: Begin completions
// Function parameter
// COMMON-DAG: Decl[LocalVar]/Local: fooParam[#FooStruct#]{{; name=.+$}}
// Global completions
// COMMON-DAG: Decl[Struct]/CurrModule:     FooStruct[#FooStruct#]{{; name=.+$}}
// COMMON-DAG: Decl[Enum]/CurrModule:       FooEnum[#FooEnum#]{{; name=.+$}}
// COMMON-DAG: Decl[Class]/CurrModule:      FooClass[#FooClass#]{{; name=.+$}}
// COMMON-DAG: Decl[Protocol]/CurrModule:   FooProtocol[#FooProtocol#]{{; name=.+$}}
// COMMON-DAG: Decl[TypeAlias]/CurrModule{{(/TypeRelation\[Identical\])?}}:  FooTypealias[#Int#]{{; name=.+$}}
// COMMON-DAG: Decl[GlobalVar]/CurrModule:  fooObject[#FooStruct#]{{; name=.+$}}
// COMMON-DAG: Keyword[try]/None: try{{; name=.+$}}
// COMMON-DAG: Literal[Boolean]/None: true[#Bool#]{{; name=.+$}}
// COMMON-DAG: Literal[Boolean]/None: false[#Bool#]{{; name=.+$}}
// COMMON-DAG: Literal[Nil]/None: nil{{; name=.+$}}
// COMMON-DAG: Decl[Struct]/OtherModule[Swift]/IsSystem:    Int8[#Int8#]{{; name=.+$}}
// COMMON-DAG: Decl[Struct]/OtherModule[Swift]/IsSystem:    Int16[#Int16#]{{; name=.+$}}
// COMMON-DAG: Decl[Struct]/OtherModule[Swift]/IsSystem:    Int32[#Int32#]{{; name=.+$}}
// COMMON-DAG: Decl[Struct]/OtherModule[Swift]/IsSystem:    Int64[#Int64#]{{; name=.+$}}
// COMMON-DAG: Decl[Struct]/OtherModule[Swift]/IsSystem:    Bool[#Bool#]{{; name=.+$}}
// COMMON-DAG: Keyword[#function]/None{{(/TypeRelation\[Identical\])?}}: #function[#String#]{{; name=.+$}}
// COMMON-DAG: Keyword[#file]/None{{(/TypeRelation\[Identical\])?}}: #file[#String#]{{; name=.+$}}
// COMMON-DAG: Keyword[#line]/None{{(/TypeRelation\[Identical\])?}}: #line[#Int#]{{; name=.+$}}
// COMMON-DAG: Keyword[#column]/None{{(/TypeRelation\[Identical\])?}}: #column[#Int#]{{; name=.+$}}
// COMMON: End completions

// NO_SELF-NOT: {{[[:<:]][Ss]elf[[:>:]]}}

//===--- Test that we can code complete at the beginning of expr-postfix.

func testExprPostfixBegin1(fooParam: FooStruct) {
  #^EXPR_POSTFIX_BEGIN_1^#
}

func testExprPostfixBegin2(fooParam: FooStruct) {
  1 + #^EXPR_POSTFIX_BEGIN_2^#
}

func testExprPostfixBegin3(fooParam: FooStruct) {
  fooFunc()
  1 + #^EXPR_POSTFIX_BEGIN_3^#
}

func testExprPostfixBegin4(fooParam: FooStruct) {
  "\(#^EXPR_POSTFIX_BEGIN_4^#)"
}

func testExprPostfixBegin3(fooParam: FooStruct) {
  1+#^EXPR_POSTFIX_BEGIN_5^#
}
func testExprPostfixBegin3(fooParam: FooStruct) {
  for i in 1...#^EXPR_POSTFIX_BEGIN_6^#
}

//===--- Test that we sometimes ignore the expr-postfix.
// In these cases, displaying '.instance*' completion results is technically
// valid, but would be extremely surprising.

func testExprPostfixBeginIgnored1(fooParam: FooStruct) {
  fooFunc()
  #^EXPR_POSTFIX_BEGIN_IGNORED_1^#
}

func testExprPostfixBeginIgnored2(fooParam: FooStruct) {
  123456789
  #^EXPR_POSTFIX_BEGIN_IGNORED_2^#
}

func testExprPostfixBeginIgnored3(fooParam: FooStruct) {
  123456789 +
      fooFunc()
  #^EXPR_POSTFIX_BEGIN_IGNORED_3^#
}

//===--- Test that we include function parameters in completion results.

func testFindFuncParam1(fooParam: FooStruct, a: Int, b: Float, c: inout Double, d: inout Double) {
  #^FIND_FUNC_PARAM_1^#
// FIND_FUNC_PARAM_1: Begin completions
// FIND_FUNC_PARAM_1-DAG: Decl[LocalVar]/Local: a[#Int#]{{; name=.+$}}
// FIND_FUNC_PARAM_1-DAG: Decl[LocalVar]/Local: b[#Float#]{{; name=.+$}}
// FIND_FUNC_PARAM_1-DAG: Decl[LocalVar]/Local: c[#inout Double#]{{; name=.+$}}
// FIND_FUNC_PARAM_1-DAG: Decl[LocalVar]/Local: d[#inout Double#]{{; name=.+$}}
// FIND_FUNC_PARAM_1: End completions
}

func testFindFuncParam2<Foo : FooProtocol>(fooParam: FooStruct, foo: Foo) {
  #^FIND_FUNC_PARAM_2^#
// FIND_FUNC_PARAM_2: Begin completions
// FIND_FUNC_PARAM_2-DAG: Decl[GenericTypeParam]/Local: Foo[#Foo#]{{; name=.+$}}
// FIND_FUNC_PARAM_2-DAG: Decl[LocalVar]/Local:         foo[#FooProtocol#]{{; name=.+$}}
// FIND_FUNC_PARAM_2: End completions
}

struct TestFindFuncParam3_4 {
  func testFindFuncParam3(a: Int, b: Float, c: Double) {
    #^FIND_FUNC_PARAM_3^#
// FIND_FUNC_PARAM_3: Begin completions
// FIND_FUNC_PARAM_3-DAG: Decl[LocalVar]/Local: self[#TestFindFuncParam3_4#]{{; name=.+$}}
// FIND_FUNC_PARAM_3-DAG: Decl[LocalVar]/Local: a[#Int#]{{; name=.+$}}
// FIND_FUNC_PARAM_3-DAG: Decl[LocalVar]/Local: b[#Float#]{{; name=.+$}}
// FIND_FUNC_PARAM_3-DAG: Decl[LocalVar]/Local: c[#Double#]{{; name=.+$}}
// FIND_FUNC_PARAM_3: End completions
  }

  func testFindFuncParam4<U>(a: Int, b: U) {
    #^FIND_FUNC_PARAM_4^#
// FIND_FUNC_PARAM_4: Begin completions
// FIND_FUNC_PARAM_4-DAG: Decl[GenericTypeParam]/Local: U[#U#]{{; name=.+$}}
// FIND_FUNC_PARAM_4-DAG: Decl[LocalVar]/Local:         self[#TestFindFuncParam3_4#]{{; name=.+$}}
// FIND_FUNC_PARAM_4-DAG: Decl[LocalVar]/Local:         a[#Int#]{{; name=.+$}}
// FIND_FUNC_PARAM_4-DAG: Decl[LocalVar]/Local:         b[#U#]{{; name=.+$}}
// FIND_FUNC_PARAM_4: End completions
  }
}

struct TestFindFuncParam5_6<T> {
  func testFindFuncParam5(a: Int, b: T) {
    #^FIND_FUNC_PARAM_5^#
// FIND_FUNC_PARAM_5: Begin completions
// FIND_FUNC_PARAM_5-DAG: Decl[GenericTypeParam]/Local: T[#T#]{{; name=.+$}}
// FIND_FUNC_PARAM_5-DAG: Decl[LocalVar]/Local: self[#TestFindFuncParam5_6<T>#]{{; name=.+$}}
// FIND_FUNC_PARAM_5-DAG: Decl[LocalVar]/Local: a[#Int#]{{; name=.+$}}
// FIND_FUNC_PARAM_5-DAG: Decl[LocalVar]/Local: b[#T#]{{; name=.+$}}
// FIND_FUNC_PARAM_5: End completions
  }

  func testFindFuncParam6<U>(a: Int, b: T, c: U) {
    #^FIND_FUNC_PARAM_6^#
// FIND_FUNC_PARAM_6: Begin completions
// FIND_FUNC_PARAM_6-DAG: Decl[GenericTypeParam]/Local:       T[#T#]{{; name=.+$}}
// FIND_FUNC_PARAM_6-DAG: Decl[GenericTypeParam]/Local:       U[#U#]{{; name=.+$}}
// FIND_FUNC_PARAM_6-DAG: Decl[LocalVar]/Local:               self[#TestFindFuncParam5_6<T>#]{{; name=.+$}}
// FIND_FUNC_PARAM_6-DAG: Decl[LocalVar]/Local:               a[#Int#]{{; name=.+$}}
// FIND_FUNC_PARAM_6-DAG: Decl[LocalVar]/Local:               b[#T#]{{; name=.+$}}
// FIND_FUNC_PARAM_6-DAG: Decl[LocalVar]/Local:               c[#U#]{{; name=.+$}}
// FIND_FUNC_PARAM_6: End completions
  }
}

class TestFindFuncParam7 {
  func testFindFuncParam7(a: Int, b: Float, c: Double) {
    #^FIND_FUNC_PARAM_7^#
// FIND_FUNC_PARAM_7: Begin completions
// FIND_FUNC_PARAM_7-DAG: Decl[LocalVar]/Local: self[#TestFindFuncParam7#]{{; name=.+$}}
// FIND_FUNC_PARAM_7-DAG: Decl[LocalVar]/Local: a[#Int#]{{; name=.+$}}
// FIND_FUNC_PARAM_7-DAG: Decl[LocalVar]/Local: b[#Float#]{{; name=.+$}}
// FIND_FUNC_PARAM_7-DAG: Decl[LocalVar]/Local: c[#Double#]{{; name=.+$}}
// FIND_FUNC_PARAM_7: End completions
  }
}

func testFindFuncParamSelector1(a: Int, b x: Float, foo fooParam: FooStruct, bar barParam: inout FooStruct) {
  #^FIND_FUNC_PARAM_SELECTOR_1^#
// FIND_FUNC_PARAM_SELECTOR_1: Begin completions
// FIND_FUNC_PARAM_SELECTOR_1-DAG: Decl[LocalVar]/Local: a[#Int#]{{; name=.+$}}
// FIND_FUNC_PARAM_SELECTOR_1-DAG: Decl[LocalVar]/Local: x[#Float#]{{; name=.+$}}
// FIND_FUNC_PARAM_SELECTOR_1-DAG: Decl[LocalVar]/Local: barParam[#inout FooStruct#]{{; name=.+$}}
// FIND_FUNC_PARAM_SELECTOR_1: End completions
}

//===--- Test that we include constructor parameters in completion results.

class TestFindConstructorParam1 {
  init(a: Int, b: Float) {
    #^FIND_CONSTRUCTOR_PARAM_1^#
// FIND_CONSTRUCTOR_PARAM_1: Begin completions
// FIND_CONSTRUCTOR_PARAM_1-DAG: Decl[LocalVar]/Local: self[#TestFindConstructorParam1#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_1-DAG: Decl[LocalVar]/Local: a[#Int#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_1-DAG: Decl[LocalVar]/Local: b[#Float#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_1: End completions
  }
}

struct TestFindConstructorParam2 {
  init(a: Int, b: Float) {
    #^FIND_CONSTRUCTOR_PARAM_2^#
// FIND_CONSTRUCTOR_PARAM_2: Begin completions
// FIND_CONSTRUCTOR_PARAM_2-DAG: Decl[LocalVar]/Local: self[#TestFindConstructorParam2#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_2-DAG: Decl[LocalVar]/Local: a[#Int#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_2-DAG: Decl[LocalVar]/Local: b[#Float#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_2: End completions
  }
}

class TestFindConstructorParam3 {
  init<U>(a: Int, b: U) {
    #^FIND_CONSTRUCTOR_PARAM_3^#
// FIND_CONSTRUCTOR_PARAM_3: Begin completions
// FIND_CONSTRUCTOR_PARAM_3-DAG: Decl[GenericTypeParam]/Local: U[#U#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_3-DAG: Decl[LocalVar]/Local:         self[#TestFindConstructorParam3#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_3-DAG: Decl[LocalVar]/Local:         a[#Int#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_3-DAG: Decl[LocalVar]/Local:         b[#U#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_3: End completions
  }
}

class TestFindConstructorParam4<T> {
  init(a: Int, b: T) {
    #^FIND_CONSTRUCTOR_PARAM_4^#
// FIND_CONSTRUCTOR_PARAM_4: Begin completions
// FIND_CONSTRUCTOR_PARAM_4-DAG: Decl[GenericTypeParam]/Local: T[#T#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_4-DAG: Decl[LocalVar]/Local:         self[#TestFindConstructorParam4<T>#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_4-DAG: Decl[LocalVar]/Local:         a[#Int#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_4-DAG: Decl[LocalVar]/Local:         b[#T#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_4: End completions
  }
}

class TestFindConstructorParam5<T> {
  init<U>(a: Int, b: T, c: U) {
    #^FIND_CONSTRUCTOR_PARAM_5^#
// FIND_CONSTRUCTOR_PARAM_5: Begin completions
// FIND_CONSTRUCTOR_PARAM_5-DAG: Decl[GenericTypeParam]/Local: T[#T#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_5-DAG: Decl[GenericTypeParam]/Local: U[#U#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_5-DAG: Decl[LocalVar]/Local:         self[#TestFindConstructorParam5<T>#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_5-DAG: Decl[LocalVar]/Local:         a[#Int#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_5-DAG: Decl[LocalVar]/Local:         b[#T#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_5-DAG: Decl[LocalVar]/Local:         c[#U#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_5: End completions
  }
}

class TestFindConstructorParamSelector1 {
  init(a x: Int, b y: Float) {
    #^FIND_CONSTRUCTOR_PARAM_SELECTOR_1^#
// FIND_CONSTRUCTOR_PARAM_SELECTOR_1: Begin completions
// FIND_CONSTRUCTOR_PARAM_SELECTOR_1-DAG: Decl[LocalVar]/Local: self[#TestFindConstructorParamSelector1#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_SELECTOR_1-DAG: Decl[LocalVar]/Local: x[#Int#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_SELECTOR_1-DAG: Decl[LocalVar]/Local: y[#Float#]{{; name=.+$}}
// FIND_CONSTRUCTOR_PARAM_SELECTOR_1: End completions
  }
}

//===--- Test that we include destructor's 'self' in completion results.

class TestFindDestructorParam1 {
  deinit {
    #^FIND_DESTRUCTOR_PARAM_1^#
// FIND_DESTRUCTOR_PARAM_1: Begin completions
// FIND_DESTRUCTOR_PARAM_1-DAG: Decl[LocalVar]/Local: self[#TestFindDestructorParam1#]{{; name=.+$}}
// FIND_DESTRUCTOR_PARAM_1: End completions
  }
}

class TestFindDestructorParam2<T> {
  deinit {
    #^FIND_DESTRUCTOR_PARAM_2^#
// FIND_DESTRUCTOR_PARAM_2: Begin completions
// FIND_DESTRUCTOR_PARAM_2-DAG: Decl[GenericTypeParam]/Local: T[#T#]{{; name=.+$}}
// FIND_DESTRUCTOR_PARAM_2-DAG: Decl[LocalVar]/Local: self[#TestFindDestructorParam2<T>#]{{; name=.+$}}
// FIND_DESTRUCTOR_PARAM_2: End completions
  }
}

struct TestPlaceholdersInNames {
  var <#placeholder_in_name1#>: FooStruct
  func test() {
    var <#placeholder_in_name2#>: FooStruct
    #^NO_PLACEHOLDER_NAMES_1^#
  }
// NO_PLACEHOLDER_NAMES_1-NOT: placeholder_in_name
}

//===--- Test that we don't crash in constructors and destructors in contexts
//===--- where they are not allowed.

init() {
  var fooParam = FooStruct()
  #^IN_INVALID_1^#
}

init { // Missing parameters
  var fooParam = FooStruct()
  #^IN_INVALID_2^#
}

deinit {
  var fooParam = FooStruct()
  #^IN_INVALID_3^#
}

func testInInvalid5() {
  var fooParam = FooStruct()
  init() {
    #^IN_INVALID_5^#
  }
}

func testInInvalid6() {
  deinit {
    var fooParam = FooStruct()
    #^IN_INVALID_6^#
  }
}

struct TestInInvalid7 {
  deinit {
    var fooParam = FooStruct()
    #^IN_INVALID_7^#
  }
}

func foo() -> Undeclared {
  var fooParam = FooStruct()
  #^IN_INVALID_8^#
}
// MY_ALIAS_1: Decl[TypeAlias]/Local:                        MyAlias[#(T, T)#];
// MY_ALIAS_1: Decl[LocalVar]/Local/TypeRelation[Identical]: x[#MyAlias<Int>#]; name=x
// MY_ALIAS_1: Decl[LocalVar]/Local/TypeRelation[Identical]: y[#(Int, Int)#]; name=y

func testGenericTypealias1() {
  typealias MyAlias<T> = (T, T)
  let x: MyAlias<Int> = (1, 2)
  var y: (Int, Int)
  y = #^GENERIC_TYPEALIAS_1^#
}
// MY_ALIAS_2: Decl[TypeAlias]/Local:                        MyAlias[#(T, T)#];
// MY_ALIAS_2: Decl[LocalVar]/Local/TypeRelation[Identical]: x[#(Int, Int)#]; name=x
// MY_ALIAS_2: Decl[LocalVar]/Local/TypeRelation[Identical]: y[#MyAlias<Int>#]; name=y
func testGenericTypealias2() {
  typealias MyAlias<T> = (T, T)
  let x: (Int, Int) = (1, 2)
  var y: MyAlias<Int>
  y = #^GENERIC_TYPEALIAS_2^#
}

func testInForEach1(arg: Int) {
  let local = 2
  for index in #^IN_FOR_EACH_1^# {
    let inBody = 3
  }
  let after = 4
// IN_FOR_EACH_1-NOT: Decl[LocalVar]
// IN_FOR_EACH_1: Decl[LocalVar]/Local:               local[#Int#];
// IN_FOR_EACH_1-NOT: after
// IN_FOR_EACH_1: Decl[LocalVar]/Local:               arg[#Int#];
// IN_FOR_EACH_1-NOT: Decl[LocalVar]
}
func testInForEach2(arg: Int) {
  let local = 2
  for index in 1 ... #^IN_FOR_EACH_2^# {
    let inBody = 3
  }
  let after = 4
// IN_FOR_EACH_2-NOT: Decl[LocalVar]
// IN_FOR_EACH_2: Decl[LocalVar]/Local/TypeRelation[Identical]: local[#Int#];
// IN_FOR_EACH_2-NOT: after
// IN_FOR_EACH_2: Decl[LocalVar]/Local/TypeRelation[Identical]: arg[#Int#];
// IN_FOR_EACH_2-NOT: Decl[LocalVar]
}
func testInForEach3(arg: Int) {
  let local = 2
  for index: Int in 1 ... 2 where #^IN_FOR_EACH_3^# {
    let inBody = 3
  }
  let after = 4
// IN_FOR_EACH_3-NOT: Decl[LocalVar]
// IN_FOR_EACH_3: Decl[LocalVar]/Local:               index[#Int#];
// IN_FOR_EACH_3-NOT: Decl[LocalVar]
// IN_FOR_EACH_3: Decl[LocalVar]/Local:               local[#Int#];
// IN_FOR_EACH_3-NOT: after
// IN_FOR_EACH_3: Decl[LocalVar]/Local:               arg[#Int#];
// IN_FOR_EACH_3-NOT: Decl[LocalVar]
}
func testInForEach4(arg: Int) {
  let local = 2
  for index in 1 ... 2 {
    #^IN_FOR_EACH_4^#
  }
  let after = 4
}

func testInForEach5(arg: Int) {
  let local = 2
  for index in [#^IN_FOR_EACH_5^#] {}
  let after = 4
}
func testInForEach6(arg: Int) {
  let local = 2
  for index in [1,#^IN_FOR_EACH_6^#] {}
  let after = 4
}
func testInForEach7(arg: Int) {
  let local = 2
  for index in [1:#^IN_FOR_EACH_7^#] {}
  let after = 4
}
func testInForEach8(arg: Int) {
  let local = 2
  for index in [#^IN_FOR_EACH_8^#:] {}
  let after = 4
}
func testInForEach9(arg: Int) {
  let local = 2
  for index in [#^IN_FOR_EACH_9^#:2] {}
  let after = 4
// NOTE: [Convertible] to AnyHashable.
// IN_FOR_EACH_4-NOT: Decl[LocalVar]
// IN_FOR_EACH_4: Decl[LocalVar]/Local/TypeRelation[Convertible]: local[#Int#];
// IN_FOR_EACH_4-NOT: after
// IN_FOR_EACH_4: Decl[LocalVar]/Local/TypeRelation[Convertible]: arg[#Int#];
// IN_FOR_EACH_4-NOT: Decl[LocalVar]
}
func testInForEach10(arg: Int) {
  let local = 2
  for index in [1:2, #^IN_FOR_EACH_10^#] {}
  let after = 4
}
func testInForEach11(arg: Int) {
  let local = 2
  for index in [1:2, #^IN_FOR_EACH_11^#:] {}
  let after = 4
}
func testInForEach12(arg: Int) {
  let local = 2
  for index in [1:2, #^IN_FOR_EACH_12^#:2] {}
  let after = 4
}

@available(*, deprecated)
struct Deprecated {
  @available(*, deprecated)
  func testDeprecated() {
    @available(*, deprecated) let local = 1
    @available(*, deprecated) func f() {}

    #^DEPRECATED_1^#
  }
}
// DEPRECATED_1: Begin completions
// DEPRECATED_1-DAG: Decl[LocalVar]/Local/NotRecommended: local[#Int#];
// DEPRECATED_1-DAG: Decl[FreeFunction]/Local/NotRecommended: f()[#Void#];
// DEPRECATED_1-DAG: Decl[InstanceMethod]/CurrNominal/NotRecommended: testDeprecated()[#Void#];
// DEPRECATED_1-DAG: Decl[Struct]/CurrModule/NotRecommended: Deprecated[#Deprecated#];
// DEPRECATED_1: End completions

func testTuple(localInt: Int) {
  let localStr: String = "foo"
  let _: (Int, String) = (1, #^IN_TUPLE_1^#)
  let _: (Int, String) = (#^IN_TUPLE_2^#, "foo")
}
// IN_TUPLE_1: Begin completions
// IN_TUPLE_1: Decl[LocalVar]/Local/TypeRelation[Identical]: localStr[#String#]; name=localStr
// IN_TUPLE_1: Decl[LocalVar]/Local:               localInt[#Int#]; name=localInt
// IN_TUPLE_1: End completions

// IN_TUPLE_2: Begin completions
// IN_TUPLE_2: Decl[LocalVar]/Local:               localStr[#String#]; name=localStr
// IN_TUPLE_2: Decl[LocalVar]/Local/TypeRelation[Identical]: localInt[#Int#]; name=localInt
// IN_TUPLE_2: End completions

var ownInit1: Int = #^OWN_INIT_1^#
// OWN_INIT_1: Begin completions
// OWN_INIT_1-NOT: ownInit1
func sync() {}
var ownInit2: () -> Void = { #^OWN_INIT_2^# }
// OWN_INIT_2: Begin completions
// OWN_INIT_2-NOT: ownInit2
var ownInit8: Int = "\(#^OWN_INIT_8^#)"
// OWN_INIT_8: Begin completions
// OWN_INIT_8-NOT: ownInit8
struct OwnInitTester {
  var ownInit3: Int = #^OWN_INIT_3^#
  // OWN_INIT_3: Begin completions
  // OWN_INIT_3-NOT: ownInit3
  var ownInit4: () -> Void = { #^OWN_INIT_4^# }
  // OWN_INIT_4: Begin completions
  // OWN_INIT_4-NOT: ownInit4
  var ownInit9: String = "\(#^OWN_INIT_9^#)"
  // OWN_INIT_9: Begin completions
  // OWN_INIT_9-NOT: ownInit9
}
func ownInitTesting() {
  var ownInit5: Int = #^OWN_INIT_5^#
  // OWN_INIT_5: Begin completions
  // OWN_INIT_5-NOT: ownInit5
  var ownInit6: () -> Void = { #^OWN_INIT_6^# }
  // OWN_INIT_6: Begin completions
  // OWN_INIT_6-NOT: ownInit6
  var ownInit10: String = "\(#^OWN_INIT_10^#)"
  // OWN_INIT_10: Begin completions
  // OWN_INIT_10-NOT: ownInit10
}
func ownInitTestingShadow(ownInit7: Int) {
  var ownInit7: Int = #^OWN_INIT_7^#
  // OWN_INIT_7: Begin completions
  // OWN_INIT_7: Decl[LocalVar]/Local/TypeRelation[Identical]: ownInit7[#Int#];
}

var inAccessor1: Int {
  get { #^OWN_ACCESSOR_1^# }
// OWN_ACCESSOR_1: Begin completions
// OWN_ACCESSOR_1: Decl[GlobalVar]/CurrModule/NotRecommended/TypeRelation[Identical]: inAccessor1[#Int#];
  set { #^OWN_ACCESSOR_2^# }
// OWN_ACCESSOR_2: Begin completions
// OWN_ACCESSOR_2: Decl[GlobalVar]/CurrModule: inAccessor1[#Int#];
}
var inAccessor2: Int = 1 {
  didSet { #^OWN_ACCESSOR_3^# }
// OWN_ACCESSOR_3: Begin completions
// OWN_ACCESSOR_3: Decl[GlobalVar]/CurrModule: inAccessor2[#Int#];
  willSet { #^OWN_ACCESSOR_4^# }
}
class InAccessorTest {
  var inAccessor3: Int {
    get { #^OWN_ACCESSOR_5^# }
// OWN_ACCESSOR_5: Begin completions
// OWN_ACCESSOR_5: Decl[InstanceVar]/CurrNominal/NotRecommended/TypeRelation[Identical]: inAccessor3[#Int#];
    set { #^OWN_ACCESSOR_6^# }
// OWN_ACCESSOR_6: Begin completions
// OWN_ACCESSOR_6: Decl[InstanceVar]/CurrNominal: inAccessor3[#Int#];
  }
  var inAccessor4: Int = 1 {
    didSet { #^OWN_ACCESSOR_7^# }
// OWN_ACCESSOR_7: Begin completions
// OWN_ACCESSOR_7: Decl[InstanceVar]/CurrNominal: inAccessor4[#Int#];
    willSet { #^OWN_ACCESSOR_8^# }
  }
}
func inAccessorTest() {
  var inAccessor5: Int {
    get { #^OWN_ACCESSOR_9^# }
// OWN_ACCESSOR_9: Begin completions
// OWN_ACCESSOR_9: Decl[LocalVar]/Local/NotRecommended/TypeRelation[Identical]: inAccessor5[#Int#];
    set { #^OWN_ACCESSOR_10^# }
// OWN_ACCESSOR_10: Begin completions
// OWN_ACCESSOR_10: Decl[LocalVar]/Local: inAccessor5[#Int#];
  }
  var inAccessor6: Int = 1 {
    didSet { #^OWN_ACCESSOR_11^# }
// OWN_ACCESSOR_11: Begin completions
// OWN_ACCESSOR_11: Decl[LocalVar]/Local: inAccessor6[#Int#];
    willSet { #^OWN_ACCESSOR_12^# }
  }
}
class InAccessorTestQualified {
  var inAccessorProp: Int {
    get {
      let _ = self.#^OWN_ACCESSOR_13^#
// OWN_ACCESSOR_13: Begin completions
// OWN_ACCESSOR_13-DAG: Decl[InstanceVar]/CurrNominal:      inAccessorProp[#Int#];
// OWN_ACCESSOR_13: End completions
      let _ = \InAccessorTestQualified.#^OWN_ACCESSOR_14^#
    }
    set {
      let _ = self.#^OWN_ACCESSOR_15^#
      let _ = \InAccessorTestQualified.#^OWN_ACCESSOR_16^#
    }
  }
}
