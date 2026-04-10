-- Build parameter sibling adapter with jump, swap, rename, and remove actions
local helpers = require("configs.hydra.atlantis.ops.actions.specific.parameter.lib.helpers")
local sibling_ops = require("configs.hydra.atlantis.ops.lib.sibling")

local M = {}

-- Parameter adapter instance
function M.create(ctx)
  local state_cache = nil
  local has_state = false

  local adapter = {}

  -- Parameter label
  function adapter:label()
    return "Parameter"
  end

  -- Parameter state
  function adapter:state()
    if has_state then
      return state_cache
    end

    has_state = true
    state_cache = helpers.resolve_state(ctx)
    return state_cache
  end

  -- Parameter target by direction
  function adapter:target(direction)
    local state = self:state()
    if direction == "previous" then
      return helpers.previous_target(state)
    end

    if direction == "next" then
      return helpers.next_target(state)
    end

    return nil
  end

  -- Parameter target list
  function adapter:target_list()
    local state = self:state()
    return type(state) == "table" and (state.parameter_targets or {}) or {}
  end

  -- Parameter label list
  function adapter:target_labels(targets)
    return helpers.build_labels(targets)
  end

  -- Jump to parameter target
  function adapter:jump(target)
    local action = helpers.jump_to_target(target)
    if type(action) == "function" then
      action()
    end
  end

  -- Swap parameter to index
  function adapter:swap_to_index(index)
    return helpers.swap_with_target_index(self:state(), index)
  end

  -- Current parameter index
  function adapter:current_index()
    local state = self:state()
    return type(state) == "table" and state.current_index or nil
  end

  -- Rename parameter action
  function adapter:rename()
    local target = helpers.current_target(self:state())
    if not target then
      vim.notify("Rename parameter is unavailable", vim.log.levels.INFO)
      return
    end

    self:jump(target)

    local ok, err = pcall(vim.lsp.buf.rename)
    if not ok then
      vim.notify("Rename parameter is unavailable: " .. tostring(err), vim.log.levels.WARN)
    end
  end

  -- Remove parameter action
  function adapter:remove()
    local target = helpers.current_target(self:state())
    if not target then
      vim.notify("Remove parameter is unavailable", vim.log.levels.INFO)
      return
    end

    self:jump(target)

    local keys = vim.api.nvim_replace_termcodes("dap", true, false, true)
    vim.api.nvim_feedkeys(keys, "n", false)
  end

  sibling_ops.attach(adapter)
  return adapter
end

return M
