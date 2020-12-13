-- pages/log.lua
-- Log page builder

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://joshstock.in>

local utils = require("utils/utils")
local git   = require("git/git_commands")

local builder  = require("utils/builder")
local tabulate = require("utils/tabulate")
local nav      = require("utils/nav")

local _M = function(repo, repo_dir, branch, n, skip)
    n = tonumber(n or 20)
    skip = tonumber(skip or 0)

    local build = builder:new()

    -- Breadcrumb navigation and repository description
    local breadcrumb_nav = {
        {string.format("/%s", repo.name),                      repo.name},
        {string.format("/%s/tree/%s", repo.name, branch.name), branch.name},
        {string.format("/%s/log/%s", repo.name, branch.name),  "log"}
    }
    build:add("<h2>"..nav(breadcrumb_nav, " / ").."</h2>")
    build:add("<p>"..repo.description.."</p>")

    -- Navigation links
    local navlinks = {
        {string.format("/%s/download", repo.name),             "Download"},
        {string.format("/%s/refs", repo.name),                 "Refs"},
        {string.format("/%s/log/%s", repo.name, branch.name),  "<b>Commit Log</b>"},
        {string.format("/%s/tree/%s", repo.name, branch.name), "Files"}
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

    -- Commits table
    build:add("<h3>Commits</h3>")

    local commits_head = git.log(repo_dir, branch.name, path, n, skip, true)

    local this_page = string.format("/%s/log/%s", repo.name, branch.name)

    -- Build controls
    local controls = [[<div class="controls">]]
    local prev = false
    if skip ~= 0 then -- previous page?
        local params = ""
        if skip - n > 0 then
            params = params.."?skip="..tostring(tonumber(skip) - tonumber(n))
        end
        if n ~= 20 then
            if params ~= "" then
                params = params.."&"
            else
                params = params.."?"
            end
            params = params.."n="..tostring(n)
        end
        controls = controls..[[<span><a href="]]..this_page..params..[[">&lt;&lt; Previous Page</a></span>]]
        prev = true
    end
    if git.count(repo_dir, commits_head[#commits_head].hash) ~= 1 then -- check if last commit in this list is actually the last
        -- it's not the last, create a "next page" button
        local params = ""
        params = params.."?skip="..tostring(skip+n)
        if n ~= 20 then
            params = params.."&n="..tostring(n)
        end
        if prev then
            controls = controls..[[<span style="margin:0 5px">|</span>]]
        end
        controls = controls..[[<span><a href="]]..this_page..params..[[">Next Page &gt;&gt;</a></span>]]
    end
    controls = controls..[[<span float="right">
    <form class="control-form" method="GET" style="display:inline;margin:0;float:right">
        <input type="hidden" name="skip" value="]]..tostring(skip)..[[">
        <label for="n">Results</label>
        <select id="n" name="n" onchange="if (this.value != 0){this.form.submit();}">
            <option disabled selected value style="display:none">]]..tostring(n)..[[</option>
            <option>10</option>
            <option>20</option>
            <option>50</option>
            <option>100</option>
        </select>
    </form>
</span>]]
    controls = controls.."</div>"

    build:add(controls)

    -- Build commit table
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

    for i, commit in pairs(commits_head) do
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
    end

    -- Add
    build:add(tabulate(commits_table_data))
    build:add(controls)

    return build
end

return _M
