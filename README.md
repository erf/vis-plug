# vis-plug 🍜

A minimal plugin-manager for [vis](https://github.com/martanne/vis)

[Configure](#Configure) plugins in your `visrc` and use [Commands](#Commands) to install and more.

Plugins are installed using `git` (in the background) to a cache folder and required on `init`.

## Install

git clone `vis-plug` and require it via your `visrc`. See [Plugins](https://github.com/martanne/vis/wiki/Plugins).

## Configure

Configure plugins in your `visrc` as a list of tables given to the `plug.init` method.

Example:

```Lua

local plug = require('plugins/vis-plug')

-- configure plugins in an array of tables with git urls and options 
local plugins = {

	-- load a plugin given a url (defaults to https://github.com/) and expects a 'init.lua' file
	{ 'erf/vis-cursors' },

	-- first parameter is a shorthand for 'url'
	{ url = 'erf/vis-cursors' },

	-- specify the lua file to require (or theme to set) and give a ref (commit, branch, tag) to checkout
	{ 'erf/vis-test', file = 'init', ref = 'other' },

	-- specify an alias to later use to access plugin variables (see example below)
	{ 'erf/vis-highlight', alias = 'hi' },

	-- configure themes by setting 'theme = true'. The theme 'file' will be set on INIT
	{ 'samlwood/vis-gruvbox', theme = true, file = 'gruvbox' },
}

-- access plugins via alias
plug.plugins.hi.patterns[' +\n'] = { style = 'back:#444444' }

-- require and optionally install plugins on init
plug.init(plugins, true)
```

Each plugin table can have the following options:

- `url` - the git url (defaults to `https://github.com` and `https://`)
- `file` - the lua file to require on init (defaults to `init`) or the theme file to set on INIT (optional)
- `ref` - checkout a spesific commit, branch or tag (optional)
- `alias` - access plugins via `plug.plugins.{alias}` (optional)
- `theme` - set `theme = true` if theme; will set theme on INIT event (optional)

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

Install themes using the `{ theme = true, file = 'acme' }` option

The first theme in the config table is set on the `INIT` event.

Example theme:

```
local conf = {
	{ url = 'timoha/vis-acme', theme = true, file = 'acme' },
}
```

## Commands

We support the following `vis` commands:

`:plug-list` - list plugins and themes in config table

`:plug-install` - install plugins (git clone)

`:plug-update` - update plugins (git pull)

`:plug-outdated` - check if plugins are up-to-date

`:plug-upgrade` - upgrade to latest vis-plug using git pull

`:plug-remove` - delete plugin by {name} (`:plug-list` for names)

`:plug-clean` - delete all plugins from disk (in conf)

`:plug-checkout` - checkout {name} {commit|branch|tag}

`:plug-commands` - list commands (these)
