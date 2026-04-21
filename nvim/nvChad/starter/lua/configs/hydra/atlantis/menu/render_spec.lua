local title_builder = require("configs.hydra.atlantis.menu.components.title.builder")
local action_rows = require("configs.hydra.atlantis.menu.components.action.rows")
local action_order = require("configs.hydra.atlantis.menu.components.action.order")
local action_labels = require("configs.hydra.atlantis.menu.components.action.labels")
local layout = require("configs.hydra.atlantis.schema.actions.layout")

local M = {}

function M.build(runtime_ctx)
  local parsed = type(runtime_ctx) == "table" and runtime_ctx.parsed_anchor or nil
  local node_info = type(runtime_ctx) == "table" and runtime_ctx.anchor_node_info or nil
  local node_kind = type(parsed) == "table" and parsed.node_kind or nil
  local grouped = action_order.build_grouped(node_kind)

  local row_opts = {
    ctx = {
      node_info = node_info,
      parsed = parsed,
      cursor_node_info = type(runtime_ctx) == "table" and runtime_ctx.cursor_node_info or nil,
      depth = type(runtime_ctx) == "table" and runtime_ctx.depth or nil,
    },
    label_overrides = action_labels.build_overrides(runtime_ctx),
  }

  local common_primary_rows = action_rows.build_rows(node_kind, grouped.common_primary, row_opts)
  local common_overflow_rows = action_rows.build_rows(node_kind, grouped.common_overflow, row_opts)
  local specific_rows = action_rows.build_rows(node_kind, grouped.specific, row_opts)

  local specific_section_title = nil
  if #specific_rows > 0 and type(node_kind) == "string" then
    specific_section_title = layout.specific_title_for_anchor_kind(node_kind)
  end

  local flat = {}
  for _, r in ipairs(common_primary_rows) do
    flat[#flat + 1] = r
  end
  for _, r in ipairs(common_overflow_rows) do
    flat[#flat + 1] = r
  end
  for _, r in ipairs(specific_rows) do
    flat[#flat + 1] = r
  end

  return {
    title = title_builder.build_from_parsed(node_info, parsed),
    action_rows = flat,
    common_primary_rows = common_primary_rows,
    common_overflow_rows = common_overflow_rows,
    specific_rows = specific_rows,
    specific_section_title = specific_section_title,
    grouped_action_names = {
      common_overflow = grouped.common_overflow,
    },
  }
end

return M
