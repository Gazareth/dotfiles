local g = vim.g

local make_font_cfg = function(font_size)
  return { "FiraCode Nerd Font,Symbols Nerd Font:h"..font_size..":#e-subpixelantialias:#h-none" }
end
-- vim.opt.guicursor = ""
g.neovide_font_size = 10
vim.opt.guifont = make_font_cfg(g.neovide_font_size)
g.neovide_line_scale_delta = 0.5

g.neovide_cursor_vfx_mode = "wireframe"

g.neovide_refresh_rate = vim.g.refresh_rate or 60

g.neovide_scroll_animation_length = 0.375

g.neovide_hide_mouse_when_typing = true

vim.opt.title = true
vim.opt.titlestring = "Neovide"

-- vim.g.neovide_opacity = 0.95
vim.g.neovide_normal_opacity = 0.975

-- This option is currently faulty
-- g.neovide_remember_window_size = true

-- Increase/Decrease font size
local function change_font(is_increase)
  local increment = 1
  if not is_increase then
    increment = -1
  end
  g.neovide_font_size = g.neovide_font_size + increment
  -- print("<Neovide> Font size set to "..g.neovide_font_size)
  vim.opt.guifont = make_font_cfg(g.neovide_font_size)
end

vim.keymap.set("n", "<C-]>", function()
  change_font(true)
end)

vim.keymap.set("n", "<C-[>", function()
  change_font(false)
end)

vim.keymap.set("n", "<F11>", function()
  if (g.neovide_fullscreen == true) then
    g.neovide_fullscreen = false
  else
    g.neovide_fullscreen = true
  end
end
)

