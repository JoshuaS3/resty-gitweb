-- resty-gitweb@utils/builder.lua
-- XML (HTML, Atom, RSS) builder class

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local builder = {}

builder.__index = function(t, k)
    if builder[k] then return builder[k] end
    return builder.createobject({}, k)
end

builder.__call = function(self, opts)
    for i,v in pairs(opts) do
        if type(i) ~= "number" then
            self._attributes[i] = v
        else
            table.insert(self._objects, v)
        end
    end
    return self
end

function builder.createobject(attr, tag)
    local o = {}
    o._type = "object"
    o._tag = tag
    o._attributes = attr or {}
    o._objects = {}
    setmetatable(o, builder)
    return o
end

function builder:new(doctype)
    local o = {}
    o._type = "root"
    o._doctype = doctype
    o._objects = {}
    setmetatable(o, self)
    return o
end

function builder:build()
    local str = ""
    if self._type == "root" then
        if self._doctype:lower() == "html" then
            str = str .. "<!DOCTYPE html>\n"
        end
    end
    if self._type == "object" then
        if self._tag then
            str = str .. "<" .. self._tag
        end
        for i,v in pairs(self._attributes) do
            if i:sub(1,1) ~= "_" then
                str = str .. " " .. i .. "=\"" .. tostring(v) .. "\""
            end
        end
        str = str .. ">"
    end
    if self._type == "object" or self._type == "root" then
        for _,v in pairs(self._objects) do
            if type(v) == "table" then
                str = str .. v:build()
            else
                str = str .. v
            end
        end
    end
    if self._type == "object" then
        if self._attributes._closetag ~= false then
            str = str .. "</" .. self._tag .. ">"
        end
    end
    return str
end

return builder
