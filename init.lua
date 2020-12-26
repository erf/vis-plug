local M = {}

-- the plugins configurations set in visrc.lua
local conf = {}

-- we store commands in an array of tables {name, func, desc}
local commands = {}

-- the required plugins are stored here
M.plugins = {}

-- e.g. /Users/user/.cache/vis-plug
local get_default_cache_path = function()
	local HOME = os.getenv('HOME')
	local XDG_CACHE_HOME = os.getenv('XDG_CACHE_HOME')
	local CACHE_DIR = XDG_CACHE_HOME or (HOME .. '/.cache')
	return CACHE_DIR .. '/vis-plug'
end

-- the dir where we store plugins on disk
local plugins_dir = nil

-- set custom path and add it first to package.path for require
M.set_path = function(path)
	plugins_dir = path
	package.path = path .. '/?.lua;' .. path .. '/?/init.lua;' .. package.path
end

-- set default install path for plugins
M.set_path(get_default_cache_path())

-- execute a command and return result string
local execute = function(command)
	local handle = io.popen(command)
	local result = handle:read("*a")
	-- strip trailing spaces
	result = result:gsub('(.-)%s*$', '%1')
	handle:close()
	return result

	--TODO improve by also getting errors based on vis-digraph
	--local file = io.popen(string.format("vis-digraph '%s' 2>&1", keys:gsub("'", "'\\''")))
	--local output = file:read('*all')
	--local success, msg, status = file:close()
end

-- check if file exists
local file_exists = function (path)
	local file = io.open(path)
	if not file then return false end
	file:close()
	return true
end

-- use repo folder as plugin name
-- E.g. https://github.com/erf/{vis-highlight}.git -> vis-highlight
local get_name_from_url = function(url)
	return url:match('^.*/([^.]+)')
end

-- E.g. '~/.cache/vis-plug/vis-highlight'
local get_path_from_name = function(name)
	return plugins_dir .. '/' .. name
end

-- return true if has the protocol part of the url
-- '{https://}github.com/erf/vis-cursors.git'
local is_full_url = function(url)
	return url:find('^.+://') ~= nil
end

-- [user@]server:project.git
local is_short_ssh_url = function(url)
	return url:find('^.+@.+:.+')
end

-- remove protocol from url to make it shorter for output
local get_short_url = function(url)
	if is_full_url(url) then
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
	if is_full_url(url) then
		return url
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
	for _, plug in ipairs(conf) do
		if plug.name == name then
			return plug
		end
	end
end

-- iterate the plugins conf and call an operation per plugin
local for_each_plugin = function (func, args)
	for _, plug in ipairs(conf) do
		func(plug, args)
	end
end

-- prepare the plug configuration
local plug_prepare = function(plug, args)
	plug.file = plug.file or 'init'
	plug.url  = get_full_url(plug.url)
 	plug.name = get_name_from_url(plug.url)
	plug.path = get_path_from_name(plug.name)
end

local checkout = function(plug)
	-- TODO don't checkout if we already are on the correct branch / commit (if more performant)
	if plug.commit then
		os.execute('git -C ' .. plug.path .. ' checkout --quiet ' .. plug.commit)
	elseif plug.branch then
		os.execute('git -C ' .. plug.path .. ' checkout --quiet ' .. plug.branch)
	else
		local result = execute('git -C ' .. plug.path .. ' rev-parse --abbrev-ref HEAD')
		if result == ('master' or 'main') then
			-- we're already on the correct branch, so no need to checkout, which is a bit faster
			return
		end
		-- set 'master|main' branch by default
		-- https://stackoverflow.com/questions/28666357/git-how-to-get-default-branch
		local master = execute('git symbolic-ref refs/remotes/origin/HEAD | sed "s@^refs/remotes/origin/@@"')
		os.execute('git -C ' .. plug.path .. ' checkout --quiet ' .. master)
	end
end

local plug_install = function(plug, args)
	local short_url = get_short_url(plug.url)
	local silent = args
	if file_exists(plug.path) then
		checkout(plug)
		if not silent then
			vis:message(plug.name .. ' (' .. short_url .. ') is already installed')
		end
	else
		os.execute('git -C ' .. plugins_dir .. ' clone ' .. plug.url .. ' --quiet 2> /dev/null')
		checkout(plug)
		if not silent then
			vis:message(plug.name .. ' (' .. short_url .. ') installed')
		end
	end
	vis:redraw()
end

local plug_update = function(plug, args)
	local short_url = get_short_url(plug.url)
	if not file_exists(plug.path) then
		vis:message(plug.name .. ' (' .. short_url .. ') is NOT installed')
		vis:redraw()
		return
	end
	checkout(plug)
	local local_hash = execute('git -C ' .. plug.path .. ' rev-parse HEAD')
	local remote_hash = execute('git ls-remote ' .. plug.url .. ' HEAD | cut -f1')
	if local_hash ~= remote_hash then
		os.execute('git -C ' .. plug.path .. ' pull')
		vis:message(plug.name .. ' UPDATED')
	else
		vis:message(plug.name .. ' is up-to-date')
	end
	vis:redraw()
end

local plug_require = function(plug, args)
	if not file_exists(plug.path) then
		return
	end
	local plugin_name = plug.name .. '/' .. plug.file
	local plugin = require(plugin_name)
	if plug.alias then
		M.plugins[plug.alias] = plugin
	end
end

local plug_outdated = function(plug, args)
	local short_url = get_short_url(plug.url)
	if not file_exists(plug.path) then
		vis:message(plug.name .. ' (' .. short_url .. ') is NOT installed')
		vis:redraw()
		return
	end
	local local_hash = execute('git -C ' .. plug.path .. ' rev-parse HEAD')
	local remote_hash = execute('git ls-remote ' .. plug.url .. ' HEAD | cut -f1')
	if local_hash == remote_hash then
		vis:message(plug.name .. ' (' .. short_url .. ') is up-to-date')
	else
		vis:message(plug.name .. ' (' .. short_url .. ') needs UPDATE')
	end
	vis:redraw()
end

local plug_list = function(plug, args)
	local short_url = get_short_url(plug.url)
	if file_exists(plug.path) then
		vis:message(plug.name .. ' (' .. short_url .. ')')
	else
		vis:message(plug.name .. ' (' .. short_url .. ') is NOT installed')
	end
	vis:redraw()
end

local install_plugins = function(silent)
	if not file_exists(plugins_dir) then
		os.execute('mkdir -p ' .. plugins_dir)
	end
	for_each_plugin(plug_install, silent)
end

local plug_delete = function(plug, args)
	if file_exists(plug.path) then
		os.execute('rm -rf ' .. plug.path)
		vis:message(plug.name .. ' (' .. plug.path .. ') deleted')
	else
		vis:message(plug.name .. ' (' .. plug.path .. ') is NOT installed')
	end
end

-- require plugins (and optionally install and checkout)
M.init = function(plugins, install_on_init)
	conf = plugins or {}
	for_each_plugin(plug_prepare)
	if install_on_init then
		install_plugins(true)
	end
	for_each_plugin(plug_require)
	return M
end

local command_install = function(argv, force, win, selection, range)
	vis:message('installing..')
	vis:redraw()
	install_plugins(false)
	vis:redraw()
	return true
end

local command_rm = function(argv, force, win, selection, range)
	local name = argv[1]
	local plug = get_plug_by_name(name)
	if plug then
		plug_delete(plug)
	else
		vis:message('Error: plug-rm missing plug {name}')
	end
	vis:redraw()
	return true
end

local command_clean = function(argv, force, win, selection, range)
	vis:message('cleaning..')
	vis:redraw()
	for_each_plugin(plug_delete)
	vis:redraw()
	return true
end

local command_update = function(argv, force, win, selection, range)
	vis:message('updating..')
	vis:redraw()
	for_each_plugin(plug_update)
	vis:redraw()
	return true
end

-- look for vis-plug path in package.path
local look_for_vis_plug_path = function()
	local plug_path = package.searchpath('plugins/vis-plug', package.path)
	if plug_path ~= nil then
		return plug_path
	end
	return package.searchpath('vis-plug', package.path)
end

-- curl fetch vis-plug init.lua file
local fetch_latest_vis_plug = function(plug_path)
	local url = 'https://raw.githubusercontent.com/erf/vis-plug/master/init.lua'
	local command = 'curl -s -S -f -H  "Cache-Control: no-cache" ' .. url .. ' > ' .. plug_path
	return execute(command)
end

local command_upgrade = function(argv, force, win, selection, range)
	vis:message('upgrading..')
	vis:redraw()
	local plug_path = look_for_vis_plug_path()
	if plug_path == nil then
		vis:message('error: could not find vis-plug path')
		vis:redraw()
		return
	end
	--  TODO: read stderr
	local result = fetch_latest_vis_plug(plug_path)
	if result ~= nil and result ~= '' then
		vis:message('upgrade error: ' .. result)
	else
		vis:message('upgrade OK - restart for latest vis-plug')
	end
	vis:redraw()
	return true
end

local command_ls = function(argv, force, win, selection, range)
	vis:message('plugins (' .. #conf .. ')')
	vis:redraw()
	for_each_plugin(plug_list)
	vis:redraw()
	return true
end

local command_outdated = function(argv, force, win, selection, range)
	vis:message('up-to-date..?')
	vis:redraw()
	for_each_plugin(plug_outdated)
	vis:redraw()
	return true
end

local command_list_commands = function(argv, force, win, selection, range)
	vis:message('vis-plug commands')
	vis:redraw()
	local arr = {}
	for _, command in ipairs(commands) do
		table.insert(arr, ':' .. command.name .. ' - ' .. command.desc)
	end
	local str = table.concat(arr, '\n')
	vis:message(str)
	vis:redraw()
	return true
end

commands = { {
		name = 'plug-ls',
		desc = 'list plugins',
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
		desc = 'are repos up-to-date? (diff commits)',
		func = command_outdated,
	}, {
		name = 'plug-upgrade',
		desc = 'fetch latest vis-plug (overwrite current)',
		func = command_upgrade,
	}, {
		name = 'plug-rm',
		desc = 'delete plugin by {name} (:plug-ls for names)',
		func = command_rm,
	}, {
		name = 'plug-clean',
		desc = 'delete all plugins in conf',
		func = command_clean,
	}, {
		name = 'plug-commands',
		desc = 'list these commands',
		func = command_list_commands,
	},
}

-- initialize commands
for _, command in ipairs(commands) do
	vis:command_register(command.name, command.func, command.desc)
end

return M