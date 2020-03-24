# vis-plug

An experimental minimal plugin manager for the [vis](https://github.com/martanne/vis) text editor.

Configure plugins in your `visrc.lua` file; then `show`, `install` or `update` them - with the help of [git](https://github.com/).

Plugins are required on start once you have installed them using the `install` command.

# Install

Download `vis-plug` and require it in your `visrc.lua` file, then configure plugins ( git url and init file ). 

#### Example visrc.lua
```lua
local plugins = {
	['https://github.com/erf/vis-cursors.git']         = 'init',
	['https://github.com/lutobler/vis-commentary.git'] = 'vis-commentary',
}
require('plugins/vis-plug').init(plugins)
```

#### curl install script
```bash
curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs
```

# Commands

We support the following `vis` commands:

`:plug-list` - list all plugins

`:plug-install` - git clone all plugins

`:plug-update` - git pull all plugins


