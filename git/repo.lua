-- resty-gitweb@git/repo.lua
-- git repository utilities

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local ffi = require("ffi")
local git2_error = require("git/git2_error")

local _M = {}

-- Returns [bool exists, git_repository* repo]
_M.open = function(repo_dir)
    local repo_obj = ffi.new("git_repository*[1]")
    err = git2.git_repository_open(ffi.cast("git_repository**", repo_obj), repo_dir)
    git2_error(err, "Failed to open repository at "..repo_dir)
    return repo_obj[0]
end

_M.free = function(repo_obj)
    git2.git_repository_free(repo_obj)
end

return _M
