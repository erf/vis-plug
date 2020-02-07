local M = {}

-- plugins directory
local plug_dir = 'plugins/'

-- plugins path
local plug_path = os.getenv('HOME') .. '/.config/vis/plugins/'

-- clone and require plugins ( set in visrc.lua )
if plugins then 
	for i, url in ipairs(plugins) do
		local name_ext = url:match('([^/]+)$')
		local name = name_ext:match('(.+)%..+')
		os.execute('git -C ' .. plug_path .. ' clone ' .. url .. ' --quiet')
		require(plug_dir .. name)
	end
end

return M

-- TODO's
-- configure plugin folder
-- commands to fetch and update plugins
-- improve match statement
-- show loading bar and plugin info in vis
