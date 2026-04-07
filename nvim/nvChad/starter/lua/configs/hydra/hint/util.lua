local M = {}

function M.str_width(text)
  local s = text or ""
  -- Hydra's hydra_hint syntax conceals unescaped _, ^, \ characters (conceallevel=3).
  -- Escaped sequences like \_ are rendered as the bare char (backslash concealed).
  -- Strip these the same way Hydra does so column widths stay accurate.
  local visible = s:gsub("\\([_^\\])", "%1"):gsub("[_^\\]", "")
  return vim.fn.strdisplaywidth(visible)
end

function M.pad_right(text, width)
  local value = text or ""
  local padding = width - M.str_width(value)
  if padding <= 0 then
    return value
  end
  return value .. string.rep(" ", padding)
end

-- Sanitize Hydra hint control characters
function M.escape_hint_text(text)
  local value = text or ""
  -- Keep hint parser safe by removing marker chars from dynamic labels
  return value:gsub("_", "-"):gsub("%^", ""):gsub("\\", "/")
end

return M
