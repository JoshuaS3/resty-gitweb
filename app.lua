-- resty-gitweb@app.lua
-- Entry point for git HTTP site implementation

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local puremagic = require("puremagic")

local utils     = require("utils/utils")
local git       = require("git/git")
local parse_uri = require("utils/parse_uri")

local parsed_uri = parse_uri()
local view
local content

-- TODO: Rewrite app script completely

if parsed_uri.repo == nil then
    content = require("pages/index")(CONFIG)
else -- repo found
    local repo
    for _,r in pairs(CONFIG) do
        if parsed_uri.repo == r.name then
            repo = r
            break
        end
    end
    if repo then
        repo.loc = repo.location.dev
        local success, repo_libgit2_object = git.repo.open(repo.loc)
        if not success then
            error("Failed to open repository at "..repo.loc)
        end
        repo.obj = repo_libgit2_object
        view = parsed_uri.parts[2] or "tree"
        local branch

        local res, status = pcall(function() -- if branch is real
            branch = git.find_rev(repo.obj, parsed_uri.parts[3]) -- if parts[3] is nil, defaults to "HEAD"
        end)
        if res then
            local res, status = pcall(function() -- effectively catch any errors, 404 if any
                if view == "tree" then -- directory display (with automatic README rendering)
                    local path = parsed_uri.parts
                    table.remove(path, 3) -- branch
                    table.remove(path, 2) -- "tree"
                    table.remove(path, 1) -- repo
                    if #path > 0 then
                        path = table.concat(path, "/").."/"
                    else
                        path = ""
                    end

                    content = require("pages/tree")(repo, repo.loc, branch, path)
                elseif view == "blob" then
                    local path = parsed_uri.parts
                    table.remove(path, 3) -- branch
                    table.remove(path, 2) -- "tree"
                    table.remove(path, 1) -- repo
                    if #path > 0 then
                        path = table.concat(path, "/")
                    else
                        path = ""
                    end

                    content = require("pages/blob")(repo, repo.loc, branch, path)
                elseif view == "raw" then
                    local path = parsed_uri.parts
                    table.remove(path, 3) -- branch
                    table.remove(path, 2) -- "tree"
                    table.remove(path, 1) -- repo
                    if #path > 0 then
                        path = table.concat(path, "/")
                    else
                        path = ""
                    end

                    content, is_binary = require("pages/raw")(repo, repo.loc, branch, path)
                    if content then
                        if is_binary then
                            mimetype = puremagic.via_content(content.body, path)
                            content.type = mimetype
                        else
                            content.type = "text/plain"
                        end
                    end

                elseif view == "log" then
                    content = require("pages/log")(repo, repo.loc, branch, ngx.var.arg_n, ngx.var.arg_skip)
                elseif view == "refs" then
                    content = require("pages/refs")(repo, repo.loc, branch)
                elseif view == "download" then
                    content = require("pages/download")(repo, repo.loc, branch)
                elseif view == "commit" then
                    -- /repo/commit/[COMMIT HASH]
                else
                    error("bad view "..view)
                end
            end) -- pcall

            if res ~= true then
                if not PRODUCTION then
                    ngx.say(res)
                    ngx.say(status)
                end
                ngx.exit(ngx.HTTP_NOT_FOUND)
                return
            end
        elseif not PRODUCTION then -- branch doesn't exist, show an error in non-prod environments
            ngx.say(res)
            ngx.say(status)
            ngx.exit(ngx.HTTP_NOT_FOUND)
        end
        git.repo.free(repo.obj)
    end
end

if content ~= nil then -- TODO: HTML templates from files, static serving
    if view ~= "raw" then
        ngx.header.content_type = "text/html"
        ngx.say([[<style>
        @import url('https://fonts.googleapis.com/css?family=Fira+Sans:400,400i,700,700i&display=swap');
        *{
        box-sizing:border-box;
        }
        body{
            color: #212121;
        font-family:'Fira Sans', sans-serif;
        padding-bottom:200px;
        line-height:1.4;
        max-width:1000px;
        margin:20px auto;
        }
        body>h2{
            margin-top:5px;
            margin-bottom:0;
        }
        h3{
        margin-bottom:4px;
        }
        td,th{
        padding:2px 5px;
        border:1px solid #858585;
        text-align:left;
        vertical-align:top;
        }
        th{
        border:1px solid #000;
        }
        table.files,table.log,table.blob{
            width:100%;
            max-width:100%;
        }
        table{
            border-collapse:collapse;
            overflow:auto;
            font-family: monospace;
            font-size:14px;
        }
        table.files td:first-child{
            padding-right:calc(5px + 1em);
        }
        table.files td:not(:nth-child(2)), table.log td:not(:nth-child(4)){
            width:1%;
            white-space:nowrap;
        }
        span.q{
        text-decoration:underline;
        text-decoration-style:dotted;
        }
        .q:hover{
        cursor:help;
        }
        th, tr:hover{ /*darker color for table head, hovered-over rows*/
            background-color:#dedede;
        }
        div.markdown{
        width:100%;
        padding:20px 50px;
        border:1px solid #858585;
        border-radius:6px;
        }
        img{
        max-width:100%;
        }
        pre{
        background-color:#eee;
        padding:15px;
        overflow-x:auto;
        border-radius:8px;
        }
        :not(pre)>code{
        background-color:#eee;
        padding:2.5px;
        border-radius:4px;
        }

        div.blob.table {
            overflow-x: auto;
            border:1px solid #858585;
            border-top: none;
        }
        div.blob.header {
            font-family: monospace;
            font-size:14px;
            font-weight: bold;
            border:1px solid #000;
            background-color:#dedede;
        }
        div.blob.header span{
            margin:0 4px;
        }
        table.blob {
            font-size:1em;
            width:100%;
            max-width:100%;
            line-height:1;
        }
        table.blob tr:hover {
            background-color: inherit;
        }
        table.blob td{
            border:none;
            padding:1px 5px;
        }
        table.blob.binary td{
            text-align:center;
            padding: 0;
        }
        table.blob.binary td>img, table.blob.binary td>video{
            max-width:100%;
            max-height:600px;
        }
        table.blob.lines td:first-child{
            text-align: right;
            padding-left:20px;
            user-select: none;
            color:#858585;
            max-width:1%;
            white-space:nowrap;
        }
        table.blob.lines td:first-child:hover{
            color: #454545;
        }
        table.blob.lines td:nth-child(2){
            width:100%;
            white-space:pre;
        }

        a{
        text-decoration:none;
        color: #0077aa;
        display: inline-block;
        }
        a:hover{
            text-decoration:underline;
        }
        .home-banner h1 {
            margin-top:40px;
            margin-bottom:0;
        }
        .home-banner p {
            margin-top:8px;
            margin-bottom:30px;
        }
        .repo-section .name {
            margin-bottom:0;
        }
        .repo-section h3 {
            margin-top:10px;
        }
        .repo-section .description {
            margin-top:8px;
        }
        .repo-section .nav {
            margin-top:10px;
        }
        hr {
            margin: 20px 0;
        }
        </style>]])

        if parsed_uri.repo then
            local arrow_left_circle = [[<img style="width:1.2em;height:1.2em;vertical-align:middle;margin-right:0.2em" src="https://joshuas3.s3.amazonaws.com/svg/arrow-left.svg"/>]]
            ngx.say("<a style=\"margin-left:-1.35em\" href=\"/\">"..arrow_left_circle.."<span style=\"vertical-align:middle\">Index</span></a>")
        end
        ngx.print(content:build())
    else
        ngx.header.content_type = content.type
        ngx.print(content.body)
    end
    ngx.exit(ngx.HTTP_OK)
    return
else
    ngx.exit(ngx.HTTP_NOT_FOUND) -- default behavior
    return
end
