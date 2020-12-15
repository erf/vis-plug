local M = {}
M.plugins = {}

local visrc, err = package.searchpath('visrc', package.path)
assert(not err)
local visrc_path = visrc:match('(.*/)')
assert(visrc_path)

local plugins_path = visrc_path ..'plugins'

local plugins = {}

function exists(path)
	local file = io.open(path)
	if not file then
		return false
	else
		file:close()
		return true
	end
end	

function iterate_plugins(op, args)
	if not plugins then return end
	for url, v in pairs(plugins) do
		local file = nil
		local var = nil
		if type(v) == "table" then
			file = v[1]
			var = v[2]
		else
			file = v
		end
		local name = url:match('.*%/(.*)%..*')
		local path = plugins_path .. '/' .. name
		op(url, file, name, path, var, args)
	end
end

function plug_install(url, file, name, path, var, silent)
	if exists(path) then
		if not silent then
			vis:message(name .. ' (already installed)')
		end
	else
		os.execute('git -C ' .. plugins_path .. ' clone ' .. url .. ' --quiet 2> /dev/null')
		if not silent then
			vis:message(name)
		end
	end
	vis:redraw()
end

function plug_update(url, file, name, path)
	if exists(path) then
		os.execute('git -C ' .. path .. ' pull --quiet 2> /dev/null')
		vis:message(name .. ' updated')
	else
		vis:message(name .. ' (not installed, do :plug-install)')
	end
	vis:redraw()
end

function plug_require(url, file, name, path, var)
	if not exists(path) then return end
	local plugin = require('plugins/' .. name .. '/' .. file)
	if var then
		M.plugins[var] = plugin
	end
end

function plug_count()
	if not plugins then return 0 end
	local count = 0
	for _ in pairs(plugins) do count = count + 1 end
	return count
end

function plug_name(url, file, name, path)
	if exists(path) then
		vis:message(name .. ' (' .. url .. ')')
	else
		vis:message(name .. ' (' .. url .. ') (not installed)')
	end
	vis:redraw()
end

function init_plugins()
	if not exists(plugins_path) then os.execute('mkdir -p ' .. plugins_path) end
	iterate_plugins(plug_install, true)
end

vis:command_register('plug-install', function(argv, force, win, selection, range)
	vis:message('plug-install')
	vis:redraw()
	if not exists(plugins_path) then os.execute('mkdir -p ' .. plugins_path) end
	iterate_plugins(plug_install, false)
	vis:message('')
	vis:redraw()
	return true
end)

vis:command_register('plug-update', function(argv, force, win, selection, range)
	vis:message('plug-update')
	vis:redraw()
	iterate_plugins(plug_update, nil)
	vis:message('')
	vis:redraw()
	return true
end)

vis:command_register('plug-list', function(argv, force, win, selection, range)
	vis:message('plug-list')
	vis:redraw()
	iterate_plugins(plug_name)
	vis:message('')
	vis:redraw()
	return true
end)

M.init = function(plugins_p, install_on_startup)
	plugins = plugins_p or {}
	if install_on_startup then
		init_plugins()
	end
	iterate_plugins(plug_require)
	return M
end

return M

