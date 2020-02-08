# What

A minimal plugin manager for the [vis](https://github.com/martanne/vis) text editor.

*EXPERIMENTAL PROTOTYPE*

# Installation

Install [git](https://git-scm.com/).

Clone `vis-plug` to your `.config/vis/plugins` folder.

# Usage

Setup your  `visrc.lua` as follows:


```
plugins = {
	'https://github.com/erf/vis-cursors.git',
	'https://github.com/erf/vis-title.git',
}

require('plugins/vis-plug')
```

Make sure plugins uses the `init.lua` convention.

Plugins are cloned to your plugins folder and required on startup.
