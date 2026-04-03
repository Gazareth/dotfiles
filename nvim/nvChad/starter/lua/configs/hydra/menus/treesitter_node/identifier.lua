local generic = require("configs.hydra.menus.treesitter_node.generic")

local M = {}

function M.build(node_info, parsed)
  local spec = generic.build(node_info, parsed)
  local role = parsed.role or "identifier"
  spec.title = "󰌽 identifier: " .. role
  return spec
end

return M
