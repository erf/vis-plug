# What

A minimal plugin manager for the [vis](https://github.com/martanne/vis) text editor.

*EARLY PROTOTYPE NOT VERY USABLE*

# Installing

You need [wget](https://www.gnu.org/software/wget/) for this to work.

Clone `vis-plug` to your `.config/vis/plugins` folder.

# Usage

In your `visrc.lua`, set the urls to your third party plugins before requiring `vis-plug`.

Example:
```
plugins = {
	'https://raw.githubusercontent.com/erf/vis-cursors/master/cursors.lua',
	'https://raw.githubusercontent.com/erf/vis-title/master/title.lua',
}

require('plugins/vis-plug')
```

Plugins will automatically download to your plugins folder and required on startup.
