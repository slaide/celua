#!/usr/bin/env lua
-- Test: Text without splicing or directives is unchanged
package.path = '../../../build/?.lua;../../?.lua;' .. package.path

local test_utils_module = require("test_utils")
local TestUtils = test_utils_module.TestUtils

local test_case = TestUtils.expect_success(
    "no_changes",
    "Text without splicing or directives is unchanged",
    "int main() { return 0; }",
    {
        output_mode = "preprocessed",
        error_code_only = false,
        input_path = "tests/inputs/simple_main.c",
        output_path = "tests/outputs/simple_main.i"
    },
    "int main() { return 0; }"
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