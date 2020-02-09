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

-- clone + require plugins ( set in visrc.lua )
if plugins then 
	for i, url in ipairs(plugins) do
		local name_ext = url:match('([^/]+)$')
		local name = name_ext:match('(.+)%..+')
		local path = plug_path .. name
		if file_exists(path) then
			--print('\27[H\27[2J'..'updating plugin ' .. name .. '..')
			--os.execute('git -C ' .. path .. ' pull --depth=1 --quiet 2> /dev/null')
		else 
			print('\27[H\27[2J'..'loading plugin ' .. name .. '..')
			os.execute('git -C ' .. plug_path .. ' clone --depth=1 ' .. url .. ' --quiet 2> /dev/null')
		end
		require(plug_dir .. name)
	end
end

return M

-- TODO's
-- configure plugin folder
-- commands to fetch and update plugins
-- improve match statement
-- show loading bar and plugin info in vis
