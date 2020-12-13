-- builder.lua
-- HTML builder class

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://joshstock.in>

local _M = {}
_M.__index = _M

function _M:new()
    local o = {}
    o.title = ""
    o.meta_tags = {}
    o.body = ""
    setmetatable(o, self)
    return o
end

function _M:set_title(str)
    self.title = str
end

function _M:add(str)
    self.body = self.body..str.."\n"
end

function _M:meta(tag)
    table.insert(self.meta_tags, tag)
end

function _M:build() -- TODO
    return self.body
end

return _M
