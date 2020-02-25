# vis-plug

An experimental minimal plugin manager for the [vis](https://github.com/martanne/vis) text editor.

# Install

git clone `vis-plug` to your `plugins` folder:

`P=$HOME/.config/vis/plugins;mkdir -p $P|git -C $P clone https://github.com/erf/vis-plug.git`

or copy using curl:

`curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs`
 
# Configure

Setup your `visrc.lua` as follows.

```
local plugins = {
	['https://github.com/erf/vis-cursors.git']         = 'init',
	['https://github.com/lutobler/vis-commentary.git'] = 'vis-commentary',
}
require('plugins/vis-plug').init(plugins)
```

Optionally set `PLUG_PATH` as an environment variable or via module.

# Commands

We support the following `vis` commands:

`plug-list` - **list** all plugins

`plug-install` - **git clone** all plugins

`plug-update` - **git pull** all plugins


