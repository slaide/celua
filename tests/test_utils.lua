local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local package = _tl_compat and _tl_compat.package or package; local pcall = _tl_compat and _tl_compat.pcall or pcall; local table = _tl_compat and _tl_compat.table or table
package.path = '../build/?.lua;' .. package.path
local compiler_module = require("compiler")
local CompilerConfig = compiler_module.CompilerConfig
local CompilerResult = compiler_module.CompilerResult

local utils_module = require("utils")
local ErrorCode = utils_module.ErrorCode











local TestUtils = {}





function TestUtils.expect_success(name, description, input, config, expected_output)
   return {
      name = name,
      description = description,
      input = input,
      config = config,
      expect_success = true,
      expected_output = expected_output,
      expected_error = "E001",
   }
end

function TestUtils.expect_error(name, description, input, config, expected_error)
   return {
      name = name,
      description = description,
      input = input,
      config = config,
      expect_success = false,
      expected_output = "",
      expected_error = expected_error,
   }
end

function TestUtils.run_test(test_case)
   local utils_module = require("utils")
   local utils = utils_module.Utils
   local Compiler = compiler_module.Compiler


   utils.set_test_mode(true)

   local actual_result
   local success, err = pcall(function()
      actual_result = Compiler.process_file(
      test_case.config.input_path or "test_file.c",
      test_case.input,
      test_case.config)

   end)


   utils.set_test_mode(false)

   if not success then
      return false, "Test framework error: " .. tostring(err)
   end


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
   TestUtils = TestUtils,
}
