-- pages/download.lua
-- Download page builder

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
        {string.format("/%s", repo.name),          repo.name},
        {string.format("/%s/download", repo.name), "download"},
    }
    build:add("<h2>"..nav(breadcrumb_nav, " / ").."</h2>")
    build:add("<p>"..repo.description.."</p>")

    -- Navigation links
    local navlinks = {
        {string.format("/%s/download", repo.name),             "<b>Download</b>"},
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

    build:add([[<div class="nav">]])
    build:add(nav(navlinks))
    build:add("</div>")

    -- Download URLs
    build:add("<h3>Download URLs</h3>")

    local urls = {}
    urls.class = "download-urls"
    urls.headers = {
        {"protocol", "Protocol"},
        {"url", "URL"}
    }
    urls.rows = {}

    for _, url in pairs(repo.download) do
        local split = string.split(url, " ")
        table.insert(urls.rows, {split[1], string.format([[<a href="%s">%s</a>]], split[2], split[2])})
    end

    build:add(tabulate(urls))

    -- Websites
    build:add("<h3>Websites</h3>")

    local sites = {}
    sites.class = "websites"
    sites.headers = {
        {"name", "Website"},
        {"url", "URL"}
    }
    sites.rows = {}

    for _, site in pairs(repo.urls) do
        local split = string.split(site, " ")
        table.insert(sites.rows, {split[1], string.format([[<a href="%s">%s</a>]], split[2], split[2])})
    end

    build:add(tabulate(sites))

    return build
end

return _M
