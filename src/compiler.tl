local utils_module = require("utils")
local utils = utils_module.Utils
local ErrorCode = utils_module.ErrorCode
local WarningCode = utils_module.WarningCode
local lexer = require("lexer")
local parser = require("parser")
local codegen = require("codegen")
local preprocessor = require("preprocessor")

local enum OutputMode
    "lua_code"      -- Default: compile to Lua
    "preprocessed"  -- -E flag: preprocessor output
    "ast_json"      -- --ast flag: AST as JSON
end

local record CompilerConfig
    output_mode: OutputMode
    error_code_only: boolean
    input_path: string
    output_path: string
end

local record CompilerResult
    success: boolean
    error_code: ErrorCode
    warnings: {WarningCode}
    warning_details: {string}
    output_content: string
    error_output: {string}  -- All error messages that would go to stderr
end

local record Compiler
    process_file: function(file_path: string, file_content: string, config: CompilerConfig): CompilerResult
    compile_file: function(input_path: string, output_path: string)
    compile_string: function(source: string): string
    preprocess_file: function(input_path: string, output_path: string)
    compile_to_ast: function(input_path: string, output_path: string)
end

function Compiler.process_file(file_path: string, file_content: string, config: CompilerConfig): CompilerResult
    -- Clear any previous error output
    utils.clear_error_buffer()
    
    local result: CompilerResult = {
        success = false,
        warnings = {},
        warning_details = {},
        output_content = "",
        error_output = {}
    }
    
    -- Wrap in pcall to catch test mode errors
    local success, err = pcall(function(): any
        if config.output_mode == "preprocessed" then
            -- Preprocessing phase (-E flag)
            local prep = preprocessor.Preprocessor:new()
            local preprocessed_content = prep:preprocess(file_content)
            result.success = true
            result.output_content = preprocessed_content
        elseif config.output_mode == "ast_json" then
            -- Parse to AST and output as JSON
            utils.unimplemented("parsing C source to AST JSON for file: " .. file_path)
        else
            -- Default: Full compilation to Lua
            -- Step 1: Tokenize (will fail - unimplemented)
            local lex = lexer.Lexer:new(file_content)
            local tokens = lex:tokenize()
            
            -- Step 2: Parse and validate
            local pars = parser.Parser:new(tokens)
            local ast = pars:parse()
            
            -- Step 3: Generate Lua code
            local generator = codegen.CodeGenerator:new()
            local lua_code = generator:generate(ast)
            
            result.success = true
            result.output_content = lua_code
        end
    end)
    
    if not success then
        -- Extract error code from test mode error
        local err_str = tostring(err)
        if err_str:match("^TEST_MODE_ERROR: ") then
            local error_code = err_str:match("^TEST_MODE_ERROR: ([^:]+):")
            result.error_code = error_code as ErrorCode or "E001"
        elseif err_str:match("TEST_MODE_ERROR:") then
            -- Handle nested test mode errors  
            local error_code = err_str:match("TEST_MODE_ERROR: ([^:]+):")
            result.error_code = error_code as ErrorCode or "E001"
        else
            -- Re-throw non-test errors
            error(err)
        end
    end
    
    -- Always include error buffer in result
    result.error_output = utils.get_error_buffer()
    
    return result
end

function Compiler.compile_file(input_path: string, output_path: string)
    local file = io.open(input_path, "r")
    if not file then
        error("Could not open input file: " .. input_path)
    end
    
    local source = file:read("*all")
    file:close()
    
    local result = Compiler.compile_string(source)
    
    local output_file = io.open(output_path, "w")
    if not output_file then
        error("Could not open output file: " .. output_path)
    end
    
    output_file:write(result)
    output_file:close()
    
    print("Successfully compiled " .. input_path .. " to " .. output_path)
end

function Compiler.compile_string(source: string): string
    local lex = lexer.Lexer:new(source)
    local tokens = lex:tokenize()
    
    local pars = parser.Parser:new(tokens)
    local ast = pars:parse()
    
    local generator = codegen.CodeGenerator:new()
    local lua_code = generator:generate(ast)
    
    return lua_code
end

function Compiler.preprocess_file(input_path: string, output_path: string)
    utils.unimplemented("preprocessing C source file from " .. input_path .. " to " .. output_path)
end

function Compiler.compile_to_ast(input_path: string, output_path: string)
    utils.unimplemented("compiling C source to AST JSON from " .. input_path .. " to " .. output_path)
end

return {
    Compiler = Compiler,
    CompilerConfig = CompilerConfig,
    CompilerResult = CompilerResult,
    OutputMode = OutputMode
}