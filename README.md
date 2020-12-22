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

-- configure plugins with URL / file|options
local conf = {
	['erf/vis-cursors'] = 'init',
	['erf/vis-highlight'] = { file = 'init', alias = 'hi' },
	['https://github.com/erf/vis-test.git'] = { file = 'init', branch = 'other' },
}

-- require plugins and optionally install them on init
plug.init(conf, true)
```

Each configuration has a:

- **key** - URL to the `git` repository
	- short urls for `https://github.com/` is allowed
- **value** - the `file` or a `table|array` with the following
	- `file` - lua file required on `init`
	- `alias` - access plugins via `plug.plugins.{alias}` (opt)
	- `branch` - use a specific branch (opt)
	- `commit` - use a specific commit (opt)

### Install on init

Pass **true** as a second arg to `init` to install and checkout on init.

```Lua
require('plugins/vis-plug').init(conf, true)
```

### Install path

Plugins are by default installed to the default cache folder on your system:  

`(XDG_CACHE_HOME|HOME/.cache)/vis-plug`

Use `plug.path(path)` to set a custom plugins folder.

```Lua
plug.path('/Users/user/my-plugins')
```

## Commands

We support the following `vis` commands:

`:plug-ls` - list plugins

`:plug-install` - install plugins (git clone)

`:plug-update` - update plugins (git pull)

`:plug-outdated` - are repos up-to-date? (diff commits)

`:plug-upgrade` - fetch latest vis-plug (overwrite current)

`:plug-rm {name}` - delete plugin by name (`:plug-ls` for names)

`:plug-clean` - delete all plugins in conf

`:plug-commands` - list commands (these!)