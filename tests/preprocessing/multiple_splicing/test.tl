#!/usr/bin/env lua
-- Test: Multiple line continuations are all removed
package.path = '../../../build/?.lua;../../?.lua;' .. package.path

local test_utils_module = require("test_utils")
local TestUtils = test_utils_module.TestUtils

local test_case = TestUtils.expect_success(
    "multiple_splicing",
    "Multiple line continuations are all removed",
    "int \\\nmain\\\n() {\n    return \\\n0;\n}",
    {
        output_mode = "preprocessed",
        error_code_only = false,
        input_path = "tests/inputs/complex_splicing.c",
        output_path = "tests/outputs/complex_splicing.i"
    },
    "int main() {\n    return 0;\n}"
)

local success, message = TestUtils.run_test(test_case)

if success then
    print("✓ " .. test_case.description)
    os.exit(0)
else
    print("✗ " .. test_case.description)
    for line in message:gmatch("[^\n]+") do
        print("| " .. line)
    end
    os.exit(1)
end