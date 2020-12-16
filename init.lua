-- resty-gitweb@init.lua
-- Preloads scripts and config for OpenResty workers

-- Copyright (c) 2020 Joshua 'joshuas3' Stockin
-- <https://git.joshstock.in/resty-gitweb>
-- This software is licensed under the MIT License.

local git = require "git/git_commands"

local pages_blob     = require "pages/blob"
local pages_commit   = require "pages/commit"
local pages_download = require "pages/download"
local pages_index    = require "pages/index"
local pages_log      = require "pages/log"
local pages_row      = require "pages/raw"
local pages_refs     = require "pages/refs"
local pages_tree     = require "pages/tree"

local builder   = require "utils/builder"
local nav       = require "utils/nav"
local parse_uri = require "utils/parse_uri"
local tabulate  = require "utils/tabulate"
local utils     = require "utils/utils"

-- Load YAML configuration
_lyaml = require "lyaml"

-- TODO: Read config file location from nginx env settings
local _yaml_config_file = io.open("/home/josh/repos/joshstock.in/resty-gitweb.yaml")
yaml_config = _lyaml.load(_yaml_config_file:read("*a"))
_yaml_config_file:close()
