local utils_module = require("utils")
local utils = utils_module.Utils
local parser = require("parser")

local record CodeGenerator
    output: {string}
    indent_level: integer
    
    new: function(self: CodeGenerator): CodeGenerator
    generate: function(self: CodeGenerator, ast: parser.Program): string
    emit: function(self: CodeGenerator, code: string)
    emit_line: function(self: CodeGenerator, code: string)
    indent: function(self: CodeGenerator)
    dedent: function(self: CodeGenerator)
    generate_function: function(self: CodeGenerator, node: parser.FunctionDeclaration): string
    generate_variable: function(self: CodeGenerator, node: parser.VariableDeclaration): string
    generate_expression: function(self: CodeGenerator, node: parser.Expression): string
end

function CodeGenerator:new(): CodeGenerator
    return setmetatable({
        output = {},
        indent_level = 0
    }, {__index = CodeGenerator})
end

function CodeGenerator:generate(ast: parser.Program): string
    utils.unimplemented("code generation from AST to Lua 5.1")
end

function CodeGenerator:emit(code: string)
    table.insert(self.output, string.rep("  ", self.indent_level) .. code)
end

function CodeGenerator:emit_line(code: string)
    self:emit(code .. "\n")
end

function CodeGenerator:indent()
    self.indent_level = self.indent_level + 1
end

function CodeGenerator:dedent()
    self.indent_level = math.max(0, self.indent_level - 1)
end

function CodeGenerator:generate_function(node: parser.FunctionDeclaration): string
    utils.unimplemented("function code generation")
end

function CodeGenerator:generate_variable(node: parser.VariableDeclaration): string
    utils.unimplemented("variable code generation")
end

function CodeGenerator:generate_expression(node: parser.Expression): string
    utils.unimplemented("expression code generation")
end

return {
    CodeGenerator = CodeGenerator
}