# vis-plug

A minimal plugin manager for [vis](https://github.com/martanne/vis) text editor.

# Install

Install [git](https://git-scm.com/)
 
git clone to your `plugins` folder:

`P=$HOME/.config/vis/plugins;mkdir -p $P|git -C $P clone https://github.com/erf/vis-plug.git`

or copy using curl:

`curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs`

# Configure

Configure your `visrc.lua` as follows:
```
plugins = {
	['https://github.com/erf/vis-cursors.git']         = 'init',
	['https://github.com/lutobler/vis-commentary.git'] = 'vis-commentary',
}

require('plugins/vis-plug')
```

Set the git `[URL]` followed by startup script ( don't include `.lua` ext ).

# Commands

We support the following commands:

`plug-list` - **list** all plugins

`plug-install` - **git clone** all plugins

`plug-update` - **git pull** all plugins


