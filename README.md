# vis-plug

Experimental plugin manager for the [vis](https://github.com/martanne/vis) editor.

> Also consider [vis-outdated](https://github.com/erf/vis-outdated) 

# Install

Download `vis-plug` manually or using this install script:

```bash
curl https://raw.githubusercontent.com/erf/vis-plug/master/init.lua -o $HOME/.config/vis/plugins/vis-plug/init.lua --create-dirs
```

Require `vis-plug` in your `visrc.lua`.

Plugins are installed to the default `visrc` + `plugins` path.

E.g.`$HOME/.config/vis/plugins`

# Configure

### Configure plugins in visrc.lua

Describe plugins in a table, in your `visrc.lua` as below:

```lua
local plugins = {
	['https://github.com/erf/vis-highlight.git'] = 'init',
	['https://github.com/erf/vis-cursors.git'] = { file = 'init', var = 'C' },
	['https://github.com/erf/vis-test.git'] = { branch = 'other' },
}
local plug = require('plugins/vis-plug').init(plugins)
plug.plugins.C.path = '/Users/user/.cursors1'
```

The **KEY** is the URL to the git repository of the plugin.

The **VALUE** is the `file` or a Lua record for `file`, `var` and `branch`.

The `file` defaults to `"init"` if not set.

Set `var` to access plugin variables. E.g. `C` is an alias to the `vis-cursors` plugin.

Set `branch` to use a spesific git branch. It is set on `vis-install` and `vis-update`.

### Install on init

Pass `true` as the second arg to `init` to install plugins on `init`.

```lua
require('plugins/vis-plug').init(plugins, true)
```

# Commands

We support the following `vis` commands:

`:plug-list` - list plugins 

`:plug-install` - git clone plugins

`:plug-update` - git pull plugins
