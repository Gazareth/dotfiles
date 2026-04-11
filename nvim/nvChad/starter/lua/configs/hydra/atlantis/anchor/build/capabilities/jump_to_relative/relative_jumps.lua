-- Resolve parent/child/sibling targets once and compute hint labels (same pipeline as menu_labels).
local menu_labels = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.menu_labels")
local probe = require("configs.hydra.atlantis.anchor.probe")
local targets = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.targets")

local M = {}

local function relation_set_from_schema(items)
  local rels = {}
  for _, row in ipairs(items or {}) do
    if type(row.relation) == "string" then
      rels[row.relation] = true
    end
  end
  return rels
end

--- @return table<string, { target: table|nil, quoted: string|nil }>
function M.labeled(anchor_node_info, jump_items)
  local out = {}
  for rel in pairs(relation_set_from_schema(jump_items)) do
    local target = targets.resolve(anchor_node_info, rel)
    if target then
      local parsed = probe.parse(target)
      out[rel] = {
        target = target,
        quoted = menu_labels.quoted_target(target, parsed),
      }
    else
      out[rel] = { target = nil, quoted = nil }
    end
  end
  return out
end

return M
