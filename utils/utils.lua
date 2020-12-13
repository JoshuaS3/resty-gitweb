-- utils.lua
-- Basic utilities/resources for git HTTP site implementation

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://joshstock.in>

local _M = {}

string.split = function(str, delimiter)
    local t = {}
    if not str or str == "" then
        return t
    end
    if delimiter == "" then -- string to table
        string.gsub(str, ".", function(c) table.insert(t, c) end)
        return t
    end
    delimiter = delimiter or "%s"
    local str_len = string.len(str)
    local ptr = 1
    while true do
        local sub = string.sub(str, ptr, str_len)
        local pre, after = string.find(sub, delimiter)
        if pre then -- delimiter found
            table.insert(t, string.sub(str, ptr, ptr + (pre - 2)))
            ptr = ptr + after
        else -- delimiter not found
            table.insert(t, string.sub(str, ptr, str_len))
            break
        end
    end
    return t
end


string.trim = function(str)
    return str:match('^()%s*$') and '' or str:match('^%s*(.*%S)')
end


_M.process = function(command)
    local output
    local status, err = pcall(function()
        local process = io.popen(command, "r")
        assert(process, "Error opening process")
        output = process:read("*all")
        process:close()
    end)
    if status then
        return output
    else
        return string.format("Error in call: %s", err or command)
    end
end

_M.markdown = function(input)
    local output
    local status, err = pcall(function()
        local tmpfile = os.tmpname()
        local fp = io.open(tmpfile, "w")
        fp:write(input)
        fp:close()
        local process = io.popen("md2html --github "..tmpfile, "r")
        assert(process, "Error opening process")
        output = process:read("*all")
        process:close()
        os.remove(tmpfile)
    end)
    if status then
        return output
    else
        return string.format("Error in call: %s", err or command)
    end
end

_M.highlight = function(input, file_name)
    local output
    local status, err = pcall(function()
        local t = os.tmpname()
        io.open(t,"w"):close()
        os.remove(t)
        local tmpfile = t..file_name
        local fp = io.open(tmpfile, "w")
        fp:write(input)
        fp:close()
        local process = io.popen("highlight --stdout -f --failsafe --inline-css "..tmpfile, "r")
        assert(process, "Error opening process")
        output = process:read("*all")
        process:close()
        os.remove(tmpfile)
    end)
    if status then
        return output
    else
        return string.format("Error in call: %s", err or command)
    end
end

_M.html_sanitize = function(str)
    return tostring(
        tostring(str):gsub("&", "&amp;")
                     :gsub("<", "&lt;")
                     :gsub(">", "&gt;")
                     :gsub("\"", "&quot;")
                     :gsub("'", "&#039;")
    )
end

_M.iso8601 = function(iso8601)
    iso8601 = iso8601 or "0000-00-00T00:00:00GMT-5:00"
    local y,mo,d,h,mi,s = iso8601:match("(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d)")
    local luatime = os.time{year=y,month=mo,day=d,hour=h,min=mi,sec=s}
    return os.date("%d %b %Y %H:%M", luatime)
end

_M.print_table = function(t, l) -- for debugging
    l = l or 0
    local n = false
    for i,v in pairs(t) do n = true break end
    if n then
        ngx.print("{\n")
        for i,v in pairs(t) do
            for i=0,l do ngx.print("    ") end
            ngx.print("<span style='color:red'>",i,"</span>: ")
            if type(v) ~= "table" then
                if type(v) == "string" then
                    ngx.print("\"")
                    local s = v:gsub("&", "&amp;"):gsub("<","&lt;"):gsub(">","&gt;"):gsub("\"","\\&quot;")
                    ngx.print(s)
                    ngx.print("\"")
                else
                    ngx.print(v)
                end
            else
                _M.print_table(v,l+1)
            end
            ngx.print("\n")
        end
        for i=0,l-1 do ngx.print("    ") end
        ngx.print("}")
    else
        ngx.print("{}")
    end
end

return _M
