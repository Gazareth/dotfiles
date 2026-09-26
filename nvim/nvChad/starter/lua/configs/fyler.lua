function open_fyler(args)
  return function() require("fyler").open(args or {}) end
end

local M = {
  keys = {
    { "<leader>b", open_fyler(), desc = "Open Fyler View" },
    { "<C-b>", open_fyler({ kind = "split_left" }), desc = "Open Fyler View - Sidebar" },
  },
  opts = {
    kind = "floating",
    follow_current_file = true,
    integrations = {
      icon = 'nvim_web_devicons'
    },
    kind_presets = {
      split_left = { width = '25%' },
      split_left_most = { width = '25%' },
    },
    mappings = {
      n = {
        ['<C-b>'] = {
          action = 'close',
        },
      },
    },
  },
}

return M
