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
		session.tabs[i] = {
			cwd = tostring(tab.current.cwd),
			cursor = nil,
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

return {
	setup = function(state, opts)
		state.state_file = STATE_FILE
		state.launch_cwd = os.getenv("PWD")
		state.restored = false
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
