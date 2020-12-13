-- nav.lua
-- Builds HTML anchors for navigation

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://joshstock.in>

local _M = function(nav_data, join)
    join = join or " | "
    local build = {}
    for _, link in pairs(nav_data) do
        local url = link[1]
        local text = link[2]
        local f = string.format([[<a class="link" href="%s">%s</a>]], url, text)
        table.insert(build, f)
    end
    return string.format([[<span class="nav">%s</span>]], table.concat(build, join))
end

return _M
