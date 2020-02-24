# vis-plug

an minimal plugin manager for the [vis](https://github.com/martanne/vis) text editor.

# Install

`curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs`
 
# Configure

configure your `visrc.lua` as follows:
```
local plugins = {
	['https://github.com/erf/vis-cursors.git']         = 'init',
	['https://github.com/lutobler/vis-commentary.git'] = 'vis-commentary',
}
require('plugins/vis-plug').init(plugins)
```

set git URL followed by startup script ( don't include `.lua` ext ).

set an optional `PLUG_PATH` environment variable.

# Commands

we support the following commands:

`plug-list` - **list** all plugins

`plug-install` - **git clone** all plugins

`plug-update` - **git pull** all plugins


