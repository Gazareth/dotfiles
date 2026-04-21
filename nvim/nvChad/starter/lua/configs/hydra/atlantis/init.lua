local anchor_build = require("configs.hydra.atlantis.anchor.build")
local capabilities = require("configs.hydra.atlantis.anchor.build.capabilities")
local reopen_seed = require("configs.hydra.atlantis.anchor.build.reopen_seed")
local atlantis_action = require("configs.hydra.atlantis.lib.atlantis_action")
local position_cursor = require("configs.hydra.atlantis.lib.position_cursor")
local create_hint_menu = require("configs.hydra.atlantis.menu.create_hint_menu")
local hint_kicker = require("configs.hydra.atlantis.menu.hint_kicker")
local layout = require("configs.hydra.atlantis.menu.layout")
local outline_build_spec = require("configs.hydra.atlantis.outline.build_spec")
local outline_walker = require("configs.hydra.atlantis.outline.walker")
local make_hydra = require("configs.hydra.lib.make_hydra")

local M = {}

local function use_container_mode(menu_opts, anchor_ctx, layout_variant)
  if layout_variant == "abort_action_menu" or not anchor_ctx.cursor_node_info then
    return false
  end
  if menu_opts.prefer_container == true or menu_opts._atlantis_container_session == true then
    return true
  end
  return not anchor_ctx.has_anchor_point
end

--- Build Hydra hint/outline spec and session state without moving the cursor or opening Hydra.
--- @return { spec: table, session: table, anchor_ctx: table, container_mode: boolean }
function M.build_view_spec(menu_opts, hydra_opts)
  menu_opts = type(menu_opts) == "table" and menu_opts or {}
  hydra_opts = type(hydra_opts) == "table" and hydra_opts or {}
  local session = {
    menu_opts = menu_opts,
    hydra_opts = vim.tbl_extend("force", {}, hydra_opts),
  }

  local anchor_ctx = anchor_build.build(menu_opts)
  local menu_layout = layout.from_context(anchor_ctx)

  local container_mode = use_container_mode(menu_opts, anchor_ctx, menu_layout.variant)
  local spec
  if container_mode then
    menu_opts._atlantis_container_session = true
    local filled_nav = capabilities.fill(anchor_ctx.anchor_node_info, {
      candidates = anchor_ctx.jump_candidates,
      selected_candidate_index = anchor_ctx.selected_jump_candidate_index,
    }, menu_opts)
    anchor_ctx.navigate_spec = filled_nav.navigate_spec
    local cursor_node = anchor_ctx.cursor_node_info and anchor_ctx.cursor_node_info.node or nil
    local bufnr = anchor_ctx.cursor_node_info and anchor_ctx.cursor_node_info.bufnr or vim.api.nvim_get_current_buf()
    local container_node, is_parse_root
    if menu_opts._atlantis_outline_file_root == true then
      menu_opts._atlantis_outline_file_root = nil
      container_node = outline_walker.parse_tree_root(bufnr)
      is_parse_root = container_node ~= nil
    else
      container_node, is_parse_root = outline_walker.container_for_nav_mode(anchor_ctx, bufnr, cursor_node)
    end
    spec = outline_build_spec.build(anchor_ctx, session, container_node, is_parse_root)
  else
    menu_opts._atlantis_container_session = nil
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
  if anchor_ctx.anchor_node_info and anchor_ctx.anchor_node_info.node then
    menu_opts._atlantis_anchor_seed = reopen_seed.pack(anchor_ctx.anchor_node_info)
  else
    menu_opts._atlantis_anchor_seed = nil
  end

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

  if menu_opts._atlantis_reopen_snap then
    menu_opts._atlantis_reopen_snap = nil
    reopen_seed.apply(menu_opts._atlantis_anchor_seed)
  end

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
  menu_opts.prefer_container = true
  M.open(menu_opts, hydra_opts)
end

return M
