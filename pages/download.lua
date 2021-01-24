-- resty-gitweb@pages/download.lua
-- Download page builder

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local utils = require("utils/utils")
local git   = require("git/git")

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
    build{
        build.h2{nav(breadcrumb_nav, " / ")},
        build.p{repo.description}
    }

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

    build{
        build.div{class="nav", nav(navlinks)},
        build.h3{"Download URLs"}
    }

    -- Download URLs
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

    build{tabulate(urls)}

    -- Websites
    build{build.h3{"Websites"}}

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

    build{tabulate(sites)}

    return build
end

return _M
