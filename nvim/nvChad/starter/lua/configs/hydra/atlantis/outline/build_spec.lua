local column_titles = require("configs.hydra.atlantis.menu.column_titles")
local fallback_jump = require("configs.hydra.atlantis.menu.sections.jump")
local index_mod = require("configs.hydra.atlantis.outline.index")
local items_mod = require("configs.hydra.atlantis.outline.items")
local schema = require("configs.hydra.atlantis.schema.menu.outline")
local swap_section = require("configs.hydra.atlantis.menu.sections.swap")
local title_builder = require("configs.hydra.atlantis.menu.components.title.builder")

local M = {}

--- @param anchor_ctx table from anchor_build.build
--- @param session { menu_opts: table, hydra_opts: table }
--- @param container_node userdata TSNode
--- @param is_parse_root boolean
function M.build(anchor_ctx, session, container_node, is_parse_root)
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
  local items = items_mod.build(index, session.menu_opts, session.hydra_opts)

  local middle_title = column_titles.navigate()
  local outline_section = {
    title = middle_title,
    items = items,
  }

  local jump_spec = anchor_ctx.jump_spec or fallback_jump

  if is_parse_root then
    -- Keep jump (Navigation: H/h, etc.) in file-level nav; otherwise `h` is not a Hydra head
    -- and the key falls through to Normal mode (e.g. cursor-left).
    return {
      title = hint_title,
      hint_opts = {
        padding_left = schema.hint_padding_left,
        padding_right = schema.hint_padding_right,
      },
      sections = { jump_spec, outline_section },
    }
  end

  return {
    title = hint_title,
    hint_opts = {
      padding_left = schema.hint_padding_left,
      padding_right = schema.hint_padding_right,
    },
    sections = { jump_spec, outline_section, swap_section },
  }
end

return M
