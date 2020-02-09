local M = {}

-- plugins directory
local plug_dir = 'plugins/'

-- plugins path
local plug_path = os.getenv('HOME') .. '/.config/vis/plugins/'

function file_exists(path)
	local f = io.open(path)
	if f == nil then return false
	else f:close() return true 
	end
end	

function iterate_plugins(operation)
	if plugins then 
		for i, url in ipairs(plugins) do
			local name_ext = url:match('([^/]+)$')
			local name = name_ext:match('(.+)%..+')
			local path = plug_path .. name
			operation(url, name, path)
		end
	end
end

function clone_and_require_plugins(url, name, path)
	if not file_exists(path) then
		--print('\27[H\27[2J'..'loading plugin ' .. name .. '..')
		vis:command(string.format(":!echo -ne '\\033[H\\033[2J%s%s'", 'loading plugin ', name))
		os.execute('git -C ' .. plug_path .. ' clone --depth=1 ' .. url .. ' --quiet 2> /dev/null')
	end
	require(plug_dir .. name)
end

function update_plugins(url, name, path)
	vis:info('updating plugin ' .. name)
	os.execute('git -C ' .. path .. ' pull --depth=1 --quiet 2> /dev/null')
	--os.execute('git -C ' .. path .. ' pull')
end

vis:command_register("plug-update", function(argv, force, win, selection, range)
	-- could spesify which plugin to update later
	--vis:info("update plugins")
	iterate_plugins(update_plugins)
	return true
end)

iterate_plugins(clone_and_require_plugins)

return M

-- TODO's
-- configure plugin folder
-- commands to fetch and update plugins
-- improve match statement
-- show loading bar and plugin info in vis
