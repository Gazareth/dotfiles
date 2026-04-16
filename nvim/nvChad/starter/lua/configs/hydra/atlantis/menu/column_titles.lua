-- Single source for Hydra hint column titles (jump / swap / action / outline window).
local M = {}

function M.hydra_default()
  return "Atlantis"
end

function M.jump()
  return " 󰌑 Jump"
end

function M.swap()
  return " ⇅ Swap"
end

function M.action()
  return " ✦ Action"
end

function M.navigate()
  return " ✦ Navigate"
end

--- Floating Hydra title when container/outline mode is active.
function M.outline_window()
  return " 󰷏 Outline"
end

return M
