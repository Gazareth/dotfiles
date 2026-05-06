local make_hydra     = require("configs.hydra.lib.make_hydra")
local standard       = require("configs.hydra.atlantis_nouveau.menu.modes.standard")
local highlight_node = require("configs.hydra.atlantis_nouveau.menu.highlight_node")

local M = {}

local function menu_title(result)
  local node = result.node and result.node.node
  if node and node.type and node.name then
    return node.type .. ": " .. node.name
  end
  return result.node_type or "node"
end

function M.open(result)
  local on_exit = highlight_node.apply(result.bufnr, result.range)
  make_hydra.open({
    title    = menu_title(result),
    sections = standard.sections(result),
    on_exit  = on_exit,
  })
end

return M
