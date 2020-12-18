# vis-plug

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
- **value** - the `file` or a `record` with the following
	- `file`
	- `alias` (optional)
	- `branch` (optional)
	- `commit` (optional)

The `file` is the lua file that is required on `init`.

Set `alias` to access plugin variables via `plug.plugins.{alias}`
> E.g. `plug.plugins.C.path = '/Users/user/.cursors1'`

Set `branch` to use a specific `git` branch.

Set `commit` to use a spesific `commit` hash.

### Install on init

Install on `init`, by passing **true** as the second argument to `init`.

```Lua
require('plugins/vis-plug').init(conf, true)
```

### Plugins path

Plugins are by default installed to your default configuration path on your 
system. 

>E.g.`$HOME/.config/vis/plugins`.

You can override this by setting `plug.path`.

```Lua
plug.path = '/Users/erlend/my-plugins'
```

## Commands

We support the following `vis` commands:

`:plug-list` - list plugins

`:plug-install` - install plugins in conf (using git clone)

`:plug-update` - update plugins in conf (using git pull)

`:plug-delete {name}` - delete a plugin by name (see `plug-list` for name)

`:plug-clean` - delete all plugins in conf