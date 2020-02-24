# vis-plug

an minimal plugin manager for the [vis](https://github.com/martanne/vis) text editor.

# Install

git clone `vis-plug` to your `plugins` folder:

`P=$HOME/.config/vis/plugins;mkdir -p $P|git -C $P clone https://github.com/erf/vis-plug.git`

or copy using curl:

`curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs`
 
# Configure

configure your `visrc.lua` as follows:
```
require('plugins/vis-plug').init({
	['https://github.com/erf/vis-cursors.git']         = 'init',
	['https://github.com/lutobler/vis-commentary.git'] = 'vis-commentary',
})
```

set the git URL followed by a startup script ( don't include `.lua` ext ).

you can set an optional `PLUG_PATH` environment variable for the plugins folder.

# Commands

we support the following commands:

`plug-list` - **list** all plugins

`plug-install` - **git clone** all plugins

`plug-update` - **git pull** all plugins


