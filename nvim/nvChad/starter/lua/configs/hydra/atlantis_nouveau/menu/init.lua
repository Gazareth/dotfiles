local make_hydra = require("configs.hydra.lib.make_hydra")
local standard   = require("configs.hydra.atlantis_nouveau.menu.modes.standard")

local M = {}

local function menu_title(result)
  local node = result.variant and result.variant.node
  if node and node.type and node.name then
    return node.type .. ": " .. node.name
  end
  return result.node_type or "node"
end

function M.open(result, all_results)
  make_hydra.open({
    title    = menu_title(result),
    sections = standard.sections(result, all_results),
  })
end

return M
