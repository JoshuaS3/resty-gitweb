local ffi = require("ffi")

ffi.include = function(header)
    p = io.popen("echo '#include <"..header..">' | gcc -E -")
    local c = {}
    while true do
        local line = p:read()
        if line then
            if not line:match("^#") then
                table.insert(c, line)
            end
        else
            break
        end
    end
    p:close()
    ffi.cdef(table.concat(c, "\n"))
end

ffi.include("git2.h")
local git2 = ffi.load("git2")

function git2_error(err, message)
    if err < 0 then
        local git2_error_message = ffi.string(git2.git_error_last().message)
        error(string.format([[libgit2 Error - %s ("%s")]], message, git2_error_message))
    end
end

function exists(repo_dir)
    local err = git2.git_repository_open(nil, repo_dir)
    return err == 0
end

function show(repo_dir, ref_name, file_path)
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

function get_ref(repo_dir, ref_name)
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

function list_refs(repo_dir)
    -- Open git repo
    local repo_obj = ffi.new("git_repository*[1]")
    local err = git2.git_repository_open(ffi.cast("git_repository**", repo_obj), repo_dir)
    repo_obj = repo_obj[0]

    -- List refs
    local refs = ffi.new("git_strarray")
    local err = git2.git_reference_list(refs, repo_obj)

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
            local err = git2.git_reference_name_to_id(oid, repo_obj, refs.strings[i])

            -- Format oid as SHA1 hash
            local hash = ffi.new("char[41]") -- SHA1 length (40 chars) + \0
            local err = git2.git_oid_fmt(hash, oid)
            hash = ffi.string(hash)

            local ref = {}
            ref.name = string.sub(name, prefix_len, string.len(name))
            ref.full = name
            ref.hash = hash
            ref.shorthash = string.sub(hash, 1, 7)
            table.insert(dest, ref)
        end

    end

    if refs ~= nil then
        git2.git_strarray_free(refs)
    end
    if repo_obj ~= nil then
        git2.git_repository_free(repo_obj)
    end

    return ret
end

local t = {
    "/home/josh/repos/lognestmonster",
}

git2.git_libgit2_init()

for _, r in pairs(t) do
    if exists(r) then
        print(r)
        local refs = list_refs(r)
        local head = get_ref(r)
        for i,v in pairs(head) do
            print(i,v)
        end
        print(show(r, head.name, "LICENSE"))
        print()
    end
end

git2.git_libgit2_shutdown()

collectgarbage()
collectgarbage()
collectgarbage()
collectgarbage()
collectgarbage()
collectgarbage()
collectgarbage()
collectgarbage()
collectgarbage()
