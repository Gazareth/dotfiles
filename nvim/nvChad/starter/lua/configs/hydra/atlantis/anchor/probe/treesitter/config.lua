local M = {}

-- Default Atlantis Tree-sitter behavior and depth modes
local defaults = {
  context_mode = "depth_0",
  safe_languages = false,
  languages = {},
  modes = {
    lowest_node = "lowest_node",
    max = "max",
    depth_0 = "depth_0",
    depth_1 = "depth_1",
  },
}

-- Mutable runtime settings initialized from defaults
local state = vim.deepcopy(defaults)

-- Merge user overrides into runtime Tree-sitter settings
function M.setup(opts)
  opts = opts or {}
  state = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts)
  return state
end

-- Return active Tree-sitter settings snapshot
function M.get()
  return state
end

return M
