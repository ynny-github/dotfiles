local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.automatically_reload_config = true

config.color_scheme = 'Night Owl (Gogh)'

config.use_ime = true

-- workspace settings
config.keys = {
  {
    mods = 'SUPER',
    key = 's',
    action = wezterm.action.ShowLauncherArgs { flags = 'WORKSPACES' , title = "Select workspace" },
  },
  {
    -- Rename workspace
    mods = 'SUPER',
    key = 'd',
    action = wezterm.action.PromptInputLine {
      description = '(wezterm) Set workspace title:',
      action = wezterm.action_callback(function(win,pane,line)
        if line then
          wezterm.mux.rename_workspace(
            wezterm.mux.get_active_workspace(),
            line
          )
        end
      end),
    },
  }
}

return config
