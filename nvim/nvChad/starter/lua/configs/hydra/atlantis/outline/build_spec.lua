local fallback_navigate = require("configs.hydra.atlantis.menu.sections.navigate")
local action_section = require("configs.hydra.atlantis.menu.sections.action")
local create_section = require("configs.hydra.atlantis.menu.sections.create")
local interact_outline_merge = require("configs.hydra.atlantis.menu.interact_outline_merge")
local index_mod = require("configs.hydra.atlantis.outline.index")
local items_mod = require("configs.hydra.atlantis.outline.items")
local schema = require("configs.hydra.atlantis.schema.menu.outline")
local title_builder = require("configs.hydra.atlantis.menu.components.title.builder")

local M = {}

--- @param anchor_ctx table from anchor_build.build
--- @param session { menu_opts: table, hydra_opts: table }
--- @param container_node userdata TSNode
function M.build(anchor_ctx, session, container_node, _is_parse_root)
  anchor_ctx = type(anchor_ctx) == "table" and anchor_ctx or {}
  session = type(session) == "table" and session or {}
  local menu_opts = type(session.menu_opts) == "table" and session.menu_opts or {}

  local hint_title = title_builder.build_from_parsed(
    anchor_ctx.positioned_anchor_node_info,
    anchor_ctx.parsed_anchor
  )
  local override = menu_opts._atlantis_outline_title_override
  if type(override) == "string" and override ~= "" then
    hint_title = override
    menu_opts._atlantis_outline_title_override = nil
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local index = index_mod.build_for_container(bufnr, container_node, schema.kind_order)
  local outline_items = items_mod.build(index, session.menu_opts, session.hydra_opts)

  local navigate_section = anchor_ctx.navigate_spec or fallback_navigate
  local interact_raw = action_section(anchor_ctx)
  local interact_section =
    interact_outline_merge.build_interact_section(interact_raw, outline_items, anchor_ctx.parsed_anchor)

  return {
    title = hint_title,
    hint_opts = {
      padding_left = schema.hint_padding_left,
      padding_right = schema.hint_padding_right,
    },
    sections = { navigate_section, interact_section, create_section },
  }
end

return M
