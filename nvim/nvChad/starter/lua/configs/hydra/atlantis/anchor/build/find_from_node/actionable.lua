local resolve_language_mapping = require("configs.hydra.atlantis.anchor.languages").resolve

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
    return true, semantic
  end
  return false, semantic
end

return M
