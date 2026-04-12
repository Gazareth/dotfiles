-- Wrap menu item actions so Treewalker can reopen after navigation (hydra/lib stays generic).
local action = require("configs.hydra.lib.action")

local M = {}

local function reopen_delta(item)
  local d = item._reopen_atlantis
  if type(d) == "number" then
    return d
  end
  return 0
end

local function schedule_reopen(session, delta)
  vim.schedule(function()
    local reopen_opts = vim.tbl_extend("force", {}, session.hydra_opts)
    local menu_for_open = session.menu_opts
    if delta ~= 0 then
      menu_for_open = vim.tbl_extend("force", {}, session.menu_opts)
      menu_for_open.depth = math.max(0, (session.menu_opts.depth or 0) + delta)
    end
    require("configs.hydra.atlantis").open(menu_for_open, reopen_opts)
  end)
end

local function schedule_file_nav(session)
  vim.schedule(function()
    require("configs.hydra.atlantis.file_nav").open(session.menu_opts, session.hydra_opts)
  end)
end

function M.wrap_item(item, session)
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
    schedule_reopen(session, delta)
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
