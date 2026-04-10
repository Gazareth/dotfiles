local M = {}

-- Build semantic resolver options from active tree-sitter config
function M.build_resolve_options(config)
  return {
    safe_languages = config.safe_languages,
    languages = config.languages,
  }
end

-- Parse depth mode token like depth_0 into numeric depth
function M.parse_depth_mode(mode)
  if type(mode) ~= "string" then
    return nil
  end

  local value = mode:match("^depth_(%d+)$")
  if not value then
    return nil
  end

  return tonumber(value)
end

return M
