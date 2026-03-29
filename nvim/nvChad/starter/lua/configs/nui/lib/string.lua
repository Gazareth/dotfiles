local M = {}

-- Return default when value is not a non-empty string.
function M.non_empty_or(value, default)
  if type(value) ~= "string" or value == "" then
    return default
  end

  return value
end

-- Return a lowercased non-empty string or default.
function M.to_lower(value, default)
  local text = M.non_empty_or(value, default)
  if type(text) ~= "string" then
    return text
  end

  return text:lower()
end

-- Return display width for text, accounting for multibyte characters.
function M.display_width(value)
  return vim.fn.strdisplaywidth(value or "")
end

return M
