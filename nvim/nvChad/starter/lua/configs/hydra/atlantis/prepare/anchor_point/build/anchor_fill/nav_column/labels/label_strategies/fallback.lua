-- Generic node text: probe short_label, then scrub + condense (always returns a non-empty string).
local condense = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.labels.condense")
local text = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.labels.text")
local short_label = require("configs.hydra.atlantis.prepare.anchor_point.probe.short_label")

local M = {}

function M.try(parsed, node_info)
  local raw = short_label.preferred_text(node_info)
  if type(raw) ~= "string" or raw == "" then
    raw = type(parsed) == "table" and parsed.text or nil
  end
  if type(raw) ~= "string" or raw == "" then
    raw = node_info and node_info.text or ""
  end

  local node_type = type(parsed) == "table" and parsed.node_type or (node_info and node_info.node_type) or nil
  local scrubbed = text.scrub_preview_text(raw, parsed, node_type)
  scrubbed = condense.condense_to_jump_name(scrubbed, node_type)
  if type(scrubbed) == "string" and scrubbed ~= "" then
    return scrubbed
  end
  return type(parsed) == "table" and tostring(parsed.display_name or parsed.node_type or "node") or "node"
end

return M
