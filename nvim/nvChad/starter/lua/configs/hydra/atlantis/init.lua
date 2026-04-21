local anchor_build = require("configs.hydra.atlantis.anchor.build")
local anchor_fill = require("configs.hydra.atlantis.anchor.build.anchor_fill")
local atlantis_action = require("configs.hydra.atlantis.lib.atlantis_action")
local position_cursor = require("configs.hydra.atlantis.lib.position_cursor")
local create_hint_menu = require("configs.hydra.atlantis.menu.create_hint_menu")
local hint_kicker = require("configs.hydra.atlantis.menu.hint_kicker")
local layout = require("configs.hydra.atlantis.menu.layout")
local container_build_spec = require("configs.hydra.atlantis.container.build_spec")
local container_scope_resolver = require("configs.hydra.atlantis.container.scope_resolver")
local schema_constants = require("configs.hydra.atlantis.schema.constants")
local container_scope = schema_constants.container_scope
local make_hydra = require("configs.hydra.lib.make_hydra")

local M = {}

local function use_container_mode(menu_opts, anchor_ctx, layout_variant)
  if layout_variant == "abort_action_menu" or not anchor_ctx.cursor_node_info then
    return false
  end
  if type(menu_opts.container_scope) == "string" then
    return true
  end
  return not anchor_ctx.has_anchor_point
end

--- Build Hydra hint/outline spec and session state without moving the cursor or opening Hydra.
--- @return { spec: table, session: table, anchor_ctx: table, container_mode: boolean }
function M.build_view_spec(menu_opts, hydra_opts)
  menu_opts = type(menu_opts) == "table" and menu_opts or {}
  hydra_opts = type(hydra_opts) == "table" and hydra_opts or {}
  local session = { hydra_opts = vim.tbl_extend("force", {}, hydra_opts) }

  -- Snap cursor to anchor position stored at build time (e.g. after LSP rename).
  if type(menu_opts.anchor_pos) == "table" then
    local pos = menu_opts.anchor_pos
    if type(pos.bufnr) == "number" and vim.api.nvim_buf_is_valid(pos.bufnr) then
      pcall(vim.api.nvim_set_current_buf, pos.bufnr)
      pcall(vim.api.nvim_win_set_cursor, 0, { pos.row or 1, pos.col or 0 })
    end
    menu_opts = vim.tbl_extend("force", {}, menu_opts)
    menu_opts.anchor_pos = nil
  end

  local anchor_ctx = anchor_build.build(menu_opts)
  local menu_layout = layout.from_context(anchor_ctx)

  local container_mode = use_container_mode(menu_opts, anchor_ctx, menu_layout.variant)
  local spec
  if container_mode then
    local filled_nav = anchor_fill.fill(anchor_ctx.anchor_node_info, {
      candidates = anchor_ctx.candidate_chain,
      selected_candidate_index = anchor_ctx.selected_jump_candidate_index,
    }, menu_opts)
    anchor_ctx.nav_column_spec = filled_nav.nav_column_spec
    local cursor_node = anchor_ctx.cursor_node_info and anchor_ctx.cursor_node_info.node or nil
    local bufnr = anchor_ctx.cursor_node_info and anchor_ctx.cursor_node_info.bufnr or vim.api.nvim_get_current_buf()
    local container_node, is_parse_root
    if menu_opts.container_scope == container_scope.file then
      container_node = container_scope_resolver.parse_tree_root(bufnr)
      is_parse_root = container_node ~= nil
    else
      container_node, is_parse_root = container_scope_resolver.container_for_nav_mode(anchor_ctx, bufnr, cursor_node)
    end
    spec = container_build_spec.build(anchor_ctx, menu_opts, hydra_opts, container_node, is_parse_root)
  else
    spec = create_hint_menu.create_hint_menu(menu_layout)
  end

  local hotkey_pool = type(menu_opts.hotkey_pool) == "string" and menu_opts.hotkey_pool
    or type(hydra_opts.hotkey_pool) == "string" and hydra_opts.hotkey_pool
    or nil
  spec.hint_opts = vim.tbl_extend("force", type(spec.hint_opts) == "table" and spec.hint_opts or {}, {
    title_kicker = container_mode and hint_kicker.container() or hint_kicker.default(),
  })
  if hotkey_pool ~= nil then
    spec.hint_opts = vim.tbl_extend("force", spec.hint_opts, {
      hotkey_pool = hotkey_pool,
    })
  end
  spec.merge_ui_opts = function(_, incoming)
    vim.tbl_extend("force", session.hydra_opts, incoming)
    return session.hydra_opts
  end
  atlantis_action.wrap_spec_items(spec, session)

  return {
    spec = spec,
    session = session,
    anchor_ctx = anchor_ctx,
    container_mode = container_mode,
  }
end

function M.open(menu_opts, hydra_opts)
  menu_opts = type(menu_opts) == "table" and menu_opts or {}
  hydra_opts = type(hydra_opts) == "table" and hydra_opts or {}

  local view = M.build_view_spec(menu_opts, hydra_opts)
  local spec = view.spec
  local session = view.session
  local anchor_ctx = view.anchor_ctx
  local container_mode = view.container_mode

  if container_mode and anchor_ctx.anchor_node_info and anchor_ctx.anchor_node_info.node then
    position_cursor.at_node_info(anchor_ctx.anchor_node_info)
  elseif spec.anchor_node_info then
    position_cursor.at_node_info(spec.anchor_node_info)
    spec.anchor_node_info = nil
  end

  make_hydra(spec, session.hydra_opts):open()
end

--- Open Atlantis in container (outline) mode.
function M.open_container(menu_opts, hydra_opts)
  menu_opts = type(menu_opts) == "table" and menu_opts or {}
  menu_opts = vim.tbl_extend("force", {}, menu_opts)
  menu_opts.container_scope = container_scope.current_scope
  M.open(menu_opts, hydra_opts)
end

return M
