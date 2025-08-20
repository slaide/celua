local enum ErrorCode
    "E001" -- Unimplemented feature
    "E002" -- Invalid command line option
    "E003" -- Missing required argument
    "E004" -- File not found
    "E005" -- File read error
    "E006" -- File write error
    "E007" -- Multiple input files not supported
    "E008" -- No input file specified
    "E009" -- Lexical analysis error
    "E010" -- Parse error
    "E011" -- Code generation error
    "E012" -- Compilation error
end

local enum WarningCode
    "W001" -- Unused variable
    "W002" -- Deprecated feature
    "W003" -- Performance warning
end

local error_messages: {ErrorCode:string} = {
    E001 = "Feature not yet implemented",
    E002 = "Invalid command line option provided",
    E003 = "Required argument missing for option",
    E004 = "Input file not found or inaccessible",
    E005 = "Error reading input file",
    E006 = "Error writing output file",
    E007 = "Multiple input files are not supported",
    E008 = "No input file specified",
    E009 = "Lexical analysis failed",
    E010 = "Parse error in source code",
    E011 = "Code generation failed",
    E012 = "Compilation failed",
}

local warning_messages: {WarningCode:string} = {
    W001 = "Unused variable detected",
    W002 = "Deprecated feature usage",
    W003 = "Performance impact warning",
}

-- Module-level test mode flag and error buffer
local test_mode = false
local error_buffer: {string} = {}

local record Utils
    error: function(code: ErrorCode, details: string)
    warning: function(code: WarningCode, details: string)
    unimplemented: function(msg: string)
    set_test_mode: function(enabled: boolean)
    is_test_mode: function(): boolean
    get_error_buffer: function(): {string}
    clear_error_buffer: function()
end

function Utils.error(code: ErrorCode, details: string)
    local message = error_messages[code] or "Unknown error"
    local error_line = code .. ": " .. message
    table.insert(error_buffer, error_line)
    
    if details and details ~= "" then
        table.insert(error_buffer, details)
    end
    
    -- Check if we're in test mode to avoid os.exit()
    if test_mode then
        error("TEST_MODE_ERROR: " .. code .. ": " .. message)
    else
        -- In CLI mode, still print to stderr and exit
        io.stderr:write(error_line .. "\n")
        if details and details ~= "" then
            io.stderr:write(details .. "\n")
        end
        os.exit(1)
    end
end

function Utils.warning(code: WarningCode, details: string)
    local message = warning_messages[code] or "Unknown warning"
    local warning_line = code .. ": " .. message
    table.insert(error_buffer, warning_line)
    
    if details and details ~= "" then
        table.insert(error_buffer, details)
    end
    
    -- In CLI mode (not test mode), also print to stderr
    if not test_mode then
        io.stderr:write(warning_line .. "\n")
        if details and details ~= "" then
            io.stderr:write(details .. "\n")
        end
    end
end

function Utils.unimplemented(msg: string)
    Utils.error("E001", "UNIMPLEMENTED: " .. msg .. "\nThis feature is not yet implemented. Please do not use it!")
end

function Utils.set_test_mode(enabled: boolean)
    test_mode = enabled
end

function Utils.is_test_mode(): boolean
    return test_mode
end

function Utils.get_error_buffer(): {string}
    return error_buffer
end

function Utils.clear_error_buffer()
    error_buffer = {}
end

return {
    Utils = Utils,
    ErrorCode = ErrorCode,
    WarningCode = WarningCode,
}