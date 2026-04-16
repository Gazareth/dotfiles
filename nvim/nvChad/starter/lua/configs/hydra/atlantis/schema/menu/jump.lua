local column_titles = require("configs.hydra.atlantis.menu.column_titles")

local M = {}

M.title = column_titles.jump()

M.group_labels = {
  navigation = " 󰷏 Navigation",
  child = " ↥ Child",
  sibling = " ↔ Sibling",
  context = " ⇧ Context",
}

M.outline_scope = {
  label = "Top level...",
}

M.current_scope = {
  label = "Current scope...",
}

M.navigation_at_top_level_message = "🔚 Already at top level"

M.document_root_jump = {
  label_phrase = "Top",
  icon = "⇪",
}

M.relation_phrase = {
  parent = "To parent",
  child = "To child",
  prev_sibling = "To prev sibling",
  next_sibling = "To next sibling",
}

M.context_phrase = {
  higher = "To higher in context",
  lower = "To lower in context",
}

M.items = {
  { group = "navigation", key = "H", icon = "󰅴", outline_scope = true },
  { group = "navigation", key = "h", icon = "󰍎", current_scope = true },
  { group = "child", key = "a", icon = "⬇", relation = "child" },
  { group = "sibling", key = "u", icon = "⬅", relation = "prev_sibling" },
  { group = "sibling", key = "i", icon = "➡", relation = "next_sibling" },
  { group = "context", key = "w", icon = "⬆", context = "higher" },
  { group = "context", key = "l", icon = "⬇", context = "lower" },
}

return M
