local M = {}

-- Default Atlantis Tree-sitter behavior and default anchor depth
local defaults = {
  depth = 0,
  safe_languages = false,
  languages = {},
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
