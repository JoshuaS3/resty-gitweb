-- resty-gitweb@git/git_commands.lua
-- git commands and parser functions

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local ffi = require("ffi")
local utils = require("utils/utils")

local _M = {}

local git = function(repo_dir, command)
    local formatted_command = string.format(
        "git --git-dir=%s %s",
        repo_dir, command
    )
    return utils.process(formatted_command)
end

local function git2_error(err, message)
    if err < 0 then
        local git2_error_message = ffi.string(git2.git_error_last().message)
        error(string.format([[libgit2 Error - %s ("%s")]], message, git2_error_message))
    end
end

_M.show_file = function(repo_dir, ref_name, file_path)
    local err = 0

    -- Open git repo
    local repo_obj = ffi.new("git_repository*[1]")
    err = git2.git_repository_open(ffi.cast("git_repository**", repo_obj), repo_dir)
    git2_error(err, "Failed opening git repository")
    repo_obj = repo_obj[0]

    -- Get tree root
    local tree = ffi.new("git_object*[1]")
    err = git2.git_revparse_single(ffi.cast("git_object**", tree), repo_obj, ref_name)
    git2_error(err, "Failed to look up tree from rev name")
    tree = tree[0]

    -- Get tree entry object (blob)
    local blob = ffi.new("git_object*[1]")
    err = git2.git_object_lookup_bypath(ffi.cast("git_object**", blob), tree, file_path, git2.GIT_OBJECT_BLOB)
    git2_error(err, "Failed to look up blob")
    blob = ffi.cast("git_blob*", blob[0])

    -- Get blob content
    local buf = ffi.new("git_buf")
    err = git2.git_blob_filter(buf, blob, file_path, nil)
    git2_error(err, "Failed to filter blob")
    local raw = ffi.string(buf.ptr)

    -- Free everything
    git2.git_buf_free(buf)
    git2.git_blob_free(blob)
    git2.git_object_free(tree)
    git2.git_repository_free(repo_obj)

    return raw
end

_M.get_head = function(repo_dir, ref_name)
    local err = 0
    ref_name = ref_name or "HEAD"

    -- Open git repo
    local repo_obj = ffi.new("git_repository*[1]")
    err = git2.git_repository_open(ffi.cast("git_repository**", repo_obj), repo_dir)
    git2_error(err, "Failed opening git repository")
    repo_obj = repo_obj[0]

    -- Get object/reference
    local object = ffi.new("git_object*[1]")
    local reference = ffi.new("git_reference*[1]")
    err = git2.git_revparse_ext(ffi.cast("git_object**", object), ffi.cast("git_reference**", reference), repo_obj, ref_name)
    git2_error(err, "Failed to find reference")
    object = object[0]
    reference = reference[0]

    -- Get full name if intermediate reference exists
    local name = ref_name
    if reference ~= nil then
        local ref_type = git2.git_reference_type(reference)
        if ref_type == git2.GIT_REFERENCE_SYMBOLIC then
            name = ffi.string(git2.git_reference_symbolic_target(reference))
        else
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

    -- Free all
    git2.git_object_free(object)
    if reference ~= nil then
        git2.git_reference_free(reference)
    end
    git2.git_repository_free(repo_obj)

    -- Format
    local ref = {}
    ref.full = name
    if name:match("^refs/heads/") then
        ref.name = string.sub(name, 12, string.len(name))
    elseif name:match("^refs/tags/") then
        ref.name = string.sub(name, 11, string.len(name))
    else
        ref.name = ref_name -- just pass input as default output
    end
    ref.hash = hash
    ref.shorthash = string.sub(hash, 1, 7)

    return ref
end

_M.count = function(repo_dir, hash)
    hash = hash or "@"
    local output = git(repo_dir, "rev-list --count "..hash.." --")
    return tonumber(string.trim(output))
end

_M.log = function(repo_dir, hash, file, number, skip, gpg)
    hash = hash or "@"
    file = file or ""
    number = tostring(number or 25)
    skip = tostring(skip or 0)
    gpg = gpg or false
    local output
    if gpg then
        output = git(repo_dir, "log --pretty=tformat:'%x00%x01%H%x00%cI%x00%cn%x00%ce%x00%s%x00%b%x00%G?%x00%GK%x00%GG%x00' --numstat -n "..number.." --skip "..skip.." "..hash.." -- "..file)
    else
        output = git(repo_dir, "log --pretty=tformat:'%x00%x01%H%x00%cI%x00%cn%x00%ce%x00%s%x00%b%x00' --numstat -n "..number.." --skip "..skip.." "..hash.." -- "..file)
    end
    local commits = {}
    local a = string.split(output,"\0\1")
    local f = false
    for i,v in pairs(a) do
        if f == true then
            local commit = {}
            local c = string.split(v, "\0")
            commit.hash = c[1]
            commit.shorthash = string.sub(c[1], 1,7)
            commit.timestamp = c[2]
            commit.author = c[3]
            commit.email = c[4]
            commit.subject = c[5]
            commit.body = string.trim(c[6])
            local diffs
            if gpg then
                commit.gpggood = c[7]
                commit.gpgkey = c[8]
                commit.gpgfull = string.trim(c[9])
                diffs = string.trim(c[10])
            else
                diffs = string.trim(c[7])
            end
            commit.diff = {}
            local b = string.split(diffs, "\n")
            commit.diff.plus = 0
            commit.diff.minus = 0
            commit.diff.num = 0
            commit.diff.files = {}
            for i,v in pairs(b) do
                local d = string.split(v,"\t")
                local x = {}
                x.plus = tonumber(d[1]) or 0
                commit.diff.plus = commit.diff.plus + x.plus
                x.minus = tonumber(d[2]) or 0
                commit.diff.minus = commit.diff.minus + x.minus
                commit.diff.files[d[3]] = x
                commit.diff.num = commit.diff.num + 1
            end
            table.insert(commits, commit)
        else
            f = true
        end
    end
    return commits
end

_M.commit = function(repo_dir, hash)
    local commit = _M.log(repo_dir, hash, "", 1, 0, true)[1]
    commit.count = _M.count(repo_dir, hash)
    return commit
end

_M.list_refs = function(repo_dir)
    -- Open git repo
    local repo_obj = ffi.new("git_repository*[1]")
    local err = git2.git_repository_open(ffi.cast("git_repository**", repo_obj), repo_dir)
    repo_obj = repo_obj[0]

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

local list_dirs = function(repo_dir, hash, path)
    hash = hash or "@"
    path = path or ""
    local output = git(repo_dir, "ls-tree -d --name-only "..hash.." -- "..path)
    local dirs = string.split(output, "\n")
    table.remove(dirs, #dirs) -- remove trailing \n
    return dirs
end

local list_all = function(repo_dir, hash, path)
    hash = hash or "@"
    path = path or ""
    local output = git(repo_dir, "ls-tree --name-only "..hash.." -- "..path)
    local all = string.split(output, "\n")
    table.remove(all, #all) -- remove trailing \n
    return all
end

_M.list_tree = function(repo_dir, hash, path)
    hash = hash or "@"
    path = path or ""
    local files = list_all(repo_dir, hash, path)
    local dirs = list_dirs(repo_dir, hash, path)
    local ret = {}
    ret.dirs = {}
    ret.files = {}
    for i,v in pairs(files) do -- iterate over all objects, separate directories from files
        local not_dir = true
        for _,d in pairs(dirs) do -- check if object is directory
            if v == d then
                not_dir = false
                break
            end
        end
        if not_dir then
            table.insert(ret.files, v)
        else
            table.insert(ret.dirs, v)
        end
    end
    return ret
end

return _M
