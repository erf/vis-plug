local M = {}

local visrc, err = package.searchpath('visrc', package.path)
assert(not err)
local visrc_path = visrc:match('(.*/)') 
assert(visrc_path)

local plug_path = visrc_path ..'plugins'

local plugins = {}

function exists(path)
	local f = io.open(path)
	if f == nil then return false
	else f:close() return true end
end	

function iterate(op, args)
	if not plugins then return end
	for url, file in pairs(plugins) do
		local name = url:match('.*%/(.*)%..*')
		local path = plug_path .. '/' .. name
		op(url, file, name, path, args)
	end
end

function plug_install(url, file, name, path, args)
	if exists(path) then
		vis:message(name .. ' is already installed')
	else 
		os.execute('git -C ' .. plug_path .. ' clone ' .. url .. ' --quiet 2> /dev/null')
		vis:message(name .. ' installed')
		vis:redraw()
	end
end

function plug_update(url, file, name, path, args)
	if exists(path) then
		os.execute('git -C ' .. path .. ' pull --quiet 2> /dev/null')
		vis:message(name .. ' updated')
		vis:redraw()
	else
		vis:message(name .. ' is not installed (call plug-install)')
	end 
end

function plug_require(url, file, name, path, args)
	if not exists(path) then return end
	require('plugins/' .. name .. '/' .. file)
end

function plug_name(url, file, name, path, list)
	vis:message(name .. ' (' .. url .. ')')
end

function plug_count()
	if not plugins then return 0 end
	local count = 0
	for _ in pairs(plugins) do count = count + 1 end
	return count
end

vis:command_register('plug-install', function(argv, force, win, selection, range)
	if not exists(plug_path) then os.execute('mkdir -p ' .. plug_path) end
	vis:message('plug install (' .. plug_count() .. ')')
	iterate(plug_install, nil)
	vis:message('done')
	return true
end)

vis:command_register('plug-update', function(argv, force, win, selection, range)
	vis:message('plug update (' .. plug_count() .. ')')
	iterate(plug_update, nil)
	vis:message('done')
	return true
end)

vis:command_register('plug-list', function(argv, force, win, selection, range)
	vis:message('plug list (' .. plug_count() .. ')')
	iterate(plug_name, list)
	vis:message('done')
	return true
end)

M.init = function(plugins_p)
	plugins = plugins_p or {}
	iterate(plug_require)
end

return M

