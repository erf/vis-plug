# vis-plug 🦑

A minimal plugin manager for the [vis](https://github.com/martanne/vis) editor.

Keep up-to-date with third-party `vis` plugins by [Configuring](#Configure) your `visrc` and typing a few [Commands](#Commands).

## Install

Download `vis-plug` and `require` in your `visrc` file. See [plugins](https://github.com/martanne/vis/wiki/Plugins).

Simple `curl` install script, that might work for you.

```bash
curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs
```

## Configure

### Configure plugins in visrc

Configure plugins in your `visrc.lua` using a set of URLs like below:

```Lua
local plug = require('plugins/vis-plug')

local conf = {
	['https://github.com/erf/vis-highlight.git'] = 'init',
	['https://github.com/erf/vis-cursors.git'] = { file = 'init', alias = 'C' },
	['https://github.com/erf/vis-test.git'] = { file = 'init', branch = 'other', commit = 'f4849d4' },
}

plug.init(conf)

```

Each configuration has a:

- **key** - the `git` repository
- **value** - the `file` or a `table|array` with the following
	- `file` - lua file required on `init`
	- `alias` - access plugin variables via `plug.plugins.{alias}` (optional)
	- `branch` - use a specific branch (optional)
	- `commit` - use a specific commit (optional)

### Install on init

Pass **true** as the second argument to `init` to `install_on_init`

```Lua
require('plugins/vis-plug').init(conf, true)
```

### Plugins install path

Plugins are by default installed to your `visrc` configuration path. 

>E.g.`$HOME/.config/vis/plugins`

Set `plug.path` to override this.

```Lua
plug.path = '/Users/erlend/my-plugins'
```

## Commands

We support the following `vis` commands:

`:plug-ls` - list plugins

`:plug-in` - install plugins in conf (using git clone)

`:plug-up` - update plugins in conf (using git pull)

`:plug-rm {name}` - delete plugin by name (see `plug-list` for name)

`:plug-cl` - delete all plugins in conf