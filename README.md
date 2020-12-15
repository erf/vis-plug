# vis-plug

Experimental plugin manager for the [vis](https://github.com/martanne/vis) editor.

> Also consider [vis-outdated](https://github.com/erf/vis-outdated) 

# Install

Download `vis-plug` manually or using this install script:

```bash
curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs
```

Require `vis-plug` in your `visrc.lua` file. See [Plugins](https://github.com/martanne/vis/wiki/Plugins).

# Configure

### Configure plugins in visrc.lua

Describe plugins in your `visrc.lua` as below

```lua
local plugins = {
	['https://github.com/erf/vis-cursors.git'] = 'init',
	['https://github.com/erf/vis-highlight.git'] = 'init',
}
require('plugins/vis-plug').init(plugins)
```

The **key** is the URL to the git repository.

The **value** is the init lua file.

### Plugin aliases

If you need to access plugin variables, use an array as the **value** and its second item will become an *alias* for the plugin. 

```lua
local plugins = {
	['https://github.com/erf/vis-cursors.git'] = { file = 'init', var = 'C' },
}
local plug = require('plugins/vis-plug').init(plugins)
plug.plugins.C.path = '/Users/erlend/.vis_plug'
```

### Install on init

Pass a second boolean argument to `init` to indicate if you'd like to install 
plugins at startup (if not already installed).

```lua
require('plugins/vis-plug').init(plugins, true)
```

Plugins are installed to the default `visrc` folder.

# Commands

We support the following `vis` commands:

`:plug-list` - list plugins 

`:plug-install` - git clone plugins

`:plug-update` - git pull plugins
