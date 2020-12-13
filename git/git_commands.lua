-- git/git_commands.lua
-- git commands and parser functions

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://joshstock.in>

local utils = require("utils/utils")

local _M = {}

local git = function(repo_dir, command)
    local formatted_command = string.format(
        "git --git-dir=%s %s",
        repo_dir, command
    )
    return utils.process(formatted_command)
end

_M.show_file = function(repo_dir, hash, filename)
    hash = hash or "@"
    filename = filename or ""
    local output = git(repo_dir, "show "..hash..":"..filename)
    return output
end

_M.get_head = function(repo_dir, head_name)
    head_name = head_name or "HEAD"
    local head = {}
    local name = string.trim(git(repo_dir, "rev-parse --abbrev-ref "..head_name))
    if name ~= "" then
        local output = git(repo_dir, "show-ref --heads --tags "..name)
        local a = string.split(string.trim(output), " ")
        head.hash = a[1]
        head.shorthash = string.sub(a[1], 1, 7)
        head.full = a[2]
        head.name = name
    else -- no ref, default to hash
        head.hash = head_name
        head.shorthash = string.sub(head_name, 1, 7)
        head.full = head_name
        head.name = head_name
    end
    return head
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

local heads = function(repo_dir)
    local output = git(repo_dir, "show-ref --heads")
    local a = string.split(output, "\n")
    table.remove(a,#a)
    local heads = {}
    for i,v in pairs(a) do
        local b = string.split(v, " ")
        local head = {}
        head.hash = b[1]
        head.shorthash = string.sub(b[1], 1, 7)
        head.full = b[2]
        head.name = string.split(b[2], "/")[3]
        table.insert(heads, head)
    end
    return heads
end

local tags = function(repo_dir)
    local output = git(repo_dir, "show-ref --tags")
    local a = string.split(output, "\n")
    table.remove(a,#a)
    local tags = {}
    for i,v in pairs(a) do
        local b = string.split(v, " ")
        local tag = {}
        tag.hash = b[1]
        tag.shorthash = string.sub(b[1], 1, 7)
        tag.full = b[2]
        tag.name = string.split(b[2], "/")[3]
        table.insert(tags, tag)
    end
    return tags
end

_M.list_refs = function(repo_dir)
    local refs = {}
    refs.heads = heads(repo_dir)
    refs.tags = tags(repo_dir)
    return refs
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
