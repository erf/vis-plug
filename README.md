# vis-plug 🍜

A minimal plugin-manager for [vis](https://github.com/martanne/vis)

`vis-plug` plugins are defined by a Lua file in a git repository and can be both a [plugin](https://github.com/martanne/vis/wiki/Plugins) or a [theme](https://github.com/martanne/vis/wiki/Themes).

[Configure](#Configure) plugins in your `visrc` and use [Commands](#Commands) to install and more.

Plugins are installed using `git` (in the background) to a cache folder and required on `init`.

## Install

git clone `vis-plug` and require it in your `visrc`.

You can use this one-liner to install `vis-plug` (if environment variables are set) and then require it in your `visrc`.

```sh
[ -n "${XDG_CONFIG_HOME:-$HOME}" ] && [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/vis/plugins" ] && git clone https://github.com/erf/vis-plug.git "${XDG_CONFIG_HOME:-$HOME/.config}/vis/plugins/vis-plug" || echo "Error: The plugin path could not be determined or does not exist. Ensure XDG_CONFIG_HOME or HOME is set and that the path exists."
```

## Configure

Configure plugins in your `visrc` as a list of tables given to the `plug.init` method.

Example:

```Lua

local plug = require('plugins/vis-plug')

-- configure plugins in an array of tables with git urls and options
local plugins = {

	-- load a plugin given a repo (https://github.com/ can be omitted and expects a 'init.lua' file)
	{ 'erf/vis-cursors' },

	-- first parameter is a shorthand for 'url'
	{ url = 'erf/vis-cursors' },

	-- specify the lua file to require (or theme to set) and give a ref (commit, branch, tag) to checkout
	{ 'erf/vis-test', file = 'test', ref = 'some-branch' },

	-- specify an alias to later use to access plugin variables (see example below)
	{ 'erf/vis-highlight', alias = 'hi' },

	-- configure themes by setting 'theme = true'. The theme 'file' will be set on INIT
	{ 'samlwood/vis-gruvbox', theme = true, file = 'gruvbox' },
}

-- require and optionally install plugins on init
plug.init(plugins, true)

-- access plugins via alias
plug.plugins.hi.patterns[' +\n'] = { style = 'back:#444444' }
```

Each plugin table can have the following options:

- `url` - the url to the git repo (`https://github.com or https://` can be omitted)
- `file` - the relative path to the lua file (defaults to `init`, skip the `.lua` part) (optional)
- `ref` - checkout a spesific commit, branch or tag (optional)
- `alias` - access plugins via `plug.plugins.{alias}` (optional)
- `theme` - set `theme = true` if theme; will set theme on INIT event (optional)

### Install on init

Pass _true_ as second argument to `init` to install on init.

```Lua
require('plugins/vis-plug').init(plugins, true)
```

### Install path

Plugins are installed (cloned) to the following path (in this order):

`(VIS_PLUG_HOME|XDG_DATA_HOME|XDG_CACHE_HOME|HOME/.cache)/vis-plug/{plugins|themes}/{plugin}`

Use `plug.path` to set a custom install path:

```Lua
plug.path('/Users/user/my-plugins')
```

### Themes

Install themes using the `{ theme = true, file = 'somepath/theme-file' }` option (don't include .lua)

The first theme in the config table is set on the `INIT` event.

Example theme:

```
local plugins = {
	{ 'timoha/vis-acme', theme = true, file = 'acme' },
}
```

## Commands

We support the following `vis` commands:

`:plug-list` - list plugins and themes

`:plug-install` - install plugins (git clone)

`:plug-update` - update plugins (git pull)

`:plug-outdated` - check if plugins are up-to-date

`:plug-upgrade` - upgrade to latest vis-plug using git pull

`:plug-remove` - delete plugin by {name} (`:plug-list` for names)

`:plug-clean` - delete all plugins from disk

`:plug-checkout` - checkout {name} {commit|branch|tag}

`:plug-commands` - list commands (these)

## vis-plugins

I've created [vis-plugins](https://github.com/erf/vis-plugins) - a web page with is a list of plugins and themes based on the [vis wiki](https://github.com/martanne/vis/wiki).

It's hosted by github at [https://erf.github.io/vis-plugins](https://erf.github.io/vis-plugins)
