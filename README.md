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

-- configure plugins in an array of tables with git urls and options 
local plugins = {
	{ url = 'erf/vis-sneak' },
	{ url = 'erf/vis-highlight', alias = 'hi' },
	{ url = 'erf/vis-test.git', file = 'init', ref = 'other' },
	{ url = 'samlwood/vis-gruvbox.git', theme = true },
}

-- access plugins via alias
plug.plugins.hi.patterns[' +\n'] = { style = 'back:#444444' }

-- require and optionally install plugins on init
plug.init(plugins, true)
```

Each plugin table can have the following options:

- `url` - the git url (you can skip `https://github.com` and `https://`)
- `file` - lua file required on init. defaults to `init` (optional)
- `alias` - access plugins via `plug.plugins.{alias}` (optional)
- `ref` - use a spesific commit, branch or tag (optional)
- `theme` - set true if theme (optional)

### Install on init

Pass **true** as second argument to `init` to install and checkout on init.

```Lua
require('plugins/vis-plug').init(conf, true)
```

### Install path

Plugins are by default installed to the default cache folder on your system: 
`(XDG_CACHE_HOME|HOME/.cache)/vis-plug/{plugins|themes}/{plug-name}`

`plug-name` is the git url last folder.

Use `plug.set_path` to set a custom install path:

```Lua
plug.set_path('/Users/user/my-plugins')
```

### Themes

Themes are installed to `{plug-path}/themes/{plug-name}`.

Set using `set theme` command:

```Lua
set theme '{plug-name}/{file}'
```

## Commands

We support the following `vis` commands:

`:plug-list` - list plugins (in conf)

`:plug-install` - install plugins (clone)

`:plug-update` - update plugins (pull)

`:plug-outdated` - check if plugins are up-to-date

`:plug-upgrade` - upgrade to latest vis-plug

`:plug-remove` - delete plugin by {name} (`:plug-ls` for names)

`:plug-clean` - delete all plugins from disk (in conf)

`:plug-checkout` - checkout {name} {commit|branch|tag}

`:plug-commands` - list commands (these)
