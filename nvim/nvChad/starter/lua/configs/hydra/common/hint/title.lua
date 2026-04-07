local util = require("configs.hydra.common.hint.util")

local M = {}

-- Title role-name formatter
local function format_title(title)
  if not title or title == "" then
    return title
  end

  -- Parse title candidate
  local function parse_candidate(candidate)
    local quoted_type, quoted_name = candidate:match('^(.-)%s+"([^"]+)"$')
    if quoted_type and quoted_name then
      return vim.trim(quoted_type), quoted_name
    end

    local colon_type, colon_name = candidate:match('^([^:]+):%s*(.+)$')
    if colon_type and colon_name then
      return vim.trim(colon_type), vim.trim(colon_name)
    end

    return nil, nil
  end

  local role, name = parse_candidate(title)
  if role and name then
    return "[" .. role .. "] " .. name
  end

  -- Icon-prefix fallback parse
  local first_token, rest = title:match("^(%S+)%s+(.+)$")
  if first_token and rest and first_token:match("[^%w_]") then
    role, name = parse_candidate(rest)
    if role and name then
      return "[" .. role .. "] " .. name
    end
  end

  return title
end

-- Main title lines
function M.build_title_lines(title, total_width)
  local formatted_title = format_title(title or "")
  local safe_title = util.escape_hint_text(formatted_title)
  if safe_title == "" then
    return {}
  end

  local available_width = math.max(total_width, util.str_width(safe_title))
  local left = math.max(0, math.floor((available_width - util.str_width(safe_title)) / 2))
  local padded_title = string.rep(" ", left) .. safe_title

  return {
    padded_title,
    string.rep("=", available_width),
    "",
  }
end

return M
