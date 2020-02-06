# vis-plug

An experimental minimal plugin manager for the [vis](https://github.com/martanne/vis) text editor.

List plugins in your `visrc.lua` file; then `show`, `install` or `update` them - with the help of [git](https://github.com/).

# Install

Download and require `vis-plug` in your `visrc.lua` file; then add plugin urls and startup scripts. 

#### Example
```
local plugins = {
	['https://github.com/erf/vis-cursors.git']         = 'init',
	['https://github.com/lutobler/vis-commentary.git'] = 'vis-commentary',
}
require('plugins/vis-plug').init(plugins)
```

#### Install script
```
curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs
```

# Commands

We support the following `vis` commands:

`:plug-list` - list all plugins

`:plug-install` - git clone all plugins

`:plug-update` - git pull all plugins


