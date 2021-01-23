-- resty-gitweb@git/list_refs.lua
-- Lists named references/revisions (branches, tags)

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local ffi = require("ffi")
local git2_error = require("git/git2_error")

_M.list_refs = function(repo_obj)
    -- List refs
    local refs = ffi.new("git_strarray")
    local err = git2.git_reference_list(ffi.cast("git_strarray*", refs), repo_obj)

    local ret = {}
    ret.heads = {}
    ret.tags = {}

    for i = 0, tonumber(refs.count)-1 do

        local name = ffi.string(refs.strings[i])

        local dest
        local prefix_len
        if name:match("^refs/heads/") then
            dest = ret.heads
            prefix_len = 12
        elseif name:match("^refs/tags/") then
            dest = ret.tags
            prefix_len = 11
        end

        if dest then
            local oid = ffi.new("git_oid")
            local err = git2.git_reference_name_to_id(ffi.cast("git_oid*", oid), repo_obj, refs.strings[i])

            -- Format oid as SHA1 hash
            local hash = ffi.new("char[41]") -- SHA1 length (40 chars) + \0
            local err = git2.git_oid_fmt(hash, ffi.cast("git_oid*", oid))
            hash = ffi.string(hash)

            local ref = {}
            ref.name = string.sub(name, prefix_len, string.len(name))
            ref.full = name
            ref.hash = hash
            ref.shorthash = string.sub(hash, 1, 7)
            table.insert(dest, ref)
        end

    end

    if refs then
        git2.git_strarray_free(ffi.cast("git_strarray*", refs))
    end
    if repo_obj then
        git2.git_repository_free(ffi.cast("git_repository*", repo_obj))
    end

    return ret
end

return _M
