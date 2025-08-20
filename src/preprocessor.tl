local record Preprocessor
    splice: function(self: Preprocessor, content: string): string
    preprocess: function(self: Preprocessor, content: string): string
end

function Preprocessor:new(): Preprocessor
    return setmetatable({}, {__index = Preprocessor})
end

-- Implement line splicing: backslash-newline sequences are removed
function Preprocessor:splice(content: string): string
    local result = {}
    local i = 1
    local len = #content
    
    while i <= len do
        local char = content:sub(i, i)
        
        if char == '\\' and i < len then
            local next_char = content:sub(i + 1, i + 1)
            
            if next_char == '\n' then
                -- Skip backslash-newline sequence
                i = i + 2
            elseif next_char == '\r' and i + 1 < len and content:sub(i + 2, i + 2) == '\n' then
                -- Skip backslash-carriage-return-newline sequence
                i = i + 3
            else
                -- Not a line continuation, keep the backslash
                table.insert(result, char)
                i = i + 1
            end
        else
            -- Regular character, keep it
            table.insert(result, char)
            i = i + 1
        end
    end
    
    return table.concat(result)
end

-- Main preprocessing function (currently only implements splicing)
function Preprocessor:preprocess(content: string): string
    -- Phase 1: Line splicing (removing backslash-newline sequences)
    local spliced = self:splice(content)
    
    -- TODO: Phase 2: Trigraph replacement (if we want C90 compatibility)
    -- TODO: Phase 3: Tokenization and macro expansion
    -- TODO: Phase 4: Directive processing (#include, #define, etc.)
    
    return spliced
end

return {
    Preprocessor = Preprocessor
}