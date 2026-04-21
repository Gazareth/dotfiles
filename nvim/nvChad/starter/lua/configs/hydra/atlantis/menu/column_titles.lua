local M = {}

function M.hydra_default()
  return "Atlantis"
end

function M.navigate()
  return " 󰌑 Navigate"
end

function M.interact()
  return " ✦ Interact"
end

function M.create()
  return " 󰄬 Create"
end

--- Floating Hydra title when container/outline mode is active.
function M.outline_window()
  return " 󰷏 Outline"
end

return M
