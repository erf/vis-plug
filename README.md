# vis-plug

A minimal plugin manager for the [vis](https://github.com/martanne/vis) editor.

> Also consider [vis-outdated](https://github.com/erf/vis-outdated) 

## Install

Download `vis-plug` manually or use this script

```bash
curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs
```

Require `vis-plug`. See [plugins](https://github.com/martanne/vis/wiki/Plugins).

Plugins are installed to the default `visrc` + `/plugins` path.

> E.g.`$HOME/.config/vis/plugins`

## Configure

Configure plugins in your `visrc.lua` as below:

```lua
local plugins = {
	['https://github.com/erf/vis-highlight.git'] = 'init',
	['https://github.com/erf/vis-cursors.git'] = { file = 'init', alias = 'C' },
	['https://github.com/erf/vis-test.git'] = { file = 'init', branch = 'other', commit = 'f4849d4' },
}
local plug = require('plugins/vis-plug').init(plugins)
plug.plugins.C.path = '/Users/user/.cursors1'
```

Each plugin configuration has a **key**, which is the URL to the git repository; and a **value**, which is either the Lua `file` or a record for `file`, `alias` and `branch`.

Set `alias` to access plugin variables via `plug.plugins.{alias}`.

> E.g. `plug.plugins.C` is an alias to `vis-cursors`

Set `branch` to use a specific `git` branch.

> `branch` is set on `plug_install`, `install_on_init` or `plug_update`

Set `commit` to use a spesific `commit` hash.

#### Install on init

Install plugins on `init`, by passing **true** as the second argument to `init`.

```lua
require('plugins/vis-plug').init(plugins, true)
```

## Commands

We support the following `vis` commands:

`:plug-list` - list plugins 

`:plug-install` - install plugins using git clone

`:plug-update` - update plugins using git pull