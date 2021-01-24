-- resty-gitweb@pages/index.lua
-- Index (home) page builder

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local utils = require("utils/utils")
local git   = require("git/git")

local builder  = require("utils/builder")
local tabulate = require("utils/tabulate")
local nav      = require("utils/nav")

local _M = function(repos)
    local build = builder:new()

    local center = build.center{
        class="index-banner",
        build.h1{class="title", "Git Repositories"},
        build.p{class="description", "Index of the git repositories hosted on this server"}
    }

    local repolist = build.div{class="index-repolist"}

    for _, repo in pairs(repos) do
        local url = "/"..repo.name
        local repo_dir = repo.location.dev

        -- Latest Commit table
        local exists, repo_obj = git.repo.open(repo_dir)
        local branch = git.find_rev(repo_obj, "HEAD")
        git.repo.free(repo_obj)
        local commit = git.commit(repo_dir, branch.name)

        -- Title and description
        local section = build.div{
            class="repo-section",
            build.h2{
                class="name",
                repo.name, " ", build.a{
                    href="/"..repo.name, style="font-size:0.65em", "[more]"
                }
            },
            build.p{class="description", repo.description},
            build.h3{"Latest Commit (", branch.name, ")"}
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

        section{tabulate(commits_table_data)}

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

        local navdiv = build.div{class="nav", nav(navlinks)}

        for i = #repo.urls, 1, -1 do
            local split = string.split(repo.urls[i], " ")
            local name = split[1]
            local url = split[2]
            navdiv{
                build.span{
                    style="float:right; margin-left:10px",
                    build.a{
                        href=url, "[on ", name, "]"
                    }
                }
            }
        end

        section{navdiv}

        repolist{section}
    end

    for i,v in pairs(repolist._objects) do
        repolist._objects[i] = v:build()
    end
    build{center, table.concat(repolist._objects, "<hr>")}

    return build
end

return _M
