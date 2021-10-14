-- resty-gitweb@pages/tree.lua
-- Tree page builder

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local utils = require("utils/utils")
local git   = require("git/git")

local builder  = require("utils/builder")
local tabulate = require("utils/tabulate")
local nav      = require("utils/nav")

local _M = function(repo, repo_dir, branch, path)

    -- Pre checks
    if path ~= "" then -- make sure path exists
        local path_tree = git.list_tree(repo_dir, branch.name, string.sub(path, 1, path:len() - 1))
        if #path_tree.dirs == 0 then -- no path found
            error("tree "..path.." is nonexistent")
        end
    end

    if branch.name == "" then
        branch.name = branch.hash
    end


    local build = builder:new()

    -- Breadcrumb navigation and repository description
    local breadcrumb_nav = {
        {string.format("/%s", repo.name),                      repo.name},
        {string.format("/%s/tree/%s", repo.name, branch.name), branch.name},
    }

    -- Navigation links
    local navlinks = {
        {string.format("/%s/download", repo.name),             "Download"},
        {string.format("/%s/refs", repo.name),                 "Refs"},
        {string.format("/%s/log/%s", repo.name, branch.name),  "Commit Log"},
        {string.format("/%s/tree/%s", repo.name, branch.name), "<b>Files</b>"}
    }

    for _, special in pairs(repo.specialfiles) do -- create nav items for special files
        local split = string.split(special, " ")
        table.insert(navlinks, {
            string.format("/%s/blob/%s/%s", repo.name, branch.name, split[2]),
            split[1]
        })
    end

    build{
        build.h2{nav(breadcrumb_nav, " / ")},
        build.p{repo.description},
        build.div{class="nav", nav(navlinks)}
    }

    -- Latest Commit table
    build{
        build.h3{"Latest Commit"}
    }

    local commit = git.log(repo_dir, branch.name, path ~= "" and path.."/" or "", 1, 0, true)[1]

    local commits_table_data = {}
    commits_table_data.class = "log"
    commits_table_data.headers = {
        {"count",     [[<span class="q" title="Commit number/count">{#}</span>]]},
        {"timestamp", "Time"},
        {"shorthash", "Hash"},
        {"subject",   "Subject"},
        {"author",    "Author"},
        {"changed_files", [[<span class="q" title="# of files changed">#</span>]]},
        {"changed_plus",  [[<span class="q" title="Insertions">(+)</span>]]},
        {"changed_minus", [[<span class="q" title="Deletions">(-)</span>]]},
        {"gpggood",       [[<span class="q" title="GPG signature status

G: Good (valid) signature
B: Bad signature
U: Good signature with unknown validity
X: Good signature that has expired
Y: Good signature made by an expired key
R: Good signature made by a revoked key
E: Signature can't be checked (e.g. missing key)
N: No signature">GPG?</span>]]}
    }
    commits_table_data.rows = {}

    table.insert(commits_table_data.rows, {
        git.count(repo_dir, commit.hash),
        utils.iso8601(commit.timestamp),
        string.format([[<a href="/%s/commit/%s">%s</a>]], repo.name, commit.hash, commit.shorthash),
        utils.html_sanitize(commit.subject),
        string.format([[<a href="mailto:%s">%s</a>]], commit.email, utils.html_sanitize(commit.author)),
        commit.diff.num,
        commit.diff.plus,
        commit.diff.minus,
        commit.gpggood
    })

    build{tabulate(commits_table_data)}

    -- Tree/files table
    local title = build.h3{"Tree"}

    if path ~= "" then -- build path with hyperlinks for section header
        local split = string.split(path, "/")
        table.remove(split, #split)
        local base = "/"..repo.name.."/tree/"..branch.name
        title{" @ ", build.a{href=base, repo.name}}
        local b = ""
        for _, part in pairs(split) do
            b = b.."/"..part
            title{" / ", build.a{href=base..b, part}}
        end
    end

    build{title}

    local files = git.list_tree(repo_dir, branch.name, path)

    local files_table_data = {}
    files_table_data.class = "files"
    files_table_data.headers = {
        {"object",    "Object"},
        {"subject",   "Latest Commit Subject"},
        {"timestamp", "Time"},
        {"shorthash", "Hash"}}
    files_table_data.rows = {}

    local file_icon   = [[<img style="width:1em;height:1em;vertical-align:middle;margin-right:0.5em;" alt="file" src="https://joshstock.in/static/svg/file.svg"/>]]
    local folder_icon = [[<img style="width:1em;height:1em;vertical-align:middle;margin-right:0.5em;fill:#ffe9a2;" alt="folder" src="https://joshstock.in/static/svg/folder.svg"/>]]

    -- .. directory
    if path ~= "" then
        local split = string.split(string.sub(path, 1, path:len() - 1), "/")
        table.remove(split, #split)
        if #split > 0 then -- deeper than 1 directory
            table.insert(files_table_data.rows, {
                string.format([[%s<a href="/%s/tree/%s/%s">..</a>]], folder_icon, repo.name, branch.name, table.concat(split, "/")),
                "","",""
            })
        else -- only one directory deep
            table.insert(files_table_data.rows, {
                string.format([[%s<a href="/%s/tree/%s">..</a>]], folder_icon, repo.name, branch.name),
                "","",""
            })
        end
    end

    -- Regular directories
    for _, dir in pairs(files.dirs) do
        local lastedit = git.log(repo_dir, branch.name.." -1", dir, 1, 0, false)[1]
        local split = string.split(dir, "/")
        local name = split[#split]
        table.insert(files_table_data.rows, {
            string.format([[%s<a href="/%s/tree/%s/%s">%s</a>]], folder_icon, repo.name, branch.name, dir, name),
            utils.html_sanitize(lastedit.subject),
            utils.iso8601(lastedit.timestamp),
            string.format([[<a href="/%s/commit/%s">%s</a>]], repo.name, lastedit.hash, lastedit.shorthash)
        })
    end

    -- Regular files
    for _, file in pairs(files.files) do
        local lastedit = git.log(repo_dir, branch.name.." -1", file, 1, 0, false)[1]
        local split = string.split(file, "/")
        local name = split[#split]
        table.insert(files_table_data.rows, {
            string.format([[%s<a href="/%s/blob/%s/%s">%s</a>]], file_icon, repo.name, branch.name, file, name),
            utils.html_sanitize(lastedit.subject),
            utils.iso8601(lastedit.timestamp),
            string.format([[<a href="/%s/commit/%s">%s</a>]], repo.name, lastedit.hash, lastedit.shorthash)
        })
    end

    build{tabulate(files_table_data)}

    -- Look for and render README if it exists
    for _, file in pairs(files.files) do
        local split = string.split(file, "/")
        local l = split[#split]:lower()
        if l:match("^readme") then
            build{build.h3{"README"}}
            local repo = git.repo.open(repo_dir)
            local text = git.read_blob(repo, branch.name, file)
            git.repo.free(repo)
            local s = l:len()
            if string.sub(l, s-2, s) == ".md" then
                build{build.div{class="markdown", utils.markdown(text)}}
            else
                build{build.pre{build.code{text}}}
            end
            break
        end
    end

    return build
end

return _M
