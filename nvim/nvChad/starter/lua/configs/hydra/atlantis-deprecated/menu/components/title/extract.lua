-- Text extraction helpers that pull name snippets from raw node source
local M = {}

-- Truncate long title fragments for compact menus
function M.truncate(text, max_len)
  max_len = max_len or 40
  if not text or text == "" then
    return ""
  end
  if #text <= max_len then
    return text
  end
  return text:sub(1, max_len) .. "..."
end

-- Extract first comment content for title name preview
function M.extract_comment_name(raw_text)
  if not raw_text then
    return nil, nil
  end

  local block = raw_text:match("^%-%-%[%[(.-)%]%]$")
  if block then
    local content = vim.trim(block:match("^[^\n]+") or block)
    return M.truncate(content, 24), #content
  end

  local line = raw_text:match("^%-%-+%s*(.+)")
  if line then
    local content = vim.trim(line)
    return M.truncate(content, 24), #content
  end

  local fallback = vim.trim(raw_text)
  return M.truncate(fallback, 24), #fallback
end

-- Extract loop iterator or clause snippet for loop titles
function M.extract_for_name(raw_text)
  if not raw_text then
    return nil
  end

  local iterator = raw_text:match("[Ff][Oo][Rr]%s+.-%s+[Ii][Nn]%s+(.-)%s+[Dd][Oo]")
  if iterator then
    return M.truncate(vim.trim(iterator), 40)
  end

  local numeric = raw_text:match("[Ff][Oo][Rr]%s+(.-)%s+[Dd][Oo]")
  if numeric then
    return M.truncate(vim.trim(numeric), 40)
  end

  return nil
end

-- Extract if-condition snippet for branch titles
function M.extract_if_name(raw_text)
  if not raw_text then
    return nil
  end

  local condition = raw_text:match("[Ii][Ff]%s+(.-)%s+[Tt][Hh][Ee][Nn]")
  if condition then
    return M.truncate(vim.trim(condition), 40)
  end

  return nil
end

-- Extract assignment target name for assignment titles
function M.extract_assignment_name(raw_text)
  if not raw_text then
    return nil
  end

  local local_name = raw_text:match("^%s*[Ll][Oo][Cc][Aa][Ll]%s+([%w_]+)")
  if local_name then
    return local_name
  end

  local plain_name = raw_text:match("^%s*([%w_][%w_.:]*[%w_]?)%s*=")
  if plain_name then
    return plain_name
  end

  return nil
end

return M
