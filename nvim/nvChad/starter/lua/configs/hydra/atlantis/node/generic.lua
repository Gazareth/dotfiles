local M = {}
local action_ids = require("configs.hydra.atlantis.treesitter.lib.atlantis.constants").action_ids
local title_builder = require("configs.hydra.atlantis.node.title")

-- Placeholder actions for generic nodes
local function build_placeholder_action(verb, label)
  return function()
    vim.notify(verb .. " " .. label .. " is not implemented yet.", vim.log.levels.INFO)
  end
end

-- Raw and Atlantis node details
local function build_inspect_action(node_info, parsed)
  return function()
    local semantic = parsed and parsed.semantic or {}
    local message = table.concat({
      "Atlantis node inspect:",
      "node=" .. tostring((parsed and parsed.node_type) or (node_info and node_info.node_type)),
      "tier=" .. tostring(parsed and parsed.node_tier),
      "kind=" .. tostring(parsed and parsed.semantic_kind),
      "actionable=" .. tostring(parsed and parsed.actionable),
      "status=" .. tostring(semantic.status),
    }, " ")

    vim.notify(message, vim.log.levels.INFO)
  end
end

-- Fallback menu for unsupported node kinds
function M.build(node_info, parsed)
  local label = (parsed and parsed.display_name) or (node_info and node_info.node_type) or "node"

  -- Basic actions for fallback menus
  return {
    title = title_builder.build_from_parsed(node_info, parsed),
    items = {
      {
        heading = "Actions",
      },
      {
        separator = true,
      },
      {
        key = "c",
        icon = ">",
        label = "Change " .. label,
        action_id = action_ids.change,
        action = build_placeholder_action("Change", label),
      },
      {
        key = "v",
        icon = "=",
        label = "Yank " .. label,
        action_id = action_ids.yank,
        action = build_placeholder_action("Yank", label),
      },
      {
        key = "d",
        icon = "x",
        label = "Delete " .. label,
        action_id = action_ids.delete,
        action = build_placeholder_action("Delete", label),
      },
      {
        key = "i",
        icon = "?",
        label = "Inspect node mapping",
        action_id = action_ids.inspect,
        action = build_inspect_action(node_info, parsed),
      },
    },
  }
end

return M
