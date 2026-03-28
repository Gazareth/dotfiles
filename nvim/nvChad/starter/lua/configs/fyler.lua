local function open_fyler()
  local fyler = require("fyler")
  local bufname = vim.api.nvim_buf_get_name(0)
  local first_open = not vim.g.fyler_has_been_opened

  fyler.open()

  if first_open and bufname ~= "" then
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(0) then
        fyler.navigate(bufname)
      end
      vim.g.fyler_has_been_opened = true
    end, 100)
  else
    vim.g.fyler_has_been_opened = true
  end
end

local M = {
  opts = {
    views = {
      finder = {
        win = {
          kind = "float",
        },
        mappings = {
          ["<C-b>"] = "CloseView",
        },
        follow_current_file = true,
      },
    },
    integrations = {
      icon = "nvim_web_devicons",
    },
  },
  keys = {
    { "<C-b>", open_fyler, desc = "Open Fyler View" },
  },
}

return M
