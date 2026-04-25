local column_titles = require("configs.hydra.atlantis.menu.column_titles")

local M = {}

M.title = column_titles.navigate()

M.group_labels = {
  nav_context = " … Nav context",
  sibling = " ↔ Sibling",
}

--- Labels for the Navigate column rows that switch outline / anchor chain scope (H, h, w).
M.nav_context = {
  to_top_level = "To top level",
  current_scope = "Current scope...",
  already_at_top_level = "Already at top level",
  higher_in_chain = "To higher in context",
}

M.document_root_jump = {
  label_phrase = "Top",
  icon = "⇪",
}

M.relation_phrase = {
  parent        = "To parent",
  child         = "To child",
  prev_sibling  = "To prev sibling",
  next_sibling  = "To next sibling",
  first_sibling = "To first sibling",
  last_sibling  = "To last sibling",
}

M.next_highest = {
  key = "h",
  icon = "⤴",
  label_phrase = "To next highest",
}

M.items = {
  { group = "nav_context", key = "H", icon = "󰅴", outline_scope = true },
  { group = "nav_context", key = "l", icon = "󰍎", current_scope = true },
  { group = "child",   key = "a", icon = "⬇", relation = "child" },
  { group = "sibling", key = "u", icon = "⬅", relation = "prev_sibling" },
  { group = "sibling", key = "u", icon = "⏭", relation = "last_sibling",  fallback_for = "prev_sibling" },
  { group = "sibling", key = "i", icon = "➡", relation = "next_sibling" },
  { group = "sibling", key = "i", icon = "⏮", relation = "first_sibling", fallback_for = "next_sibling" },
  { group = "nav_context", key = "w", icon = "⬆", context = "higher" },
}

return M
