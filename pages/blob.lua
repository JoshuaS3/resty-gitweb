-- resty-gitweb@pages/blob.lua
-- File blob page builder

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local puremagic = require("puremagic")

local utils = require("utils/utils")
local git   = require("git/git")

local builder  = require("utils/builder")
local tabulate = require("utils/tabulate")
local nav      = require("utils/nav")

local _M = function(repo, repo_dir, branch, file_path)

    -- Pre checks
    if file_path ~= "" then -- make sure path exists
        local path_tree = git.list_tree(repo_dir, branch.name, file_path)
        if #path_tree.files == 0 then -- no path found
            return nil
        end
    else
        return nil
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

    local commit = git.log(repo_dir, branch.name, file_path, 1, 0, true)[1]

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

    -- Tree breadcrumb
    build:add("<h3>Blob @ ")

    local treelinks = {
        {string.format("/%s/tree/%s", repo.name, branch.name), repo.name}
    }

    local base_path = treelinks[1][1] -- /repo/tree/branch

    local path_string = ""
    local path_split = string.split(file_path, "/")
    local file_name = path_split[#path_split]
    table.remove(path_split, #path_split)

    for _, part in pairs(path_split) do
        path_string = path_string.."/"..part
        table.insert(treelinks, {base_path..path_string, part})
    end
    path_string = path_string.."/"..file_name
    table.insert(treelinks, {
        string.format("/%s/blob/%s"..path_string, repo.name, branch.name), file_name
    })

    build:add(nav(treelinks, " / "))
    build:add("</h3>")

    -- File
    local success, repo_obj = git.repo.open(repo_dir)
    local content, is_binary = git.read_blob(repo_obj, branch.name, file_path)
    git.repo.free(repo_obj)

    mimetype = puremagic.via_content(content, file_path)

    build:add([[<div class="blob">]])

    local text_table = {}
    text_table.headers = {}
    text_table.rows = {}
    if not is_binary then
        text_table.class = "blob lines"
        for i, line in pairs(string.split(utils.highlight(content, file_name), "\n")) do
            if line ~= "" then
                local ftab = line:gsub("\t", "    ")
                table.insert(text_table.rows, {i, ftab})
            else
                table.insert(text_table.rows, {i, "\n"}) -- preserve newlines for copying/pasting
            end
        end
    else
        text_table.class = "blob binary"
        table.insert(text_table.headers, {"blob", string.format([[<span>%s</span><span style="font-weight:normal">%d bytes</span><span style="float:inherit"><a href="/%s/raw/%s/%s">download raw</a></span>]], mimetype, string.len(content), repo.name, branch.name, file_path)})
        if string.sub(mimetype, 1, 6) == "image/" then
            table.insert(text_table.rows, {string.format([[<img src="/%s/raw/%s/%s">]], repo.name, branch.name, file_path)})
        elseif string.sub(mimetype, 1, 6) == "video/" then
            table.insert(text_table.rows, {string.format([[<video controls><source src="/%s/raw/%s/%s" type="%s"></audio>]], repo.name, branch.name, file_path, mimetype)})
        elseif string.sub(mimetype, 1, 6) == "audio/" then
            table.insert(text_table.rows, {string.format([[<audio controls><source src="/%s/raw/%s/%s" type="%s"></audio>]], repo.name, branch.name, file_path, mimetype)})
        else
            table.insert(text_table.rows, {string.format([[----- can't preview binary content -----]], repo.name, branch.name, file_path)})
        end
    end

    build:add(tabulate(text_table))

    build:add("</div>")

    return build
end

return _M
