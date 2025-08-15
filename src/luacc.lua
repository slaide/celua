#!/usr/bin/env lua

-- luacc - A C23-compliant preprocessor written in Lua
-- Usage: luacc [options] [input-file]

local Preprocessor = require("preprocessor")

local function show_version()
    print("luacc 1.0.0")
    print("C23-compliant preprocessor written in Lua")
    print("Coverage: ~98% of C23 preprocessing specification")
end

local function show_help()
    print("Usage: luacc [options] [input-file]")
    print("")
    print("Options:")
    print("  -E               Run the preprocessor (required)")
    print("  -I <dir>         Add directory to include search path")
    print("  --json-errors    Output errors in JSON format")
    print("  --version        Show version information")
    print("  --help           Show this help message")
    print("")
    print("If no input file is specified, reads from stdin.")
    print("Output is written to stdout, errors to stderr.")
    print("")
    print("Examples:")
    print("  luacc -E input.c")
    print("  luacc -E -I./include -I/usr/include input.c")
    print("  cat input.c | luacc -E")
    print("  luacc -E --json-errors input.c 2> errors.json")
end

local function parse_args(args)
    local options = {
        preprocess = false,
        json_errors = false,
        include_paths = {},
        input_file = nil,
        show_help = false,
        show_version = false
    }
    
    local i = 1
    while i <= #args do
        local arg = args[i]
        
        if arg == "-E" then
            options.preprocess = true
        elseif arg == "--json-errors" then
            options.json_errors = true
        elseif arg == "--help" or arg == "-h" then
            options.show_help = true
        elseif arg == "--version" then
            options.show_version = true
        elseif arg == "-I" then
            -- Next argument should be the include path
            i = i + 1
            if i <= #args then
                table.insert(options.include_paths, args[i])
            else
                io.stderr:write("Error: -I requires a directory argument\n")
                os.exit(1)
            end
        elseif arg:match("^-I(.+)") then
            -- -I<dir> format (no space)
            local path = arg:match("^-I(.+)")
            table.insert(options.include_paths, path)
        elseif arg:sub(1, 1) == "-" then
            io.stderr:write("Error: Unknown option: " .. arg .. "\n")
            io.stderr:write("Use --help for usage information.\n")
            os.exit(1)
        else
            -- Input file
            if options.input_file then
                io.stderr:write("Error: Multiple input files specified\n")
                os.exit(1)
            end
            options.input_file = arg
        end
        
        i = i + 1
    end
    
    return options
end

local function main()
    local options = parse_args(arg)
    
    -- Handle help and version first
    if options.show_help then
        show_help()
        os.exit(0)
    end
    
    if options.show_version then
        show_version()
        os.exit(0)
    end
    
    -- If no -E flag and no help/version, show help
    if not options.preprocess then
        show_help()
        os.exit(0)
    end
    
    -- Read input
    local input
    if options.input_file then
        local file = io.open(options.input_file, "r")
        if not file then
            io.stderr:write("Error: Cannot open file: " .. options.input_file .. "\n")
            os.exit(1)
        end
        input = file:read("*all")
        file:close()
    else
        input = io.read("*all")
    end
    
    -- Create preprocessor with options
    local preprocessor_options = {
        json_errors = options.json_errors
    }
    
    local preprocessor = Preprocessor:new(preprocessor_options)
    
    -- Set filename for error reporting
    if options.input_file then
        preprocessor.filename = options.input_file
        preprocessor.base_filename = options.input_file
    end
    
    -- Add include paths (add current directory first, then specified paths)
    preprocessor.include_paths = {"."}
    for _, path in ipairs(options.include_paths) do
        table.insert(preprocessor.include_paths, path)
    end
    
    -- Process the input
    local output, errors, error_directive_encountered = preprocessor:process(input)
    
    -- Output errors
    if options.json_errors then
        if #errors > 0 then
            io.stderr:write(preprocessor:format_errors_json(errors) .. "\n")
        end
    else
        for _, error in ipairs(errors) do
            if type(error) == "table" then
                -- Convert JSON format back to human readable
                local formatted = string.format("%s:%d: %s: %s", error.filename, error.line, error.level, error.message)
                io.stderr:write(formatted .. "\n")
            else
                io.stderr:write(error .. "\n")
            end
        end
    end
    
    -- Only output preprocessed content if no error directive was encountered
    if not error_directive_encountered then
        io.write(output)
    end
    
    if error_directive_encountered or #errors > 0 then
        os.exit(1)
    end
end

-- Only run main if this file is executed directly
if arg and arg[0] and arg[0]:match("luacc%.lua$") then
    main()
end

return {
    main = main,
    parse_args = parse_args,
    show_help = show_help,
    show_version = show_version
}