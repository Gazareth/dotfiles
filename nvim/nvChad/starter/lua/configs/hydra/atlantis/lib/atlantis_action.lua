-- Wrap menu item actions so Atlantis can reopen after navigation (hydra/lib stays generic).
-- Pickers require this module too; lazy-require inside closures to avoid a load-time cycle.
local action = require("configs.hydra.lib.action")

local M = {}

local function reopen_delta(item)
  local d = item._reopen_atlantis
  if type(d) == "number" then
    return d
  end
  return 0
end

local function schedule_reopen(session, delta, item)
  vim.schedule(function()
    local reopen_opts = vim.tbl_extend("force", {}, session.hydra_opts)
    local menu_opts = session.menu_opts
    if type(item) == "table" and item._atlantis_reopen_anchor_mode == true then
      if item._preserve_container_on_reopen ~= true then
        menu_opts._atlantis_container_session = nil
        menu_opts.prefer_container = nil
      end
    end
    if delta ~= 0 then
      menu_opts.depth = math.max(0, (menu_opts.depth or 0) + delta)
    elseif type(item) == "table" and item._atlantis_snap_reopen == true then
      -- Opt-in: LSP rename etc. can leave the cursor on an inner node; snap restores outer anchor for rebuild.
      menu_opts._atlantis_reopen_snap = true
    end
    require("configs.hydra.atlantis").open(menu_opts, reopen_opts)
  end)
end

local function schedule_container_reopen(session, extra)
  extra = type(extra) == "table" and extra or {}
  vim.schedule(function()
    local menu_opts = session.menu_opts
    if type(menu_opts) == "table" then
      menu_opts._atlantis_container_session = true
      if extra.outline_current_scope == true then
        menu_opts._atlantis_outline_file_root = nil
        menu_opts._atlantis_outline_title_override = nil
      else
        if extra.outline_file_root == true then
          menu_opts._atlantis_outline_file_root = true
        else
          menu_opts._atlantis_outline_file_root = nil
        end
        if type(extra.title_override) == "string" and extra.title_override ~= "" then
          menu_opts._atlantis_outline_title_override = extra.title_override
        else
          menu_opts._atlantis_outline_title_override = nil
        end
      end
    end
    require("configs.hydra.atlantis").open(menu_opts, vim.tbl_extend("force", {}, session.hydra_opts))
  end)
end

function M.wrap_item(item, session)
  if item.action_id == "jump_to_child" then
    item.action = function()
      require("configs.hydra.atlantis.anchor.build.jump_child_picker").open(session)
    end
    return
  end

  if item._action_common_overflow == true and type(item._overflow_action_names) == "table" then
    local names = item._overflow_action_names
    item._action_common_overflow = nil
    item._overflow_action_names = nil
    item.action = function()
      require("configs.hydra.atlantis.anchor.build.action_overflow_picker").open(session, names)
    end
    -- Submenu opener: do not schedule parent reopen (would fight the child Hydra).
    return
  end

  if item.action == nil then
    return
  end

  if item._reopen_container_mode == true then
    local inner = item.action
    local nav_mode = item._atlantis_nav_mode
    local wrapper
    wrapper = function(it)
      if nav_mode == "current_scope" then
        it.action = inner
        action.execute(it)
        it.action = wrapper
        schedule_container_reopen(session, { outline_current_scope = true })
        return
      end
      local ab = require("configs.hydra.atlantis.anchor.build")
      local title_builder = require("configs.hydra.atlantis.menu.components.title.builder")
      local snap = ab.build(vim.tbl_extend("force", {}, session.menu_opts))
      -- "Top level..." always indexes from the parse tree root (file-level outline), not from
      -- whatever node `container_for_nav_mode` would pick when the anchor happens to match root.
      local title_override = title_builder.build_from_parsed(snap.positioned_anchor_node_info, snap.parsed_anchor)
      it.action = inner
      action.execute(it)
      it.action = wrapper
      schedule_container_reopen(session, {
        outline_file_root = true,
        title_override = title_override,
      })
    end
    item.action = wrapper
    return
  end

  local delta = reopen_delta(item)
  if delta == -1 then
    return
  end

  local inner = item.action
  local wrapper
  wrapper = function(it)
    it.action = inner
    action.execute(it)
    it.action = wrapper
    schedule_reopen(session, delta, it)
  end
  item.action = wrapper
end

local function resolve_section_for_wrap(section_spec)
  if type(section_spec) == "function" then
    local ok, result = pcall(section_spec)
    if not ok or type(result) ~= "table" then
      return nil
    end
    return result
  end
  if type(section_spec) == "table" then
    return section_spec
  end
  return nil
end

function M.wrap_spec_items(spec, session)
  for _, section in ipairs(spec.sections or {}) do
    local resolved = resolve_section_for_wrap(section)
    if resolved and type(resolved.items) == "table" then
      for _, item in ipairs(resolved.items) do
        M.wrap_item(item, session)
      end
    end
  end
end

return M
