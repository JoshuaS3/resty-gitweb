-- pages/tree.lua
-- Tree page builder

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://joshstock.in>

local utils = require("utils/utils")
local git   = require("git/git_commands")

local builder  = require("utils/builder")
local tabulate = require("utils/tabulate")
local nav      = require("utils/nav")

local _M = function(repo, repo_dir, branch, path)

    -- Pre checks
    if path ~= "" then -- make sure path exists
        local path_tree = git.list_tree(repo_dir, branch.name, string.sub(path, 1, path:len() - 1))
        if #path_tree.dirs == 0 then -- no path found
            return nil
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
    build:add("<h2>"..nav(breadcrumb_nav, " / ").."</h2>")
    build:add("<p>"..repo.description.."</p>")

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

    build:add([[<div class="nav">]])
    build:add(nav(navlinks))
    build:add("</div>")

    -- Latest Commit table
    build:add("<h3>Latest Commit</h3>")

    local commit = git.log(repo_dir, branch.name, path.."/", 1, 0, true)[1]

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

    build:add(tabulate(commits_table_data))

    -- Tree/files table
    local title = builder:new()

    if path == "" then
        title:add("<h3>Tree</h3>")
    else -- build path with hyperlinks for section header
        title:add("<h3>Tree")
        local split = string.split(path, "/")
        table.remove(split, #split)
        local base = "/"..repo.name.."/tree/"..branch.name
        title:add(string.format([[ @ <a href="%s">%s</a>]], base, repo.name))
        local build = ""
        for _, part in pairs(split) do
            build = build.."/"..part
            title:add(string.format([[ / <a href="%s%s">%s</a>]], base, build, part))
        end
        title:add("</h3>")
    end

    build:add(title.body)

    local files = git.list_tree(repo_dir, branch.name, path)

    local files_table_data = {}
    files_table_data.class = "files"
    files_table_data.headers = {
        {"object",    "Object"},
        {"subject",   "Latest Commit Subject"},
        {"timestamp", "Time"},
        {"shorthash", "Hash"}}
    files_table_data.rows = {}

    local file_icon   = [[<img style="width:1em;height:1em;vertical-align:middle;margin-right:0.5em;" src="https://joshuas3.s3.amazonaws.com/svg/file.svg"/>]]
    local folder_icon = [[<img style="width:1em;height:1em;vertical-align:middle;margin-right:0.5em;fill:#ffe9a2;" src="https://joshuas3.s3.amazonaws.com/svg/folder.svg"/>]]

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

    build:add(tabulate(files_table_data))

    -- Look for and render README if it exists
    for _, file in pairs(files.files) do
        local split = string.split(file, "/")
        local l = split[#split]:lower()
        if l:match("^readme") then
            build:add("<h3>README</h3>")
            local text = git.show_file(repo_dir, branch.name, file)
            local s = l:len()
            local body = builder:new()
            if string.sub(l, s-2, s) == ".md" then
                body:add([[<div class="markdown">]]..utils.markdown(text).."</div>")
            else
                body:add("<pre><code>"..text.."</code></pre>")
            end
            build:add(body.body)
            break
        end
    end

    return build
end

return _M
