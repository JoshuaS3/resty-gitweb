# resty-gitweb

A git web interface for Lua/OpenResty.

![Sample image](https://joshstock.in/static/images/resty-gitweb.png)

## Requirements

Lua modules (Lua 5.1/LuaJIT 2.1.0/OpenResty LuaJIT compatible, accessible from
Lua path/cpath):

| Module | Description |
| ------ | ----------- |
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
| [libgit2](https://github.com/libgit2/libgit2) | Dynamically linkable C API for Git |

## Using

1. Copy this directory with its scripts to a place OpenResty/nginx workers have
   access, such as `/srv/[SITE]/resty-gitweb`. (In reality it doesn't matter
   where, as long as it's accessible.)

2. Copy your config file (`resty-gitweb.yaml`) to
   `/etc/[SITE]/resty-gitweb.yaml` (or somewhere else)

3. Add the following near the top (`main` context, outside of any blocks) of
   your OpenResty/nginx configuration file:

```
# resty-gitweb won't run without this
env RESTY_GITWEB_ENABLED=;

# PROD for Production, DEV for Development. DEV by default.
env RESTY_GITWEB_ENV=PROD;

# Wherever you put your configuration file
env RESTY_GITWEB_CONFIG=/etc/[SITE]/resty-gitweb.yaml;
```

4. Add the following to the `http` block in your OpenResty/nginx configuration
   file:

```
# Add resty-gitweb to your Lua package path
lua_package_cpath "/usr/local/lib/lua/5.1;;"
lua_package_path "/usr/local/share/lua/5.1;/srv/[SITE]/resty-gitweb/?.lua;;";

# Initialize modules for nginx workers
init_by_lua_file /srv/[SITE]/resty-gitweb/init.lua;
```

5. And in whichever `location` block you wish to serve content:

```
# Delegate request to OpenResty through resty-gitweb app script
content_by_lua_file /srv/[SITE]/resty-gitweb/app.lua;
```

6. Reload OpenResty/nginx to update config

## OpenResty or nginx?

Note that I use "OpenResty/nginx" instead of just OpenResty; while you can just
install and use the pre-built
[OpenResty](https://openresty.org/en/download.html) package, you could actually
use nginx with only a few added OpenResty components. These are the only
OpenResty components you actually need to
[compile](https://www.nginx.com/resources/wiki/extending/compiling/) to use
this package:

#### nginx modules

* [lua-nginx-module](https://github.com/openresty/lua-nginx-module)

#### Lua libraries

(run `sudo make all install LUA_VERSION=5.1` for each)

* [lua-resty-core](https://github.com/openresty/lua-resty-core)
* [lua-resty-shell](https://github.com/openresty/lua-resty-shell)
* [lua-resty-lrucache](https://github.com/openresty/lua-resty-lrucache)
* [lua-resty-signal](https://github.com/openresty/lua-resty-signal)
* [lua-tablepool](https://github.com/openresty/lua-tablepool)

Note that lua-nginx-module is the only nginx module that needs to be installed
with nginx compatibility. The other dependencies just need to be installed on
your Lua path/cpath. **If you're compiling OpenResty components yourself, you
may need to build them with OpenResty's
[branch](https://github.com/openresty/luajit2) of LuaJIT 2.1.0 instead of the
original.**

(The full OpenResty package has far more precompiled OpenResty components, so
you may just want to use that if resty-gitweb isn't the only thing you want to
use OpenResty for.)

## Copyright and Licensing

This package is copyrighted by [Joshua 'joshuas3'
Stockin](https://joshstock.in/) and licensed under the [MIT License](LICENSE).

&lt;<https://joshstock.in>&gt; | josh@joshstock.in | joshuas3#9641
