local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.color_scheme = 'AdventureTime'
config.font = wezterm.font 'UDEV Gothic JPDOC'

return config
