local generic = require("configs.hydra.atlantis.menu.nodes.generic")
local title_builder = require("configs.hydra.atlantis.menu.title")

local M = {}

-- Condition menu builder
function M.build(node_info, parsed)
  local spec = generic.build(node_info, parsed)
  local condition_name = title_builder.extract_if_name((parsed and parsed.text) or (node_info and node_info.text))

  spec.title = title_builder.build({
    semantic_kind = "control_frame",
    node_type = parsed and parsed.node_type,
    name = condition_name,
  })

  return spec
end

return M
