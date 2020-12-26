# vis-plug

A minimal plugin manager for the [vis](https://github.com/martanne/vis) editor

[Configure](#Configure) third-party plugins in your `visrc` and use [Commands](#Commands)

## Install

Download and `require` in your `visrc` file, see [plugins](https://github.com/martanne/vis/wiki/Plugins).

### Download script

A simple `curl` download script that works for me on macOS.

```bash
curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs
```

## Configure

Configure plugins in `visrc` as below:

```Lua

local plug = require('plugins/vis-plug')

-- configure plugins as an array of tables with { url, file, alias, branch, commit }
local plugins = {
	{ url = 'erf/vis-cursors' },
	{ url = 'erf/vis-sneak', file = 'init', alias = 'hi' },
	{ url = 'https://github.com/erf/vis-test.git', file = 'init', branch = 'other' },
}

-- require plugins and optionally install them on init
plug.init(plugins)
```

Each configuration is a table with the following records:

- `url` - the git repo ( you can drop `https://github.com` )
- `file` - lua file required on init - defaults to `init` (opt)
- `alias` - access plugins via `plug.plugins.{alias}` (opt)
- `branch` - use branch (opt)
- `commit` - use commit (opt)

### Install on init

Pass **true** as second argument to `init` to install and checkout on init.

```Lua
require('plugins/vis-plug').init(conf, true)
```

### Install path

Plugins are by default installed to the default cache folder on your system:  

`(XDG_CACHE_HOME|HOME/.cache)/vis-plug`

Use `plug.set_path(path)` to set a custom plugins folder.

```Lua
plug.set_path('/Users/user/my-plugins')
```

## Commands

We support the following `vis` commands:

`:plug-ls` - list plugins

`:plug-install` - install plugins (git clone and checkout)

`:plug-update` - update plugins (git pull and checkout)

`:plug-outdated` - are repos up-to-date? (diff commits)

`:plug-upgrade` - fetch latest vis-plug (overwrite current)

`:plug-rm` - delete plugin by {name} (`:plug-ls` for names)

`:plug-clean` - delete all plugins in conf

`:plug-commands` - list commands (these!)