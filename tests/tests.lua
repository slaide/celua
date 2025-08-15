#!/usr/bin/env lua

local TestFramework = require("test_framework")

local function run_tests()
    local framework = TestFramework:new()
    
    framework:add_test(
        "Simple macro definition and expansion",
        [[#define MAX 100
int x = MAX;]],
        "int x = 100;"
    )
    
    framework:add_test(
        "Function-like macro",
        [[#define SQUARE(x) ((x) * (x))
int result = SQUARE(5);]],
        "int result = ((5) * (5));"
    )
    
    framework:add_test(
        "Multiple argument macro",
        [[#define ADD(a, b) ((a) + (b))
int sum = ADD(3, 4);]],
        "int sum = ((3) + (4));"
    )
    
    framework:add_test(
        "Conditional compilation - ifdef true",
        "#define DEBUG\n#ifdef DEBUG\nprintf(\"Debug mode\");\n#endif",
        "printf(\"Debug mode\");"
    )
    
    framework:add_test(
        "Conditional compilation - ifdef false", 
        "#ifdef RELEASE\nprintf(\"Release mode\");\n#endif\nprintf(\"Always\");",
        "\n\n\nprintf(\"Always\");"
    )
    
    framework:add_test(
        "Conditional compilation - ifndef",
        "#ifndef NDEBUG\nprintf(\"Debug assertions\");\n#endif",
        "printf(\"Debug assertions\");"
    )
    
    framework:add_test(
        "Conditional compilation - if with else",
        [[#define VERSION 2
#if VERSION > 1
printf("New version");
#else
printf("Old version");
#endif]],
        "printf(\"New version\");"
    )
    
    framework:add_test(
        "Nested conditionals",
        [[#define A
#define B
#ifdef A
#ifdef B
printf("Both defined");
#endif
#endif]],
        "printf(\"Both defined\");"
    )
    
    framework:add_test(
        "Macro undef",
        [[#define TEMP 42
int x = TEMP;
#undef TEMP
int y = TEMP;]],
        [[int x = 42;
int y = TEMP;]]
    )
    
    framework:add_test(
        "Empty macro",
        "#define EMPTY\nint x EMPTY = 5;",
        "int x  = 5;"
    )
    
    framework:add_test(
        "Macro with spaces",
        "#define HELLO world\nprintf(\"Hello HELLO\");\nchar *msg = HELLO;",
        "printf(\"Hello HELLO\");\nchar *msg = world;"
    )
    
    framework:add_test(
        "Multiple macros on same line",
        "#define A 1\n#define B 2\nint sum = A + B;",
        "int sum = 1 + 2;"
    )
    
    framework:add_test(
        "Macro redefinition warning",
        "#define MAX 100\n#define MAX 200\nint x = MAX;",
        "int x = 200;"
    )
    
    framework:add_test(
        "Conditional with defined operator",
        "#define TEST\n#if defined(TEST)\nprintf(\"Test defined\");\n#endif",
        "printf(\"Test defined\");"
    )
    
    framework:add_test(
        "Conditional with defined parentheses",
        "#if defined(UNDEFINED)\nprintf(\"Should not appear\");\n#else\nprintf(\"Not defined\");\n#endif",
        "printf(\"Not defined\");"
    )
    
    framework:add_test(
        "Complex macro expansion",
        "#define MAX(a,b) ((a) > (b) ? (a) : (b))\nint max_val = MAX(x + 1, y * 2);",
        "int max_val = ((x + 1) > (y * 2) ? (x + 1) : (y * 2));"
    )
    
    framework:add_test(
        "Macro with no arguments",
        "#define FUNC() return 0\nint main() { FUNC(); }",
        "int main() { return 0; }"
    )
    
    framework:add_test(
        "Whitespace preservation",
        "    int x = 5;\n        int y = 10;",
        "    int x = 5;\n        int y = 10;"
    )
    
    framework:add_test(
        "Comment-like strings should not be treated as comments",
        "printf(\"// This is not a comment\");",
        "printf(\"// This is not a comment\");"
    )
    
    framework:add_test(
        "Malformed define error",
        "#define\nint x = 5;",
        "int x = 5;",
        {"malformed #define directive"}
    )
    
    framework:add_test(
        "Undefined macro in function call",
        "result = UNDEFINED_MACRO(5);",
        "result = UNDEFINED_MACRO(5);"
    )
    
    framework:add_test(
        "Unterminated conditional error",
        "#ifdef TEST\nprintf(\"test\");",
        "",
        {"unterminated conditional directive"}
    )
    
    framework:add_test(
        "Multiple else error",
        [[#ifdef TEST
printf("if");
#else
printf("else1");
#else
printf("else2");
#endif]],
        "printf(\"else1\");",
        {"multiple #else directives"}
    )
    
    framework:add_test(
        "Endif without if error",
        "printf(\"before\");\n#endif\nprintf(\"after\");",
        "printf(\"before\");\nprintf(\"after\");",
        {"#endif without matching #if"}
    )
    
    framework:add_test(
        "Nested macro calls",
        "#define OUTER(x) INNER(x)\n#define INNER(x) (x)\nint val = OUTER(42);",
        "int val = (42);"
    )
    
    framework:add_test(
        "Macro with string containing commas",
        "#define MSG \"Hello, world!\"\nprintf(MSG);",
        "printf(\"Hello, world!\");"
    )
    
    framework:add_test(
        "Function macro with string args",
        "#define PRINT(msg) printf(msg)\nPRINT(\"Hello\");",
        "printf(\"Hello\");"
    )
    
    framework:add_test(
        "Zero-argument function macro",
        "#define NEWLINE() printf(\"\\n\")\nNEWLINE();",
        "printf(\"\\n\");"
    )
    
    framework:add_test(
        "Macro argument with parentheses",
        "#define CALL(func) func()\nCALL(some_function);",
        "some_function();"
    )
    
    framework:add_test(
        "Nested conditionals with else",
        [[#define A
#ifdef A
#ifdef B
printf("Both");
#else
printf("Only A");
#endif
#endif]],
        "printf(\"Only A\");"
    )
    
    framework:add_test(
        "Line continuation handling",
        "int very_long_variable_name = 42;",
        "int very_long_variable_name = 42;"
    )
    
    framework:add_test(
        "Block comment removal",
        "int x /* this is a comment */ = 5;",
        "int x  = 5;"
    )
    
    framework:add_test(
        "Line comment removal",
        "int y = 10; // this is a line comment",
        "int y = 10;  "
    )
    
    framework:add_test(
        "Multiple comments on one line",
        "int a /* first */ = /* second */ 42;",
        "int a  =  42;"
    )
    
    framework:add_test(
        "Comments in strings should be preserved",
        [[printf("This /* is not */ a comment");]],
        [[printf("This /* is not */ a comment");]]
    )
    
    framework:add_test(
        "Comment with macro expansion",
        [[#define MAX 100
int x /* comment */ = MAX;]],
        "int x  = 100;"
    )
    
    framework:add_test(
        "Comment at start of line",
        "/* comment at start */ int x = 5;",
        " int x = 5;"
    )
    
    framework:add_test(
        "Comment at end of line",
        "int x = 5; /* comment at end */",
        "int x = 5;  "
    )
    
    framework:add_test(
        "Empty comment",
        "int x /**/ = 5;",
        "int x  = 5;"
    )
    
    framework:add_test(
        "Nested-style comment (not actually nested)",
        "int x /* outer /* inner */ = 5;",
        "int x  = 5;"
    )
    
    framework:add_test(
        "Multi-line block comment",
        [[int x = /*
        This is a multi-line
        block comment
        */ 5;]],
        [[int x =  
 
 
 5;]]
    )
    
    framework:add_test(
        "Line continuation basic",
        [[int x = \
5;]],
        "int x = 5;"
    )
    
    framework:add_test(
        "Line comment with continuation",
        [[int x = 5; // comment with \
continuation
int y = 10;]],
        [[int x = 5;  
# 3 "<stdin>"
int y = 10;]]
    )
    
    framework:add_test(
        "Macro with line continuation",
        [[#define LONG_MACRO \
some_value
int x = LONG_MACRO;]],
        [[# 3 "<stdin>"
int x = some_value;]]
    )
    
    framework:add_test(
        "Line directive processing",
        [[# 100
int x = 5;]],
        "int x = 5;"
    )
    
    framework:add_test(
        "Line directive with filename",
        [[# 50 "other.c"
int y = 10;]],
        "int y = 10;"
    )
    
    framework:add_test(
        "Line continuation with directive insertion",
        [[int a = \
1;
int b = 2;]],
        [[int a = 1;
# 3 "<stdin>"
int b = 2;]]
    )
    
    framework:add_test(
        "Multiple line continuations",
        [[int x = \
\
\
42;
int y = 10;]],
        [[int x = 42;
# 5 "<stdin>"
int y = 10;]]
    )
    
    framework:add_test(
        "Tab to space conversion",
        "int\tx\t=\t5;",
        "int x = 5;"
    )
    
    framework:add_test(
        "Tabs in macro definition",
        "#define\tMAX\t100\nint\tx\t=\tMAX;",
        "int x = 100;"
    )
    
    framework:add_test(
        "Mixed tabs and spaces",
        "int \tx\t =  5;",
        "int  x  =  5;"
    )
    
    framework:add_test(
        "Tabs in comments preserved in strings",
        "printf(\"Tab:\tHere\");",
        "printf(\"Tab: Here\");"
    )
    
    framework:add_test(
        "Tabs in block comments",
        "int/*\ttab\tcomment\t*/x = 5;",
        "int  x = 5;"
    )
    
    framework:add_test(
        "Pragma once directive processing",
        [[#pragma once
int x = 5;]],
        [[
int x = 5;]]
    )
    
    
    framework:add_test(
        "Basic elif - first branch taken",
        [[#define A 1
#if A == 2
printf("A is 2");
#elif A == 1
printf("A is 1");
#else
printf("A is other");
#endif]],
        "printf(\"A is 1\");"
    )
    
    framework:add_test(
        "Basic elif - second branch taken",
        [[#define A 3
#if A == 2
printf("A is 2");
#elif A == 3
printf("A is 3");
#else
printf("A is other");
#endif]],
        "printf(\"A is 3\");"
    )
    
    framework:add_test(
        "Basic elif - else branch taken",
        [[#define A 5
#if A == 2
printf("A is 2");
#elif A == 3
printf("A is 3");
#else
printf("A is other");
#endif]],
        "printf(\"A is other\");"
    )
    
    framework:add_test(
        "Multiple elif branches",
        [[#define VAL 4
#if VAL == 1
printf("one");
#elif VAL == 2
printf("two");
#elif VAL == 3
printf("three");
#elif VAL == 4
printf("four");
#else
printf("other");
#endif]],
        "printf(\"four\");"
    )
    
    framework:add_test(
        "elifdef - macro defined",
        [[#define B
#ifdef A
printf("A defined");
#elifdef B
printf("B defined");
#else
printf("Neither");
#endif]],
        "printf(\"B defined\");"
    )
    
    framework:add_test(
        "elifdef - no macro defined",
        [[#ifdef A
printf("A defined");
#elifdef B
printf("B defined");
#else
printf("Neither");
#endif]],
        "printf(\"Neither\");"
    )
    
    framework:add_test(
        "elifndef - macro not defined",
        [[#define B
#ifdef A
printf("A defined");
#elifndef C
printf("C not defined");
#else
printf("Other");
#endif]],
        "printf(\"C not defined\");"
    )
    
    framework:add_test(
        "elifndef - macro is defined",
        [[#define B
#define C
#ifdef A
printf("A defined");
#elifndef C
printf("C not defined");
#else
printf("Other");
#endif]],
        "printf(\"Other\");"
    )
    
    framework:add_test(
        "Mixed elif types",
        [[#define X 5
#define Y
#if X == 1
printf("X is 1");
#elif X == 2
printf("X is 2");
#elifdef Y
printf("Y is defined");
#elifndef Z
printf("Z not defined");
#else
printf("fallback");
#endif]],
        "printf(\"Y is defined\");"
    )
    
    framework:add_test(
        "Nested conditionals with elif",
        [[#define A 1
#define B 2
#if A == 1
#if B == 1
printf("A=1, B=1");
#elif B == 2
printf("A=1, B=2");
#endif
#elif A == 2
printf("A=2");
#endif]],
        "printf(\"A=1, B=2\");"
    )
    
    framework:add_test(
        "Error: elif without if",
        [[#elif 1
printf("test");]],
        "printf(\"test\");",
        {"#elif without matching #if"}
    )
    
    framework:add_test(
        "Error: elif after else",
        [[#if 0
printf("if");
#else
printf("else");
#elif 1
printf("elif");
#endif]],
        "printf(\"else\");",
        {"#elif after #else"}
    )
    
    framework:add_test(
        "Error: elifdef after else",
        [[#if 0
printf("if");
#else
printf("else");
#elifdef X
printf("elifdef");
#endif]],
        "printf(\"else\");",
        {"#elifdef after #else"}
    )
    
    framework:add_test(
        "Line directive after skipped if block",
        [[int a;
#if 0
int b;
int c;
#endif
int d;]],
        [[int a;



int d;]]
    )
    
    framework:add_test(
        "Line directive after else block",
        [[#if 0
int x;
#else
int y;
#endif
int z;]],
        [[

int y;

int z;]]
    )
    
    framework:add_test(
        "Line directive after elif chain",
        [[#define A 2
#if A == 1
int x;
#elif A == 2
int y;
#else
int z;
#endif
int w;]],
        [[


int y;


int w;]]
    )
    
    framework:add_test(
        "Nested conditionals with line directives",
        [[#if 1
#if 0
int a;
#else
int b;
#endif
int c;
#endif]],
        [[


int b;

int c;
]]
    )
    
    framework:add_test(
        "Multiple skipped blocks",
        [[int start;
#if 0
int block1;
#endif
int middle;
#if 0
int block2;
#endif
int end;]],
        [[int start;


int middle;


int end;]]
    )
    
    framework:add_test(
        "Line directive with elifdef",
        [[#ifdef UNDEFINED
int x;
#elifdef ALSO_UNDEFINED  
int y;
#else
int z;
#endif
int w;]],
        [[



int z;

int w;]]
    )
    
    framework:add_test(
        "Error directive",
        [[int x = 5;
#error "This is an error message"
int y = 10;]],
        [[]],
        {"This is an error message"}
    )
    
    framework:add_test(
        "Warning directive",
        [[int x = 5;
#warning "This is a warning message"
int y = 10;]],
        [[int x = 5;

int y = 10;]],
        {"This is a warning message"}
    )
    
    framework:add_test(
        "Error directive without message",
        [[#error
int x = 5;]],
        [[]],
        {""}
    )
    
    framework:add_test(
        "Warning directive without quotes",
        [[#warning Deprecated feature
int x = 5;]],
        [[
int x = 5;]],
        {"Deprecated feature"}
    )
    
    framework:add_test(
        "Error directive in conditional - not processed",
        [[#if 0
#error "Should not see this"
#endif
int x = 5;]],
        [[


int x = 5;]]
    )
    
    framework:add_test(
        "Warning directive in conditional - processed",
        [[#if 1
#warning "Active warning"
#endif
int x = 5;]],
        [[

int x = 5;]],
        {"Active warning"}
    )
    
    -- Stringification operator tests
    framework:add_test(
        "Stringification operator basic",
        [[#define STR(x) #x
printf(STR(hello world));]],
        [[
printf("hello world");]]
    )
    
    framework:add_test(
        "Stringification with quotes",
        [[#define STR(x) #x
printf(STR("quoted string"));]],
        [[
printf("\"quoted string\"");]]
    )
    
    framework:add_test(
        "Stringification with backslashes",
        [[#define STR(x) #x
printf(STR(path\file));]],
        [[
printf("path\\file");]]
    )
    
    -- Token pasting operator tests
    framework:add_test(
        "Token pasting basic",
        [[#define CONCAT(a, b) a##b
int CONCAT(var, 123) = 5;]],
        [[
int var123 = 5;]]
    )
    
    framework:add_test(
        "Token pasting with underscores",
        [[#define MAKE_FUNC(name) func_##name
void MAKE_FUNC(init)(void);]],
        [[
void func_init(void);]]
    )
    
    framework:add_test(
        "Token pasting multiple",
        [[#define TRIPLE(a, b, c) a##b##c
int TRIPLE(x, y, z) = 1;]],
        [[
int xyz = 1;]]
    )
    
    -- Variadic macro tests
    framework:add_test(
        "Variadic macro basic",
        [[#define LOG(fmt, ...) printf(fmt, __VA_ARGS__)
LOG("Hello %s %d", "world", 42);]],
        [[
printf("Hello %s %d", "world", 42);]]
    )
    
    framework:add_test(
        "Variadic macro empty args",
        [[#define DEBUG(msg, ...) printf(msg, __VA_ARGS__)
DEBUG("test");]],
        [[
printf("test", );]]
    )
    
    framework:add_test(
        "Variadic macro single arg",
        [[#define PRINT(...) printf(__VA_ARGS__)
PRINT("hello");]],
        [[
printf("hello");]]
    )
    
    framework:add_test(
        "Variadic stringification",
        [[#define DEBUG(...) printf(#__VA_ARGS__)
DEBUG(x, y, z);]],
        [[
printf("x, y, z");]]
    )
    
    framework:add_test(
        "Mixed fixed and variadic params",
        [[#define LOG(level, fmt, ...) printf("[%s] " fmt, level, __VA_ARGS__)
LOG("INFO", "Count: %d", 42);]],
        [[
printf("[%s] " "Count: %d", "INFO", 42);]]
    )
    
    -- Combined features tests
    framework:add_test(
        "Stringification and token pasting",
        [[#define MAKE_STR(x, y) #x##y
char* str = MAKE_STR(hello, world);]],
        [[
char* str = "hello"world;]]
    )
    
    framework:add_test(
        "Variadic with token pasting",
        [[#define FUNC(name, ...) name##_impl(__VA_ARGS__)
FUNC(test, 1, 2, 3);]],
        [[
test_impl(1, 2, 3);]]
    )
    
    -- __VA_OPT__ tests
    framework:add_test(
        "__VA_OPT__ with arguments",
        [[#define FUNC(name, ...) name(__VA_OPT__(,) __VA_ARGS__)
FUNC(printf, "hello", 42);]],
        [[
printf(, "hello", 42);]]
    )
    
    framework:add_test(
        "__VA_OPT__ without arguments", 
        [[#define FUNC(name, ...) name(__VA_OPT__(,) __VA_ARGS__)
FUNC(printf);]],
        [[
printf( );]]
    )
    
    framework:add_test(
        "__VA_OPT__ optional comma pattern",
        [[#define LOG(fmt, ...) printf(fmt __VA_OPT__(,) __VA_ARGS__)
LOG("test");
LOG("value: %d", 42);]],
        [[
printf("test"  );
printf("value: %d" , 42);]]
    )
    
    framework:add_test(
        "__VA_OPT__ with complex content",
        [[#define DEBUG(msg, ...) printf("[DEBUG] " msg __VA_OPT__(": ") __VA_ARGS__)
DEBUG("start");
DEBUG("count", "%d", 5);]],
        [[
printf("[DEBUG] " "start" );
printf("[DEBUG] " "count" ": " "%d", 5);]]
    )
    
    -- Predefined macro tests
    framework:add_test(
        "__FILE__ predefined macro",
        [[printf("Current file: %s\n", __FILE__);]],
        [[printf("Current file: %s\n", "<stdin>");]]
    )
    
    framework:add_test(
        "__LINE__ predefined macro",
        [[int x = __LINE__;
printf("Line: %d\n", __LINE__);]],
        [[int x = 1;
printf("Line: %d\n", 2);]]
    )
    
    framework:add_test(
        "__DATE__ predefined macro existence",
        [[#ifdef __DATE__
int date_defined = 1;
#endif]],
        [[int date_defined = 1;
]]
    )
    
    framework:add_test(
        "__TIME__ predefined macro existence", 
        [[#ifdef __TIME__
int time_defined = 1;
#endif]],
        [[int time_defined = 1;
]]
    )
    
    framework:add_test(
        "__STDC__ predefined macro",
        [[#if __STDC__
printf("Standard C\n");
#endif]],
        [[
printf("Standard C\n");
]]
    )
    
    framework:add_test(
        "__STDC_VERSION__ predefined macro",
        [[printf("C standard version: %s\n", __STDC_VERSION__);]],
        [[printf("C standard version: %s\n", 202311);]]
    )
    
    framework:add_test(
        "Multiple predefined macros in expression",
        [[#if __STDC__
#if __STDC_VERSION__
printf("C23 or later\n");
#endif
#endif]],
        [[

printf("C23 or later\n");

]]
    )
    
    framework:add_test(
        "Predefined macros in macro definitions",
        [[#define LOG_LOCATION() printf("At %s:%d\n", __FILE__, __LINE__)
LOG_LOCATION();]],
        [[
printf("At %s:%d\n", "<stdin>", 2);]]
    )
    
    -- Include directive tests (these need the actual files to exist)
    framework:add_test(
        "Local include directive",
        [[#include "include/local_header.h"
int x = LOCAL_CONSTANT;]],
        [[

# 2 "<stdin>"
int x = 42;]]
    )
    
    framework:add_test(
        "System include directive",
        [[#include <system_header.h>
typedef system_int_t my_int;]],
        [[


typedef int system_int_t;
# 2 "<stdin>"
typedef system_int_t my_int;]]
    )
    
    framework:add_test(
        "Include with macro expansion",
        [[#include "include/local_header.h"
int result = LOCAL_FUNC(10);]],
        [[

# 2 "<stdin>"
int result = ((10) * 2);]]
    )
    
    -- New predefined macros tests
    framework:add_test(
        "__COUNTER__ predefined macro incrementing",
        [[int a = __COUNTER__;
int b = __COUNTER__;
int c = __COUNTER__;]],
        [[int a = 0;
int b = 1;
int c = 2;]]
    )
    
    framework:add_test(
        "__BASE_FILE__ predefined macro",
        [[printf("Base file: %s\n", __BASE_FILE__);]],
        [[printf("Base file: %s\n", "<stdin>");]]
    )
    
    framework:add_test(
        "__TIMESTAMP__ predefined macro existence",
        [[#ifdef __TIMESTAMP__
int timestamp_defined = 1;
#endif]],
        [[int timestamp_defined = 1;
]]
    )
    
    -- Column tracking tests (simplified since we can't easily test JSON in this framework)
    framework:add_test(
        "Malformed define triggers error",
        [[    #define]],
        "",
        {"malformed #define directive"}
    )
    
    -- Pragma directive tests
    framework:add_test(
        "Pragma once directive",
        [[#pragma once
int x = 1;]],
        [[
int x = 1;]]
    )
    
    framework:add_test(
        "Pragma pack directive with warning",
        [[#pragma pack(1)
int x = 1;]],
        [[
int x = 1;]],
        {"pragma pack is recognized but not implemented"}
    )
    
    framework:add_test(
        "Pragma GCC diagnostic directive with warning",
        [[#pragma GCC diagnostic push
int x = 1;]],
        [[
int x = 1;]],
        {"pragma GCC diagnostic is recognized but not implemented"}
    )
    
    framework:add_test(
        "Unknown pragma directive with warning",
        [[#pragma unknown_directive
int x = 1;]],
        [[
int x = 1;]],
        {"unknown pragma 'unknown_directive' ignored"}
    )
    
    -- _Pragma operator tests
    framework:add_test(
        "_Pragma operator with pragma once",
        [[_Pragma("once")
int x = 1;]],
        [[
int x = 1;]]
    )
    
    framework:add_test(
        "_Pragma operator with warnings",
        [[_Pragma("pack(1)")
int x = 1;]],
        [[
int x = 1;]],
        {"pragma pack is recognized but not implemented"}
    )
    
    framework:add_test(
        "_Pragma in macro expansion",
        [[#define PRAGMA_ONCE _Pragma("once")
PRAGMA_ONCE
int x = 1;]],
        [[

int x = 1;]]
    )
    
    -- __has_include tests
    framework:add_test(
        "__has_include with existing local header",
        [[#if __has_include("include/local_header.h")
int header_found = 1;
#else
int header_not_found = 0;
#endif]],
        [[int header_found = 1;

]]
    )
    
    framework:add_test(
        "__has_include with non-existent header",
        [[#if __has_include("nonexistent.h")
int header_found = 1;
#else
int header_not_found = 0;
#endif]],
        [[
int header_not_found = 0;
]]
    )
    
    framework:add_test(
        "__has_include with system header",
        [[#if __has_include(<system_header.h>)
int system_header_found = 1;
#else
int system_header_not_found = 0;
#endif]],
        [[int system_header_found = 1;

]]
    )
    
    framework:add_test(
        "__has_include feature detection",
        [[#ifdef __has_include
int has_include_supported = 1;
#endif]],
        [[int has_include_supported = 1;
]]
    )
    
    -- __has_feature tests
    framework:add_test(
        "__has_feature with supported feature",
        [[#if __has_feature(c_variadic_macros)
int feature_supported = 1;
#else
int feature_not_supported = 0;
#endif]],
        [[int feature_supported = 1;

]]
    )
    
    framework:add_test(
        "__has_feature with unsupported feature",
        [[#if __has_feature(c_atomic)
int feature_supported = 1;
#else
int feature_not_supported = 0;
#endif]],
        [[
int feature_not_supported = 0;
]]
    )
    
    framework:add_test(
        "__has_feature feature detection",
        [[#ifdef __has_feature
int has_feature_supported = 1;
#endif]],
        [[int has_feature_supported = 1;
]]
    )
    
    framework:add_test(
        "__has_feature direct expansion",
        [[int result = __has_feature(c_variadic_macros);]],
        [[int result = 1;]]
    )
    
    return framework:run_all()
end

if arg and arg[0] then
    local success = run_tests()
    os.exit(success and 0 or 1)
end

return run_tests