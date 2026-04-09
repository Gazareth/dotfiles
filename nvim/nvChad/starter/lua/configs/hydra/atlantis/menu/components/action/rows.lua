local node_actions = require("configs.hydra.atlantis.registry.node_actions")
local action_registry = require("configs.hydra.atlantis.menu.components.action.registry")

local M = {}

-- Action label formatter
local function format_label(action_name, label, opts)
  local label_override = type(opts) == "table" and type(opts.label) == "string" and opts.label or nil
  local label_builder = type(opts) == "table" and opts.label_builder or nil

  if type(label_builder) == "function" then
    return label_builder(label, action_name)
  end

  if type(label_override) == "string" and label_override ~= "" then
    return label .. " " .. label_override
  end

  return label
end

-- Single action row builder
function M.build_row(anchor_type, action_name, opts)
  if type(anchor_type) ~= "string" or type(action_name) ~= "string" then
    return nil
  end

  local presentation = action_registry.action_menu_item[action_name]
  if type(presentation) ~= "table" then
    return nil
  end

  local ctx = type(opts) == "table" and opts.ctx or nil
  local capabilities = type(opts) == "table" and opts.capabilities or nil

  -- Capability lookup action resolver
  local action = nil
  if type(capabilities) == "table"
    and type(capabilities.lookup) == "table"
    and type(capabilities.lookup[action_name]) == "function" then
    action = capabilities.lookup[action_name]
  else
    action = node_actions.build(anchor_type, action_name, ctx)
  end
  if type(action) ~= "function" then
    return nil
  end

  local key = (type(opts) == "table" and type(opts.key) == "string" and opts.key) or presentation.key
  local icon = (type(opts) == "table" and type(opts.icon) == "string" and opts.icon) or presentation.icon

  return {
    key = key,
    icon = icon,
    label = format_label(action_name, presentation.label, opts),
    action_id = node_actions.action_id_by_name[action_name],
    action = action,
  }
end

-- Multi action row builder
function M.build_rows(anchor_type, action_names, opts)
  local rows = {}
  if type(action_names) ~= "table" then
    return rows
  end

  for _, action_name in ipairs(action_names) do
    local action_opts = {}
    if type(opts) == "table" then
      action_opts = {
        label = opts.label,
        label_builder = opts.label_builder,
        ctx = opts.ctx,
        capabilities = opts.capabilities,
      }

      local key_overrides = opts.key_overrides
      if type(key_overrides) == "table" and type(key_overrides[action_name]) == "string" then
        action_opts.key = key_overrides[action_name]
      end

      local icon_overrides = opts.icon_overrides
      if type(icon_overrides) == "table" and type(icon_overrides[action_name]) == "string" then
        action_opts.icon = icon_overrides[action_name]
      end

      local label_overrides = opts.label_overrides
      if type(label_overrides) == "table" then
        local override = label_overrides[action_name]
        if type(override) == "string" then
          action_opts.label_builder = function()
            return override
          end
        elseif type(override) == "function" then
          action_opts.label_builder = override
        end
      end
    end

    local row = M.build_row(anchor_type, action_name, action_opts)
    if type(row) == "table" then
      rows[#rows + 1] = row
    end
  end

  return rows
end

return M
