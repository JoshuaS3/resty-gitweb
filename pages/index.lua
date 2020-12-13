-- pages/index.lua
-- Index (home) page builder

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://joshstock.in>

local utils = require("utils/utils")
local git   = require("git/git_commands")

local builder  = require("utils/builder")
local tabulate = require("utils/tabulate")
local nav      = require("utils/nav")

local _M = function(repos)
    local build = builder:new()

    build:add("<center class=\"home-banner\">")
    build:add("<h1>Git Repositories</h1>")
    build:add("<p>Index of the git repositories hosted on this server</p>")
    build:add("</center>")

    build:add("<div class=\"index-repolist\">")
    local repo_sections = {}
    for _, repo in pairs(repos) do
        local section = builder:new()

        local url = "/"..repo.name
        local repo_dir = repo.location.dev

        -- Title and description
        section:add([[<div class="repo-section">]])
        section:add(string.format([[<h2 class="name">%s <a href="/%s" style="font-size:0.65em">[more]</a></h2>]], repo.name, repo.name))
        section:add([[<p class="description">]]..repo.description.."</p>")

        -- Latest Commit table
        local branch = git.get_head(repo_dir)
        local commit = git.commit(repo_dir, branch.name)

        section:add(string.format("<h3>Latest Commit (%s)</h3>", branch.name))

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
        commits_table_data.rows = {{
            commit.count,
            utils.iso8601(commit.timestamp),
            string.format([[<a href="/%s/commit/%s">%s</a>]], repo.name, commit.hash, commit.shorthash),
            utils.html_sanitize(commit.subject),
            string.format([[<a href="mailto:%s">%s</a>]], commit.email, utils.html_sanitize(commit.author)),
            commit.diff.num,
            commit.diff.plus,
            commit.diff.minus,
            commit.gpggood
        }}

        section:add(tabulate(commits_table_data))

        -- Navigation links
        local navlinks = {
            {string.format("/%s/download", repo.name),             "Download"},
            {string.format("/%s/refs", repo.name),                 "Refs"},
            {string.format("/%s/log/%s", repo.name, branch.name),  "Commit Log"},
            {string.format("/%s/tree/%s", repo.name, branch.name), "Files"}
        }

        for _, special in pairs(repo.specialfiles) do -- create nav items for special files
            local split = string.split(special, " ")
            table.insert(navlinks, {
                string.format("/%s/blob/%s/%s", repo.name, branch.name, split[2]),
                split[1]
            })
        end

        section:add([[<div class="nav">]])
        section:add(nav(navlinks))

        local gitlab_url = string.split(repo.urls[3], " ")[2]
        local github_url = string.split(repo.urls[2], " ")[2]
        section:add(string.format([[<span style="float:right"><a href="%s">[on GitLab]</a></span>]], gitlab_url))
        section:add(string.format([[<span style="float:right;margin-right:10px"><a href="%s">[on GitHub]</a></span>]], github_url))

        section:add("</div>") -- nav

        section:add("</div>") -- repo-section

        table.insert(repo_sections, section.body)
    end

    -- Format repo sections
    build:add(table.concat(repo_sections, "<hr>"))

    build:add("</div>")

    return build
end

return _M
