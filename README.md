# What

A minimal plugin manager for the [vis](https://github.com/martanne/vis) text editor.

*PROTOTYPE FOR TESTING ONLY*

# Installation

You need `git`.

Clone `vis-plug` in your  `.config/vis/plugins` folder.

Setup your  `visrc.lua` as follows:


```
plugins = {
	'https://github.com/erf/vis-cursors.git',
	'https://github.com/erf/vis-title.git',
}

require('plugins/vis-plug')
```

Make sure plugins uses the `init.lua` convention.

Plugins will download to your plugins folder and require on startup.
