-- resty-gitweb@git/git2_error.lua
-- Error handling for libgit2

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local ffi = require("ffi")

local _M = function(err, message)
    if err < 0 then
        local git2_error_message = ffi.string(git2.git_error_last().message)
        error(string.format([[libgit2 Error - %s ("%s")]], message, git2_error_message))
    end
end

return _M
