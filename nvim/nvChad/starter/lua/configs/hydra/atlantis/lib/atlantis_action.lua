-- Wrap menu item actions so Atlantis can reopen after navigation (hydra/lib stays generic).
-- Pickers require this module too; lazy-require inside closures to avoid a load-time cycle.
local action = require("configs.hydra.lib.action")

local M = {}

function M.wrap_item(item, session)
  if item.action_id == "jump_to_child" then
    local reopen_args = type(item.reopen) == "table" and item.reopen or {}
    item.action = function()
      require("configs.hydra.atlantis.prepare.anchor_point.build.jump_child_picker").open(reopen_args, session.hydra_opts)
    end
    return
  end

  if item._action_common_overflow == true and type(item._overflow_action_names) == "table" then
    local names = item._overflow_action_names
    item._action_common_overflow = nil
    item._overflow_action_names = nil
    local reopen_args = type(item.reopen) == "table" and item.reopen or {}
    item.action = function()
      require("configs.hydra.atlantis.prepare.anchor_point.build.action_overflow_picker").open(
        reopen_args,
        session.hydra_opts,
        names
      )
    end
    -- Submenu opener: do not schedule parent reopen (would fight the child Hydra).
    return
  end

  if item.action == nil or type(item.reopen) ~= "table" then
    return
  end

  local reopen_args = item.reopen
  local inner = item.action
  local wrapper
  wrapper = function(it)
    it.action = inner
    action.execute(it)
    it.action = wrapper
    vim.schedule(function()
      local hydra_opts = vim.tbl_extend("force", {}, session.hydra_opts)
      if type(reopen_args.anchor_pos) == "table" then
        local pos = reopen_args.anchor_pos
        if type(pos.bufnr) == "number" and vim.api.nvim_buf_is_valid(pos.bufnr) then
          pcall(vim.api.nvim_set_current_buf, pos.bufnr)
          pcall(vim.api.nvim_win_set_cursor, 0, { pos.row or 1, pos.col or 0 })
        end
      end
      require("configs.hydra.atlantis").open(reopen_args, hydra_opts)
    end)
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
