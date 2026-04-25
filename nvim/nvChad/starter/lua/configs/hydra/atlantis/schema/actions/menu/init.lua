local schema_constants = require("configs.hydra.atlantis.schema.constants")
local reopen = schema_constants.reopen

local M = {}

M.action_menu_item = {
  rename = {
    key = "r",
    icon = ">",
    label = "Rename",
    snap_to_anchor = true,
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
    reopen_depth_delta = reopen.deeper,
  },
  jump_to_parameter = {
    key = "p",
    icon = ">",
    label = "Jump to parameter",
    reopen_depth_delta = reopen.deeper,
  },
  jump_to_return = {
    key = "u",
    icon = ">",
    label = "Jump to return",
    reopen_depth_delta = reopen.deeper,
  },
  jump_to_child = {
    key = "k",
    icon = ">",
    label = "Jump to child…",
    reopen_depth_delta = reopen.same,
  },
  rescope = {
    key = ",",
    icon = ">",
    label = "Re-scope",
    -- Close menu and do not reopen; avoids Hydra key leakage into other UIs.
    reopen_depth_delta = reopen.close,
  },
  jump_function_header = {
    key = "j",
    icon = ">",
    label = "Jump to function header",
    reopen_depth_delta = reopen.deeper,
  },
  jump_prev_parameter = {
    key = "[",
    icon = ">",
    label = "Previous parameter",
    reopen_depth_delta = reopen.deeper,
  },
  jump_next_parameter = {
    key = "]",
    icon = ">",
    label = "Next parameter",
    reopen_depth_delta = reopen.deeper,
  },
  jump_to_parent_signature = {
    key = "j",
    icon = ">",
    label = "Jump to parent signature",
    reopen_depth_delta = reopen.deeper,
  },
  jump_to_enclosing_function = {
    key = "j",
    icon = ">",
    label = "Jump to enclosing function",
    reopen_depth_delta = reopen.deeper,
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
