-- Notify users about semantic parser status in plain messages
local M = {}

-- Format cursor row and column for semantic status messages
local function format_cursor(cursor)
  if type(cursor) ~= "table" then
    return "?:?"
  end

  return tostring(cursor.row or "?") .. ":" .. tostring(cursor.col or "?")
end

-- Notify user when a node is unrecognized or the language is unsupported
-- Return semantic build status payload from parsed result
function M.get(parsed)
  local semantic = parsed and parsed.semantic
  if type(semantic) ~= "table" then
    return nil
  end

  return semantic
end

-- Notify user when semantic build status needs attention
function M.notify(parsed)
  local semantic = M.get(parsed)
  if not semantic then
    return
  end

  if semantic.status == "unknown-node" then
    vim.notify(table.concat({
      "Atlantis does not recognize this node.",
      "node=" .. tostring(semantic.raw_node_type),
      "language=" .. tostring(semantic.language),
      "cursor=" .. format_cursor(semantic.cursor),
      "parent=" .. tostring(semantic.parent_node_type),
      "named=" .. tostring(semantic.named),
    }, " "), vim.log.levels.INFO)
    return
  end

  if semantic.status == "unsupported-language" then
    vim.notify(table.concat({
      "Atlantis language support is disabled for this buffer.",
      "language=" .. tostring(semantic.language),
      "node=" .. tostring(semantic.raw_node_type),
      "cursor=" .. format_cursor(semantic.cursor),
    }, " "), vim.log.levels.WARN)
  end
end

return M
