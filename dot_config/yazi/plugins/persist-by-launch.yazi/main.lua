-- ~/.config/yazi/plugins/persist-by-launch.yazi/main.lua
-- Persist yazi session state keyed by the launch cwd (parent shell's $PWD).
--
-- Currently persists per launch cwd:
--   - active tab's cwd, hovered cursor, sort, linemode, show_hidden
--   - last_seen timestamp for TTL-based sweep (see TTL_SECONDS)
--
-- On every save the store is swept: entries whose last_seen is older than
-- TTL_SECONDS (or missing) are dropped.
--
-- Not implemented:
--   - multi-select restore (cx.active.selected iterates but always returns 0
--     entries in our save context; API investigation deferred)
--   - multi-tab restore (only the active tab is saved/restored; tab_create /
--     tab_close / tab_switch orchestration deferred)

local STATE_FILE = os.getenv("HOME") .. "/.local/state/yazi/persist-by-launch.json"
local TTL_SECONDS = 30 * 24 * 60 * 60 -- 30 days: prune entries not saved within this window

local function read_all(path)
	local file = io.open(path, "r")
	if not file then
		return {}
	end
	local content = file:read("*a")
	file:close()
	local ok, decoded = pcall(ya.json_decode, content)
	if not ok or type(decoded) ~= "table" then
		return {}
	end
	return decoded
end

local function ensure_dir(path)
	local dir = path:match("(.*)/[^/]+$")
	if dir then
		os.execute("mkdir -p '" .. dir .. "'")
	end
end

local function write_all(path, data)
	ensure_dir(path)
	local encoded = ya.json_encode(data)
	if not encoded then
		ya.err("persist-by-launch: json_encode failed")
		return
	end
	local file = io.open(path, "w")
	if not file then
		ya.err("persist-by-launch: cannot open " .. path .. " for write")
		return
	end
	file:write(encoded)
	file:close()
end

local function sweep(all, now)
	local cutoff = now - TTL_SECONDS
	local kept = {}
	local dropped = 0
	for key, entry in pairs(all) do
		if type(entry) == "table" and (tonumber(entry.last_seen) or 0) >= cutoff then
			kept[key] = entry
		else
			dropped = dropped + 1
		end
	end
	return kept, dropped
end

local save = ya.sync(function(state)
	if not state.launch_cwd then
		return
	end
	local tab = cx.active
	local hovered = tab.current.hovered
	local cursor_name = hovered and tostring(hovered.url):match("([^/]+)$") or nil
	local now = os.time()
	local session = {
		cwd = tostring(tab.current.cwd),
		cursor = cursor_name,
		sort = {
			by = tab.pref.sort_by,
			reverse = tab.pref.sort_reverse,
			dir_first = tab.pref.sort_dir_first,
			sensitive = tab.pref.sort_sensitive,
			translit = tab.pref.sort_translit,
		},
		linemode = tab.pref.linemode,
		show_hidden = tab.pref.show_hidden,
		last_seen = now,
	}
	local all = read_all(state.state_file)
	all[state.launch_cwd] = session
	local kept, dropped = sweep(all, now)
	write_all(state.state_file, kept)
	if dropped > 0 then
		ya.dbg("persist-by-launch: saved " .. state.launch_cwd .. ", swept " .. dropped .. " stale")
	else
		ya.dbg("persist-by-launch: saved " .. state.launch_cwd)
	end
end)

local pending = nil

local restore_prefs = ya.sync(function(state)
	if state.restored then
		return
	end
	state.restored = true
	if not state.launch_cwd then
		return
	end
	local all = read_all(state.state_file)
	local entry = all[state.launch_cwd]
	if type(entry) ~= "table" or not entry.cwd then
		return
	end
	ya.emit("cd", { entry.cwd })
	if type(entry.sort) == "table" then
		ya.emit("sort", entry.sort)
	end
	if entry.linemode then
		ya.emit("linemode", { entry.linemode })
	end
	if entry.show_hidden ~= nil then
		ya.emit("hidden", { entry.show_hidden and "show" or "hide" })
	end
	pending = entry
	ya.dbg("persist-by-launch: restored " .. state.launch_cwd)
end)

local restore_cursor = ya.sync(function()
	if not pending or not pending.cursor then
		return
	end
	ya.emit("reveal", { pending.cwd .. "/" .. pending.cursor, no_dummy = true, raw = true })
	pending = nil
end)

return {
	setup = function(state, opts)
		state.state_file = STATE_FILE
		state.launch_cwd = os.getenv("PWD")
		state.restored = false

		ps.sub("cd", function()
			ya.async(function()
				ya.sleep(0.05)
				local ok, err = pcall(restore_prefs)
				if not ok then
					ya.err("persist-by-launch: restore_prefs failed: " .. tostring(err))
					return
				end
				ya.sleep(0.15)
				pcall(restore_cursor)
			end)
		end)
	end,

	entry = function(_, job)
		if job.args[1] == "save-and-quit" then
			local ok, err = pcall(save)
			if not ok then
				ya.err("persist-by-launch: save failed: " .. tostring(err))
			end
			ya.emit("quit", {})
		end
	end,
}
