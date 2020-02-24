local M = {}

local VIS_PATH = os.getenv('VIS_PATH') or os.getenv('HOME') .. '/.config/vis'

local PLUG_PATH = os.getenv('PLUG_PATH') or VIS_PATH .. '/plugins'

local plugins = {}

function exists(path)
	local f = io.open(path)
	if f == nil then return false
	else f:close() return true 
	end
end	

function iterate(op, args)
	if not plugins then return end
	for k, v in pairs(plugins) do
		local url      = k
		local file     = v
		local name_ext = url:match('([^/]+)$')
		local name     = name_ext:match('(.+)%..+')
		local path     = PLUG_PATH .. '/' .. name
		op(url, file, name, path, args)
	end
end

function plug_install(url, file, name, path, args)
	if exists(path) then
		vis:message(name .. " is already installed")
	else 
		vis:message(name)
		vis:redraw()
		os.execute('git -C ' .. PLUG_PATH .. ' clone ' .. url .. ' --quiet 2> /dev/null')
	end
end

function plug_update(url, file, name, path, args)
	if exists(path) then
		vis:message(name)
		vis:redraw()
		os.execute('git -C ' .. path .. ' pull --quiet 2> /dev/null')
	else
		vis:message(name .. " does not exists ( call plug-install )")
	end 
end

function plug_require(url, file, name, path, args)
	if not exists(path) then return end
	require('plugins/' .. name .. '/' .. file)
end

function plug_name(url, file, name, path, list)
	vis:message(name .. ' ( ' .. url .. ' ) ')
end

function plug_count()
	if not plugins then return 0 end
	local count = 0
	for _ in pairs(plugins) do count = count + 1 end
	return count
end

vis:command_register("plug-install", function(argv, force, win, selection, range)
	if not exists(PLUG_PATH) then os.execute('mkdir -p ' .. PLUG_PATH) end
	local count = plug_count()
	vis:message('plug install (' .. count .. ')')
	iterate(plug_install, nil)
	vis:message('done')
	return true
end)

vis:command_register("plug-update", function(argv, force, win, selection, range)
	local count = plug_count()
	vis:message('plug update (' .. count .. ')')
	iterate(plug_update, nil)
	vis:message('done')
	return true
end)

vis:command_register("plug-list", function(argv, force, win, selection, range)
	local count = plug_count()
	vis:message('plug list (' .. count .. ')')
	iterate(plug_name, list)
	vis:message('done')
	return true
end)

M.init = function(plugins_p)
	plugins = plugins_p or {}
	iterate(plug_require)
end

return M

-- TODO
-- improve match statement
-- progress bar for install / update
-- spesify which plugin to update?

