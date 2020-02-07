local M = {}

-- plugins directory
local plugins_dir = 'plugins/'

-- plugins path
local plugins_path = os.getenv('HOME') .. '/.config/vis/plugins'

-- downlaod and require plugins ( set in visrc.lua )
if plugins then 
	for i, url in ipairs(plugins) do
		-- -q  > quite
		-- -nc > dont download if file exists ( even if newer )
		-- -N  > download if newer
		-- -P  > set directory prefix
		os.execute('wget -q -nc -P ' .. plugins_path .. ' ' .. url)
		local name_ext = url:match('([^/]+)$')
		local name = name_ext:match('(.+)%..+')
		local path = plugins_path .. '/' .. name
		require(plugins_dir .. name)
	end
end

return M

-- TODO 
-- only use repo name ( when plugins have init.lua file we could use git clone to plugins folder )
-- download and overwrite if newer file exists ( use -N )
-- configurable plugin folder
-- commands to download plugin files
-- simplify match statement
-- show loading bar and plugin info in vis
-- customize plugins ( set variables etc )
