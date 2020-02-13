# vis-plug

A minimal plugin manager for [vis](https://github.com/martanne/vis) text editor.

*EXPERIMENTAL PROTOTYPE*

# Install
 
`mkdir -p $HOME/.config/vis/plugins|git -C $HOME/.config/vis/plugins clone https://github.com/erf/vis-plug.git`

Add to your `visrc.lua` as follows:

```
plugins = {
	['https://github.com/erf/vis-cursors.git']         = 'init',
	['https://github.com/lutobler/vis-commentary.git'] = 'vis-commentary',
}

require('plugins/vis-plug')
```

Add the plugin `[URL]` first, followed by the startup file ( without the `.lua` ext ).

# Commands

We support the following commands:

`plug-list` - **list** all plugins

`plug-install` - **git clone** all plugins

`plug-update` - **git pull** all plugins


