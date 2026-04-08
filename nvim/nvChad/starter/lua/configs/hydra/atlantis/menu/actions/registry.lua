local M = {}

-- Action row presentation map
M.action_menu_item = {
  change = {
    key = "c",
    icon = ">",
    label = "Change",
  },
  yank = {
    key = "y",
    icon = "=",
    label = "Yank",
  },
  select = {
    key = "v",
    icon = "=",
    label = "Select",
  },
  delete = {
    key = "d",
    icon = "x",
    label = "Delete",
  },
  inspect = {
    key = "i",
    icon = "?",
    label = "Inspect node mapping",
  },
  change_name = {
    key = "c",
    icon = ">",
    label = "Change name",
  },
  view_call_hierarchy = {
    key = "h",
    icon = ">",
    label = "View call hierarchy",
  },
  jump_to_lhs = {
    key = "h",
    icon = ">",
    label = "Left hand side",
  },
  jump_to_rhs = {
    key = "l",
    icon = ">",
    label = "Right hand side",
  },
}

-- Generic action order
M.generic_action_order = {
  "change",
  "yank",
  "select",
  "delete",
  "inspect",
}

return M
