local generic = require("configs.hydra.atlantis.menu.nodes.generic")
local title_builder = require("configs.hydra.atlantis.menu.title")

local M = {}

-- Call menu builder
function M.build(node_info, parsed)
  local spec = generic.build(node_info, parsed)
  local text = (parsed and parsed.text) or (node_info and node_info.text) or "call"

  spec.title = title_builder.build({
    semantic_kind = "call",
    node_type = parsed and parsed.node_type,
    name = title_builder.truncate(vim.trim((text:match("^([^\n]+)") or text)), 50),
  })

  return spec
end

return M
