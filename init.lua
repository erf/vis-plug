local M = {}

-- the required plugins are stored here
M.plugins = {}

-- the plugins configurations set in visrc.lua
local plugins_conf = {}

-- the dir where we store plugins on disk
local plugins_path = nil

-- we store commands in an array of tables {name, func, desc}
local commands = {}

-- add a searcher to find plugins by filename, not module path
table.insert(package.searchers, function(name)
	local file, err = package.searchpath(name, package.path, '', '') -- don't replace . with /
	if file then
		return loadfile(file), file
	else
		return nil, err
	end
end)

-- set custom path and add it first to package.path for require
M.path = function(path)
	plugins_path = path
	package.path = path .. '/?.lua;' .. path .. '/?/init.lua;' .. package.path
end

-- e.g. /Users/user/.cache/vis-plug
local get_cache_path = function()
	local HOME = os.getenv('HOME')
	local XDG_CACHE_HOME = os.getenv('XDG_CACHE_HOME')
	local HOME_CACHE = HOME .. '/.cache'
	local CACHE_DIR = XDG_CACHE_HOME or HOME_CACHE
	return CACHE_DIR .. '/vis-plug'
end

-- set default install path for plugins
M.path(get_cache_path())

-- execute a command and return result string
local execute = function(command)
	local file = io.popen(command)
	local result = file:read("*a")
	result = result:gsub('(.-)%s*$', '%1') -- strip trailing spaces
	local success, message, code = file:close()
	return result, success, message, code
end

-- check if file exists
local file_exists = function(path)
	local file = io.open(path)
	if not file then return false end
	file:close()
	return true
end

-- get plugin name from repo dir
-- E.g. https://github.com/erf/{vis-highlight}.git -> vis-highlight
local get_name_from_url = function(url)
	return url:match('^.*/([^.]+)')
end

-- get the dir from the given file
local get_dir_from_file = function(file)
	return file:match('(.+)%/.+$')
end

-- separate folders in CACHE_DIR/vis-plug/{plugins|themes}
local get_folder = function(theme)
	if theme then
		return '/themes'
	else
		return '/plugins'
	end
end

-- E.g. '~/.cache/vis-plug/plugins/'
local get_base_path = function(theme)
	return plugins_path .. get_folder(theme)
end

-- get path to file
local get_file_path = function(plug)
	return plug.path .. plug.file .. '.lua'
end

-- '{http[s]://github.com}/erf/vis-cursors.git'
local is_github_url = function(url)
	return url:find('^http[s]?://github.com.+') ~= nil
end

-- return true if has the protocol part of the url
-- '{https://}github.com/erf/vis-cursors.git'
local is_host_url = function(url)
	return url:find('^.+://') ~= nil
end

-- return true if has the protocol part of the url
-- '{github.com/}erf/vis-cursors.git'
local is_no_host_url = function(url)
	return url:find('^%w+%.%w+[^/]') ~= nil
end

-- [user@]server:project.git
local is_short_ssh_url = function(url)
	return url:find('^.+@.+:.+')
end

-- remove protocol from url to make it shorter for output
local get_short_url = function(url)
	if is_github_url(url) then
		return url:match('^.+://.-/(.*)')
	elseif is_host_url(url) then
		return url:match('^.+://(.*)')
	elseif is_short_ssh_url(url) then
		return url -- TODO shorten?
	else
		return url
	end
end

-- given a github short hand url, return the full url
-- E.g. 'erf/vis-cursors' -> 'https://github.com/erf/vis-cursors.git'
local get_full_url = function(url)
	if is_host_url(url) then
		return url
	elseif is_no_host_url(url) then
		return 'https://' .. url
	elseif is_short_ssh_url(url) then
		return url
	else
		return 'https://github.com/' .. url
	end
end

-- find the plug in conf by name, used by plug-rm
local get_plug_by_name = function(name)
	if name == nil then
		return nil
	end
	for _, plug in ipairs(plugins_conf) do
		if plug.name == name then
			return plug
		end
	end
end

-- iterate the plugins conf and call an operation per plugin
local for_each_plugin = function (func, args)
	for _, plug in ipairs(plugins_conf) do
		func(plug, args)
	end
end

-- prepare the plug configuration
local plug_init = function(plug, args)
	plug.file = plug.file and '/' .. plug.file or ''
	plug.url = get_full_url(plug.url or plug[1])
	plug.name = get_name_from_url(plug.url)
	plug.path = get_base_path(plug.theme) .. '/' .. plug.name
end

-- checkout specific commit, branch or tag
local checkout = function(plug)
	if plug.ref then
		os.execute('git -C ' .. plug.path .. ' checkout --quiet ' .. plug.ref)
	else
		-- ELSE do nothing; there is no default "master" branch or "origin"
		-- for reference:
		-- git rev-parse --abbrev-ref HEAD
		-- git symbolic-ref refs/remotes/origin/HEAD --short
	end
end

local plug_require = function(plug, args)
	if not file_exists(plug.path) then
		return
	end
	if plug.theme then
		return
	end
	local name = 'plugins/' .. plug.name .. plug.file
	local plugin = require(name)
	if plug.alias then
		M.plugins[plug.alias] = plugin
	end
end

local plug_outdated = function(plug, args)
	local short_url = get_short_url(plug.url)
	if not file_exists(plug.path) then
		vis:message(plug.name .. ' (' .. short_url .. ') NOT INSTALLED')
		vis:redraw()
		return
	end
	local local_hash = execute('git -C ' .. plug.path .. ' rev-parse HEAD')
	local remote_hash = execute('git ls-remote ' .. plug.url .. ' HEAD | cut -f1')
	if local_hash == remote_hash then
		vis:message(plug.name .. ' (' .. short_url .. ') ✓')
	else
		vis:message(plug.name .. ' (' .. short_url .. ') OUTDATED')
	end
	vis:redraw()
end

local count_themes = function()
	local themes = 0
	for _, plug in ipairs(plugins_conf) do
		if plug.theme then
			themes = themes + 1
		end
	end
	return themes
end

local plug_list = function(plug, theme)
	if (theme and not plug.theme) or (not theme and plug.theme) then
		return
	end
	local short_url = get_short_url(plug.url)
	if file_exists(plug.path) then
		vis:message(short_url .. ' (' .. plug.file .. ')')
	else
		vis:message(short_url .. ' (' .. plug.file .. ') NOT INSTALLED')
	end
	vis:redraw()
end

-- run a set of bash commands given a table
function execute_commands_in_background(commands)
	table.insert(commands, 'wait')
	os.execute(string.format('sh -c \'(\n%s\n)\'', table.concat(commands, '\n')))
end

local install_plugins = function(silent)

	-- create folders
	os.execute('mkdir -p ' .. plugins_path .. '/plugins')
	os.execute('mkdir -p ' .. plugins_path .. '/themes')

	-- build shell commands which run in the background and wait
	local commands = {}
	for i, plug in ipairs(plugins_conf) do
		if not file_exists(plug.path) then
			local path = get_base_path(plug.theme)  
			table.insert(commands, string.format('git -C %s clone %s --quiet 2> /dev/null &', path, plug.url))
		end
	end

	-- execute commands and wait
	if #commands > 0 then
		vis:info('Installing..')
		vis:redraw()
		execute_commands_in_background(commands)
	end

	-- checkout git repo
	for_each_plugin(checkout)

	-- print result
	if #commands > 0 then
		vis:info('' .. #commands - 1 .. ' plugin(s) installed')
	elseif not silent then
		vis:info('Nothing to install')
	end

end

local update_plugins = function()

	-- build shell commands which run in the background and wait
	local commands = {}
	for key, plug in ipairs(plugins_conf) do
		if file_exists(plug.path) then
			table.insert(commands, string.format('git -C %s pull --quiet 2> /dev/null &', plug.path))
		end
	end

	-- execute commands and wait
	if #commands > 0 then
		vis:info('Updating..')
		vis:redraw()
		execute_commands_in_background(commands)
	end

	-- checkout git repo
	for_each_plugin(checkout)

	-- print result
	if #commands > 0 then
		vis:info('' .. #commands - 1 .. ' plugin(s) updated')
	else
		vis:info('Nothing to update')
	end
end

-- require plugins (and optionally install and checkout)
M.init = function(plugins, install_on_init)
	plugins_conf = plugins or {}
	for_each_plugin(plug_init)
	if install_on_init then
		install_plugins(true)
	end
	for_each_plugin(plug_require)
	return M
end

local command_install = function(argv, force, win, selection, range)
	install_plugins(false)
	return true
end

local command_rm = function(argv, force, win, selection, range)
	local name = argv[1]
	local plug = get_plug_by_name(name)
	if not plug then
		vis:info('\'' .. name .. '\' not found')
		return true
	end
	if file_exists(plug.path) then
		os.execute('rm -rf ' .. plug.path)
		vis:info(plug.name .. ' (' .. plug.path .. ') deleted')
	else
		vis:info(plug.name .. ' is not installed')
	end
	return true
end

local command_checkout = function(argv, force, win, selection, range)
	local name = argv[1]
	local ref = argv[2]
	if name == nil or ref == nil then
		vis:info('Missing {name} or {commit|branch|tag}')
		return true
	end
	local plug = get_plug_by_name(name)
	if not plug then
		vis:info('\'' .. name .. '\' not found')
		return true
	end
	plug.ref = ref
	checkout(plug)
	vis:info('Checked out \'' .. ref .. '\'')
	return true
end

local command_clean = function(argv, force, win, selection, range)
	local deleted = 0
	for _, plug in ipairs(plugins_conf) do
		if file_exists(plug.path) then
			os.execute('rm -rf ' .. plug.path)
			deleted = deleted + 1
		end
	end
	if deleted == 0 then
		vis:info('Nothing to delete')
	else
		vis:info('' .. deleted .. ' packages deleted')
	end
	return true
end

local command_update = function(argv, force, win, selection, range)
	update_plugins()
	return true
end

-- look for vis-plug path in package.path because it is NOT necessarily in the
-- `plugins_path` but could rather have been required from some other path E.g.
-- the `visrc` config path
local look_for_vis_plug_path = function()
	local plug_path = package.searchpath('plugins/vis-plug', package.path)
	if plug_path ~= nil then
		return plug_path
	end
	return package.searchpath('vis-plug', package.path)
end

-- upgrade vis-plug by doing a git pull
local command_upgrade = function(argv, force, win, selection, range)
	vis:info('Upgrading vis-plug..')
	vis:redraw()
	local plug_path = look_for_vis_plug_path()
	if plug_path == nil then
		vis:info('Could not find vis-plug path')
		return
	end

	local plug_dir = get_dir_from_file(plug_path)
	local upgrade_command = string.format('git -C %s pull --quiet 2> /dev/null', plug_dir)
	local result, success, message, code = execute(upgrade_command)
	if success then
		vis:info('vis-plug is up-to-date - restart for latest')
	else
		vis:info('Upgrade failed with code: ' .. tostring(code))
	end
	return true
end

local command_ls = function(argv, force, win, selection, range)

	local num_themes = count_themes()
	local num_plugins = #plugins_conf - num_themes

	vis:message('Plugins (' .. num_plugins .. ')')
	vis:redraw()
	for_each_plugin(plug_list, false)

	vis:message('\nThemes (' .. num_themes .. ')')
	vis:redraw()
	for_each_plugin(plug_list, true)

	return true
end

local command_outdated = function(argv, force, win, selection, range)
	vis:message('Are plugins up-to-date?')
	vis:redraw()
	for_each_plugin(plug_outdated)
	return true
end

local command_list_commands = function(argv, force, win, selection, range)
	local arr = {}
	table.insert(arr, 'vis-plug commands')
	for _, command in ipairs(commands) do
		table.insert(arr, ':' .. command.name .. ' - ' .. command.desc)
	end
	local str = table.concat(arr, '\n')
	vis:message(str)
	return true
end

commands = { {
		name = 'plug-list',
		desc = 'list plugins and themes',
		func = command_ls,
	}, {
		name = 'plug-install',
		desc = 'install plugins (git clone)',
		func = command_install,
	}, {
		name = 'plug-update',
		desc = 'update plugins (git pull)',
		func = command_update,
	}, {
		name = 'plug-outdated',
		desc = 'check if plugins are up-to-date',
		func = command_outdated,
	}, {
		name = 'plug-upgrade',
		desc = 'upgrade to latest vis-plug version',
		func = command_upgrade,
	}, {
		name = 'plug-remove',
		desc = 'delete plugin by {name} (:plug-list for names)',
		func = command_rm,
	}, {
		name = 'plug-clean',
		desc = 'delete all plugins from disk',
		func = command_clean,
	}, {
		name = 'plug-checkout',
		desc = 'checkout {name} {commit|branch|tag}',
		func = command_checkout,
	}, {
		name = 'plug-commands',
		desc = 'list commands (these)',
		func = command_list_commands,
	},
}

-- initialize commands
for _, command in ipairs(commands) do
	vis:command_register(command.name, command.func, command.desc)
end

-- set theme on INIT event
vis.events.subscribe(vis.events.INIT, function()
	for _, plug in ipairs(plugins_conf) do
		if plug.theme and file_exists(get_file_path(plug)) then
			vis:command('set theme ' .. plug.name .. plug.file)
			return -- set first theme and return
		end
	end
end)

return M
