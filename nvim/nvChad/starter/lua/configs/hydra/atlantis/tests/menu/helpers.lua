-- Helpers for Jump / Action menu column tests.

local jump_schema = require("configs.hydra.atlantis.schema.menu.jump")
local menu_schema = require("configs.hydra.atlantis.schema.actions.menu")

local M = {}

--- Keys declared on jump schema rows (single-char hotkeys).
function M.jump_schema_key_set()
  local set = {}
  for _, row in ipairs(jump_schema.items or {}) do
    if type(row.key) == "string" and row.key ~= "" then
      set[row.key] = true
    end
  end
  return set
end

--- Items from `anchor_ctx.jump_spec.items` with a hotkey (excludes separators / bare labels).
function M.jump_items_with_key(items)
  local out = {}
  for _, it in ipairs(items or {}) do
    if type(it) == "table" and type(it.key) == "string" and it.key ~= "" then
      out[#out + 1] = it
    end
  end
  return out
end

--- action_id -> label from render_spec.build output.
function M.action_ids_to_labels(render_spec)
  local map = {}
  for _, r in ipairs(render_spec.action_rows or {}) do
    if type(r) == "table" and type(r.action_id) == "string" then
      map[r.action_id] = r.label
    end
  end
  return map
end

--- Expected label string from schema actions.menu for an action_id.
function M.expected_menu_label(action_id)
  local spec = menu_schema.action_menu_item[action_id]
  if type(spec) == "table" and type(spec.label) == "string" then
    return spec.label
  end
  return nil
end

--- Extract quoted fragment from a jump label like `To prev sibling - "foo"`.
function M.quoted_fragment(label)
  if type(label) ~= "string" then
    return nil
  end
  local a, b = label:match('^(.-) %- "(.*)"$')
  if not b then
    return nil
  end
  return b
end

return M
