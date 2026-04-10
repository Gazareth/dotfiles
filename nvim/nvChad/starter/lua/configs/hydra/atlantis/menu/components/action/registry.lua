local M = {}

-- Action row presentation map
M.action_menu_item = {
  rename = {
    key = "r",
    icon = ">",
    label = "Rename",
  },
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
  view_call_hierarchy = {
    key = "h",
    icon = ">",
    label = "View call hierarchy",
  },
  jump_lhs = {
    key = "h",
    icon = ">",
    label = "Left hand side",
  },
  jump_rhs = {
    key = "l",
    icon = ">",
    label = "Right hand side",
  },
  jump_to_body = {
    key = "b",
    icon = ">",
    label = "Jump to body",
  },
  jump_to_parameter = {
    key = "p",
    icon = ">",
    label = "Jump to parameter",
  },
}

-- Generic action order
M.generic_action_order = {
  "rename",
  "change",
  "yank",
  "select",
  "delete",
  "inspect",
}

return M
