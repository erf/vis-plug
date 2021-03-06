# vis-plug

A minimal plugin (and theme) manager for [vis](https://github.com/martanne/vis)

Installs plugins in parallel using `git` and `xargs` to a cache folder and require them on `init`.

[Configure](#Configure) plugins in your `visrc` and use [Commands](#Commands) to install and more.

## Install

Download and `require` `vis-plug` in your `visrc` file, see [Plugins](https://github.com/martanne/vis/wiki/Plugins).

## Configure

Configure plugins in your `visrc` as below:

```Lua

local plug = require('plugins/vis-plug')

-- plugins are configured as an array of tables with a git url and other params 
local plugins = {
	{ url = 'erf/vis-sneak' },
	{ url = 'erf/vis-highlight', alias = 'hi' },
	{ url = 'github.com/erf/vis-test.git', file = 'init', branch = 'other' },
	{ url = 'samlwood/vis-gruvbox.git', theme = true },
}

-- require plugins and optionally install them on init
plug.init(plugins)
```

Each table can have the following options:

- `url` - the git repo ( you can drop `https://github.com` or `https://` )
- `file` - lua file required on init - defaults to `init` (optional)
- `alias` - access plugins via `plug.plugins.{alias}` (optional)
- `branch` - use branch (optional)
- `commit` - use commit (optional)
- `theme` - true if theme (optional)

### Install on init

Pass **true** as second argument to `init` to install and checkout on init.

```Lua
require('plugins/vis-plug').init(conf, true)
```

### Install path

Plugins are by default installed to the default cache folder on your system: 
`(XDG_CACHE_HOME|HOME/.cache)/vis-plug`

Use `plug.set_path` to set a custom install path:

```Lua
plug.set_path('/Users/user/my-plugins')
```

### Themes

Themes are installed to `{plug-path}/themes/name`.

Set theme in `visrc` file like:

```Lua
set theme 'name/file'
```

## Commands

We support the following `vis` commands:

`:plug-ls` - list all plugins in conf

`:plug-install` - install all plugins in conf (git clone)

`:plug-update` - update all plugins in conf (git pull)

`:plug-outdated` - are repos up-to-date? (diff commits)

`:plug-upgrade` - download latest vis-plug version (overwrites current)

`:plug-rm` - delete a plugin by {name} (`:plug-ls` for names)

`:plug-clean` - delete all plugins in conf

`:plug-checkout` - checkout {name} {branch|commit}

`:plug-commands` - list all commands (these)

