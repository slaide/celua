#!/usr/bin/env lua
-- Test: Basic line splicing removes backslash-newline
package.path = '../../../build/?.lua;../../?.lua;' .. package.path

local test_utils_module = require("test_utils")
local TestUtils = test_utils_module.TestUtils

local test_case = TestUtils.expect_success(
    "basic_splicing",
    "Basic line splicing removes backslash-newline",
    "int \\\na;",
    {
        output_mode = "preprocessed",
        error_code_only = false,
        input_path = "tests/inputs/splicing_test.c",
        output_path = "tests/outputs/splicing_test.i"
    },
    "int a;"
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