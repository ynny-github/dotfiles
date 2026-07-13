-- ~/.config/yazi/plugins/persist-by-launch.yazi/main.lua
-- Persist yazi session state keyed by the launch cwd (parent shell's $PWD).

local STATE_FILE = os.getenv("HOME") .. "/.local/state/yazi/persist-by-launch.json"

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

local save = ya.sync(function(state)
	if not state.launch_cwd then
		return
	end
	local tabs = cx.tabs
	local session = {
		active = tabs.idx,
		tabs = {},
	}
	for i, tab in ipairs(tabs) do
		local hovered = tab.current.hovered
		local cursor_name = nil
		if hovered then
			cursor_name = tostring(hovered.url):match("([^/]+)$")
		end
		session.tabs[i] = {
			cwd = tostring(tab.current.cwd),
			cursor = cursor_name,
			selected = {},
			sort = {
				by = tab.pref.sort_by,
				reverse = tab.pref.sort_reverse,
				dir_first = tab.pref.sort_dir_first,
				sensitive = tab.pref.sort_sensitive,
				translit = tab.pref.sort_translit,
			},
			linemode = tab.pref.linemode,
			show_hidden = tab.pref.show_hidden,
		}
	end
	local all = read_all(state.state_file)
	all[state.launch_cwd] = session
	write_all(state.state_file, all)
	ya.dbg("persist-by-launch: saved " .. state.launch_cwd)
end)

local pending_tab_data = nil

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
	if type(entry) ~= "table" or type(entry.tabs) ~= "table" or #entry.tabs == 0 then
		return
	end
	local tab_data = entry.tabs[1]
	ya.emit("cd", { tab_data.cwd })
	if type(tab_data.sort) == "table" then
		ya.emit("sort", tab_data.sort)
	end
	if tab_data.linemode then
		ya.emit("linemode", { tab_data.linemode })
	end
	if tab_data.show_hidden ~= nil then
		ya.emit("hidden", { tab_data.show_hidden and "show" or "hide" })
	end
	pending_tab_data = tab_data
	ya.dbg("persist-by-launch: restored " .. state.launch_cwd)
end)

local restore_cursor = ya.sync(function()
	if not pending_tab_data or not pending_tab_data.cursor then
		return
	end
	local target = pending_tab_data.cwd .. "/" .. pending_tab_data.cursor
	ya.emit("reveal", { target, no_dummy = true, raw = true })
	pending_tab_data = nil
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
