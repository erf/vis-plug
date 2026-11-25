local M = {}

-- the required plugins are stored here
M.plugins = {}

-- the plugins configurations set in visrc.lua
local plugins_conf = {}

-- the dir where we store plugins on disk
local plugins_path = nil

-- we store commands in a list of tables {name, func, desc}
local command_list = {}

-- problems found on init (load errors, name conflicts), reported on INIT
local init_errors = {}

-- the dir this file was loaded from, used by plug-upgrade and plug-purge
local vis_plug_dir = debug.getinfo(1, 'S').source:match('^@(.*)/[^/]*$')

-- add a searcher to find plugins by filename, not module path
table.insert(package.searchers, function(name)
	local file, err = package.searchpath(name, package.path, '', '') -- don't replace . with /
	if not file then
		return err
	end
	local loader, load_err = loadfile(file)
	if not loader then
		return load_err
	end
	return loader, file
end)

-- set custom path and add it first to package.path for require
M.path = function(path)
	plugins_path = path
	package.path = path .. '/?.lua;' .. path .. '/?/init.lua;' .. package.path
end

-- e.g. /Users/some-user/.cache/vis-plug
local get_plugins_path = function()
	local VIS_PLUG_HOME = os.getenv('VIS_PLUG_HOME')
	if VIS_PLUG_HOME then
		return VIS_PLUG_HOME
	end
	local cache = os.getenv('XDG_CACHE_HOME') or (os.getenv('HOME') .. '/.cache')
	return cache .. '/vis-plug'
end

-- set default install path for plugins
M.path(get_plugins_path())

-- quote a string for safe use as a single shell argument
local sh_quote = function(str)
	return "'" .. str:gsub("'", "'\\''") .. "'"
end

-- execute a command and return result string
local execute = function(command)
	local file = io.popen(command)
	if not file then
		return nil
	end
	local result = file:read("*a")
	result = result:gsub('(.-)%s*$', '%1') -- strip trailing spaces
	local success, message, code = file:close()
	return result, success, message, code
end

-- run shell commands in parallel, wait for all to finish and return the output
local run_parallel = function(commands)
	local jobs = {}
	for _, command in ipairs(commands) do
		table.insert(jobs, '(\n' .. command .. '\n) &')
	end
	table.insert(jobs, 'wait')
	return execute(table.concat(jobs, '\n'))
end

-- check if file exists
local file_exists = function(path)
	local file = io.open(path)
	if not file then
		return false
	end
	file:close()
	return true
end

-- format rows (lists of strings) as aligned columns, indented by two spaces
-- returns a list of lines
local format_lines = function(rows)
	local widths = {}
	for _, row in ipairs(rows) do
		for i, cell in ipairs(row) do
			widths[i] = math.max(widths[i] or 0, #cell)
		end
	end
	local lines = {}
	for _, row in ipairs(rows) do
		local cells = {}
		for i, cell in ipairs(row) do
			cells[i] = cell .. string.rep(' ', widths[i] - #cell)
		end
		local line = '  ' .. table.concat(cells, '  ')
		table.insert(lines, (line:gsub('%s+$', '')))
	end
	return lines
end

-- format rows as aligned columns, returns a string
local format_rows = function(rows)
	return table.concat(format_lines(rows), '\n')
end

-- get plugin name from repo url
-- E.g. https://github.com/erf/{vis-highlight}.git -> vis-highlight
local get_name_from_url = function(url)
	return url:gsub('/+$', ''):gsub('%.git$', ''):match('([^/:]+)$')
end

-- separate folders in $VIS_PLUG_HOME/{plugins|themes}
local get_folder = function(theme)
	if theme then
		return '/themes'
	else
		return '/plugins'
	end
end

-- E.g. '~/$VIS_PLUG_HOME/plugins/'
local get_base_path = function(theme)
	return plugins_path .. get_folder(theme)
end

-- get path to file
local get_file_path = function(plug)
	return plug.path .. '/' .. plug.file .. '.lua'
end

-- '{http[s]://github.com}/erf/vis-cursors.git'
local is_github_url = function(url)
	return url:find('^http[s]?://github.com.+') ~= nil
end

-- return true if has the protocol part of the url
-- '{https://}github.com/erf/vis-cursors.git'
local is_host_url = function(url)
	return url:find('^.+://') ~= nil
end

-- return true if has a host but no protocol
-- '{github.com/}erf/vis-cursors.git'
local is_no_host_url = function(url)
	return url:find('^%w+%.%w+[^/]') ~= nil
end

-- [user@]server:project.git
local is_short_ssh_url = function(url)
	return url:find('^.+@.+:.+')
end

-- remove protocol from url to make it shorter for output
local get_short_url = function(url)
	if is_github_url(url) then
		return url:match('^.+://.-/(.*)')
	elseif is_host_url(url) then
		return url:match('^.+://(.*)')
	elseif is_short_ssh_url(url) then
		return url -- TODO shorten?
	else
		return url
	end
end

-- given a github short hand url, return the full url
-- E.g. 'erf/vis-cursors' -> 'https://github.com/erf/vis-cursors.git'
local get_full_url = function(url)
	if is_host_url(url) then
		return url
	elseif is_no_host_url(url) then
		return 'https://' .. url
	elseif is_short_ssh_url(url) then
		return url
	else
		return 'https://github.com/' .. url
	end
end

-- find the plug in conf by name (e.g. vis-cursors) or url (e.g. erf/vis-cursors)
local get_plug_by_name = function(name)
	if name == nil then
		return nil
	end
	for _, plug in ipairs(plugins_conf) do
		if plug.name == name or get_short_url(plug.url) == name or plug.url == name then
			return plug
		end
	end
end

-- iterate the plugins conf and call an operation per plugin
local for_each_plugin = function(func, args)
	for _, plug in ipairs(plugins_conf) do
		func(plug, args)
	end
end

-- prepare the plug configuration
local plug_init = function(plug, args)
	plug.file = plug.file or ''
	plug.url = get_full_url(plug.url or plug[1])
	plug.name = get_name_from_url(plug.url)
	plug.path = get_base_path(plug.theme) .. '/' .. plug.name
end

local git_cmd = function(plug)
	return 'git -C ' .. sh_quote(plug.path)
end

-- shell command to shallow clone a plugin, checking out its ref if given
-- branches and tags are cloned shallow, commits fall back to a full clone
local clone_command = function(plug)
	local url, path = sh_quote(plug.url), sh_quote(plug.path)
	local full = 'git clone --quiet --recurse-submodules'
	local shallow = full .. ' --depth 1 --shallow-submodules'
	if not plug.ref then
		return string.format('%s %s %s 2>/dev/null', shallow, url, path)
	end
	local ref = sh_quote(plug.ref)
	return string.format('%s --branch %s %s %s 2>/dev/null || ' ..
		'{ %s %s %s 2>/dev/null && %s checkout --quiet %s 2>/dev/null; }',
		shallow, ref, url, path, full, url, path, git_cmd(plug), ref)
end

-- shell command to checkout a specific commit, branch or tag
-- if the ref is not found locally (e.g. shallow clone), fetch everything and retry
local checkout_command = function(plug)
	local git, ref = git_cmd(plug), sh_quote(plug.ref)
	return string.format('%s checkout --quiet %s 2>/dev/null || { ' ..
		'%s remote set-branches origin "*" 2>/dev/null; ' ..
		'%s fetch --quiet --tags --unshallow 2>/dev/null || %s fetch --quiet --tags 2>/dev/null; ' ..
		'%s checkout --quiet %s 2>/dev/null; }',
		git, ref, git, git, git, git, ref)
end

-- checkout specific commit, branch or tag, return true on success
local checkout = function(plug)
	if not plug.ref then
		return true
	end
	local _, success = execute(checkout_command(plug))
	return success
end

-- run a shell command (made by make_command) for each installed plugin in
-- parallel, return a table of {plug = output}; commands should print one line
local run_for_installed = function(make_command)
	local commands = {}
	for i, plug in ipairs(plugins_conf) do
		if file_exists(plug.path) then
			table.insert(commands, string.format('out=$(\n%s\n)\necho %d":$out"', make_command(plug), i))
		end
	end
	local results = {}
	if #commands == 0 then
		return results
	end
	for line in (run_parallel(commands) or ''):gmatch('[^\n]+') do
		local i, out = line:match('^(%d+):(.*)$')
		local plug = plugins_conf[tonumber(i or '')]
		if plug then
			results[plug] = out
		end
	end
	return results
end

-- describe the checked out version: the branch, or the tag or commit when pinned
local version_command = function(plug)
	local git = git_cmd(plug)
	return string.format('if %s symbolic-ref -q HEAD >/dev/null; then %s symbolic-ref --short HEAD; ' ..
		'else echo "$(%s describe --tags --exact-match 2>/dev/null || %s rev-parse --short HEAD) (pinned)"; fi',
		git, git, git, git)
end

local plug_require = function(plug, args)
	if not file_exists(plug.path) then
		return
	end
	if plug.theme then
		return
	end
	local name = 'plugins/' .. plug.name
	if plug.file ~= '' then
		name = name .. '/' .. plug.file
	end
	local ok, plugin = pcall(require, name)
	if not ok then
		table.insert(init_errors, 'failed to load ' .. plug.name .. ': ' .. tostring(plugin))
		return
	end
	if plug.alias then
		M.plugins[plug.alias] = plugin
	end
end

-- warn about plugins with the same name, as they would share a folder
local check_name_conflicts = function()
	local seen = {}
	for _, plug in ipairs(plugins_conf) do
		local other = seen[plug.path]
		if other then
			table.insert(init_errors, string.format('%s and %s have the same name (%s), remove one',
				get_short_url(other.url), get_short_url(plug.url), plug.name))
		else
			seen[plug.path] = plug
		end
	end
end

local install_plugins = function(silent)
	-- clone missing plugins, checkout ref of installed plugins
	local clones, queued, checkouts = {}, {}, {}
	for _, plug in ipairs(plugins_conf) do
		if not file_exists(plug.path) then
			table.insert(clones, clone_command(plug))
			table.insert(queued, plug)
		elseif plug.ref then
			table.insert(checkouts, checkout_command(plug))
		end
	end

	if #checkouts > 0 then
		run_parallel(checkouts)
	end

	if #clones == 0 then
		if not silent then
			vis:info('Nothing to install')
		end
		return
	end

	vis:info('Installing ' .. #clones .. ' plugin(s)..')
	vis:redraw()
	-- create the plugins and themes folders, only when we have something to clone
	os.execute('mkdir -p ' .. sh_quote(get_base_path(false)) .. ' ' .. sh_quote(get_base_path(true)))
	run_parallel(clones)

	local installed = 0
	for _, plug in ipairs(queued) do
		if file_exists(plug.path) then
			installed = installed + 1
		end
	end
	local failed = #queued - installed
	if failed > 0 then
		vis:info(string.format('%d plugin(s) installed, %d failed', installed, failed))
	else
		vis:info(string.format('%d plugin(s) installed', installed))
	end
end

-- fetch and print how many commits the branch is behind its upstream
-- (prints nothing for pinned plugins, which have no upstream)
local outdated_command = function(plug)
	local git = git_cmd(plug)
	return string.format('%s fetch --quiet 2>/dev/null && %s rev-list --count "HEAD..@{u}" 2>/dev/null',
		git, git)
end

local plug_outdated = function()
	vis:info('Checking for outdated plugins..')
	vis:redraw()
	local results = run_for_installed(outdated_command)
	local rows = {}
	for _, plug in ipairs(plugins_conf) do
		local behind = tonumber(results[plug] or '')
		if behind and behind > 0 then
			table.insert(rows, { plug.name, behind .. ' commit(s) behind' })
		end
	end
	if #rows == 0 then
		vis:info('All plugins and themes are up to date')
		return
	end
	vis:message(string.format('%d outdated plugin(s), :plug-update to update:\n%s', #rows, format_rows(rows)))
end

-- shell command to checkout the ref (if any) and pull if on a branch
-- prints {hash before}:{hash after}:{branch|pinned|failed}
local update_command = function(plug)
	local git = git_cmd(plug)
	local lines = { string.format('before=$(%s rev-parse HEAD 2>/dev/null)', git) }
	if plug.ref then
		table.insert(lines, checkout_command(plug))
	end
	table.insert(lines, string.format(
		'if %s symbolic-ref -q HEAD >/dev/null; then state=branch; ' ..
		'%s pull --quiet --recurse-submodules >/dev/null 2>&1 || state=failed; ' ..
		'else state=pinned; fi', git, git))
	table.insert(lines, string.format('echo "$before:$(%s rev-parse HEAD 2>/dev/null):$state"', git))
	return table.concat(lines, '\n')
end

local update_plugins = function()
	vis:info('Updating plugins..')
	vis:redraw()

	local results = run_for_installed(update_command)
	local updated, failed, pinned = {}, {}, {}
	for _, plug in ipairs(plugins_conf) do
		local before, after, state = (results[plug] or ''):match('^(%x*):(%x*):(%a+)$')
		if state == 'failed' then
			table.insert(failed, { plug.name, get_short_url(plug.url) })
		elseif state and before ~= after then
			table.insert(updated, { plug.name, before:sub(1, 7) .. ' → ' .. after:sub(1, 7) })
		elseif state == 'pinned' then
			table.insert(pinned, plug.name)
		end
	end

	local pinned_text = 'Pinned (not updated): ' .. table.concat(pinned, ', ')
	if #updated == 0 and #failed == 0 then
		vis:info('All plugins and themes are up to date' .. (#pinned > 0 and '. ' .. pinned_text or ''))
		return
	end
	local messages = {}
	if #updated > 0 then
		table.insert(messages, string.format('Updated %d plugin(s):\n%s', #updated, format_rows(updated)))
	end
	if #failed > 0 then
		table.insert(messages, string.format('Failed to update %d plugin(s):\n%s', #failed, format_rows(failed)))
	end
	if #pinned > 0 then
		table.insert(messages, pinned_text)
	end
	vis:message(table.concat(messages, '\n'))
end

-- require plugins (and optionally install and checkout)
M.init = function(plugins, install_on_init)
	plugins_conf = plugins or {}
	for_each_plugin(plug_init)
	check_name_conflicts()
	if install_on_init then
		install_plugins(true)
	end
	for_each_plugin(plug_require)
	return M
end

local command_install = function(argv, force, win, selection, range)
	install_plugins(false)
	return true
end

local command_rm = function(argv, force, win, selection, range)
	local name = argv[1]
	if name == nil then
		vis:info('Missing {name} (:plug-list for names)')
		return true
	end
	local plug = get_plug_by_name(name)
	if not plug then
		vis:info('\'' .. name .. '\' not found')
		return true
	end
	if file_exists(plug.path) then
		os.execute('rm -rf ' .. sh_quote(plug.path))
		vis:info(plug.name .. ' (' .. plug.path .. ') deleted')
	else
		vis:info(plug.name .. ' is not installed')
	end
	return true
end

local command_checkout = function(argv, force, win, selection, range)
	local name = argv[1]
	local ref = argv[2]
	if name == nil or ref == nil then
		vis:info('Missing {name} or {commit|branch|tag}')
		return true
	end
	local plug = get_plug_by_name(name)
	if not plug then
		vis:info('\'' .. name .. '\' not found')
		return true
	end
	vis:info('Checking out \'' .. ref .. '\' for ' .. plug.name .. '..')
	vis:redraw()
	plug.ref = ref
	if checkout(plug) then
		vis:info('Checked out \'' .. ref .. '\'')
	else
		vis:info('Could not checkout \'' .. ref .. '\' for ' .. plug.name)
	end
	return true
end

local command_clean = function(argv, force, win, selection, range)
	local deleted = 0
	for _, plug in ipairs(plugins_conf) do
		if file_exists(plug.path) then
			os.execute('rm -rf ' .. sh_quote(plug.path))
			deleted = deleted + 1
		end
	end
	if deleted == 0 then
		vis:info('Nothing to delete')
	else
		vis:info('' .. deleted .. ' plugin(s) deleted')
	end
	return true
end

local command_update = function(argv, force, win, selection, range)
	update_plugins()
	return true
end

-- upgrade vis-plug with git pull, only if its dir is the root of its own git clone
-- (not e.g. copied into a dotfiles repo, where git would pull the dotfiles repo)
local command_upgrade = function(argv, force, win, selection, range)
	if not vis_plug_dir then
		vis:info('Could not find the vis-plug folder')
		return true
	end
	vis:info('Upgrading vis-plug..')
	vis:redraw()
	local dir = sh_quote(vis_plug_dir)
	local git = 'git -C ' .. dir
	local result = execute(string.format(
		'[ "$(%s rev-parse --show-toplevel 2>/dev/null)" = "$(cd %s && pwd -P)" ] || { echo not-a-clone; exit; }\n' ..
		'before=$(%s rev-parse --short HEAD)\n' ..
		'%s pull --quiet --ff-only >/dev/null 2>&1 || { echo failed; exit; }\n' ..
		'echo "$before:$(%s rev-parse --short HEAD)"',
		git, dir, git, git, git))
	local before, after = (result or ''):match('^(%x+):(%x+)$')
	if result == 'not-a-clone' then
		vis:info('vis-plug in ' .. vis_plug_dir .. ' is not a git clone, upgrade it manually')
	elseif not before then
		vis:info('Upgrade failed (git pull in ' .. vis_plug_dir .. ')')
	elseif before == after then
		vis:info('vis-plug is already up to date')
	else
		vis:info('vis-plug upgraded ' .. before .. ' → ' .. after .. ', restart vis to use it')
	end
	return true
end

-- find installed plugins and themes (git repos) which are not in the config
local get_orphans = function()
	local keep = {}
	for _, plug in ipairs(plugins_conf) do
		keep[plug.path] = true
	end
	if vis_plug_dir then
		keep[vis_plug_dir] = true
	end
	local find_command = string.format('find %s %s -mindepth 1 -maxdepth 1 -type d 2> /dev/null',
		sh_quote(get_base_path(false)), sh_quote(get_base_path(true)))
	local orphans = {}
	for dir in (execute(find_command) or ''):gmatch('[^\n]+') do
		if not keep[dir] and file_exists(dir .. '/.git') then
			table.insert(orphans, dir)
		end
	end
	table.sort(orphans)
	return orphans
end

-- list plugins not in the config, or delete them if forced with !
local command_purge = function(argv, force, win, selection, range)
	local orphans = get_orphans()
	if #orphans == 0 then
		vis:info('Nothing to purge')
		return true
	end
	-- show folders relative to the install path, e.g. plugins/vis-foo
	local rows = {}
	for _, dir in ipairs(orphans) do
		table.insert(rows, { dir:sub(#plugins_path + 2) })
	end
	if not force then
		vis:message(string.format('%d plugin(s) in %s not in config, :plug-purge! to delete:\n%s',
			#orphans, plugins_path, format_rows(rows)))
		return true
	end
	for _, dir in ipairs(orphans) do
		os.execute('rm -rf ' .. sh_quote(dir))
	end
	vis:message(string.format('Deleted %d plugin(s) in %s:\n%s', #orphans, plugins_path, format_rows(rows)))
	return true
end

-- list plugins and themes as: name, source, version or status, (file)
local command_ls = function(argv, force, win, selection, range)
	if #plugins_conf == 0 then
		vis:info('No plugins or themes in config')
		return true
	end
	local groups = { { title = 'Plugins', plugs = {} }, { title = 'Themes', plugs = {} } }
	for _, plug in ipairs(plugins_conf) do
		table.insert(groups[plug.theme and 2 or 1].plugs, plug)
	end
	-- format plugins and themes together so their columns line up
	local versions = run_for_installed(version_command)
	local rows = {}
	for _, group in ipairs(groups) do
		for _, plug in ipairs(group.plugs) do
			local status = versions[plug] or 'not installed'
			local file = plug.file ~= '' and '(' .. plug.file .. ')' or ''
			table.insert(rows, { plug.name, get_short_url(plug.url), status, file })
		end
	end
	local lines = format_lines(rows)
	local out, i = {}, 0
	for _, group in ipairs(groups) do
		if #group.plugs > 0 then
			table.insert(out, (#out > 0 and '\n' or '') .. group.title .. ' (' .. #group.plugs .. ')')
			for _ = 1, #group.plugs do
				i = i + 1
				table.insert(out, lines[i])
			end
		end
	end
	vis:message(table.concat(out, '\n'))
	return true
end

local command_outdated = function(argv, force, win, selection, range)
	plug_outdated()
	return true
end

local command_list_commands = function(argv, force, win, selection, range)
	local rows = {}
	for _, command in ipairs(command_list) do
		table.insert(rows, { ':' .. command.name, command.desc })
	end
	vis:message('vis-plug commands\n' .. format_rows(rows))
	return true
end

-- we store commands in a list of tables {name, func, desc}
command_list = { {
	name = 'plug-list',
	desc = 'list plugins and themes',
	func = command_ls
}, {
	name = 'plug-install',
	desc = 'install plugins (git clone)',
	func = command_install
}, {
	name = 'plug-update',
	desc = 'update plugins (git pull)',
	func = command_update
}, {
	name = 'plug-outdated',
	desc = 'check if plugins are up-to-date',
	func = command_outdated
}, {
	name = 'plug-upgrade',
	desc = 'upgrade to latest vis-plug version',
	func = command_upgrade
}, {
	name = 'plug-remove',
	desc = 'delete plugin by {name} (:plug-list for names)',
	func = command_rm
}, {
	name = 'plug-clean',
	desc = 'delete all plugins from disk',
	func = command_clean
}, {
	name = 'plug-purge',
	desc = 'list plugins not in config (! to delete them)',
	func = command_purge
}, {
	name = 'plug-checkout',
	desc = 'checkout {name} {commit|branch|tag}',
	func = command_checkout
}, {
	name = 'plug-commands',
	desc = 'list commands (these)',
	func = command_list_commands
} }

-- initialize commands
for _, command in ipairs(command_list) do
	vis:command_register(command.name, command.func, command.desc)
end

-- set theme and report problems found on init on INIT event
vis.events.subscribe(vis.events.INIT, function()
	if #init_errors > 0 then
		vis:message('vis-plug:\n' .. table.concat(init_errors, '\n'))
	end
	for _, plug in ipairs(plugins_conf) do
		if plug.theme and file_exists(get_file_path(plug)) then
			vis:command('set theme ' .. plug.name .. '/' .. plug.file)
			return -- set first theme and return
		end
	end
end)

return M
