local args = {...}
local hook = args[1]

print("Creating executable wrapper...")

local wrapper_content = [[#!/usr/bin/env lua
package.path = './build/?.lua;' .. package.path
require('main')
]]

local file = io.open("celua", "w")
if file then
    file:write(wrapper_content)
    file:close()
    
    local success = os.execute("chmod +x celua")
    if success then
        print("✓ Created executable: ./celua")
    else
        print("✗ Failed to make celua executable")
    end
else
    print("✗ Failed to create celua executable")
end