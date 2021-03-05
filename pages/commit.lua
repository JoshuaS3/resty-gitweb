-- resty-gitweb@pages/commit.lua
-- List commit info

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local utils = require("utils/utils")
local git   = require("git/git")

local builder  = require("utils/builder")
local tabulate = require("utils/tabulate")
local nav      = require("utils/nav")

local _M = function(repo, repo_dir, commit_hash)

    -- Latest Commit table
    local commit = git.commit(repo_dir, commit_hash)

    local build = builder:new()

    -- Breadcrumb navigation and repository description
    local breadcrumb_nav = {
        {string.format("/%s", repo.name),                      repo.name},
        {string.format("/%s/tree/%s", repo.name, commit_hash), commit.shorthash},
    }
    build{
        build.h2{nav(breadcrumb_nav, " / ")},
        build.p{repo.description}
    }

    -- Navigation links
    local navlinks = {
        {string.format("/%s/download", repo.name),             "Download"},
        {string.format("/%s/refs", repo.name),                 "Refs"},
        {string.format("/%s/log/%s", repo.name, commit_hash),  "Commit Log"},
        {string.format("/%s/tree/%s", repo.name, commit_hash), "Files"}
    }

    for _, special in pairs(repo.specialfiles) do -- create nav items for special files
        local split = string.split(special, " ")
        table.insert(navlinks, {
            string.format("/%s/blob/%s/%s", repo.name, commit_hash, split[2]),
            split[1]
        })
    end

    build{
        build.div{class="nav", nav(navlinks)},
        build.h3{"Latest Commit"}
    }

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


    return build
end

return _M
