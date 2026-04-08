local node_actions = require("configs.hydra.atlantis.registry.node_actions")

local M = {}

-- Node capability map
local function build_capabilities(parsed)
  if type(parsed) ~= "table" then
    return {}
  end

  local allowed_action_ids = node_actions.get_allowed_action_ids(parsed.node_kind)
  if type(allowed_action_ids) ~= "table" then
    return {}
  end

  return allowed_action_ids
end

-- Node child summary
local function build_children_summary(parsed)
  local targets = type(parsed) == "table" and parsed.targets or nil
  if type(targets) ~= "table" then
    return {}
  end

  return {
    parameters = type(targets.parameters) == "table" and #targets.parameters or 0,
    nested_functions = type(targets.nested_functions) == "table" and #targets.nested_functions or 0,
    assignments = type(targets.assignments) == "table" and #targets.assignments or 0,
  }
end

-- Node descriptor normalization
function M.normalize_node_descriptor(node_info, parsed)
  return {
    node_kind = parsed and parsed.node_kind,
    text = (parsed and parsed.text) or (node_info and node_info.text) or "",
    range = {
      start_row = node_info and node_info.start_row,
      start_col = node_info and node_info.start_col,
      end_row = node_info and node_info.end_row,
      end_col = node_info and node_info.end_col,
    },
    parent_kind = (parsed and parsed.semantic and parsed.semantic.parent_node_type) or (node_info and node_info.parent_type),
    scope = {
      language = parsed and parsed.semantic and parsed.semantic.language,
      node_tier = parsed and parsed.node_tier,
      semantic_kind = parsed and parsed.semantic_kind,
    },
    capabilities = build_capabilities(parsed),
    children_summary = build_children_summary(parsed),
  }
end

return M
