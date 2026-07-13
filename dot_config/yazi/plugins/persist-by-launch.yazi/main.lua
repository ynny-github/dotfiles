-- ~/.config/yazi/plugins/persist-by-launch.yazi/main.lua
-- Persist yazi session state keyed by the launch cwd (parent shell's $PWD).

local STATE_FILE = os.getenv("HOME") .. "/.local/state/yazi/persist-by-launch.json"

local get_launch_cwd = ya.sync(function()
	return tostring(cx.tabs[1].current.cwd)
end)

return {
	setup = function(state, opts)
		state.state_file = STATE_FILE
		state.launch_cwd = get_launch_cwd()
		state.restored = false
		ya.dbg("persist-by-launch: launch_cwd=" .. tostring(state.launch_cwd))
	end,

	entry = function(state, job)
		local action = job.args[1]
		if action == "save-and-quit" then
			ya.emit("quit", {})
		end
	end,
}
