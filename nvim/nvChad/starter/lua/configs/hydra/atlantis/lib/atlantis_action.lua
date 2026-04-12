-- Wrap menu item actions so Treewalker can reopen after navigation (hydra/lib stays generic).
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
    if delta ~= 0 then
      menu_opts.depth = math.max(0, (menu_opts.depth or 0) + delta)
    elseif type(item) == "table" and item._atlantis_snap_reopen == true then
      -- Opt-in: LSP rename etc. can leave the cursor on an inner node; snap restores outer anchor for rebuild.
      menu_opts._atlantis_reopen_snap = true
    end
    require("configs.hydra.atlantis").open(menu_opts, reopen_opts)
  end)
end

local function schedule_file_nav(session)
  vim.schedule(function()
    require("configs.hydra.atlantis.file_nav").open(session.menu_opts, session.hydra_opts)
  end)
end

function M.wrap_item(item, session)
  if item.action_id == "jump_to_child" then
    item.action = function()
      require("configs.hydra.atlantis.anchor.build.jump_child_picker").open(session)
    end
    return
  end

  if item._modify_common_overflow == true and type(item._overflow_action_names) == "table" then
    local names = item._overflow_action_names
    item._modify_common_overflow = nil
    item._overflow_action_names = nil
    item.action = function()
      require("configs.hydra.atlantis.anchor.build.modify_overflow_picker").open(session, names)
    end
    -- Submenu opener: do not schedule parent reopen (would fight the child Hydra).
    return
  end

  if item.action == nil then
    return
  end

  if item._reopen_file_nav == true then
    local inner = item.action
    local wrapper
    wrapper = function(it)
      it.action = inner
      action.execute(it)
      it.action = wrapper
      schedule_file_nav(session)
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

function M.wrap_spec_items(spec, session)
  for _, section in ipairs(spec.sections or {}) do
    for _, item in ipairs(section.items or {}) do
      M.wrap_item(item, session)
    end
  end
end

return M
