# What

A minimal plugin manager for the [vis](https://github.com/martanne/vis) text editor.

*EARLY PROTOTYPE NOT VERY USABLE*

# Installing

You need [wget](https://www.gnu.org/software/wget/) for this to work.

Copy `plug.lua` to your `.config/vis/plugins` folder.

# Usage

In your `visrc.lua`, set the urls to your third party plugins before requiring `plug.lua`.

Example:
```
plugins = {
	'https://raw.githubusercontent.com/erf/vis-cursors/master/cursors.lua',
	'https://raw.githubusercontent.com/erf/vis-title/master/title.lua',
}

require('plugins/plug')
```

Plugins will automatically be downloaded to your plugins folder and required on start.
