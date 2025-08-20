-- Common test utilities and framework
package.path = '../build/?.lua;' .. package.path
local compiler_module = require("compiler")
local CompilerConfig = compiler_module.CompilerConfig
local CompilerResult = compiler_module.CompilerResult

local utils_module = require("utils")
local ErrorCode = utils_module.ErrorCode

local record TestCase
    name: string
    description: string
    input: string
    config: CompilerConfig
    expect_success: boolean
    expected_output: string
    expected_error: ErrorCode
end

local record TestUtils
    expect_success: function(name: string, description: string, input: string, config: CompilerConfig, expected_output: string): TestCase
    expect_error: function(name: string, description: string, input: string, config: CompilerConfig, expected_error: ErrorCode): TestCase
    run_test: function(test_case: TestCase): boolean, string
end

function TestUtils.expect_success(name: string, description: string, input: string, config: CompilerConfig, expected_output: string): TestCase
    return {
        name = name,
        description = description,
        input = input,
        config = config,
        expect_success = true,
        expected_output = expected_output,
        expected_error = "E001" as ErrorCode
    }
end

function TestUtils.expect_error(name: string, description: string, input: string, config: CompilerConfig, expected_error: ErrorCode): TestCase
    return {
        name = name,
        description = description,
        input = input,
        config = config,
        expect_success = false,
        expected_output = "",
        expected_error = expected_error
    }
end

function TestUtils.run_test(test_case: TestCase): boolean, string
    local utils_module = require("utils")
    local utils = utils_module.Utils
    local Compiler = compiler_module.Compiler
    
    -- Enable test mode
    utils.set_test_mode(true)
    
    local actual_result: CompilerResult
    local success, err = pcall(function(): any
        actual_result = Compiler.process_file(
            test_case.config.input_path or "test_file.c",
            test_case.input,
            test_case.config
        )
    end)
    
    -- Disable test mode
    utils.set_test_mode(false)
    
    if not success then
        return false, "Test framework error: " .. tostring(err)
    end
    
    -- Check results
    if test_case.expect_success then
        if actual_result.success then
            if test_case.expected_output ~= "" and actual_result.output_content ~= test_case.expected_output then
                return false, "Expected output: '" .. test_case.expected_output .. "', got: '" .. actual_result.output_content .. "'"
            end
            return true, "Test passed"
        else
            local error_msg = "Expected success but got error: " .. (actual_result.error_code or "unknown")
            if actual_result.error_output and #actual_result.error_output > 0 then
                error_msg = error_msg .. "\n" .. table.concat(actual_result.error_output, "\n")
            end
            return false, error_msg
        end
    else
        if actual_result.success then
            return false, "Expected error " .. test_case.expected_error .. " but compilation succeeded"
        elseif actual_result.error_code == test_case.expected_error then
            return true, "Got expected error: " .. actual_result.error_code
        else
            local error_msg = "Expected error " .. test_case.expected_error .. " but got: " .. (actual_result.error_code or "unknown")
            if actual_result.error_output and #actual_result.error_output > 0 then
                error_msg = error_msg .. "\n" .. table.concat(actual_result.error_output, "\n")
            end
            return false, error_msg
        end
    end
end

return {
    TestUtils = TestUtils
}