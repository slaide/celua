local utils_module = require("utils")
local utils = utils_module.Utils
local ErrorCode = utils_module.ErrorCode
local compiler_module = require("compiler")
local compiler = compiler_module.Compiler
local CompilerConfig = compiler_module.CompilerConfig
local OutputMode = compiler_module.OutputMode

local record Args
    input_file: string
    output_file: string
    help: boolean
    version: boolean
    preprocess_only: boolean
    ast_output: boolean
    error_code_only: boolean
end

local function parse_args(args: {string}): Args
    local result: Args = {}
    local i = 1
    
    while i <= #args do
        local argument = args[i]
        
        if argument == "-h" or argument == "--help" then
            result.help = true
        elseif argument == "-v" or argument == "--version" then
            result.version = true
        elseif argument == "-E" then
            result.preprocess_only = true
        elseif argument == "--ast" then
            result.ast_output = true
        elseif argument == "--error-code-only" then
            result.error_code_only = true
        elseif argument == "-o" or argument == "--output" then
            i = i + 1
            if i <= #args then
                result.output_file = args[i]
            else
                utils.error("E003", "Option " .. argument .. " requires an argument")
            end
        elseif not argument:match("^%-") then
            if not result.input_file then
                result.input_file = argument
            else
                utils.error("E007", "Multiple input files not supported yet")
            end
        else
            utils.error("E002", "Unknown option: " .. argument)
        end
        
        i = i + 1
    end
    
    return result
end

local function show_help()
    print("celua - C23 compliant compiler")
    print("")
    print("USAGE:")
    print("    celua [OPTIONS] <INPUT_FILE>")
    print("")
    print("OPTIONS:")
    print("    -h, --help       Show this help message")
    print("    -v, --version    Show version information")
    print("    -o, --output     Specify output file")
    print("    -E               Run preprocessor only (up to phase 4)")
    print("    --ast            Output AST as JSON instead of compiled code")
    print("    --error-code-only    Only output error codes (e.g. E001), no descriptions")
    print("")
    print("COMPILATION MODES:")
    print("    Default          Parse and validate, output Lua code")
    print("    -E               Preprocessing only, output preprocessed C")
    print("    --ast            Parse and output AST as JSON")
    print("")
    print("EXAMPLES:")
    print("    celua main.c                    # Compile to Lua")
    print("    celua -o output.lua input.c     # Custom output file")
    print("    celua -E input.c                # Preprocess only")
    print("    celua --ast input.c             # Output AST as JSON")
    print("    celua --ast -o ast.json input.c # Save AST to file")
end

local function show_version()
    print("celua 0.1.0")
    print("A C23 compliant compiler written in Teal")
end

local function compile(args: Args)
    local file = io.open(args.input_file, "r")
    if not file then
        utils.error("E004", "Could not open input file: " .. args.input_file)
    end
    
    local file_content = file:read("*all")
    file:close()
    
    local output_mode: OutputMode = "lua_code"
    if args.preprocess_only then
        output_mode = "preprocessed"
    elseif args.ast_output then
        output_mode = "ast_json"
    end
    
    local config: CompilerConfig = {
        output_mode = output_mode,
        error_code_only = args.error_code_only,
        input_path = args.input_file,
        output_path = args.output_file
    }
    
    local result = compiler.process_file(args.input_file, file_content, config)
    
    if result.success then
        if args.output_file then
            local output_file = io.open(args.output_file, "w")
            if not output_file then
                utils.error("E006", "Could not open output file: " .. args.output_file)
            end
            output_file:write(result.output_content)
            output_file:close()
            print("Successfully compiled " .. args.input_file .. " to " .. args.output_file)
        else
            print(result.output_content)
        end
        
        -- Print warnings if any
        for i, warning_code in ipairs(result.warnings) do
            local warning_detail = result.warning_details[i] or ""
            if args.error_code_only then
                io.stderr:write(warning_code .. "\n")
            else
                utils.warning(warning_code, warning_detail)
            end
        end
    else
        if args.error_code_only then
            io.stderr:write(result.error_code .. "\n")
            os.exit(1)
        else
            local error_details = "Compilation failed"
            if output_mode == "preprocessed" then
                error_details = "UNIMPLEMENTED: C preprocessor (splicer and macro expansion) for file: " .. args.input_file .. "\nThis feature is not yet implemented. Please do not use it!"
            elseif output_mode == "ast_json" then
                error_details = "UNIMPLEMENTED: parsing C source to AST JSON for file: " .. args.input_file .. "\nThis feature is not yet implemented. Please do not use it!"
            else
                error_details = "UNIMPLEMENTED: lexical analysis for C23 source code\nThis feature is not yet implemented. Please do not use it!"
            end
            utils.error(result.error_code, error_details)
        end
    end
end

local function main()
    local args = parse_args(arg as {string})
    
    if args.help then
        show_help()
        return
    end
    
    if args.version then
        show_version()
        return
    end
    
    if not args.input_file then
        utils.error("E008", "Use --help for usage information")
    end
    
    if not args.output_file then
        local default_ext = ".lua"
        if args.preprocess_only then
            default_ext = ".i"
        elseif args.ast_output then
            default_ext = ".json"
        end
        args.output_file = args.input_file:gsub("%.c$", default_ext)
    end
    
    compile(args)
end

main()