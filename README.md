# vis-plug

A minimal plugin and themes manager for the [vis](https://github.com/martanne/vis) text editor.

Configure plugin and theme urls in your `visrc.lua`. See [Config](#config). 

List, install and update plugins and themes using the [Commands](#commands). 

Plugins are required at startup after calling `plug-install`.

# Install

Download `vis-plug` manually or use this install script. 

```bash
curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs
```

Require `vis-plug` in your `visrc.lua` file. See [Plugins](https://github.com/martanne/vis/wiki/Plugins).

# Config

Configure plugins in your `visrc.lua`, using a Lua table with git url, initial 
file name and an optional plugin name for accessing it's variables. Then pass it 
to the `init` method of `vis-plug`. 

Example `visrc.lua`.

```lua
local plugins = {
	['https://github.com/erf/vis-cursors.git']         = { 'init', 'cursors' },
	['https://github.com/lutobler/vis-commentary.git'] = { 'vis-commentary' },
}
local plug = require('plugins/vis-plug')
plug.init(plugins)
plug.plugins.cursors.path = '/Users/name/.test'
```

Optionally add a list of themes as a second parameter to `init`.

```lua
local themes = {
	'https://raw.githubusercontent.com/pshevtsov/base16-vis/master/themes/base16-summerfruit-light.lua',
	'https://raw.githubusercontent.com/pshevtsov/base16-vis/master/themes/base16-unikitty-light.lua',
}
require('plugins/vis-plug').init(plugins, themes)
```

# Commands

We support the following `vis` commands:

`:plug-list` - list plugins and themes

`:plug-install` - git clone plugins and curl install themes

`:plug-update` - git pull plugins


