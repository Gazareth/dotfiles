local M = {}

M.title = " 󰌑 Jump"

M.group_labels = {
  file_nav = " 󰷏 File",
  parent_child = " ↥ Parent / Child",
  sibling = " ↔ Sibling",
  context = " ⇧ Context",
}

M.file_nav_scope = {
  label = "Top-level outline (by kind)...",
}

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
  { group = "file_nav", key = "n", icon = "󰅴", file_nav_scope = true },
  { group = "parent_child", key = "w", icon = "⬆", relation = "parent" },
  { group = "parent_child", key = "a", icon = "⬇", relation = "child" },
  { group = "sibling", key = "u", icon = "⬅", relation = "prev_sibling" },
  { group = "sibling", key = "i", icon = "➡", relation = "next_sibling" },
  { group = "context", key = "h", icon = "⬆", context = "higher" },
  { group = "context", key = "l", icon = "⬇", context = "lower" },
}

return M
