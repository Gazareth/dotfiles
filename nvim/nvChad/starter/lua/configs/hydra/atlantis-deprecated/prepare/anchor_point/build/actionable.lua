local resolve_language_mapping = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.languages").resolve

local M = {}

function M.resolve_options_from_config(config)
  return {
    safe_languages = config and config.safe_languages,
    languages = config and config.languages,
  }
end

--- Same rule as the vertical anchor candidate chain: language-mapped and actionable.
function M.check(node_info, resolve_options)
  local semantic = resolve_language_mapping(node_info, resolve_options)
  if semantic and semantic.actionable == true then
    if semantic.non_actionable_parent_types and node_info.node then
      local parent = node_info.node:parent()
      if parent and semantic.non_actionable_parent_types[parent:type()] then
        return false, semantic
      end
    end
    return true, semantic
  end
  return false, semantic
end

--- Type-name lookup against the schema: true when the node's type is marked container = true.
function M.is_container(node_info, resolve_options)
  local semantic = resolve_language_mapping(node_info, resolve_options)
  return semantic ~= nil and semantic.container == true
end

return M
