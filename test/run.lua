-- Tests for vis-plug, run with: lua test/run.lua (needs git)
--
-- vis-plug is loaded with a fake `vis` that records messages, and plugins are
-- installed from local git repos (file:// urls) created in a temp folder, so
-- the tests run real git commands without network access. The install folder
-- has a space and a quote in its name to test shell quoting.

local sh_quote = function(str)
	return "'" .. str:gsub("'", "'\\''") .. "'"
end

-- re-run with an empty git config, so user settings (e.g. commit signing)
-- don't affect the tests
if not os.getenv('VIS_PLUG_TEST') then
	local i = 0
	while arg[i - 1] do
		i = i - 1
	end
	local ok = os.execute(string.format('VIS_PLUG_TEST=1 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 %s %s',
		sh_quote(arg[i]), sh_quote(arg[0])))
	os.exit(ok == true or ok == 0)
end

local root = (arg[0]:match('^(.*)/[^/]*$') or '.') .. '/..'

-- helpers

-- run a shell command, return its output, error if it fails
local sh = function(command)
	local file = io.popen(command .. ' 2>&1')
	local output = file:read('*a'):gsub('%s+$', '')
	if not file:close() then
		error('command failed: ' .. command .. '\n' .. output, 2)
	end
	return output
end

local git = function(dir, args)
	return sh('git -C ' .. sh_quote(dir) .. ' ' .. args)
end

local read_file = function(path)
	local file = assert(io.open(path))
	local content = file:read('*a')
	file:close()
	return content
end

local exists = function(path)
	local file = io.open(path)
	if file then
		file:close()
	end
	return file ~= nil
end

local new_repo = function(dir)
	sh('mkdir -p ' .. sh_quote(dir) .. ' && git init -q -b main ' .. sh_quote(dir))
end

local commit = function(dir, file, content, message)
	local f = assert(io.open(dir .. '/' .. file, 'w'))
	f:write(content)
	f:close()
	git(dir, 'add ' .. sh_quote(file))
	git(dir, '-c user.name=test -c user.email=test@test commit -q -m ' .. sh_quote(message))
end

local is_shallow = function(dir)
	return git(dir, 'rev-parse --is-shallow-repository') == 'true'
end

local branch = function(dir)
	return (io.popen('git -C ' .. sh_quote(dir) .. ' symbolic-ref -q --short HEAD'):read('*l'))
end

local head = function(dir)
	return git(dir, 'rev-parse HEAD')
end

local describe = function(dir)
	return git(dir, 'describe --tags --exact-match')
end

-- assertions, errors point to the line in the test

local eq = function(actual, expected)
	if actual ~= expected then
		error(string.format('expected %q, got %q', tostring(expected), tostring(actual)), 2)
	end
end

local contains = function(str, sub)
	if not str:find(sub, 1, true) then
		error(string.format('expected %q in:\n%s', sub, str), 2)
	end
end

local matches = function(str, pattern)
	if not str:find(pattern) then
		error(string.format('expected pattern %q in:\n%s', pattern, str), 2)
	end
end

-- fixtures: source repos that each test clones bare remotes from

local tmp = sh('mktemp -d')
local src = tmp .. '/src'
local home -- install folder, set per test

-- plugin: main with commits c1 (tag v1), c2, c3 and a dev branch
new_repo(src .. '/plugin')
commit(src .. '/plugin', 'init.lua', 'return { v = 1 }', 'c1')
git(src .. '/plugin', 'tag v1')
local c1 = head(src .. '/plugin')
commit(src .. '/plugin', 'init.lua', 'return { v = 2 }', 'c2')
commit(src .. '/plugin', 'init.lua', 'return { v = 3 }', 'c3')
git(src .. '/plugin', 'checkout -q -b dev')
commit(src .. '/plugin', 'init.lua', "return { v = 'dev' }", 'dev')
git(src .. '/plugin', 'checkout -q main')

new_repo(src .. '/broken')
commit(src .. '/broken', 'init.lua', 'return {', 'syntax error')

new_repo(src .. '/theme')
commit(src .. '/theme', 'mytheme.lua', '-- theme', 'theme')

local id = 0
local next_id = function()
	id = id + 1
	return id
end

-- create a bare remote {name}.git from a source repo, return its file:// url
local remote = function(source, name)
	local path = string.format('%s/remotes/%d/%s.git', tmp, next_id(), name)
	sh(string.format('git clone -q --bare %s %s', sh_quote(src .. '/' .. source), sh_quote(path)))
	return 'file://' .. path
end

-- push a new commit to a branch of a remote
local push = function(url, branch_name, content)
	local work = tmp .. '/work/' .. next_id()
	sh(string.format('git clone -q %s %s', sh_quote(url), sh_quote(work)))
	git(work, 'checkout -q ' .. branch_name)
	commit(work, 'init.lua', content, 'new')
	git(work, 'push -q origin ' .. branch_name)
end

-- load a fresh vis-plug with a fake vis (like starting vis), init it with conf
-- and return the fake vis, which records infos, messages and commands
local load = function(conf, install, init_file)
	local v = { infos = {}, messages = {}, commands = {}, cmds = {} }
	vis = {
		events = { INIT = 'INIT', subscribe = function(_, func) v.on_init = func end },
		command_register = function(_, name, func) v.cmds[name] = func end,
		info = function(_, text) table.insert(v.infos, text) end,
		message = function(_, text) table.insert(v.messages, text) end,
		redraw = function() end,
		command = function(_, text) table.insert(v.commands, text) end,
	}
	for name in pairs(package.loaded) do
		if name:match('^plugins/') then
			package.loaded[name] = nil
		end
	end
	v.plug = dofile(init_file or root .. '/init.lua')
	v.plug.path(home)
	v.plug.init(conf, install)
	-- run a command, e.g. v.run('plug-checkout', { 'vis-a', 'v1' })
	v.run = function(name, argv, force)
		v.infos, v.messages = {}, {}
		v.cmds[name](argv or {}, force or false)
	end
	v.info = function()
		return v.infos[#v.infos]
	end
	v.message = function()
		return table.concat(v.messages, '\n')
	end
	return v
end

-- tests

local tests = {}
local test = function(name, func)
	table.insert(tests, { name = name, func = func })
end

test('urls: full url, name and install path', function()
	local conf = {
		{ 'erf/vis-cursors' },
		{ url = 'https://github.com/erf/vis-title.git' },
		{ 'gitlab.com/muhq/vis-lspc' },
		{ 'git@github.com:erf/vis-sneak.git' },
		{ 'https://example.com/foo/vis.dotted/' },
		{ 'samlwood/vis-gruvbox', theme = true, file = 'gruvbox' },
	}
	local v = load(conf, false)
	eq(conf[1].url, 'https://github.com/erf/vis-cursors')
	eq(conf[1].name, 'vis-cursors')
	eq(conf[1].path, home .. '/plugins/vis-cursors')
	eq(conf[2].name, 'vis-title')
	eq(conf[3].url, 'https://gitlab.com/muhq/vis-lspc')
	eq(conf[3].name, 'vis-lspc')
	eq(conf[4].url, 'git@github.com:erf/vis-sneak.git')
	eq(conf[4].name, 'vis-sneak')
	eq(conf[5].name, 'vis.dotted')
	eq(conf[6].path, home .. '/themes/vis-gruvbox')
	v.run('plug-list')
	matches(v.message(), 'vis%-cursors%s+erf/vis%-cursors%s+not installed')
end)

test('install: shallow clones, refs and loading', function()
	local conf = {
		{ remote('plugin', 'vis-a'), alias = 'a' },
		{ remote('plugin', 'vis-b'), ref = 'dev', alias = 'b' },
		{ remote('plugin', 'vis-c'), ref = 'v1', alias = 'c' },
		{ remote('plugin', 'vis-d'), ref = c1, alias = 'd' },
		{ remote('plugin', 'vis.dotted') .. '/', alias = 'dotted' },
		{ remote('theme', 'vis-theme'), theme = true, file = 'mytheme' },
	}
	local v = load(conf, true)
	eq(v.info(), 'Installed 6 plugins')
	local plugins = v.plug.plugins
	-- no ref: shallow on the default branch
	eq(is_shallow(conf[1].path), true)
	eq(branch(conf[1].path), 'main')
	eq(plugins.a.v, 3)
	-- branch and tag refs: shallow
	eq(is_shallow(conf[2].path), true)
	eq(branch(conf[2].path), 'dev')
	eq(plugins.b.v, 'dev')
	eq(is_shallow(conf[3].path), true)
	eq(describe(conf[3].path), 'v1')
	eq(plugins.c.v, 1)
	-- commit ref: full clone
	eq(is_shallow(conf[4].path), false)
	eq(head(conf[4].path), c1)
	eq(plugins.d.v, 1)
	-- names with dots are required by file name
	eq(plugins.dotted.v, 3)
	v.on_init()
	eq(v.commands[1], 'set theme vis-theme/mytheme')
	v.run('plug-install')
	eq(v.info(), 'Nothing to install')
end)

test('install: failed clones are reported', function()
	local v = load({ { 'file://' .. tmp .. '/missing/vis-x.git' }, { remote('plugin', 'vis-a') } }, true)
	eq(v.info(), 'Installed 1 plugin, 1 failed (see :plug-list)')
end)

test('init: broken plugins are reported, others still load', function()
	local v = load({ { remote('broken', 'vis-broken') }, { remote('plugin', 'vis-a'), alias = 'a' } }, true)
	eq(v.plug.plugins.a.v, 3)
	v.on_init()
	matches(v.message(), '^vis%-plug problems %(1%)\n  failed to load vis%-broken: .*unexpected symbol')
end)

test('init: plugins with the same name, only the first is used', function()
	local conf = {
		{ remote('plugin', 'vis-a'), alias = 'a' },
		{ remote('broken', 'vis-a'), alias = 'other' }, -- would fail to load if used
	}
	-- run a few times, the clones used to race for the same folder
	for _ = 1, 3 do
		sh('rm -rf ' .. sh_quote(home))
		local v = load(conf, true)
		eq(v.info(), 'Installed 1 plugin')
		eq(v.plug.plugins.a.v, 3)
		eq(v.plug.plugins.other, nil)
		v.on_init()
		contains(v.message(), 'have the same name (vis-a), using the first')
		v.run('plug-list')
		matches(v.message(), 'vis%-a%s+%S+%s+skipped, same name as another plugin')
		v.run('plug-update')
		eq(v.info(), 'All plugins and themes are up to date')
	end
end)

test('ref: a changed ref is applied on start', function()
	local url = remote('plugin', 'vis-a')
	local path = home .. '/plugins/vis-a'
	load({ { url, ref = 'v1' } }, true)
	eq(describe(path), 'v1')
	load({ { url, ref = 'dev' } }, true)
	eq(branch(path), 'dev')
	load({ { url, ref = c1 } }, true)
	eq(head(path), c1)
	load({ { url, ref = 'main' } }, true)
	eq(branch(path), 'main')
end)

test('outdated and update: commits behind, updates and pinned plugins', function()
	local a = remote('plugin', 'vis-a')
	local v = load({ { a }, { remote('plugin', 'vis-c'), ref = 'v1' } }, true)
	push(a, 'main', 'return { v = 4 }')
	v.run('plug-outdated')
	matches(v.message(), '^Outdated %(1%)\n  vis%-a%s+1 commit behind\n\nRun :plug%-update to update\n$')
	v.run('plug-update')
	matches(v.message(), '^Updated %(1%)\n  vis%-a%s+%x+ → %x+\n\nPinned, not updated %(1%)\n  vis%-c%s+v1\n$')
	v.run('plug-update')
	eq(v.info(), 'All plugins and themes are up to date (1 pinned)')
	v.run('plug-outdated')
	eq(v.info(), 'All plugins and themes are up to date')
end)

test('checkout: tags, branches and errors on a shallow clone', function()
	local conf = { { remote('plugin', 'vis-a') } }
	local path = home .. '/plugins/vis-a'
	local v = load(conf, true)
	v.run('plug-checkout', { 'vis-a', 'v1' })
	eq(v.info(), 'Checked out v1 in vis-a')
	eq(describe(path), 'v1')
	v.run('plug-checkout', { conf[1].url, 'dev' }) -- by url
	eq(branch(path), 'dev')
	v.run('plug-checkout', { 'vis-a', 'nope' })
	eq(v.info(), 'Could not check out nope in vis-a')
	v.run('plug-checkout', { 'nope', 'v1' })
	eq(v.info(), 'No plugin named nope (see :plug-list)')
	v.run('plug-checkout')
	eq(v.info(), 'Usage: :plug-checkout {name} {commit|branch|tag}')
end)

test('list: names, urls, versions and status', function()
	local v = load({
		{ remote('plugin', 'vis-a') },
		{ remote('plugin', 'vis-c'), ref = 'v1' },
		{ 'file://' .. tmp .. '/missing/vis-x.git' },
		{ remote('theme', 'vis-theme'), theme = true, file = 'mytheme' },
	}, true)
	v.run('plug-list')
	local message = v.message()
	matches(message, '^Plugins %(3%)\n')
	matches(message, '\n  vis%-a%s+%S+/vis%-a%.git%s+main\n')
	matches(message, '\n  vis%-c%s+%S+/vis%-c%.git%s+v1 %(pinned%)\n')
	matches(message, '\n  vis%-x%s+%S+/vis%-x%.git%s+not installed\n')
	matches(message, '\n\nThemes %(1%)\n  vis%-theme%s+%S+%s+main%s+file: mytheme\n$')
end)

test('purge: lists and deletes plugins not in config', function()
	local a, b = remote('plugin', 'vis-a'), remote('plugin', 'vis-b')
	load({ { a }, { b } }, true)
	local v = load({ { a } }, false)
	v.run('plug-purge')
	matches(v.message(), '^Not in config %(1%)\n  plugins/vis%-b\n\nRun :plug%-purge! to delete them')
	eq(exists(home .. '/plugins/vis-b'), true)
	v.run('plug-purge', {}, true)
	contains(v.message(), 'Deleted (1)\n  plugins/vis-b')
	eq(exists(home .. '/plugins/vis-b'), false)
	eq(exists(home .. '/plugins/vis-a'), true)
	v.run('plug-purge')
	eq(v.info(), 'Nothing to purge')
end)

test('help: lists all commands', function()
	local v = load({}, false)
	v.run('plug-help')
	local message = v.message()
	contains(message, 'vis-plug commands (8)')
	for _, name in ipairs({ 'list', 'install', 'update', 'outdated', 'upgrade', 'purge', 'checkout', 'help' }) do
		contains(message, ':plug-' .. name)
	end
end)

test('upgrade: pulls its own git clone only', function()
	-- an upstream repo with this vis-plug, and a clone to load vis-plug from
	local upstream, clone = tmp .. '/upgrade/upstream', tmp .. '/upgrade/clone'
	new_repo(upstream)
	commit(upstream, 'init.lua', read_file(root .. '/init.lua'), 'vis-plug')
	sh(string.format('git clone -q %s %s', sh_quote(upstream), sh_quote(clone)))
	commit(upstream, 'README.md', 'new', 'new')
	local v = load({}, false, clone .. '/init.lua')
	v.run('plug-upgrade')
	matches(v.info(), '^Upgraded vis%-plug %x+ → %x+, restart vis to use it$')
	v.run('plug-upgrade')
	eq(v.info(), 'vis-plug is already up to date')
	-- copied into a dotfiles repo: refuse and leave the dotfiles repo alone
	local dotfiles = tmp .. '/upgrade/dotfiles'
	new_repo(dotfiles)
	sh('mkdir ' .. sh_quote(dotfiles .. '/vis-plug'))
	commit(dotfiles, 'vis-plug/init.lua', read_file(root .. '/init.lua'), 'dotfiles')
	git(dotfiles, 'remote add origin ' .. sh_quote(upstream))
	local before = head(dotfiles)
	v = load({}, false, dotfiles .. '/vis-plug/init.lua')
	v.run('plug-upgrade')
	eq(v.info(), 'vis-plug is not a git clone, upgrade it manually')
	eq(head(dotfiles), before)
end)

-- run

local failed = 0
for i, t in ipairs(tests) do
	home = tmp .. "/home dir's/" .. i
	local ok, err = pcall(t.func)
	if ok then
		print('ok    ' .. t.name)
	else
		failed = failed + 1
		print('FAIL  ' .. t.name .. '\n      ' .. tostring(err):gsub('\n', '\n      '))
	end
end
sh('rm -rf ' .. sh_quote(tmp))
print(string.format('\n%d passed, %d failed', #tests - failed, failed))
os.exit(failed == 0)
