local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

config.automatically_reload_config = true

config.font_size = 14.0
config.font = wezterm.font('Moralerspace Argon JPDOC')

config.color_scheme = 'Night Owl (Gogh)'

config.use_ime = true

-- Launcher choices
local launcher_choices = {
 { label = "Neovim", command = "nvim", icon = "md_file_edit" },
 { label = "Lazygit", command = "lazygit", icon = "md_git" }
}

wezterm.on("augment-command-palette", function()
 local entries = {}
 for _, item in ipairs(launcher_choices) do
  table.insert(entries, {
   brief = "Launch: " .. item.label,
   icon = item.icon,
   action = spawn_overlay_pane(item.command),
  })
 end
 return entries
end)

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
  },
 -- Select a command via fuzzy finder and run it in an overlay pane
  {
    key = "l",
    mods = "SUPER",
    action = act.InputSelector({
    title = "Launcher",
    choices = (function()
        local choices = {}
        for _, item in ipairs(launcher_choices) do
        table.insert(choices, { label = item.label })
        end
        return choices
    end)(),
    action = wezterm.action_callback(function(window, pane, _id, label)
        if not label then
        return
        end
        for _, item in ipairs(launcher_choices) do
        if item.label == label then
        local new_pane = pane:split({
        direction = "Bottom",
        args = { os.getenv("SHELL"), "-ic", item.command },
        })
        window:perform_action(act.TogglePaneZoomState, new_pane)
        return
        end
        end
    end),
  }),
 },
}

config.use_fancy_tab_bar = false
config.status_update_interval = 1000

wezterm.on('update-right-status', function(window, pane)
  local date = wezterm.strftime('%Y-%m-%d %H:%M:%S')
  window:set_right_status(wezterm.format {
    { Text = date },
  })
end)

return config
