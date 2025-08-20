local utils_module = require("utils")
local utils = utils_module.Utils

local enum TokenType
    "EOF"
    "IDENTIFIER"
    "INTEGER"
    "FLOAT"
    "STRING"
    "CHAR"
    
    "PLUS"
    "MINUS"
    "MULTIPLY"
    "DIVIDE"
    "MODULO"
    
    "ASSIGN"
    "EQUAL"
    "NOT_EQUAL"
    "LESS"
    "LESS_EQUAL"
    "GREATER"
    "GREATER_EQUAL"
    
    "LOGICAL_AND"
    "LOGICAL_OR"
    "LOGICAL_NOT"
    
    "BITWISE_AND"
    "BITWISE_OR"
    "BITWISE_XOR"
    "BITWISE_NOT"
    "LEFT_SHIFT"
    "RIGHT_SHIFT"
    
    "INCREMENT"
    "DECREMENT"
    
    "LEFT_PAREN"
    "RIGHT_PAREN"
    "LEFT_BRACE"
    "RIGHT_BRACE"
    "LEFT_BRACKET"
    "RIGHT_BRACKET"
    
    "SEMICOLON"
    "COMMA"
    "DOT"
    "ARROW"
    
    "IF"
    "ELSE"
    "WHILE"
    "FOR"
    "DO"
    "BREAK"
    "CONTINUE"
    "RETURN"
    "SWITCH"
    "CASE"
    "DEFAULT"
    
    "INT"
    "FLOAT_TYPE"
    "DOUBLE"
    "CHAR_TYPE"
    "VOID"
    "CONST"
    "STATIC"
    "EXTERN"
    "AUTO"
    "REGISTER"
    "VOLATILE"
    
    "STRUCT"
    "UNION"
    "ENUM"
    "TYPEDEF"
    "SIZEOF"
    
    "INCLUDE"
    "DEFINE"
    "IFDEF"
    "IFNDEF"
    "ENDIF"
    "ELSE_PP"
    "ELIF"
end

local record Token
    type: TokenType
    value: string
    line: integer
    column: integer
end

local record Lexer
    source: string
    position: integer
    line: integer
    column: integer
    tokens: {Token}
    
    new: function(self: Lexer, source: string): Lexer
    tokenize: function(self: Lexer): {Token}
end

function Lexer:new(source: string): Lexer
    return setmetatable({
        source = source,
        position = 1,
        line = 1,
        column = 1,
        tokens = {}
    }, {__index = Lexer})
end

function Lexer:tokenize(): {Token}
    utils.unimplemented("lexical analysis for C23 source code")
end

return {
    Lexer = Lexer,
    Token = Token,
    TokenType = TokenType
}