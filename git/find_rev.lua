-- resty-gitweb@git/find_rev.lua
-- Finds and formats a revision by name

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local ffi = require("ffi")
local git2_error = require("git/git2_error")

local _M = function(repo_obj, rev)
    local err = 0
    rev = rev or "HEAD"

    -- Get object/reference
    local object = ffi.new("git_object*[1]")
    local reference = ffi.new("git_reference*[1]")
    err = git2.git_revparse_ext(ffi.cast("git_object**", object), ffi.cast("git_reference**", reference), repo_obj, rev)
    git2_error(err, "Failed to find reference")
    object = object[0]
    reference = reference[0]

    -- Get full name if intermediate reference exists
    local name = rev
    if reference ~= nil then
        local ref_type = git2.git_reference_type(reference)
        if ref_type == git2.GIT_REFERENCE_SYMBOLIC then
            name = ffi.string(git2.git_reference_symbolic_target(reference))
        elseif ref_type == git2.GIT_REFERENCE_DIRECT then
            name = ffi.string(git2.git_reference_name(reference))
        end
    end

    -- Get OID
    local oid = git2.git_object_id(object)

    -- Format oid as SHA1 hash
    local hash = ffi.new("char[41]") -- SHA1 length (40 chars) + \0
    err = git2.git_oid_fmt(hash, oid)
    git2_error(err, "Failed formatting OID")
    hash = ffi.string(hash)

    local shorthash_buf = ffi.new("git_buf")
    err = git2.git_object_short_id(shorthash_buf, object)
    git2_error(err, "Failed to calculate short id for object")
    shorthash = ffi.string(shorthash_buf.ptr)

    -- Free all
    git2.git_buf_free(shorthash_buf)
    git2.git_object_free(object)
    if reference ~= nil then
        git2.git_reference_free(reference)
    end

    -- Format
    local ref = {}
    ref.full = name
    if name:match("^refs/heads/") then
        ref.name = string.sub(name, 12, string.len(name))
    elseif name:match("^refs/tags/") then
        ref.name = string.sub(name, 11, string.len(name))
    else
        if rev == hash then -- input was 40-digit hex
            ref.name = shorthash
        else -- fallback
            ref.name = rev -- just pass input as default output
        end
    end
    ref.hash = hash
    ref.shorthash = shorthash

    return ref
end

return _M
