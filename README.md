# vis-plug

A minimal plugin manager for the [vis](https://github.com/martanne/vis) text editor.

Configure plugins as **git** urls to your `visrc.lua`. See [Config](#config). 
List, install and update plugins using the [Commands](#commands). Plugins are 
required at startup after calling `plug-install`.

# Install

Download `vis-plug` manually or use this install script. 

```bash
curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs
```

Require `vis-plug` in your `visrc.lua` file. See [Plugins](https://github.com/martanne/vis/wiki/Plugins).

# Config

Configure plugins in your `visrc.lua`, using a Lua table with git url, file pairs, and pass it to `vis-plug`. 

Example `visrc.lua`.

```lua
local plugins = {
	['https://github.com/erf/vis-cursors.git']         = 'init',
	['https://github.com/lutobler/vis-commentary.git'] = 'vis-commentary',
}
require('plugins/vis-plug').init(plugins)
```


# Commands

We support the following `vis` commands:

`:plug-list` - list plugins

`:plug-install` - git clone plugins

`:plug-update` - git pull plugins


