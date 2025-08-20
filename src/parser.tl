local utils_module = require("utils")
local utils = utils_module.Utils
local lexer = require("lexer")

local record ASTNode
    type: string
end

local record Program
    type: string
    declarations: {ASTNode}
end

local record FunctionDeclaration
    type: string
    name: string
    parameters: {ASTNode}
    return_type: string
    body: ASTNode
end

local record VariableDeclaration
    type: string
    name: string
    var_type: string
    initializer: ASTNode
end

local record Expression
    type: string
end

local record BinaryExpression
    type: string
    operator: string
    left: ASTNode
    right: ASTNode
end

local record UnaryExpression
    type: string
    operator: string
    operand: ASTNode
end

local record Identifier
    type: string
    name: string
end

local record Literal
    type: string
    value: string
    literal_type: string
end

local record Parser
    tokens: {lexer.Token}
    current: integer
    
    new: function(self: Parser, tokens: {lexer.Token}): Parser
    parse: function(self: Parser): Program
    parse_declaration: function(self: Parser): ASTNode
    parse_function_declaration: function(self: Parser): FunctionDeclaration
    parse_variable_declaration: function(self: Parser): VariableDeclaration
    parse_statement: function(self: Parser): ASTNode
    parse_expression: function(self: Parser): Expression
end

function Parser:new(tokens: {lexer.Token}): Parser
    return setmetatable({
        tokens = tokens,
        current = 1
    }, {__index = Parser})
end

function Parser:parse(): Program
    utils.unimplemented("parsing C23 tokens into AST")
end

function Parser:parse_declaration(): ASTNode
    utils.unimplemented("parsing declarations")
end

function Parser:parse_function_declaration(): FunctionDeclaration
    utils.unimplemented("parsing function declarations")
end

function Parser:parse_variable_declaration(): VariableDeclaration
    utils.unimplemented("parsing variable declarations")
end

function Parser:parse_statement(): ASTNode
    utils.unimplemented("parsing statements")
end

function Parser:parse_expression(): Expression
    utils.unimplemented("parsing expressions")
end

return {
    Parser = Parser,
    Program = Program,
    FunctionDeclaration = FunctionDeclaration,
    VariableDeclaration = VariableDeclaration,
    Expression = Expression,
    BinaryExpression = BinaryExpression,
    UnaryExpression = UnaryExpression,
    Identifier = Identifier,
    Literal = Literal,
    ASTNode = ASTNode
}