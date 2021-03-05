-- resty-gitweb@git/git2_error.lua
-- Error handling for libgit2

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local ffi = require("ffi")

local _M = function(err, message)
    if err < 0 then
        local git2_error_message = ffi.string(git2.git_error_last().message)
        error(string.format("<pre>libgit2 Error - %s (\"%s\")\n%s</pre>", message, git2_error_message, debug.traceback()))
    end
end

return _M
