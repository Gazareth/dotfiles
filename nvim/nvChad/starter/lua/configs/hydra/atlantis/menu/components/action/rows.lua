local node_actions = require("configs.hydra.atlantis.anchor.actions")
local action_schema = require("configs.hydra.atlantis.schema.actions")

local M = {}

local function build_row(anchor_type, action_name, opts)
  if type(anchor_type) ~= "string" or type(action_name) ~= "string" then
    return nil
  end

  local presentation = action_schema.action_menu_item[action_name]
  if type(presentation) ~= "table" then
    return nil
  end

  local ctx = type(opts) == "table" and opts.ctx or nil

  local action = node_actions.build(anchor_type, action_name, ctx)
  if type(action) ~= "function" then
    return nil
  end

  local key = (type(opts) == "table" and type(opts.key) == "string" and opts.key) or presentation.key
  local icon = (type(opts) == "table" and type(opts.icon) == "string" and opts.icon) or presentation.icon
  local label = presentation.label
  local label_builder = type(opts) == "table" and opts.label_builder or nil
  local label_suffix = type(opts) == "table" and type(opts.label) == "string" and opts.label or nil

  if type(label_builder) == "function" then
    label = label_builder(label, action_name)
  elseif type(label_suffix) == "string" and label_suffix ~= "" then
    label = label .. " " .. label_suffix
  end

  local row = {
    key = key,
    icon = icon,
    label = label,
    action_id = action_name,
    action = action,
  }
  if type(presentation._reopen_atlantis) == "number" then
    row._reopen_atlantis = presentation._reopen_atlantis
  end
  return row
end

function M.build_rows(anchor_type, action_names, opts)
  local rows = {}
  if type(action_names) ~= "table" then
    return rows
  end

  for _, action_name in ipairs(action_names) do
    local row_opts = {
      ctx = type(opts) == "table" and opts.ctx or nil,
      label = type(opts) == "table" and opts.label or nil,
      label_builder = type(opts) == "table" and opts.label_builder or nil,
    }

    if type(opts) == "table" then
      local key_overrides = opts.key_overrides
      if type(key_overrides) == "table" and type(key_overrides[action_name]) == "string" then
        row_opts.key = key_overrides[action_name]
      end

      local icon_overrides = opts.icon_overrides
      if type(icon_overrides) == "table" and type(icon_overrides[action_name]) == "string" then
        row_opts.icon = icon_overrides[action_name]
      end

      local label_overrides = opts.label_overrides
      local label_override = type(label_overrides) == "table" and label_overrides[action_name] or nil
      if type(label_override) == "string" then
        row_opts.label_builder = function()
          return label_override
        end
      elseif type(label_override) == "function" then
        row_opts.label_builder = label_override
      end
    end

    local row = build_row(anchor_type, action_name, row_opts)
    if type(row) == "table" then
      rows[#rows + 1] = row
    end
  end

  return rows
end

return M
