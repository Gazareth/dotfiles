local M = {}

local function build_placeholder_action(verb, label)
  return function()
    vim.notify(verb .. " " .. label .. " is not implemented yet.", vim.log.levels.INFO)
  end
end

function M.build(node_info, parsed)
  local label = (parsed and parsed.display_name) or (node_info and node_info.node_type) or "node"

  return {
    title = "󰘗 " .. label,
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
        action = build_placeholder_action("Change", label),
      },
      {
        key = "v",
        icon = "=",
        label = "Yank " .. label,
        action = build_placeholder_action("Yank", label),
      },
      {
        key = "d",
        icon = "x",
        label = "Delete " .. label,
        action = build_placeholder_action("Delete", label),
      },
    },
  }
end

return M
