#!/usr/bin/env lua
-- Test: Error-code-only mode produces same output as normal mode
package.path = '../../../build/?.lua;../../?.lua;' .. package.path

local test_utils_module = require("test_utils")
local TestUtils = test_utils_module.TestUtils

local test_case = TestUtils.expect_success(
    "error_code_only",
    "Error-code-only mode produces same output as normal mode",
    "int main() { return 0; }",
    {
        output_mode = "lua_code",
        error_code_only = true,
        input_path = "simple_main.c",
        output_path = "simple_main_error_only.lua"
    },
    "function main()\n  return 0\nend\n\n-- Entry point\nmain()"
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