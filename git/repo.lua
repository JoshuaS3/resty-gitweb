-- resty-gitweb@git/repo.lua
-- git repository utilities

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local ffi = require("ffi")

local _M = {}

-- Returns [bool exists, git_repository* repo]
_M.open = function(repo_dir)
    local repo_obj = ffi.new("git_repository*[1]")
    err = git2.git_repository_open(ffi.cast("git_repository**", repo_obj), repo_dir)
    ret_obj = nil
    if err == 0 then
        ret_obj = repo_obj[0]
    end
    return err == 0, ret_obj
end

_M.free = function(repo_obj)
    git2.git_repository_free(repo_obj)
end

return _M
