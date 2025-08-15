#!/usr/bin/env lua

local Preprocessor = {}
Preprocessor.__index = Preprocessor

function Preprocessor:new(options)
    local self = setmetatable({}, Preprocessor)
    self.defines = {}
    self.include_paths = {"."}
    self.condition_stack = {}
    self.line_number = 0
    self.column_number = 1
    self.filename = "<stdin>"
    self.base_filename = "<stdin>"  -- Track the original input file
    self.counter = 0  -- For __COUNTER__ macro
    self.output = {}
    self.errors = {}
    self.in_block_comment = false
    self.json_errors = (options and options.json_errors) or false
    self.error_directive_encountered = false
    self:init_predefined_macros()
    return self
end

function Preprocessor:init_predefined_macros()
    -- Initialize predefined macros
    local now = os.date("*t")
    
    -- __DATE__ - "Mmm dd yyyy" format
    local months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
                   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
    local date_str = string.format("\"%s %2d %d\"", months[now.month], now.day, now.year)
    
    -- __TIME__ - "hh:mm:ss" format
    local time_str = string.format("\"%02d:%02d:%02d\"", now.hour, now.min, now.sec)
    
    self.defines["__STDC__"] = {type = "object", value = "1"}
    self.defines["__STDC_VERSION__"] = {type = "object", value = "202311"}  -- C23 (without L suffix for evaluation)
    self.defines["__DATE__"] = {type = "object", value = date_str}
    self.defines["__TIME__"] = {type = "object", value = time_str}
    
    -- Add placeholder defines for dynamic macros so they're recognized in #ifdef
    self.defines["__FILE__"] = {type = "object", value = ""}  -- Placeholder, expanded dynamically
    self.defines["__LINE__"] = {type = "object", value = ""}  -- Placeholder, expanded dynamically  
    self.defines["__COUNTER__"] = {type = "object", value = ""} -- Placeholder, expanded dynamically
    self.defines["__BASE_FILE__"] = {type = "object", value = ""} -- Placeholder, expanded dynamically
    self.defines["__TIMESTAMP__"] = {type = "object", value = ""} -- Placeholder, expanded dynamically
    
    -- Feature detection macros (C++17/C23 standard and Clang extensions)
    self.defines["__has_include"] = {type = "object", value = "1"} -- Available as feature detection
    self.defines["__has_feature"] = {type = "object", value = "1"} -- Available as feature detection
end

function Preprocessor:error(msg, code, column)
    self:add_diagnostic("error", msg, code or "E999", column)
end

function Preprocessor:warning(msg, code, column)
    self:add_diagnostic("warning", msg, code or "W999", column)
end

function Preprocessor:add_diagnostic(level, msg, code, column)
    local col = column or self.column_number
    if self.json_errors then
        local diagnostic = {
            level = level,
            code = code,
            filename = self.filename,
            line = self.line_number,
            column = col,
            message = msg
        }
        table.insert(self.errors, diagnostic)
    else
        local formatted = string.format("%s:%d:%d: %s: %s", self.filename, self.line_number, col, level, msg)
        table.insert(self.errors, formatted)
    end
end

function Preprocessor:trim(s)
    return s:match("^%s*(.-)%s*$")
end

function Preprocessor:find_column_of_pattern(line, pattern)
    -- Find the column position where a pattern starts in a line
    local start_pos = line:find(pattern)
    if start_pos then
        return start_pos
    end
    return 1  -- Default to column 1 if not found
end

function Preprocessor:remove_comments(line)
    local result = ""
    local i = 1
    local in_string = false
    local escape_next = false
    
    -- If we're already in a block comment from a previous line
    if self.in_block_comment then
        result = " "  -- Replace the entire line with space if still in comment
        
        -- Look for end of block comment
        while i <= #line - 1 do
            if line:sub(i, i) == "*" and line:sub(i + 1, i + 1) == "/" then
                self.in_block_comment = false
                i = i + 2
                break
            end
            i = i + 1
        end
        
        -- If comment ends, process the rest of the line
        if not self.in_block_comment and i <= #line then
            result = result .. self:remove_comments(line:sub(i))
        end
        
        return result
    end
    
    while i <= #line do
        local c = line:sub(i, i)
        local next_c = i < #line and line:sub(i + 1, i + 1) or ""
        
        if escape_next then
            result = result .. c
            escape_next = false
            i = i + 1
        elseif c == "\\" and in_string then
            result = result .. c
            escape_next = true
            i = i + 1
        elseif c == '"' and not escape_next then
            in_string = not in_string
            result = result .. c
            i = i + 1
        elseif not in_string and c == "/" then
            if next_c == "*" then
                -- Start of block comment
                result = result .. " "
                i = i + 2
                
                -- Find end of comment
                while i <= #line - 1 do
                    if line:sub(i, i) == "*" and line:sub(i + 1, i + 1) == "/" then
                        i = i + 2
                        break
                    end
                    i = i + 1
                end
                
                -- If comment doesn't end on this line, mark as in comment
                if i > #line then
                    self.in_block_comment = true
                    break
                end
            elseif next_c == "/" then
                -- Start of line comment - consume rest of line
                result = result .. " "
                break
            else
                result = result .. c
                i = i + 1
            end
        else
            result = result .. c
            i = i + 1
        end
    end
    
    return result
end

function Preprocessor:split_args(args_str)
    local args = {}
    local current = ""
    local paren_count = 0
    local in_string = false
    local escape_next = false
    
    for i = 1, #args_str do
        local c = args_str:sub(i, i)
        
        if escape_next then
            current = current .. c
            escape_next = false
        elseif c == "\\" then
            current = current .. c
            escape_next = true
        elseif c == '"' and not escape_next then
            in_string = not in_string
            current = current .. c
        elseif not in_string then
            if c == "(" then
                paren_count = paren_count + 1
                current = current .. c
            elseif c == ")" then
                paren_count = paren_count - 1
                current = current .. c
            elseif c == "," and paren_count == 0 then
                table.insert(args, self:trim(current))
                current = ""
            else
                current = current .. c
            end
        else
            current = current .. c
        end
    end
    
    if current ~= "" then
        table.insert(args, self:trim(current))
    end
    
    return args
end

function Preprocessor:expand_macro(name, args)
    local macro = self.defines[name]
    if not macro then
        return name
    end
    
    if macro.type == "object" then
        return macro.value
    elseif macro.type == "function" then
        if not args then
            self:error("macro '" .. name .. "' requires arguments")
            return name
        end
        
        local result = macro.value
        for i, param in ipairs(macro.params) do
            local arg = args[i] or ""
            result = result:gsub("%%" .. param .. "%%", arg)
        end
        return result
    end
    
    return name
end

function Preprocessor:tokenize_line(line)
    local tokens = {}
    local current = ""
    local in_string = false
    local escape_next = false
    
    for i = 1, #line do
        local c = line:sub(i, i)
        
        if escape_next then
            current = current .. c
            escape_next = false
        elseif c == "\\" then
            current = current .. c
            escape_next = true
        elseif c == '"' then
            in_string = not in_string
            current = current .. c
        elseif not in_string and c:match("%s") then
            if current ~= "" then
                table.insert(tokens, current)
                current = ""
            end
        else
            current = current .. c
        end
    end
    
    if current ~= "" then
        table.insert(tokens, current)
    end
    
    return tokens
end

function Preprocessor:expand_line(line)
    local result = line
    local changed = true
    local max_iterations = 100
    local iterations = 0
    
    while changed and iterations < max_iterations do
        changed = false
        iterations = iterations + 1
        local new_result = ""
        local i = 1
        local in_string = false
        local escape_next = false
        
        while i <= #result do
            local c = result:sub(i, i)
            local matched = false
            
            -- Handle string state
            if escape_next then
                escape_next = false
            elseif c == "\\" and in_string then
                escape_next = true
            elseif c == '"' and not escape_next then
                in_string = not in_string
            end
            
            -- Only expand macros outside of strings
            if not in_string then
                -- Handle dynamic predefined macros first
                if result:sub(i, i + 7) == "__FILE__" and
                   (i == 1 or not result:sub(i - 1, i - 1):match("[%w_]")) and
                   (i + 8 > #result or not result:sub(i + 8, i + 8):match("[%w_]")) then
                    new_result = new_result .. '"' .. self.filename .. '"'
                    i = i + 8
                    matched = true
                    changed = true
                elseif result:sub(i, i + 7) == "__LINE__" and
                       (i == 1 or not result:sub(i - 1, i - 1):match("[%w_]")) and
                       (i + 8 > #result or not result:sub(i + 8, i + 8):match("[%w_]")) then
                    new_result = new_result .. tostring(self.line_number)
                    i = i + 8
                    matched = true
                    changed = true
                elseif result:sub(i, i + 10) == "__COUNTER__" and
                       (i == 1 or not result:sub(i - 1, i - 1):match("[%w_]")) and
                       (i + 11 > #result or not result:sub(i + 11, i + 11):match("[%w_]")) then
                    new_result = new_result .. tostring(self.counter)
                    self.counter = self.counter + 1  -- Increment after use
                    i = i + 11
                    matched = true
                    changed = true
                elseif result:sub(i, i + 12) == "__BASE_FILE__" and
                       (i == 1 or not result:sub(i - 1, i - 1):match("[%w_]")) and
                       (i + 13 > #result or not result:sub(i + 13, i + 13):match("[%w_]")) then
                    new_result = new_result .. '"' .. self.base_filename .. '"'
                    i = i + 13
                    matched = true
                    changed = true
                elseif result:sub(i, i + 12) == "__TIMESTAMP__" and
                       (i == 1 or not result:sub(i - 1, i - 1):match("[%w_]")) and
                       (i + 13 > #result or not result:sub(i + 13, i + 13):match("[%w_]")) then
                    -- Generate timestamp in the format: "Sun Sep 16 01:03:52 1973"
                    local timestamp_str = os.date('"%a %b %d %H:%M:%S %Y"')
                    new_result = new_result .. timestamp_str
                    i = i + 13
                    matched = true
                    changed = true
                elseif result:sub(i, i + 6) == "_Pragma" and
                       (i == 1 or not result:sub(i - 1, i - 1):match("[%w_]")) and
                       (i + 7 <= #result and result:sub(i + 7, i + 7):match("[%s%(]")) then
                    -- Handle _Pragma operator: _Pragma("string")
                    local remaining = result:sub(i)
                    local full_match, pragma_content = remaining:match("^(_Pragma%s*%(%s*\"([^\"]*)\"%s*%))") 
                    if full_match and pragma_content then
                        -- Destringize: replace \\ with \ and \" with "
                        local destringized = pragma_content:gsub("\\\\", "\\"):gsub("\\\"", "\"")
                        -- Process as pragma directive
                        self:process_pragma("#pragma " .. destringized)
                        -- Skip the entire _Pragma(...) expression
                        i = i + #full_match
                        matched = true
                        changed = true
                    end
                elseif result:sub(i, i + 12) == "__has_include" and
                       (i == 1 or not result:sub(i - 1, i - 1):match("[%w_]")) and
                       (i + 13 <= #result and result:sub(i + 13, i + 13):match("[%s%(]")) then
                    -- Handle __has_include(<header>) or __has_include("header")
                    local remaining = result:sub(i)
                    local full_match, angle_header = remaining:match("^(__has_include%s*%(%s*<([^>]+)>%s*%))") 
                    local quote_header
                    if not full_match then
                        full_match, quote_header = remaining:match("^(__has_include%s*%(%s*\"([^\"]+)\"%s*%))") 
                    end
                    
                    if full_match then
                        local header = angle_header or quote_header
                        local is_system = angle_header ~= nil
                        local found = self:check_header_exists(header, is_system)
                        new_result = new_result .. (found and "1" or "0")
                        i = i + #full_match
                        matched = true
                        changed = true
                    end
                elseif result:sub(i, i + 12) == "__has_feature" and
                       (i == 1 or not result:sub(i - 1, i - 1):match("[%w_]")) and
                       (i + 13 <= #result and result:sub(i + 13, i + 13):match("[%s%(]")) then
                    -- Handle __has_feature(feature_name)
                    local remaining = result:sub(i)
                    local full_match, feature_name = remaining:match("^(__has_feature%s*%(%s*([%w_]+)%s*%))")
                    
                    if full_match then
                        local supported = self:check_feature_support(feature_name)
                        new_result = new_result .. (supported and "1" or "0")
                        i = i + #full_match
                        matched = true
                        changed = true
                    end
                end
                
                -- If not matched by dynamic macros, check regular macros
                if not matched then
                    -- Sort macros by name length (longest first) to handle overlapping names
                    local macro_names = {}
                    for name, _ in pairs(self.defines) do
                        table.insert(macro_names, name)
                    end
                    table.sort(macro_names, function(a, b) return #a > #b end)
                
                    for _, name in ipairs(macro_names) do
                        local macro = self.defines[name]
                        if result:sub(i, i + #name - 1) == name then
                            if macro.type == "object" then
                                if (i == 1 or not result:sub(i - 1, i - 1):match("[%w_]")) and
                                   (i + #name > #result or not result:sub(i + #name, i + #name):match("[%w_]")) then
                                new_result = new_result .. macro.value
                                i = i + #name
                                matched = true
                                changed = true
                                break
                            end
                        elseif macro.type == "function" then
                            if i + #name <= #result and result:sub(i + #name, i + #name) == "(" then
                                local paren_count = 1
                                local j = i + #name + 1
                                while j <= #result and paren_count > 0 do
                                    if result:sub(j, j) == "(" then
                                        paren_count = paren_count + 1
                                    elseif result:sub(j, j) == ")" then
                                        paren_count = paren_count - 1
                                    end
                                    j = j + 1
                                end
                                
                                if paren_count == 0 then
                                    local args_str = result:sub(i + #name + 1, j - 2)
                                    local args = self:split_args(args_str)
                                    
                                    local expanded = macro.value
                                    
                                    -- Step 1: Handle stringification first (#param and #__VA_ARGS__)
                                    -- Handle variadic stringification
                                    if macro.is_variadic then
                                        local variadic_args = {}
                                        for k = #macro.params + 1, #args do
                                            table.insert(variadic_args, args[k])
                                        end
                                        local va_args = table.concat(variadic_args, ", ")
                                        local va_stringified = '"' .. va_args:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
                                        expanded = expanded:gsub("([^#])#%s*__VA_ARGS__%f[^%w_]", "%1" .. va_stringified)
                                        expanded = expanded:gsub("^#%s*__VA_ARGS__%f[^%w_]", va_stringified)
                                    end
                                    
                                    -- Handle parameter stringification
                                    for k, param in ipairs(macro.params) do
                                        local arg = args[k] or ""
                                        local stringified = '"' .. arg:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
                                        -- Make sure we don't match ## patterns by requiring the # not to be preceded by #
                                        expanded = expanded:gsub("([^#])#%s*" .. param .. "%f[^%w_]", "%1" .. stringified)
                                        -- Also handle # at start of line/string
                                        expanded = expanded:gsub("^#%s*" .. param .. "%f[^%w_]", stringified)
                                    end
                                    
                                    -- Step 2: Handle normal parameter substitution  
                                    -- Handle variadic substitution
                                    if macro.is_variadic then
                                        local variadic_args = {}
                                        for k = #macro.params + 1, #args do
                                            table.insert(variadic_args, args[k])
                                        end
                                        local va_args = table.concat(variadic_args, ", ")
                                        local has_va_args = #variadic_args > 0 and va_args ~= ""
                                        
                                        -- Handle __VA_OPT__(content) - expands to content if variadic args exist
                                        if has_va_args then
                                            -- Replace __VA_OPT__(content) with content
                                            expanded = expanded:gsub("__VA_OPT__%s*%(%s*([^)]*)%s*%)", "%1")
                                        else
                                            -- Remove __VA_OPT__(content) entirely if no variadic args
                                            expanded = expanded:gsub("__VA_OPT__%s*%(%s*[^)]*%s*%)", "")
                                        end
                                        
                                        local escaped_va_args = va_args:gsub("%%", "%%%%")
                                        expanded = expanded:gsub("%f[%w_]__VA_ARGS__%f[^%w_]", escaped_va_args)
                                    end
                                    
                                    -- Handle normal parameter substitution
                                    for k, param in ipairs(macro.params) do
                                        local arg = args[k] or ""
                                        -- Escape % characters in replacement to prevent gsub interpretation
                                        local escaped_arg = arg:gsub("%%", "%%%%")
                                        expanded = expanded:gsub("%f[%w_]" .. param .. "%f[^%w_]", escaped_arg)
                                    end
                                    
                                    -- Step 3: Handle token pasting (##) - after parameter substitution
                                    expanded = expanded:gsub("%s*##%s*", "")
                                    
                                    new_result = new_result .. expanded
                                    i = j
                                    matched = true
                                    changed = true
                                    break
                                end
                            end
                        end
                    end
                    end
                end
            end
            
            if not matched then
                new_result = new_result .. result:sub(i, i)
                i = i + 1
            end
        end
        
        result = new_result
    end
    
    return result
end

function Preprocessor:process_include(directive)
    -- Determine include type and extract filename
    local local_include = directive:match('#include%s*"([^"]+)"')
    local system_include = directive:match('#include%s*<([^>]+)>')
    
    local filename, is_system
    if local_include then
        filename = local_include
        is_system = false
    elseif system_include then
        filename = system_include
        is_system = true
    else
        local col = self:find_column_of_pattern(directive, "#include")
        self:error("malformed #include directive", "E101", col)
        return
    end
    
    -- Check if this file was marked with #pragma once
    if self.pragma_once_files and self.pragma_once_files[filename] then
        -- File has #pragma once and was already included, skip it
        return
    end
    
    local file_content = self:read_file(filename, is_system)
    if file_content then
        local old_filename = self.filename
        local old_line_number = self.line_number
        
        self.filename = filename
        self.line_number = 0
        
        for line in file_content:gmatch("[^\r\n]*") do
            self.line_number = self.line_number + 1
            self:process_line(line)
        end
        
        self.filename = old_filename
        self.line_number = old_line_number
    else
        self:error("file '" .. filename .. "' not found", "E102")
    end
end

function Preprocessor:read_file(filename, is_system)
    if is_system then
        -- For system includes (<>), search only in include paths (skip current directory)
        for i = 2, #self.include_paths do  -- Skip index 1 which is usually "."
            local path = self.include_paths[i]
            local full_path = path .. "/" .. filename
            local file = io.open(full_path, "r")
            if file then
                local content = file:read("*all")
                file:close()
                return content
            end
        end
    else
        -- For local includes (""), search current directory first, then include paths
        for _, path in ipairs(self.include_paths) do
            local full_path = path .. "/" .. filename
            local file = io.open(full_path, "r")
            if file then
                local content = file:read("*all")
                file:close()
                return content
            end
        end
    end
    return nil
end

function Preprocessor:check_header_exists(filename, is_system)
    -- Check if a header file exists without reading it (for __has_include)
    if is_system then
        -- For system includes (<>), search only in include paths (skip current directory)
        for i = 2, #self.include_paths do  -- Skip index 1 which is usually "."
            local path = self.include_paths[i]
            local full_path = path .. "/" .. filename
            local file = io.open(full_path, "r")
            if file then
                file:close()
                return true
            end
        end
    else
        -- For local includes (""), search current directory first, then include paths
        for _, path in ipairs(self.include_paths) do
            local full_path = path .. "/" .. filename
            local file = io.open(full_path, "r")
            if file then
                file:close()
                return true
            end
        end
    end
    return false
end

function Preprocessor:check_feature_support(feature_name)
    -- Check if a language feature is supported (for __has_feature)
    -- This is a basic implementation supporting common C features
    local supported_features = {
        -- C standard features that this preprocessor supports
        c_static_assert = true,
        c_generic_selections = false,
        c_atomic = false,
        c_thread_local = false,
        c_alignas = false,
        c_alignof = false,
        c_variadic_macros = true,
        
        -- Preprocessor features
        c_preprocessor = true,
        c_pragma_operator = true,  -- _Pragma
        
        -- GNU/Clang specific features (mostly unsupported)
        gnu_inline = false,
        gnu_statement_expression = false,
        clang_version = false,
    }
    
    return supported_features[feature_name] or false
end

function Preprocessor:process_define(directive)
    local content = directive:match('#define%s+(.*)')
    if not content then
        local col = self:find_column_of_pattern(directive, "#define")
        self:error("malformed #define directive", "E103", col)
        return
    end
    
    local name, rest = content:match("^([%w_]+)%s*(.*)")
    if not name then
        local col = self:find_column_of_pattern(directive, "#define")
        self:error("malformed #define directive", "E103", col)
        return
    end
    
    if content:match("^[%w_]+%(") then
        local func_name, params_str, value = content:match("^([%w_]+)%(([^)]*)%)%s*(.*)")
        if func_name then
            local params = {}
            local is_variadic = false
            if params_str ~= "" then
                for param in params_str:gmatch("[^,]+") do
                    local trimmed = self:trim(param)
                    if trimmed == "..." then
                        is_variadic = true
                        -- Don't add ... to params list, it's handled specially
                    else
                        table.insert(params, trimmed)
                    end
                end
            end
            
            -- Remove comments from macro value
            value = self:remove_comments(value or "")
            
            self.defines[func_name] = {
                type = "function",
                params = params,
                value = value,
                is_variadic = is_variadic
            }
        else
            self:error("malformed function-like macro", "E104")
        end
    else
        -- Remove comments from macro value
        rest = self:remove_comments(rest)
        
        self.defines[name] = {
            type = "object",
            value = rest
        }
    end
end

function Preprocessor:process_undef(directive)
    local name = directive:match('#undef%s+([%w_]+)')
    if name then
        self.defines[name] = nil
    else
        self:error("malformed #undef directive", "E105")
    end
end

function Preprocessor:process_error(directive)
    local message = directive:match('#error%s*(.*)')
    if not message then
        message = ""
    end
    -- Remove quotes if present
    message = message:gsub('^"(.*)"$', '%1')
    self:error(message, "E200")
    
    -- Mark that an error directive was encountered but continue processing
    self.error_directive_encountered = true
end

function Preprocessor:process_warning(directive)
    local message = directive:match('#warning%s*(.*)')
    if not message then
        message = ""
    end
    -- Remove quotes if present
    message = message:gsub('^"(.*)"$', '%1')
    self:warning(message, "W200")
end

function Preprocessor:process_pragma(directive)
    local content = directive:match('#pragma%s+(.*)')
    if not content then
        local col = self:find_column_of_pattern(directive, "#pragma")
        self:warning("malformed #pragma directive", "W002", col)
        return
    end
    
    -- Parse pragma directive
    local pragma_name = content:match("^([%w_]+)")
    
    if pragma_name == "once" then
        -- #pragma once - include guard
        if not self.pragma_once_files then
            self.pragma_once_files = {}
        end
        self.pragma_once_files[self.filename] = true
        
    elseif pragma_name == "pack" then
        -- #pragma pack - structure packing (just issue a warning that it's not fully supported)
        self:warning("pragma pack is recognized but not implemented", "W003")
        
    elseif pragma_name == "GCC" then
        -- #pragma GCC diagnostic - warning control (just issue a warning)
        self:warning("pragma GCC diagnostic is recognized but not implemented", "W004")
        
    else
        -- Unknown pragma - just pass through silently (this is standard behavior)
        self:warning("unknown pragma '" .. (pragma_name or content) .. "' ignored", "W005")
    end
end

function Preprocessor:evaluate_condition(expr)
    expr = self:trim(expr)
    
    local function expand_defined(e)
        e = e:gsub("defined%s*%(%s*([%w_]+)%s*%)", function(name)
            return self.defines[name] and "1" or "0"
        end)
        e = e:gsub("defined%s+([%w_]+)", function(name)
            return self.defines[name] and "1" or "0"
        end)
        return e
    end
    
    expr = expand_defined(expr)
    expr = self:expand_line(expr)
    
    local result = load("return " .. expr)
    if result then
        local ok, value = pcall(result)
        if ok then
            return value and value ~= 0
        end
    end
    
    if expr:match("^[%w_]+$") then
        local macro = self.defines[expr]
        if macro and macro.value ~= "0" and macro.value ~= "" then
            return true
        end
        return false
    end
    
    return false
end

function Preprocessor:process_conditional(directive)
    local condition_type = directive:match("^#(%w+)")
    
    if condition_type == "if" then
        local expr = directive:match("#if%s+(.*)")
        local result = self:evaluate_condition(expr)
        table.insert(self.condition_stack, {
            type = "if", 
            active = result, 
            has_else = false,
            any_branch_taken = result
        })
    elseif condition_type == "ifdef" then
        local name = directive:match("#ifdef%s+([%w_]+)")
        local result = self.defines[name] ~= nil
        table.insert(self.condition_stack, {
            type = "ifdef", 
            active = result, 
            has_else = false,
            any_branch_taken = result
        })
    elseif condition_type == "ifndef" then
        local name = directive:match("#ifndef%s+([%w_]+)")
        local result = self.defines[name] == nil
        table.insert(self.condition_stack, {
            type = "ifndef", 
            active = result, 
            has_else = false,
            any_branch_taken = result
        })
    elseif condition_type == "elif" then
        if #self.condition_stack == 0 then
            self:error("#elif without matching #if", "E106")
            return
        end
        local current = self.condition_stack[#self.condition_stack]
        if current.has_else then
            self:error("#elif after #else", "E107")
            current.active = false
            return
        end
        
        local expr = directive:match("#elif%s+(.*)")
        local result = self:evaluate_condition(expr)
        -- elif is active only if no previous branch was taken AND condition is true
        current.active = (not current.any_branch_taken) and result
        if current.active then
            current.any_branch_taken = true
        end
    elseif condition_type == "elifdef" then
        if #self.condition_stack == 0 then
            self:error("#elifdef without matching #if", "E106")
            return
        end
        local current = self.condition_stack[#self.condition_stack]
        if current.has_else then
            self:error("#elifdef after #else", "E107")
            current.active = false
            return
        end
        
        local name = directive:match("#elifdef%s+([%w_]+)")
        local result = self.defines[name] ~= nil
        current.active = (not current.any_branch_taken) and result
        if current.active then
            current.any_branch_taken = true
        end
    elseif condition_type == "elifndef" then
        if #self.condition_stack == 0 then
            self:error("#elifndef without matching #if", "E106")
            return
        end
        local current = self.condition_stack[#self.condition_stack]
        if current.has_else then
            self:error("#elifndef after #else", "E107")
            current.active = false
            return
        end
        
        local name = directive:match("#elifndef%s+([%w_]+)")
        local result = self.defines[name] == nil
        current.active = (not current.any_branch_taken) and result
        if current.active then
            current.any_branch_taken = true
        end
    elseif condition_type == "else" then
        if #self.condition_stack == 0 then
            self:error("#else without matching #if", "E108")
            return
        end
        local current = self.condition_stack[#self.condition_stack]
        if current.has_else then
            self:error("multiple #else directives", "E109")
            current.active = false
            return
        end
        -- else is active only if no previous branch was taken
        current.active = not current.any_branch_taken
        current.has_else = true
    elseif condition_type == "endif" then
        if #self.condition_stack == 0 then
            self:error("#endif without matching #if", "E110")
            return
        end
        table.remove(self.condition_stack)
    end
end

function Preprocessor:should_output()
    for _, condition in ipairs(self.condition_stack) do
        if not condition.active then
            return false
        end
    end
    return true
end

function Preprocessor:process_line_directive(line)
    local line_num, filename = line:match("^%s*#%s+(%d+)%s*\"([^\"]+)\"")
    if not line_num then
        line_num, filename = line:match("^%s*#%s+(%d+)%s+(%S+)")
    end
    if not line_num then
        line_num = line:match("^%s*#%s+(%d+)")
        filename = self.filename
    end
    
    if line_num then
        self.line_number = tonumber(line_num) - 1  -- Will be incremented before next line
        if filename then
            self.filename = filename
        end
    end
end

function Preprocessor:replace_tabs(line)
    return line:gsub("\t", " ")
end

function Preprocessor:process_line(line)
    -- Replace tabs with spaces first (C standard requirement)
    line = self:replace_tabs(line)
    
    -- Remove comments first, but preserve them in preprocessor directives
    local is_directive = line:match("^%s*#")
    if not is_directive then
        line = self:remove_comments(line)
    end
    
    local was_outputting = self:should_output()
    
    if is_directive then
        if line:match("^%s*#include") then
            if self:should_output() then
                self:process_include(line)
                -- Insert line directive after include to restore correct line tracking
                table.insert(self.output, "# " .. (self.line_number + 1) .. " \"" .. self.filename .. "\"")
            else
                -- Emit empty line to maintain line numbers
                table.insert(self.output, "")
            end
        elseif line:match("^%s*#define") then
            if self:should_output() then
                self:process_define(line)
            end
            -- Always emit empty line for directive
            table.insert(self.output, "")
        elseif line:match("^%s*#undef") then
            if self:should_output() then
                self:process_undef(line)
            end
            -- Always emit empty line for directive
            table.insert(self.output, "")
        elseif line:match("^%s*#if") or line:match("^%s*#elif") or line:match("^%s*#else") or line:match("^%s*#endif") then
            self:process_conditional(line)
            -- Always emit empty line for directive
            table.insert(self.output, "")
        elseif line:match("^%s*#%s*%d+") or line:match("^%s*#line%s+%d+") then
            -- Line directive - consume and update tracking
            self:process_line_directive(line)
            -- Emit empty line to maintain line numbers
            table.insert(self.output, "")
        elseif line:match("^%s*#error") then
            if self:should_output() then
                self:process_error(line)
            end
            -- Always emit empty line for directive
            table.insert(self.output, "")
        elseif line:match("^%s*#warning") then
            if self:should_output() then
                self:process_warning(line)
            end
            -- Always emit empty line for directive
            table.insert(self.output, "")
        elseif line:match("^%s*#pragma") then
            if self:should_output() then
                self:process_pragma(line)
            end
            -- Always emit empty line for directive
            table.insert(self.output, "")
        else
            -- Unknown directive - pass through if should output, otherwise empty line
            if self:should_output() then
                table.insert(self.output, line)
            else
                table.insert(self.output, "")
            end
        end
    else
        if self:should_output() then
            local expanded = self:expand_line(line)
            table.insert(self.output, expanded)
        else
            -- Emit empty line to maintain line numbers
            table.insert(self.output, "")
        end
    end
end

function Preprocessor:handle_line_continuations(input)
    local result = ""
    local lines = {}
    
    -- Split into lines
    for line in input:gmatch("[^\r\n]*") do
        table.insert(lines, line)
    end
    
    local i = 1
    local output_line_num = 1
    
    while i <= #lines do
        local line = lines[i]
        local original_line_num = i
        local lines_consumed = 1
        
        -- Check for line continuation (backslash at end, ignoring whitespace)
        while line:match("\\%s*$") and i < #lines do
            -- Remove the backslash and any trailing whitespace
            line = line:gsub("\\%s*$", "")
            i = i + 1
            lines_consumed = lines_consumed + 1
            -- Join with next line
            line = line .. lines[i]
        end
        
        -- If we consumed multiple lines, insert a line directive before the next line
        local needs_line_directive = lines_consumed > 1
        
        if result ~= "" then
            result = result .. "\n"
        end
        result = result .. line
        
        -- Insert line directive if needed and there are more lines
        if needs_line_directive and i < #lines then
            result = result .. "\n# " .. (i + 1) .. " \"" .. self.filename .. "\""
        end
        
        i = i + 1
        output_line_num = output_line_num + 1
    end
    
    return result
end

function Preprocessor:process(input)
    -- Handle line continuations first
    input = self:handle_line_continuations(input)
    
    for line in input:gmatch("[^\r\n]*") do
        self.line_number = self.line_number + 1
        self.column_number = 1  -- Reset column at start of each line
        -- Check if this is an inserted line directive (from line continuation)
        if line:match("^# %d+ \".*\"$") and line:find("<stdin>") then
            -- This is an inserted line directive - output directly
            table.insert(self.output, line)
        else
            self:process_line(line)
        end
    end
    
    if #self.condition_stack > 0 then
        self:error("unterminated conditional directive", "E111")
    end
    
    return table.concat(self.output, "\n"), self.errors, self.error_directive_encountered
end

function Preprocessor:format_errors_json(errors)
    local json_objects = {}
    for _, err in ipairs(errors) do
        if type(err) == "table" then
            -- Already in JSON format
            local json_str = string.format('{"level":"%s","code":"%s","filename":"%s","line":%d,"column":%d,"message":"%s"}',
                err.level, err.code, err.filename, err.line, err.column, err.message:gsub('"', '\\"'))
            table.insert(json_objects, json_str)
        else
            -- Convert string format to JSON (fallback)
            table.insert(json_objects, string.format('{"level":"error","code":"E999","filename":"<unknown>","line":0,"column":0,"message":"%s"}',
                err:gsub('"', '\\"')))
        end
    end
    return "[" .. table.concat(json_objects, ",") .. "]"
end

if arg and arg[0] and arg[0]:match("preprocessor%.lua$") then
    -- Parse command line flags
    local json_errors = false
    local show_help = false
    
    for i = 1, #arg do
        if arg[i] == "--json-errors" then
            json_errors = true
        elseif arg[i] == "--help" or arg[i] == "-h" then
            show_help = true
        end
    end
    
    if show_help then
        print("Usage: preprocessor.lua [options] < input > output")
        print("Options:")
        print("  --json-errors    Output errors in JSON format")
        print("  --help, -h       Show this help message")
        os.exit(0)
    end
    
    local input = io.read("*all")
    local preprocessor = Preprocessor:new({json_errors = json_errors})
    local output, errors, error_directive_encountered = preprocessor:process(input)
    
    if json_errors then
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

return Preprocessor