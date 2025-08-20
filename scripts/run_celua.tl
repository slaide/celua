local hook, ... = ...

local args = {...}
table.remove(args, 1) -- Remove hook name

local cmd_args = table.concat(args, " ")
local cmd = "lua build/main.lua " .. cmd_args

print("Running: " .. cmd)
local success = os.execute(cmd)
if not (success == 0 or success == true) then
    os.exit(1)
end