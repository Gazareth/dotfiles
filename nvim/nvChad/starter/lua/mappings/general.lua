local current_file_dir = require("functions.mappings").current_file_dir
local switch_window = require("functions.mappings").switch_window
local explore_current_file_dir = require("functions.mappings").explore_current_file_dir
local return_to_dashboard = require("functions.mappings").return_to_dashboard
local flick_command = require("functions.scroll-flick").flick_command

local M = {}

M.general = {
    [{"n", "i"}] = {
        ["<C-Tab>"] = {"<cmd> tabnext <CR>", "Switch to next tab"},
        ["<C-S-Tab>"] = {"<cmd> tabprev <CR>", "Switch to previous tab"},
        -- cycle through buffers
        ["<leader><TAB>"] = {"<cmd> bnext <CR>", "Next buffer"},
        ["<leader><S-TAB>"] = {"<cmd> bprevious <CR>", "Prev buffer"},
        ["<leader>x"] = {"<cmd> bd <CR>", "Delete buffer"},
        ["<leader>ww"] = {function()
            local node = vim.treesitter.get_node()
            if not node then
                return
            end
            local start_row, start_col = node:start()
            local end_row, end_col = node:end_()
            local node_info = {
                type = node:type(),
                start_row = start_row,
                start_col = start_col,
                end_row = end_row,
                end_col = end_col
            }
            print(vim.inspect(node_info))

            if node:type() == "function_declaration" or node:type() == "function" then
                -- Different languages have different structure
                -- Lua: function_declaration has a name as first child
                local name_node = node:named_child(0)
                local func_name = vim.treesitter.get_node_text(name_node, bufnr)
                print("Function name: " .. func_name)
            end

        end, "Print current treesitter node"}
    },
    n = {
        -- Meta stuff
        ["<leader>lzs"] = {"<cmd> Lazy sync <CR>", "Sync plugins"},
        ["<leader>cd"] = {"<cmd> :cd %:p:h <CR>", "Set directory to current file's"},
        ["<leader>ycd"] = {function()
            vim.fn.setreg("*", current_file_dir())
        end, "Yank current file directory to clipboard"},
        ["<leader>ecd"] = {explore_current_file_dir, "Open explorer at current file's directory (windows)"},

        ["ZW"] = {"<cmd> wa <CR>", "Save all files"},
        ["ZD"] = {return_to_dashboard(false), "Return to project dashboard"},
        ["ZDQ"] = {return_to_dashboard(true), "Return to dashboard"},
        ["ZA"] = {"<cmd> wa | qa <CR>", "Save all files then quit vim"},
        ["Zs"] = {"<cmd>so %<CR>", "Source current file"},

        -- Tab/window switching
        ["<C-w><C-v>"] = {"<cmd> vert sb # <CR>", "Open a vertical split of current and previous buffer"},
        ["<C-w><C-t>"] = {"<cmd> tabc <CR>", "Close tab"},
        ["<C-t>"] = {"<cmd> tabnew | Alpha <CR>", "Open new tab and run Alpha (dashboard)"},
        ["<Tab>"] = {"<cmd> wincmd w <CR>", "Switch to next window"},
        ["<S-Tab>"] = {"<cmd> wincmd W <CR>", "Switch to previous window"},

        -- Scrolling
        ["<C-S-g>"] = {flick_command("2.15"), "Jump ↑ by ½ screen"},
        ["<C-S-h>"] = {flick_command("-2.15"), "Jump ↓ by ½ screen"},
        ["<C-S-j>"] = {flick_command("0.75"), "Jump ↑ by ¼ screen"},
        ["<C-S-k>"] = {flick_command("-0.75"), "Jump ↓ by ¼ screen"},

        -- Help with editing/writing text
        ["Y"] = {"^vg_", "select line (excluding EOL character)"},
        ["<leader><enter>"] = {":call feedkeys('] [ i')<cr>", "Insert mode with new line above and below."},

        ["]d"] = {function()
            vim.diagnostic.goto_next()
        end, "Go to next diagnostic issue"},
        ["[d"] = {function()
            vim.diagnostic.goto_prev()
        end, "Go to previous diagnostic issue"}
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
        ["<space> ="] = {" = ", "spaced equals"},
        ["<space> >="] = {" >= ", "spaced greater than or equal to"},
        ["<space> <="] = {" <= ", "spaced less than or equal to"},
        ["<space> =="] = {" == ", "spaced equality"},
        ["<space>=>"] = {" => ", "spaced arrow operator"},
        ["{<space>"] = {"{  }<left><left>", "spaced curly braces"},
        ["[<space>"] = {"[  ]<left><left>", "spaced square braces"}
    },
    c = {},
    v = {
        ["<leader>/sa"] = {'y:%s/<C-R>"//g<left><left>', "Replace selection on all lines."},
        ["<leader>/sc"] = {'y:%s/<C-R>"//gc<left><left><left>', "Replace selection on all lines (with confirmation)."},
        ["<leader>/sl"] = {'y:s/<C-R>"//g<left><left>', "Replace selection on current line."}
    },
    x = {
        ["il"] = {"g_o^", "Select inner line"}
    },
    o = {
        ["il"] = {"<cmd>:normal vil<CR>", "Text object: inner line"}
    }
}

return M
