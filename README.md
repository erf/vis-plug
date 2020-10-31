# vis-plug

Experimental plugin manager for [vis](https://github.com/martanne/vis).

[Configure](#configure) plugins and themes in `visrc.lua`.

List, install and update using [Commands](#commands).

Plugins are required and optionally installed on startup.

Plugins are installed to the default `visrc` folder.

> If you want something simpler consider [vis-outdated](https://github.com/erf/vis-outdated)

# Install

Download `vis-plug` manually or using this install script:

```bash
curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs
```

Require `vis-plug` in your `visrc.lua` file. See [Plugins](https://github.com/martanne/vis/wiki/Plugins).

# Configure

### Plugins

Describe plugins in your `visrc.lua` using a Lua table as below:

```lua
local plugins = {
	['https://github.com/erf/vis-cursors.git'] = { 'init', 'cursors' },
	['https://github.com/lutobler/vis-commentary.git'] = 'vis-commentary',
}
local plug = require('plugins/vis-plug')
plug.init(plugins)
plug.plugins.cursors.path = '/Users/name/.test'
```

The key is the URL of the plugin git repo. 

The value is either a string with the lua start file or a table with an initial file name and an optional name for accessing the plugin after initialization (and setting variables).

Pass the config table to the `init` method and access plugins via `plug.plugins`

### Themes

We also support adding a list of themes as a second parameter to `init`. Themes are fetched using `curl` on `plug-install` and listed using `plug-list`.

Example:

```lua
local themes = {
	'https://raw.githubusercontent.com/pshevtsov/base16-vis/master/themes/base16-summerfruit-light.lua',
	'https://raw.githubusercontent.com/pshevtsov/base16-vis/master/themes/base16-unikitty-light.lua',
}
local plug = require('plugins/vis-plug').init(plugins, themes)
```


### Install on initialization

Pass a bool `install_on_init` as the third parameter to `plug.init` to indicate 
you'd like to install the plugins and themes at startup if they don't already 
exists.

Example:

```lua
local plug = require('plugins/vis-plug')
plug.init(plugins, themes, true)
```

# Commands

We support the following `vis` commands:

`:plug-list` - list plugins and themes

`:plug-install` - git clone plugins and curl install themes

`:plug-update` - git pull plugins


