local function json_encode_pretty(val, indent, seen)
    indent = indent or 0
    local t = type(val)
    local pad = string.rep("  ", indent)
    local pad_next = string.rep("  ", indent + 1)

    if t == "string" then
        return '"' .. val:gsub('[%z\1-\31\\"]', function(c)
            local map = { ['"']='\\"', ['\\']='\\\\', ['\b']='\\b', ['\f']='\\f', ['\n']='\\n', ['\r']='\\r', ['\t']='\\t' }
            return map[c] or string.format("\\u%04x", c:byte())
        end) .. '"'
    elseif t == "number" then
        if val ~= val or val == math.huge or val == -math.huge then return "null" end
        return tostring(val)
    elseif t == "boolean" then
        return val and "true" or "false"
    elseif t == "nil" then
        return "null"
    elseif t == "table" then
        if seen[val] then error("json.encode: circular reference") end
        seen[val] = true

        local is_array, max = true, 0
        for k,_ in pairs(val) do
            if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
                is_array = false
                break
            end
            if k > max then max = k end
        end

        local out = {}
        if is_array then
            for i = 1, max do
                out[#out+1] = pad_next .. json_encode_pretty(val[i], indent+1, seen)
            end
            seen[val] = nil
            return "[\n" .. table.concat(out, ",\n") .. "\n" .. pad .. "]"
        else
            for k,v in pairs(val) do
                out[#out+1] = pad_next .. '"' .. tostring(k) .. '": ' .. json_encode_pretty(v, indent+1, seen)
            end
            seen[val] = nil
            return "{\n" .. table.concat(out, ",\n") .. "\n" .. pad .. "}"
        end
    else
        return "null"
    end
end

local function json_decode(str)
    local pos = 1
    local function skip_ws()
        local _, e = str:find("^[ \n\r\t]*", pos)
        pos = (e or pos - 1) + 1
    end

    local function parse_value()
        skip_ws()
        local c = str:sub(pos, pos)
        if c == "{" then -- object
            pos = pos + 1
            local obj = {}
            skip_ws()
            if str:sub(pos, pos) == "}" then pos = pos + 1 return obj end
            while true do
                skip_ws()
                local key = parse_value()
                skip_ws()
                assert(str:sub(pos, pos) == ":", "expected ':' after key")
                pos = pos + 1
                obj[key] = parse_value()
                skip_ws()
                local ch = str:sub(pos, pos)
                if ch == "}" then pos = pos + 1 break end
                assert(ch == ",", "expected ',' or '}'")
                pos = pos + 1
            end
            return obj

        elseif c == "[" then -- array
            pos = pos + 1
            local arr = {}
            skip_ws()
            if str:sub(pos, pos) == "]" then pos = pos + 1 return arr end
            local i = 1
            while true do
                arr[i] = parse_value()
                i = i + 1
                skip_ws()
                local ch = str:sub(pos, pos)
                if ch == "]" then pos = pos + 1 break end
                assert(ch == ",", "expected ',' or ']'")
                pos = pos + 1
            end
            return arr

        elseif c == '"' then -- string
            pos = pos + 1
            local s = {}
            while true do
                local ch = str:sub(pos, pos)
                assert(ch ~= "", "unterminated string")
                if ch == '"' then pos = pos + 1 break end
                if ch == "\\" then
                    local esc = str:sub(pos + 1, pos + 1)
                    local map = { b = "\b", f = "\f", n = "\n", r = "\r", t = "\t", ['"'] = '"', ["\\"] = "\\" }
                    if esc == "u" then
                        local hex = str:sub(pos + 2, pos + 5)
                        s[#s + 1] = utf8.char(tonumber(hex, 16))
                        pos = pos + 6
                    else
                        s[#s + 1] = map[esc] or esc
                        pos = pos + 2
                    end
                else
                    s[#s + 1] = ch
                    pos = pos + 1
                end
            end
            return table.concat(s)

        elseif str:find("^[-%d%.eE]+", pos) then -- number
            local nstr = str:match("^[-%d%.eE]+", pos)
            pos = pos + #nstr
            return tonumber(nstr)

        elseif str:sub(pos, pos + 3) == "true" then
            pos = pos + 4
            return true
        elseif str:sub(pos, pos + 4) == "false" then
            pos = pos + 5
            return false
        elseif str:sub(pos, pos + 3) == "null" then
            pos = pos + 4
            return nil
        else
            error("Invalid JSON at position " .. pos)
        end
    end

    return parse_value()
end

json = {
    encode = function(val) return json_encode_pretty(val, 0, {}) end,
    decode = json_decode 
}
