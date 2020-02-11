local M = {}

local plugins_dir = 'plugins/'
local plugins_path = os.getenv('HOME') .. '/.config/vis/plugins/'

function exists(path)
	local f = io.open(path)
	if f == nil then return false
	else f:close() return true 
	end
end	

function iterate(operation)
	if plugins then 
		for i, url in ipairs(plugins) do
			local name_ext = url:match('([^/]+)$')
			local name = name_ext:match('(.+)%..+')
			local path = plugins_path .. name
			operation(url, name, path)
		end
	end
end

function plugins_install(url, name, path)
	if not exists(path) then
		vis:info('plug -> install ' .. name)
		os.execute('git -C ' .. plugins_path .. ' clone ' .. url .. ' --quiet 2> /dev/null')
	end
end

function plugins_update(url, name, path)
	if exists(path) then
		vis:info('plug -> updating ' .. name)
		os.execute('git -C ' .. path .. ' pull --depth=1 --quiet 2> /dev/null')
	end
end

function plugins_require(url, name, path)
	if exists(path) then
		require(plugins_dir .. name)
	end
end

vis:command_register("plug-install", function(argv, force, win, selection, range)
	iterate(plugins_install)
	vis:info('plugins installed')
	return true
end)

vis:command_register("plug-update", function(argv, force, win, selection, range)
	iterate(plugins_update)
	vis:info('plugins updated')
	return true
end)

iterate(plugins_require)

return M

-- TODO's
-- fix vis:info not showing up before after command
-- configure plugin folder
-- commands to fetch and update plugins
-- improve match statement
-- show loading bar and plugin info in vis
-- spesify which plugin to update?
