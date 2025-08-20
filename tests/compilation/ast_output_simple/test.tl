#!/usr/bin/env lua
-- Test: Main function produces structured AST JSON
package.path = '../../../build/?.lua;../../?.lua;' .. package.path

local test_utils_module = require("test_utils")
local TestUtils = test_utils_module.TestUtils

local test_case = TestUtils.expect_success(
    "ast_output_simple",
    "Main function produces structured AST JSON",
    "int main() { return 0; }",
    {
        output_mode = "ast_json",
        error_code_only = false,
        input_path = "simple_main.c",
        output_path = "simple_main.json"
    },
    '{"type":"Program","body":[{"type":"FunctionDeclaration","name":"main","returnType":"int","body":[{"type":"ReturnStatement","value":{"type":"Literal","value":0}}]}]}'
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