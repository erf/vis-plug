# vis-plug

A minimal plugin-manager for [vis](https://github.com/martanne/vis)

[Configure](#Configure) plugins in your `visrc` and use [Commands](#Commands) to install and more.

Plugins are installed using `git` and `xargs` (in parallel), to a cache folder and required on `init`.

## Install

Download and require `vis-plug` in your `visrc`. See [Plugins](https://github.com/martanne/vis/wiki/Plugins).

## Configure

Configure plugins in your `visrc` as below:

```Lua

local plug = require('plugins/vis-plug')

-- configure plugins in an array of tables with git urls and options 
local plugins = {
	{ url = 'erf/vis-cursors' },
	{ url = 'erf/vis-test', file = 'init', ref = 'other' },
	{ url = 'erf/vis-highlight', alias = 'hi' },
	{ url = 'samlwood/vis-gruvbox', theme = true },
}

-- access plugins via alias
plug.plugins.hi.patterns[' +\n'] = { style = 'back:#444444' }

-- require and optionally install plugins on init
plug.init(plugins, true)
```

Each plugin table can have the following options:

- `url` - the git url (you can skip `https://github.com` and `https://`)
- `file` - lua file required on init. defaults to `init` (optional)
- `ref` - checkout a spesific commit, branch or tag (optional)
- `alias` - access plugins via `plug.plugins.{alias}` (optional)
- `theme` - set true if theme (optional)

### Install on init

Pass *true* as second argument to `init` to install and checkout on init.

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

Install themes by setting the `theme = true` option.

Themes are installed to `{plug-path}/themes/{plug-name}`.

Set a theme using the `set theme` command in your `visrc`.

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

`:plug-remove` - delete plugin by {name} (`:plug-list` for names)

`:plug-clean` - delete all plugins from disk (in conf)

`:plug-checkout` - checkout {name} {commit|branch|tag}

`:plug-commands` - list commands (these)
