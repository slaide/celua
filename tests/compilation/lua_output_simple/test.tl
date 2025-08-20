#!/usr/bin/env lua
-- Test: Main function compiles to callable Lua function
package.path = '../../../build/?.lua;../../?.lua;' .. package.path

local test_utils_module = require("test_utils")
local TestUtils = test_utils_module.TestUtils

local test_case = TestUtils.expect_success(
    "lua_output_simple",
    "Main function compiles to callable Lua function",
    "int main() { return 0; }",
    {
        output_mode = "lua_code",
        error_code_only = false,
        input_path = "simple_main.c",
        output_path = "simple_main.lua"
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