local hint_util = require("configs.hydra.lib.hint.util")

local hint_title = {}

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

-- Title header lines (optional centered kicker above the main title)
function hint_title.build_title_lines(title, total_width, hint_opts)
  hint_opts = type(hint_opts) == "table" and hint_opts or {}
  local kicker_raw = hint_opts.title_kicker
  local kicker = type(kicker_raw) == "string" and kicker_raw ~= "" and hint_util.escape_hint_text(kicker_raw) or ""

  local formatted_title = format_title(title or "")
  local safe_title = hint_util.escape_hint_text(formatted_title)

  local lines = {}
  if kicker ~= "" then
    local kw = hint_util.str_width(kicker)
    local available_k = math.max(total_width, kw)
    local k_left = math.max(0, math.floor((available_k - kw) / 2))
    lines[#lines + 1] = string.rep(" ", k_left) .. kicker
    if safe_title ~= "" then
      lines[#lines + 1] = ""
    end
  end

  if safe_title == "" then
    return lines
  end

  local available_width = math.max(total_width, hint_util.str_width(safe_title))
  if kicker ~= "" then
    for i = 1, #lines - 1 do
      local w = hint_util.str_width(lines[i])
      available_width = math.max(available_width, w)
    end
  end
  local left = math.max(0, math.floor((available_width - hint_util.str_width(safe_title)) / 2))
  local padded_title = string.rep(" ", left) .. safe_title

  lines[#lines + 1] = padded_title
  lines[#lines + 1] = string.rep("=", available_width)
  return lines
end

return hint_title
