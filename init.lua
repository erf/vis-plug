local M = {}

-- the required plugins are stored here
M.plugins = {}

local get_default_plugins_path = function()
	local visrc, err = package.searchpath('visrc', package.path)
	if err then return nil end
	local visrc_path = visrc:match('(.*/)')
	return visrc_path ..'plugins'
end

-- the path where we store plugins on disk
M.path = get_default_plugins_path()

-- the plugins configurations set in visrc.lua
local plugins_conf = {}

local file_exists = function (path)
	local file = io.open(path)
	if not file then return false end
	file:close()
	return true
end

local get_name_from_url = function(url)
	return string.match(url, '^.*/([^$.]+)')
end

local get_plugin_path = function(name)
	return M.path .. '/' .. name
end

local for_each_plugin = function (op, args)
	for url, val in pairs(plugins_conf) do
		local file, alias, branch, commit
		if type(val) == 'table' then
			file   = val['file']   or val[1]
			alias  = val['alias']  or val[2]
			branch = val['branch'] or val[3]
			commit = val['commit'] or val[4]
		else
			file   = val
		end
 		local name = get_name_from_url(url)
		if name then
			local path = get_plugin_path(name)
			op(url, name, path, file, alias, branch, commit, args)
		end
	end
end

local checkout = function(path, branch, commit)
	if commit then
		os.execute('git -C ' .. path .. ' checkout --quiet ' .. commit)
	elseif branch then
		os.execute('git -C ' .. path .. ' checkout --quiet ' .. branch)
	else
		os.execute('git -C ' .. path .. ' checkout --quiet master')
	end
end

local plug_install = function(url, name, path, file, alias, branch, commit, args)
	local silent = args
	if file_exists(path) then
		checkout(path, branch, commit)
		if not silent then
			vis:message(name .. ' already installed')
		end
	else
		os.execute('git -C ' .. M.path .. ' clone ' .. url .. ' --quiet 2> /dev/null')
		checkout(path, branch, commit)
		if not silent then
			vis:message(name .. ' installed')
		end
	end
	vis:redraw()
end

local plug_update = function(url, name, path, file, alias, branch, commit, args)
	if file_exists(path) then
		checkout(path, branch, commit)
		os.execute('git -C ' .. path .. ' pull --quiet 2> /dev/null')
		vis:message(name .. ' updated')
	else
		vis:message(name .. ' NOT installed')
	end
	vis:redraw()
end

local plug_require = function(url, name, path, file, alias, branch, commit, args)
	if not file_exists(path) then
		return
	end
	local plugin = require('plugins/' .. name .. '/' .. file)
	if alias then
		M.plugins[alias] = plugin
	end
end

local plug_count = function()
	local count = 0
	for _ in pairs(plugins_conf) do
		count = count + 1
	end
	return count
end

local plug_name = function(url, name, path, file, alias, branch, commit, args)
	if file_exists(path) then
		vis:message(name .. ' (' .. url .. ')')
	else
		vis:message(name .. ' (' .. url .. ') NOT installed')
	end
	vis:redraw()
end

local install_plugins = function(silent)
	if not file_exists(M.path) then
		os.execute('mkdir -p ' .. M.path)
	end
	for_each_plugin(plug_install, silent)
end

local plug_delete = function(url, name, path, file)
	if file_exists(path) then
		os.execute('rm -rf ' .. path)
		vis:message(name .. ' (' .. path .. ') deleted')
	else
		--vis:message(name .. ' (' .. path .. ') not there')
	end
end

vis:command_register('plug-install', function(argv, force, win, selection, range)
	vis:message('installing..')
	vis:redraw()
	install_plugins(false)
	vis:message('done')
	vis:redraw()
	return true
end)

vis:command_register('plug-rm', function(argv, force, win, selection, range)
	vis:message('deleting..')
	vis:redraw()
	local name = argv[1]
	local path = get_plugin_path(name)
	plug_delete(nil, name, path)
	vis:message('done')
	vis:redraw()
	return true
end)

vis:command_register('plug-clean', function(argv, force, win, selection, range)
	vis:message('deleting..')
	vis:redraw()
	for_each_plugin(plug_delete)
	vis:message('done')
	vis:redraw()
	return true
end)

vis:command_register('plug-update', function(argv, force, win, selection, range)
	vis:message('updating..')
	vis:redraw()
	for_each_plugin(plug_update)
	vis:message('done')
	vis:redraw()
	return true
end)

vis:command_register('plug-ls', function(argv, force, win, selection, range)
	vis:message('plugins (' .. plug_count() .. ')')
	vis:redraw()
	for_each_plugin(plug_name)
	vis:message('done')
	vis:redraw()
	return true
end)

M.init = function(plugins, install_on_init)
	plugins_conf = plugins or {}
	if install_on_init then
		install_plugins(true)
	end
	for_each_plugin(plug_require)
	return M
end

return M