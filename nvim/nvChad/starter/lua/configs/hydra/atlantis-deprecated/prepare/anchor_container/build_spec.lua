local fallback_navigate = require("configs.hydra.atlantis-deprecated.menu.sections.navigate")
local create_section = require("configs.hydra.atlantis-deprecated.menu.sections.create")
local column_titles = require("configs.hydra.atlantis-deprecated.menu.column_titles")
local index_mod = require("configs.hydra.atlantis-deprecated.prepare.anchor_container.index")
local items_mod = require("configs.hydra.atlantis-deprecated.prepare.anchor_container.items")
local schema = require("configs.hydra.atlantis-deprecated.schema.menu.outline")
local title_builder = require("configs.hydra.atlantis-deprecated.menu.components.title.builder")

local M = {}

--- @param anchor_ctx table from anchor_build.build
--- @param menu_opts table initial open args (depth, container_scope, title_override, etc.)
--- @param hydra_opts table
--- @param container_node userdata TSNode
function M.build(anchor_ctx, menu_opts, hydra_opts, container_node, _is_parse_root)
  anchor_ctx = type(anchor_ctx) == "table" and anchor_ctx or {}
  menu_opts = type(menu_opts) == "table" and menu_opts or {}
  hydra_opts = type(hydra_opts) == "table" and hydra_opts or {}

  local hint_title = title_builder.build_from_parsed(
    anchor_ctx.positioned_anchor_node_info,
    anchor_ctx.parsed_anchor
  )
  local override = menu_opts.title_override
  if type(override) == "string" and override ~= "" then
    hint_title = override
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local index = index_mod.build_for_container(bufnr, container_node, schema.kind_order)
  local outline_items = items_mod.build(index, menu_opts, hydra_opts)

  local navigate_section = anchor_ctx.nav_column_spec or fallback_navigate
  local outline_section = {
    title = column_titles.outline(),
    items = outline_items,
  }

  return {
    title = hint_title,
    hint_opts = {
      padding_left = schema.hint_padding_left,
      padding_right = schema.hint_padding_right,
    },
    sections = { navigate_section, outline_section, create_section },
  }
end

return M
