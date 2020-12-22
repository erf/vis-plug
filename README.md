# vis-plug 🦑

A minimal plugin manager for the [vis](https://github.com/martanne/vis) editor.

[Configure](#Configure) your plugins in your `visrc` and type a few [Commands](#Commands).

## Install

Download `vis-plug` and `require` in your `visrc` file (see [plugins](https://github.com/martanne/vis/wiki/Plugins)).

Here is a simple `curl` install script:

```bash
curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs
```

## Configure

### Configure plugins in visrc

Configure plugins in your `visrc.lua` as below:

```Lua
local plug = require('plugins/vis-plug')

local conf = {
	['erf/vis-cursors'] = 'init',
	['erf/vis-highlight'] = { file = 'init', alias = 'hi' },
	['https://github.com/erf/vis-test.git'] = { file = 'init', commit = 'f4849d4' },
}

plug.init(conf)

```

Each configuration has a:

- **key** - the `git` repository 
	- defaults to `https://github.com/` if no **host** is defined
- **value** - the `file` or a `table|array` with the following
	- `file` - lua file required on `init`
	- `alias` - access plugins via `plug.plugins.{alias}` (opt)
	- `branch` - use a specific branch (opt)
	- `commit` - use a specific commit (opt)

### Install on init

Pass **true** as the second argument to `init` to `install_on_init`

```Lua
require('plugins/vis-plug').init(conf, true)
```

### Plugins install path

Plugins are by default installed to your `visrc` configuration path. 

>E.g.`$HOME/.config/vis/plugins`

Use `plug.set_path(path)` to override this.

```Lua
plug.set_path('/Users/some-user/my-plugins')
```

## Commands

We support the following `vis` commands:

`:plug-ls` - list plugins in conf

`:plug-install` - install plugins in conf (using git clone)

`:plug-update` - update plugins in conf (using git pull)

`:plug-rm {name}` - remove plugin by name (see `plug-list` for name)

`:plug-clean` - delete all plugins in conf

`:plug-outdated` - check if repos are up-to-date

`:plug-commands` - list available commands (these!)
