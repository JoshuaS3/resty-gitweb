-- app.lua
-- Entry point for git HTTP site implementation

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://joshstock.in>

local utils     = require("utils/utils")
local git       = require("git/git_commands")
local parse_uri = require("utils/parse_uri")

local parsed_uri = parse_uri()
local content

if parsed_uri.repo == nil then
    content = require("pages/index")(yaml_config)
else -- repo found
    local repo
    for _,r in pairs(yaml_config) do
        if parsed_uri.repo == r.name then
            repo = r
            break
        end
    end
    if repo then
        local repo_dir = repo.location.dev
        local view = parsed_uri.parts[2] or "tree"
        local branch

        if pcall(function() -- if branch is real
            branch = git.get_head(repo_dir, parsed_uri.parts[3]) -- if parts[3] is nil, defaults to "HEAD"
        end) then
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

                    content = require("pages/tree")(repo, repo_dir, branch, path)
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

                    content = require("pages/blob")(repo, repo_dir, branch, path)
                elseif view == "raw" then
                    -- /repo/raw/branch/[FILE PATH]
                elseif view == "log" then
                    content = require("pages/log")(repo, repo_dir, branch, ngx.var.arg_n, ngx.var.arg_skip)
                elseif view == "refs" then
                    content = require("pages/refs")(repo, repo_dir, branch)
                elseif view == "download" then
                    content = require("pages/download")(repo, repo_dir, branch)
                elseif view == "commit" then
                    -- /repo/commit/[COMMIT HASH]
                end
            end) -- pcall

            if res ~= true then
                ngx.say(res)
                ngx.say(status)
                ngx.exit(ngx.HTTP_NOT_FOUND)
                return
            end
        end
    end
end

if content ~= nil then -- TODO: HTML templates from files, static serving
ngx.say([[<style>
@import url('https://fonts.googleapis.com/css?family=Fira+Sans:400,400i,700,700i&display=swap');
*{
box-sizing:border-box;
}
body{
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
table.files,table.log,table.blob-lines{
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

div.blob {
    border:1px solid #858585;
    overflow-x: auto;
}
table.blob-lines{
    font-size:1em;
    max-width:100%;
    line-height:1;
}
table.blob-lines tr:hover {
    background-color: inherit;
}
table.blob-lines td{
    border:none;
    padding:1px 5px;
}
table.blob-lines td:first-child{
    text-align: right;
    padding-left:20px;
    cursor: pointer;
    user-select: none;
    color:#858585;
    max-width:1%;
    white-space:nowrap;
}
table.blob-lines td:first-child:hover{
    color: #454545;
}
table.blob-lines td:nth-child(2){
    width:100%;
    white-space:pre;
}

a{
text-decoration:none;
color: #0077aa;
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
    ngx.say(content:build())
    ngx.exit(ngx.HTTP_OK)
    return
else
    ngx.exit(ngx.HTTP_NOT_FOUND) -- default behavior
    return
end
