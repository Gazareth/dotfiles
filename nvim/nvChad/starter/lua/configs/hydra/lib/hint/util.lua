local M = {}

-- Hydra hint syntax uses ASCII `_` around keys (_k_). Use fullwidth low line (U+FF3F) for literal underscores in labels.
local HINT_UNDERSCORE = vim.fn.nr2char(0xff3f)

function M.str_width(text)
  local s = text or ""
  -- Hint text uses fullwidth ＿ (U+FF3F) instead of ASCII _ so Hydra’s _key_ markup is not triggered.
  -- After unescaping \-pairs, drop ^ and stray \ for width.
  local visible = s:gsub("\\([_^\\])", "%1"):gsub("[%^\\]", "")
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

-- Sanitize Hydra hint control characters (dynamic labels from menus, etc.)
function M.escape_hint_text(text)
  local value = text or ""
  value = value:gsub("\\", "/")
  value = value:gsub("%^", "")
  value = value:gsub("_", HINT_UNDERSCORE)
  return value
end

return M
