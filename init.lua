local M = {}
M.plugins = {}

local visrc, err = package.searchpath('visrc', package.path)
assert(not err)
local visrc_path = visrc:match('(.*/)')
assert(visrc_path)
local plugins_path = visrc_path ..'plugins'
local plugins_conf = {}

local exists = function (path)
	local file = io.open(path)
	if not file then
		return false
	end
	file:close()
	return true
end

local iterate_plugins = function (op, args)
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
		local name = url:match('.*%/(.*)%.git')
		local path = plugins_path .. '/' .. name
		op(url, file, name, path, alias, branch, commit, args)
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

local plug_install = function(url, file, name, path, alias, branch, commit, args)
	local silent = args
	if exists(path) then
		checkout(path, branch, commit)
		if not silent then
			vis:message(name .. ' (already installed - checkout)')
		end
	else
		os.execute('git -C ' .. plugins_path .. ' clone ' .. url .. ' --quiet 2> /dev/null')
		checkout(path, branch, commit)
		if not silent then
			vis:message(name .. ' (installed)')
		end
	end
	vis:redraw()
end

local plug_update = function(url, file, name, path, alias, branch, commit, args)
	if exists(path) then
		checkout(path, branch, commit)
		os.execute('git -C ' .. path .. ' pull --quiet 2> /dev/null')
		vis:message(name .. ' updated')
	else
		vis:message(name .. ' (not installed, do :plug-install)')
	end
	vis:redraw()
end

local plug_require = function(url, file, name, path, alias, branch, commit, args)
	if not exists(path) then
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

local plug_name = function(url, file, name, path, alias, branch, commit, args)
	if exists(path) then
		vis:message(name .. ' (' .. url .. ')')
	else
		vis:message(name .. ' (' .. url .. ') (not installed)')
	end
	vis:redraw()
end

local install_plugins = function(silent)
	if not exists(plugins_path) then
		os.execute('mkdir -p ' .. plugins_path)
	end
	iterate_plugins(plug_install, silent)
end

vis:command_register('plug-install', function()
	vis:message('installing...')
	vis:redraw()
	install_plugins(false)
	vis:message('')
	vis:redraw()
	return true
end)

vis:command_register('plug-update', function()
	vis:message('updating...')
	vis:redraw()
	iterate_plugins(plug_update)
	vis:message('')
	vis:redraw()
	return true
end)

vis:command_register('plug-list', function()
	vis:message('plugins (' .. plug_count() .. ')')
	vis:redraw()
	iterate_plugins(plug_name)
	vis:message('')
	vis:redraw()
	return true
end)

M.init = function(plugins, install_on_init)
	plugins_conf = plugins or {}
	if install_on_init then
		install_plugins(true)
	end
	iterate_plugins(plug_require)
	return M
end

return M