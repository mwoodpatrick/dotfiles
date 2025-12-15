-- [Wez's Terminal Emulator](https://wezterm.org/)
-- [wezterm wezterm](https://github.com/wezterm/wezterm)
--[How To Create An Amazing Terminal Setup With Wezterm](https://www.josean.com/posts/how-to-setup-wezterm-terminal)
local wezterm = require("wezterm")
local config = {} -- wezterm.config_builder()

-- Use config_builder if available for better error messages
-- if wezterm.config_builder then
--	config = wezterm.config_builder()
-- end

-- Set the default domain to your WSL distribution
-- config.default_domain = "WSL:Ubuntu"

-- Example of additional configurations

-- Explicitly request the application to draw its own menubar and title bar
-- config.window_decorations = "TITLE | MENUBAR"
-- RESIZE allows the OS to handle the border for resizing, often enabling movement
-- config.window_decorations = "RESIZE"

-- Alternatively, NONE might fix it if RESIZE doesn't
config.window_decorations = "NONE"

config.initial_cols = 120
config.initial_rows = 28
config.font_size = 10
config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.color_scheme = "AdventureTime"
-- Explicitly set a dark theme (or 'Breeze Light' for a light theme)
config.color_scheme = "Catppuccin Macchiato"

config.launch_menu = {
	{
		args = { "top" },
	},
	{
		-- Optional label to show in the launcher. If omitted, a label
		-- is derived from the `args`
		label = "Bash",
		-- The argument array to spawn.  If omitted the default program
		-- will be used as described in the documentation above
		args = { "bash", "-l" },

		-- You can specify an alternative current working directory;
		-- if you don't specify one then a default based on the OSC 7
		-- escape sequence will be used (see the Shell Integration
		-- docs), falling back to the home directory.
		-- cwd = "/some/path"

		-- You can override environment variables just for this command
		-- by setting this here.  It has the same semantics as the main
		-- set_environment_variables configuration option described above
		-- set_environment_variables = { FOO = "bar" },
	},
}

return config
