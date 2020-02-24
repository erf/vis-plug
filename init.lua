local M = {}

local plugins_path = os.getenv('HOME') .. '/.config/vis/plugins/'

function exists(path)
	local f = io.open(path)
	if f == nil then return false
	else f:close() return true 
	end
end	

function iterate(operation, args)
	if not plugins then return end
	for k, v in pairs(plugins) do
		local url      = k
		local file     = v
		local name_ext = url:match('([^/]+)$')
		local name     = name_ext:match('(.+)%..+')
		local path     = plugins_path .. name
		operation(url, file, name, path, args)
	end
end

function plugins_install(url, file, name, path, args)
	if exists(path) then
		vis:message(name .. " already installed")
		vis:redraw()
	else 
		vis:message(name)
		vis:redraw()
		os.execute('git -C ' .. plugins_path .. ' clone ' .. url .. ' --quiet 2> /dev/null')
	end
end

function plugins_update(url, file, name, path, args)
	if exists(path) then
		vis:message(name)
		vis:redraw()
		os.execute('git -C ' .. path .. ' pull --quiet 2> /dev/null')
	else
		vis:message(name .. " does not exists ( call plug-install )")
		vis:redraw()
	end 
end

function plugins_require(url, file, name, path, args)
	if exists(path) then
		require('plugins/' .. name .. '/' .. file)
	end
end

function plugins_name(url, file, name, path, list)
	list[#list+1] = name .. ' ( ' .. url .. ' ) '
end

function plugins_count()
	if not plugins then return 0 end
	local count = 0
	for _ in pairs(plugins) do count = count + 1 end
	return count
end

vis:command_register("plug-install", function(argv, force, win, selection, range)
	local count = plugins_count()
	vis:message('installing plugins (' .. count .. ')')
	iterate(plugins_install, nil)
	vis:message('done')
	return true
end)

vis:command_register("plug-update", function(argv, force, win, selection, range)
	local count = plugins_count()
	vis:message('updating plugins (' .. count .. ')')
	iterate(plugins_update, nil)
	vis:message('done')
	return true
end)

vis:command_register("plug-list", function(argv, force, win, selection, range)
	local list = {}
	iterate(plugins_name, list)
	local str = ''
	for i,v in ipairs(list) do
		str = str .. v .. '\n'
	end
	vis:message('plugins (' .. #list .. ')\n' .. str)
	return true
end)

iterate(plugins_require)

return M

-- TODO's
-- info not showing up before after git command
-- configure plugin folder
-- improve match statement
-- show loading bar and plugin info in vis
-- spesify which plugin to update?
