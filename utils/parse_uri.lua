-- parse_uri.lua
-- URI parsing

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://joshstock.in>

local utils = require("utils/utils")

local _M = function()
    local uri = ngx.var.uri
    local split = string.split(string.sub(uri,2),"/")

    local parsed = {}
    parsed.uri = uri
    parsed.parts = split
    parsed.repo = split[1]

    return parsed
end

return _M
