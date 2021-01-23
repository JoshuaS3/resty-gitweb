-- resty-gitweb@init.lua
-- Preloads scripts and config for OpenResty workers. MUST be called by init_by_lua_file.

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.


-- Check for RESTY_GITWEB_ENABLE in environment variables
if os.getenv("RESTY_GITWEB_ENABLE") == nil then
    ngx.log(ngx.ERR, "RESTY_GITWEB_ENABLE not found in environment variables; are you missing an `env` directive?")
    os.exit(1)
end

-- In production mode?
PRODUCTION = os.getenv("RESTY_GITWEB_ENV") == "PROD"

-- Get config path
local resty_gitweb_config = os.getenv("RESTY_GITWEB_CONFIG")
if resty_gitweb_config == nil then
    ngx.log(ngx.ERR, "RESTY_GITWEB_CONFIG not found in environment variables; are you missing an `env` directive?")
    os.exit(1)
elseif resty_gitweb_config == "" then
    ngx.log(ngx.ERR, "RESTY_GITWEB_CONFIG is empty")
    os.exit(1)
end

-- Require external modules
local ffi       = require "ffi"
local lyaml     = require "lyaml"
local puremagic = require "puremagic"

-- Load YAML configuration
local yaml_config_file = io.open(resty_gitweb_config)
CONFIG = lyaml.load(yaml_config_file:read("*a"))
yaml_config_file:close()

-- Load libgit2 into FFI and initialize
ffi.include = function(header)
    local p = io.popen("echo '#include <"..header..">' | gcc -E -")
    local c = {}
    while true do
        local line = p:read()
        if line then
            if not line:match("^#") then
                table.insert(c, line)
            end
        else
            break
        end
    end
    p:close()
    ffi.cdef(table.concat(c, "\n"))
end

ffi.include("git2.h")
git2 = ffi.load("git2")
git2.git_libgit2_init()

-- Require internal modules
local git            = require "git/git"
local git_git2_error = require "git/git2_error"
local git_find_rev   = require "git/find_rev"
local git_read_blob  = require "git/read_blob"
local git_repo       = require "git/repo"

--local pages          = require "pages/pages"
local pages_blob     = require "pages/blob"
local pages_commit   = require "pages/commit"
local pages_download = require "pages/download"
local pages_index    = require "pages/index"
local pages_log      = require "pages/log"
local pages_row      = require "pages/raw"
local pages_refs     = require "pages/refs"
local pages_tree     = require "pages/tree"

--local utils     = require "utils/utils"
local builder   = require "utils/builder"
local nav       = require "utils/nav"
local parse_uri = require "utils/parse_uri"
local tabulate  = require "utils/tabulate"
local utils     = require "utils/utils"
