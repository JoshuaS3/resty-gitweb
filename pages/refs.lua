-- pages/refs.lua
-- Refs page builder

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://joshstock.in>

local utils = require("utils/utils")
local git   = require("git/git_commands")

local builder  = require("utils/builder")
local tabulate = require("utils/tabulate")
local nav      = require("utils/nav")

local _M = function(repo, repo_dir, branch)
    local build = builder:new()

    -- Breadcrumb navigation and repository description
    local breadcrumb_nav = {
        {string.format("/%s", repo.name),      repo.name},
        {string.format("/%s/refs", repo.name), "refs"},
    }
    build:add("<h2>"..nav(breadcrumb_nav, " / ").."</h2>")
    build:add("<p>"..repo.description.."</p>")

    -- Navigation links
    local navlinks = {
        {string.format("/%s/download", repo.name),             "Download"},
        {string.format("/%s/refs", repo.name),                 "<b>Refs</b>"},
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

    build:add([[<div class="nav">]])
    build:add(nav(navlinks))
    build:add("</div>")

    -- Refs
    local all_refs = git.list_refs(repo_dir)

    -- Branches
    if #all_refs.heads > 0 then
        build:add("<h3>Branches</h3>")

        local branches_table_data = {}
        branches_table_data.class = "branches"
        branches_table_data.headers = {
            {"name", "Name"},
            {"ref", "Ref"},
            {"has", "Hash"}
        }
        branches_table_data.rows = {}

        for _, b in pairs(all_refs.heads) do
            table.insert(branches_table_data.rows, {
                b.name ~= branch.name and b.name or b.name.." <b>(HEAD)</b>",
                string.format([[<a href="/%s/tree/%s">%s</a>]], repo.name, b.name, b.full),
                string.format([[<a href="/%s/commit/%s">%s</a>]], repo.name, b.hash, b.shorthash)
            })
        end

        build:add(tabulate(branches_table_data))
    end

    -- Tags
    if #all_refs.tags > 0 then
        build:add("<h3>Tags</h3>")

        local tags_table_data = {}
        tags_table_data.class = "tags"
        tags_table_data.headers = {
            {"name", "Name"},
            {"ref", "Ref"},
            {"has", "Hash"}
        }
        tags_table_data.rows = {}
        for _, t in pairs(all_refs.tags) do
            table.insert(tags_table_data.rows, {
                t.name ~= branch.name and t.name or t.name.." <b>(HEAD)</b>",
                string.format([[<a href="/%s/tree/%s">%s</a>]], repo.name, t.name, t.full),
                string.format([[<a href="/%s/commit/%s">%s</a>]], repo.name, t.hash, t.shorthash)
            })
        end

        build:add(tabulate(tags_table_data))
    end

    return build
end

return _M
