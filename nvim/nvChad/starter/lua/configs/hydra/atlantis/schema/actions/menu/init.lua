local M = {}

M.action_menu_item = {
  rename = {
    key = "r",
    icon = ">",
    label = "Rename",
    --- After LSP rename, reopen with cursor snapped to outer anchor (see atlantis init reopen_seed).
    _atlantis_snap_reopen = true,
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
    key = "o",
    icon = "?",
    label = "Inspect node mapping",
  },
  view_call_hierarchy = {
    key = "g",
    icon = ">",
    label = "View call hierarchy",
  },
  jump_lhs = {
    key = "z",
    icon = ">",
    label = "Left hand side",
  },
  jump_rhs = {
    key = "x",
    icon = ">",
    label = "Right hand side",
  },
  jump_to_body = {
    key = "b",
    icon = ">",
    label = "Jump to body",
    _reopen_atlantis = 1,
  },
  jump_to_parameter = {
    key = "p",
    icon = ">",
    label = "Jump to parameter",
    _reopen_atlantis = 1,
  },
  jump_to_return = {
    key = "u",
    icon = ">",
    label = "Jump to return",
    _reopen_atlantis = 1,
  },
  jump_to_child = {
    key = "k",
    icon = ">",
    label = "Jump to child…",
    _reopen_atlantis = 0,
  },
  rescope = {
    key = ",",
    icon = ">",
    label = "Re-scope",
    -- Close menu and do not reopen; avoids Hydra key leakage into other UIs.
    _reopen_atlantis = -1,
  },
  jump_function_header = {
    key = "h",
    icon = ">",
    label = "Jump to function header",
    _reopen_atlantis = 1,
  },
  jump_prev_parameter = {
    key = "[",
    icon = ">",
    label = "Previous parameter",
    _reopen_atlantis = 1,
  },
  jump_next_parameter = {
    key = "]",
    icon = ">",
    label = "Next parameter",
    _reopen_atlantis = 1,
  },
  jump_to_parent_signature = {
    key = "h",
    icon = ">",
    label = "Jump to parent signature",
    _reopen_atlantis = 1,
  },
  jump_to_enclosing_function = {
    key = "h",
    icon = ">",
    label = "Jump to enclosing function",
    _reopen_atlantis = 1,
  },
}

M.default_action_order = {
  "rename",
  "change",
  "yank",
  "select",
  "delete",
  "inspect",
}

return M
