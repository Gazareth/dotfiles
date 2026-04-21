local text = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.labels.text")

local M = {}

local IDENTIFIER_NODE_TYPES = {
  identifier = true,
  property_identifier = true,
  field_identifier = true,
  type_identifier = true,
  ["shorthand_property_identifier"] = true,
}

function M.condense_to_jump_name(text_in, node_type)
  if type(text_in) ~= "string" or text_in == "" then
    return text_in
  end
  local t = vim.trim(text_in)
  if node_type and IDENTIFIER_NODE_TYPES[node_type] then
    return t
  end
  if t:match("^[%a_][%w_]*$") then
    return t
  end
  local assign_lhs = text.lhs_identifier_from_assignment_line(t)
  if assign_lhs then
    return assign_lhs
  end
  local callish = t:match("^([%a_][%w_.]*)%s*%(")
  if callish then
    local tail = callish:match("([%a_][%w_]*)$")
    return tail or callish
  end
  return t
end

return M
