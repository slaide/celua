#!/usr/bin/env lua
-- Test: Empty file produces parse error E010
package.path = '../../../build/?.lua;../../?.lua;' .. package.path

local test_utils_module = require("test_utils")
local TestUtils = test_utils_module.TestUtils

local test_case = TestUtils.expect_error(
    "lua_output_empty",
    "Empty file produces parse error E010",
    "",
    {
        output_mode = "lua_code",
        error_code_only = false,
        input_path = "empty.c",
        output_path = "empty.lua"
    },
    "E010"
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