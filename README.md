# Celua - C23 Compliant Compiler

A C23 compliant compiler written in Teal, targeting Lua 5.1 output.

## Current Status

🚧 **Early Development** - This project is in the initial implementation phase.

All compiler features currently use the `unimplemented()` function, which will crash with a clear error message when called. This is intentional to make it explicit that features are not yet ready for use.

### Test-Driven Development Approach
Most tests are currently **failing by design**. The test suite defines what the compiler SHOULD do, not what it currently does. As features are implemented, tests will begin passing. This ensures:
- Clear specification of desired behavior
- Confidence when implementing features  
- Protection against regressions
- Incremental, well-tested development

## Build Requirements

- [Cyan](https://github.com/teal-language/cyan) (Teal package manager)
- Lua

## Building

```bash
cyan build
```

This will:
1. Type check all Teal sources
2. Compile Teal to Lua 5.1 compatible code
3. Run post-build script to create the `celua` executable

## Usage

### Compiler Modes

The compiler operates in different phases, allowing you to stop at various compilation stages:

```bash
# Preprocessing only (-E flag, up to phase 4)
./celua -E input.c       # Run splicer and preprocessor only, output preprocessed C
./celua -E -o output.i input.c  # Save preprocessed output to file

# Full compilation (default, up to parsing and validation)
./celua input.c          # Parse and validate, output to Lua (currently unimplemented)
./celua -o output.lua input.c  # Custom output file

# AST output mode
./celua --ast input.c    # Output AST as JSON instead of compiled code
./celua --ast -o ast.json input.c  # Save AST JSON to file

# Error reporting modes
./celua --error-code-only input.c    # Only output error codes (E001), no descriptions
./celua --error-code-only -E input.c # Works with any compilation mode
```

### General Usage

```bash
# Run the compiler
./celua --help           # Show help
./celua --version        # Show version

# Alternative run script
./run --help             # Same as ./celua --help

# Run tests
./test                   # Run all tests

# Development commands
cyan check               # Type check only
cyan build               # Build and create executable
```

## Architecture

- **src/main.tl** - Command line interface
- **src/utils.tl** - Utility functions including `unimplemented()` and error handling
- **src/lexer.tl** - Lexical analysis (tokenization)
- **src/parser.tl** - Syntax analysis (AST generation)  
- **src/codegen.tl** - Code generation (Lua 5.1 output)
- **src/compiler.tl** - Main compiler orchestration
- **tests/** - Complete test suite (see Testing section below)
- **scripts/** - Build and automation scripts
- **tlconfig.lua** - Cyan build configuration

## Testing

The compiler includes a comprehensive test framework for ensuring correctness and catching regressions.

### Test Structure

All test-related files are located in the `tests/` directory:

- **tests/test_framework.tl** - Core testing infrastructure
- **tests/simple_test.lua** - Main test runner with basic functionality tests
- **tests/basic_test.tl** - Utility function tests
- **tests/compiler_tests.tl** - Compiler functionality tests
- **tests/run_all_tests.tl** - Comprehensive test suite runner

### Running Tests

From the project root:

```bash
# Run the main test suite
./test

# Or run tests directly
cd tests && lua simple_test.lua
```

### Interpreting Results

Test output uses clear symbols:
- **✓** - Test passed
- **✗** - Test failed (with detailed failure reason)

Example output:
```
===================================================
TEST SUMMARY  
===================================================
✗ Compilation Tests: 3/5 (60.0%)
  ✗ AST Output: 0/1 (0.0%)
  ✗ Lua Output: 1/3 (33.3%)
✓ Preprocessing Tests: 1/1 (100.0%)
⚠ Option Tests: 1/1 (100.0%)

OVERALL: 5/7 tests passed (71.4%)
❌ Many tests failed - needs investigation
```

**Note**: Many tests will initially fail because they define desired behavior that hasn't been implemented yet. This is intentional and drives development forward.

### Error Code Testing

The test framework can verify specific error codes are returned:

```lua
-- Test that compilation fails with specific error code
TestFramework.expect_error(
    "Test name",
    "int main() { return 0; }",  -- C source code
    {
        output_mode = "lua_code",  -- Compiler configuration
        error_code_only = false,
        input_path = "test.c",
        output_path = "test.lua"
    },
    "E001"  -- Expected error code
)
```

### Adding New Tests

**IMPORTANT PHILOSOPHY**: Tests should define what we WANT the compiler to do, not what it currently does. Write tests for the desired behavior first, then implement features to make them pass. This is Test-Driven Development (TDD).

#### Example: Adding a New Feature

```lua
-- ❌ WRONG: Testing current broken behavior
TestFramework.expect_error(
    "Integer parsing currently fails",
    "int x = 42;", 
    config,
    "E001"  -- Expecting it to fail because we know lexer is unimplemented
)

-- ✅ CORRECT: Testing desired behavior
TestFramework.expect_success(
    "Integer variable declaration should compile",
    "int x = 42;",
    config,
    "local x = 42"  -- What we want the output to be
)
```

1. **Create test case** in appropriate test group structure
2. **Choose test type based on desired outcome**:
   - `expect_success()` - Feature should work and produce specific output
   - `expect_error()` - Invalid code should produce specific error
   - `expect_warnings()` - Code should compile but warn about issues

3. **Test structure**:
```lua
-- Create logical groups first
local declarations_group = TestFramework.create_group("Variable Declarations", parent_group)

-- Add test for desired behavior
TestFramework.add_test_to_group(declarations_group, TestFramework.expect_success(
    "Simple integer declaration",
    "int x = 42;",
    compiler_config,
    "local x = 42"  -- Expected Lua output
))
```

4. **Add to hierarchical test structure** using groups for organization

### Nested Test Groups

The test framework supports organizing tests into hierarchical groups for better organization and reporting:

```lua
-- Create main test groups  
local lexer_group = TestFramework.create_group("Lexer Tests", nil)
local parser_group = TestFramework.create_group("Parser Tests", nil)

-- Create subgroups
local basic_tokens = TestFramework.create_group("Basic Tokens", lexer_group)  
local keywords = TestFramework.create_group("Keywords", lexer_group)
TestFramework.add_subgroup(lexer_group, basic_tokens)
TestFramework.add_subgroup(lexer_group, keywords)

-- Add tests to groups
TestFramework.add_test_to_group(basic_tokens, test_case)

-- Run all groups with hierarchical summary
local summary = framework:run_group_suite({lexer_group, parser_group})
TestFramework.print_summary(summary)
```

**Group Summary Output:**
```
===================================================
TEST SUMMARY  
===================================================
✗ Lexer Tests: 3/4 (75.0%)
  ✓ Basic Tokens: 2/2 (100.0%)
  ✗ Keywords: 1/2 (50.0%)
✓ Parser Tests: 4/4 (100.0%)

OVERALL: 7/8 tests passed (87.5%)
⚠️  Most tests passed, but some need attention
```

### Test Framework Features

- **No crashes during testing** - `unimplemented()` calls are caught and converted to error codes
- **File content testing** - Tests provide C source as strings, not file paths
- **Multiple compiler modes** - Can test preprocessing (-E), AST output (--ast), and default compilation
- **Detailed failure reporting** - Shows expected vs actual results
- **Structured results** - Tests return `CompilerResult` with success/error/warnings/output
- **Nested test groups** - Organize tests hierarchically with unlimited depth
- **Group statistics** - Track pass/fail rates for each group and subgroup
- **Formatted summaries** - Visual output with indentation, icons, and percentages

## Development Philosophy

### Test-Driven Development (TDD)
**Write tests for what you WANT the compiler to do, not what it currently does.** This means:

1. **Add tests first** - Before implementing any feature, write tests that describe the desired behavior
2. **Tests should initially fail** - New feature tests will fail until the feature is implemented
3. **Implement to make tests pass** - Write the minimum code needed to make the test pass
4. **Refactor and improve** - Clean up implementation while keeping tests passing

### Error Handling
Every unimplemented code path uses `unimplemented(msg)` which will crash immediately with a clear error message. No silent failures or warnings - if something isn't implemented, the program will make it abundantly clear.

### Example TDD Workflow
```bash
# 1. Add test for new feature (will fail)
TestFramework.expect_success("Parse function calls", "foo(1, 2)", config, expected_lua)

# 2. Run tests - see the new test fail
./test

# 3. Implement just enough to make test pass
# (implement lexer tokens, parser rules, codegen for function calls)

# 4. Run tests - see the test pass
./test

# 5. Add more comprehensive tests and repeat
```

This ensures every feature is properly tested and the compiler grows incrementally with confidence.

## Next Steps

Implementation priorities:
1. Basic lexer for C tokens
2. Simple expression parser
3. Basic code generation for arithmetic
4. Function declarations and calls
5. Control flow structures
6. Full C23 standard compliance