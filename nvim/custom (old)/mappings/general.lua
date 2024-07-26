local current_file_dir = require("custom.functions.mappings").current_file_dir
local switch_window = require("custom.functions.mappings").switch_window
local explore_current_file_dir = require("custom.functions.mappings").explore_current_file_dir
local return_to_dashboard = require("custom.functions.mappings").return_to_dashboard



local M = {}


M.general = {
  [{"n", "i"}] = {
    ["<C-Tab>"] = { "<cmd> tabnext <CR>", "Switch to next tab" },
    ["<C-S-Tab>"] = { "<cmd> tabprev <CR>", "Switch to previous tab" },
  },
  n = {
    -- Meta stuff
    ["<leader>lzs"] = { "<cmd> Lazy Sync <CR>", "Sync plugins" },
    ["<leader>cd"] = { "<cmd> :cd %:p:h <CR>", "Set directory to current file's" },
    ["<leader>ycd"] = {
      function()
        vim.fn.setreg("*", current_file_dir())
      end,
      "Yank current file directory to clipboard",
    },
    ["<leader>ecd"] = { explore_current_file_dir, "Open explorer at current file's directory (windows)" },

    -- Modes
    [";"] = { ":", "enter command mode", opts = { nowait = true } },

    ["ZW"] = { "<cmd> wa <CR>", "Save all files" },
    ["ZD"] = { return_to_dashboard(false), "Return to project dashboard" },
    ["ZDQ"] = { return_to_dashboard(true), "Return to dashboard" },
    ["ZA"] = { "<cmd> wa | qa <CR>", "Save all files then quit vim" },
    ["Zs"] = { "<cmd>so %<CR>", "Source current file" },

    -- Tab/window switching
    ["<C-w><C-v>"] = { "<cmd> vert sb # <CR>", "Open a vertical split of current and previous buffer" },
    ["<C-w><C-t>"] = { "<cmd> tabc <CR>", "Close tab" },
    ["<C-t>"] = { "<cmd> tabnew | Alpha <CR>", "Open new tab and run Alpha (dashboard)" },
    ["<Tab>"] = { switch_window "w", "Switch to next window" },
    ["<S-Tab>"] = { switch_window "W", "Switch to previous window" },

    -- Help with editing/writing text
    ["Y"] = { "^vg_", "select line (excluding EOL character)" },
    ["<leader><enter>"] = { ":call feedkeys('] [ i')<cr>", "Insert mode with new line above and below." },

    ["]d"] = { function() vim.diagnostic.goto_next() end, "Go to next diagnostic issue" },
    ["[d"] = { function() vim.diagnostic.goto_prev() end, "Go to previous diagnostic issue" },
    -- Print out current mode on a delay (for debugging)
    -- ["<leader>m"] = { function()
    --   local timer = vim.loop.new_timer()
    --   local print_timer = vim.loop.new_timer()
    --   local curr_mode  = "n"
    --   timer:start(1000, 0, function ()
    --     curr_mode = vim.api.nvim_get_mode().mode
    --     print("Got mode!!!")
    --     print_timer:start(1000,0, function()
    --       print("Mode is: "..curr_mode)
    --       print_timer:stop()
    --       print_timer:close()
    --     end)
    --     timer:stop()
    --     timer:close()
    --   end)
    -- end
    -- ,
  },
  i = {
    ["="] = { " = ", "spaced equals" },
    [">="] = { " >= ", "spaced greater than or equal to" },
    ["<="] = { " <= ", "spaced less than or equal to" },
    ["=="] = { " == ", "spaced equality" },
    ["=>"] = { " => ", "spaced arrow operator" },
    ["{<space>"] = { "{  }<left><left>", "spaced curly braces" },
    ["[<space>"] = { "[  ]<left><left>", "spaced square braces" },
  },
  c = {},
  v = {
    ["<leader>/sa"] = { 'y:%s/<C-R>"//g<left><left>', "Replace selection on all lines." },
    ["<leader>/sc"] = { 'y:%s/<C-R>"//gc<left><left><left>', "Replace selection on all lines (with confirmation)." },
    ["<leader>/sl"] = { 'y:s/<C-R>"//g<left><left>', "Replace selection on current line." },
  },
  x = {
    ["il"] = { "g_o^", "Select inner line" },
  },
  o = {
    ["il"] = { "<cmd>:normal vil<CR>", "Text object: inner line" }
  }
}

return M
