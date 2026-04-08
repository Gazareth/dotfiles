local generic = require("configs.hydra.atlantis.menu.nodes.generic")
local title_builder = require("configs.hydra.atlantis.menu.title")

local M = {}

function M.build(node_info, parsed)
  local spec = generic.build(node_info, parsed)
  local role = parsed.role or "identifier"
  spec.title = title_builder.build({
    semantic_kind = "identifier",
    node_type     = parsed and parsed.node_type,
    name          = role,
  })
  return spec
end

return M
