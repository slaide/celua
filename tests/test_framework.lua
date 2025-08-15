#!/usr/bin/env lua

-- Add src directory to Lua path
package.path = package.path .. ";../src/?.lua"
local Preprocessor = require("preprocessor")

local TestFramework = {}
TestFramework.__index = TestFramework

function TestFramework:new()
    local self = setmetatable({}, TestFramework)
    self.tests = {}
    self.passed = 0
    self.failed = 0
    return self
end

function TestFramework:add_test(name, input, expected_output, expected_errors)
    table.insert(self.tests, {
        name = name,
        input = input,
        expected_output = expected_output or "",
        expected_errors = expected_errors or {}
    })
end

function TestFramework:trim(s)
    return s:match("^%s*(.-)%s*$")
end

function TestFramework:normalize_whitespace(s)
    return s:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

function TestFramework:compare_outputs(actual, expected)
    local actual_norm = self:normalize_whitespace(actual)
    local expected_norm = self:normalize_whitespace(expected)
    return actual_norm == expected_norm
end

function TestFramework:compare_errors(actual_errors, expected_errors)
    if #actual_errors ~= #expected_errors then
        return false
    end
    
    for i, expected in ipairs(expected_errors) do
        local found = false
        for _, actual in ipairs(actual_errors) do
            if actual:find(expected, 1, true) then
                found = true
                break
            end
        end
        if not found then
            return false
        end
    end
    
    return true
end

function TestFramework:run_test(test)
    local preprocessor = Preprocessor:new()
    -- Add test include paths for include directive tests
    preprocessor.include_paths = {".", "include", "system_include"}
    local actual_output, actual_errors, error_directive_encountered = preprocessor:process(test.input)
    
    -- Match main script behavior: suppress output if error directive encountered
    if error_directive_encountered then
        actual_output = ""
    end
    
    local output_match = self:compare_outputs(actual_output, test.expected_output)
    local errors_match = self:compare_errors(actual_errors, test.expected_errors)
    
    if output_match and errors_match then
        self.passed = self.passed + 1
        print("PASS: " .. test.name)
        return true
    else
        self.failed = self.failed + 1
        print("FAIL: " .. test.name)
        
        if not output_match then
            print("  Expected output: '" .. test.expected_output .. "'")
            print("  Actual output:   '" .. actual_output .. "'")
        end
        
        if not errors_match then
            print("  Expected errors: " .. table.concat(test.expected_errors, ", "))
            print("  Actual errors:   " .. table.concat(actual_errors, ", "))
        end
        
        return false
    end
end

function TestFramework:run_all()
    print("Running " .. #self.tests .. " tests...\n")
    
    for _, test in ipairs(self.tests) do
        self:run_test(test)
    end
    
    print("\n" .. string.rep("=", 50))
    print("Results: " .. self.passed .. " passed, " .. self.failed .. " failed")
    
    if self.failed == 0 then
        print("All tests passed!")
        return true
    else
        print("Some tests failed!")
        return false
    end
end

return TestFramework