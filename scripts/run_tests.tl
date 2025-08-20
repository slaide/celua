local hook, ... = ...

print("Running tests...")

local function run_test(test_file: string): boolean
    print("• Running " .. test_file)
    local cmd = "cd build && lua ../tests/" .. test_file
    local success = os.execute(cmd)
    return success == 0 or success == true
end

local test_files = {"basic_test.tl"}
local all_passed = true

for _, test_file in ipairs(test_files) do
    if not run_test(test_file) then
        all_passed = false
        print("✗ " .. test_file .. " failed")
    else
        print("✓ " .. test_file .. " passed")
    end
end

if all_passed then
    print("✓ All tests passed!")
else
    print("✗ Some tests failed!")
    os.exit(1)
end