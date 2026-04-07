local M = {}

-- Default Tree-sitter settings
local defaults = {
  context_mode = "standard",
  safe_languages = false,
  languages = {},
  modes = {
    standard = "standard",
    lowest_node = "lowest_node",
    max = "max",
    depth_0 = "depth_0",
    depth_1 = "depth_1",
  },
}

-- Live Tree-sitter settings
local state = vim.deepcopy(defaults)

-- Merge user Tree-sitter settings
function M.setup(opts)
  opts = opts or {}
  state = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts)
  return state
end

-- Current Tree-sitter settings
function M.get()
  return state
end

-- Temporary context mode override
function M.with_context_mode(mode, fn)
  if type(fn) ~= "function" then
    return nil
  end

  local previous_mode = state.context_mode
  state.context_mode = mode or previous_mode

  local ok, result = pcall(fn)
  state.context_mode = previous_mode

  if not ok then
    error(result)
  end

  return result
end

return M
