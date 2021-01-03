-- resty-gitweb@git/read_blob.lua
-- Opens and reads blob by filename and rev

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local ffi = require("ffi")
local bit = require("bit")
local git2_error = require("git/git2_error")

local _M = function(repo_obj, rev, file_path)
    local err = 0

    -- Get tree root
    local tree = ffi.new("git_object*[1]")
    err = git2.git_revparse_single(ffi.cast("git_object**", tree), repo_obj, rev)
    git2_error(err, "Failed to look up tree from rev name")
    tree = tree[0]

    -- Get tree entry object (blob)
    local blob = ffi.new("git_object*[1]")
    err = git2.git_object_lookup_bypath(ffi.cast("git_object**", blob), tree, file_path, git2.GIT_OBJECT_BLOB)
    git2_error(err, "Failed to look up blob")
    blob = ffi.cast("git_blob*", blob[0])

    -- Get blob content
    local buf = ffi.new("git_buf")
    err = git2.git_blob_filtered_content(buf, blob, file_path, 0)
    git2_error(err, "Failed to filter blob")
    local raw = ffi.string(buf.ptr, buf.size)
    local is_binary = git2.git_blob_is_binary(blob) == 1

    -- Free everything
    git2.git_buf_free(buf)
    git2.git_blob_free(blob)
    git2.git_object_free(tree)

    return raw, is_binary
end

return _M
