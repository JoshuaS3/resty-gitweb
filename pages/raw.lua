-- resty-gitweb@pages/raw.lua
-- Raw file page builder

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local utils = require("utils/utils")
local git   = require("git/git")

local builder  = require("utils/builder")

local _M = function(repo, repo_dir, branch, file_path)
    -- Pre checks
    if file_path ~= "" then -- make sure path exists
        local path_tree = git.list_tree(repo_dir, branch.name, file_path)
        if #path_tree.files == 0 then -- no path found
            error("file "..file_path.." is nonexistent")
        end
    else
        error("file path is empty")
    end

    local build = builder:new()

    -- File
    local repo_obj = git.repo.open(repo_dir)
    local content, is_binary = git.read_blob(repo_obj, branch.name, file_path)
    git.repo.free(repo_obj)

    build{content}

    return build, is_binary
end

return _M
