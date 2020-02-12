# vis-plug

A minimal plugin manager for the [vis](https://github.com/martanne/vis) text editor, which is itself a plugin.

This is an *EXPERIMENTAL PROTOTYPE* built for fun.

# Install

Make sure you have [git](https://git-scm.com/) installed.

Clone `vis-plug` to your `.config/vis/plugins` folder.

# Configure

Setup your  `visrc.lua` as follows.

```
plugins = {
	['https://github.com/erf/vis-cursors.git']         = 'init',
	['https://github.com/lutobler/vis-commentary.git'] = 'vis-commentary',
}

require('plugins/vis-plug')
```

That is the `[URL]` first, followed by the startup file without the `.lua` ext.

# Commands

We support the following commands:

`plug-list` - list the names of all plugins

`plug-install` - does **git clone** on all plugins

`plug-update` - does **git pull** on all plugins


