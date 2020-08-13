# vis-plug

An experimental plugin and theme manager for the [vis](https://github.com/martanne/vis) editor.

[Configure](#configure) plugins and themes in `visrc.lua`.

List, install and update plugins and themes using the [Commands](#commands). 

Plugins are required at startup after calling `plug-install`.

# Install

Download `vis-plug` manually or using this install script:

```bash
curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs
```

Require `vis-plug` in your `visrc.lua` file. See [Plugins](https://github.com/martanne/vis/wiki/Plugins).

# Configure

### Plugins

Describe plugins in your `visrc.lua` using a Lua table. Key is the URL for the plugin git repo and the value a table with the lua file name and an optional name for accessing the plugin after initialization (and setting variables).

Pass the plugins table to the `init` method and access the plugins via `plug.plugins`.

Example:

```lua
local plugins = {
	['https://github.com/erf/vis-cursors.git']         = { 'init', 'cursors' },
	['https://github.com/lutobler/vis-commentary.git'] = { 'vis-commentary' },
}
local plug = require('plugins/vis-plug')
plug.init(plugins)
plug.plugins.cursors.path = '/Users/name/.test'
```

### Themes

Optionally add a list of theme urls as a second parameter to `init`. Themes are
fetched using `curl` on `plug-install` and listed using `plug-list`.

```lua
local themes = {
	'https://raw.githubusercontent.com/pshevtsov/base16-vis/master/themes/base16-summerfruit-light.lua',
	'https://raw.githubusercontent.com/pshevtsov/base16-vis/master/themes/base16-unikitty-light.lua',
}
local plug = require('plugins/vis-plug')
plug.init(plugins, themes)
```

# Commands

We support the following `vis` commands:

`:plug-list` - list plugins and themes

`:plug-install` - git clone plugins and curl install themes

`:plug-update` - git pull plugins


