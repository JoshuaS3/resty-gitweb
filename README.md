# resty-gitweb

A git web interface for Lua/OpenResty.

## Requirements

Lua modules (Lua 5.1/LuaJIT 2.1.0/OpenResty LuaJIT compatible, accessible from
Lua path/cpath):

| Module | Description |
| ------ | ----------- |
| [lfs](https://github.com/keplerproject/luafilesystem) | Filesystem API |
| [lyaml](https://github.com/gvvaughan/lyaml) | Reads and parses YAML config files |
| [puremagic](https://github.com/wbond/puremagic) | MIME type by content, used in blob rendering |
| [etlua](https://github.com/leafo/etlua) | Embedded Lua templating (for HTML rendering) |

Other command line tools (installed on system path, accessible from shell):

| Program | Description |
| ------- | ----------- |
| [md4c](https://github.com/mity/md4c) (md2html) | Renders GitHub flavored Markdown |
| [highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php) | Syntax highlighting in HTML format |

Linkable Libraries (installed on system path, accessible with LuaJIT's C FFI):

| Library | Description |
| ------- | ----------- |
| [libgit2](https://github.com/libgit2/libgit2) | Linkable C API for Git |

## Using

1. Copy this directory with its scripts to a place OpenResty/nginx workers have
   access, such as `/srv/[SITE]/resty-gitweb`. (In reality it doesn't matter
   where, as long as it's accessible.)

2. Copy your config file (`resty-gitweb.yaml`) to
   `/etc/[SITE]/resty-gitweb.yaml` (or somewhere else)

3. Add the following near the top (`main` context, outside of any blocks) of
   your OpenResty/nginx configuration file:

```
# resty-gitweb configuration
env RESTY_GITWEB;          # Script won't run without this
env RESTY_GITWEB_ENV=PROD; # PROD for Production, DEV for Development. DEV by default.
env RESTY_GITWEB_CONFIG=/etc/[SITE]/resty-gitweb.yaml; # Wherever you put your configuration file
```

4. Add the following to the `http` block in your OpenResty/nginx configuration
   file:

```
lua_package_path ";;/srv/[SITE]/resty-gitweb/?.lua"; # Add resty-gitweb to your Lua package path
init_by_lua_file /srv/[SITE]/resty-gitweb/init.lua;  # Initialize modules for nginx workers
```

5. And in whichever `location` block you wish to serve content:

```
content_by_lua_file /srv/[SITE]/resty-gitweb/app.lua;
```

6. Restart OpenResty/nginx

Note that I use "OpenResty/nginx" instead of just OpenResty; if you desire, you
can actually use nginx with only a few OpenResty components. These are the only
OpenResty components you actually need to
[compile](https://www.nginx.com/resources/wiki/extending/compiling/) to use
this package:

* [lua-nginx-module](https://github.com/openresty/lua-nginx-module)
* [lua-resty-core](https://github.com/openresty/lua-resty-core)
* [lua-resty-shell](https://github.com/openresty/lua-resty-shell)

Optionally, you can build these with OpenResty's
[branch](https://github.com/openresty/luajit2) of LuaJIT 2 instead of the
original.

## Copyright and Licensing

This package is copyrighted by [Joshua 'joshuas3'
Stockin](https://joshstock.in/) and licensed under the [MIT License](LICENSE).

&lt;<https://joshstock.in>&gt; | josh@joshstock.in | joshuas3#9641
