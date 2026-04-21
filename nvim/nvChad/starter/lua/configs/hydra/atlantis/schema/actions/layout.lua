local supported_nodes = require("configs.hydra.atlantis.anchor.probe.treesitter.constants").supported_nodes

local M = {}

--- Which Action column bucket an action belongs in ("common" = any anchor; "specific" = under kind subheading).
M.action_role = {
  rename = "common",
  change = "common",
  yank = "common",
  select = "common",
  delete = "common",
  inspect = "common",
  -- specific
  view_call_hierarchy = "specific",
  jump_lhs = "specific",
  jump_rhs = "specific",
  jump_to_body = "specific",
  jump_to_parameter = "specific",
  jump_to_return = "specific",
  jump_to_child = "specific",
  rescope = "specific",
  jump_function_header = "specific",
  jump_prev_parameter = "specific",
  jump_next_parameter = "specific",
  jump_to_parent_signature = "specific",
  jump_to_enclosing_function = "specific",
}

--- Shown on the main Interact column for common actions.
M.common_primary_order = {
  "rename",
  "select",
}

--- Remaining common actions (overflow Hydra).
M.common_overflow_order = {
  "change",
  "yank",
  "delete",
  "inspect",
}

--- Ordering for anchor-specific action names (intersect with enabled set).
M.specific_action_order = {
  "rescope",
  "jump_lhs",
  "jump_rhs",
  "jump_to_body",
  "jump_to_parameter",
  "jump_to_return",
  "jump_to_child",
  "view_call_hierarchy",
  "jump_function_header",
  "jump_prev_parameter",
  "jump_next_parameter",
  "jump_to_parent_signature",
  "jump_to_enclosing_function",
}

M.action_common_heading = "Common"
M.action_overflow_row_label = "More common actions"
M.action_overflow_picker_title = " More common"
M.action_overflow_menu_key = "."

--- Human title for the node-specific subheading (under Interact).
M.specific_section_title_by_anchor_kind = {
  [supported_nodes.generic] = "Node",
  [supported_nodes.identifier] = "Identifier",
  [supported_nodes.assignment] = "Assignment",
  [supported_nodes.fn] = "Function",
  [supported_nodes.parameter] = "Parameter",
  [supported_nodes.binary_expression] = "Binary expression",
  [supported_nodes.body] = "Body",
  [supported_nodes.return_stmt] = "Return",
}

function M.specific_title_for_anchor_kind(anchor_kind)
  if type(anchor_kind) ~= "string" then
    return "Node"
  end
  return M.specific_section_title_by_anchor_kind[anchor_kind] or "Node"
end

return M
