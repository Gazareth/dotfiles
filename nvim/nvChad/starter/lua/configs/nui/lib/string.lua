local M = {}

-- Return default when value is not a non-empty string.
function M.non_empty_or(value, default)
  if type(value) ~= "string" or value == "" then
    return default
  end

  return value
end

return M
