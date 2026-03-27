local M = {}

M.cellular_automation = {
  n = {
    ["<leader>fml"] = { "<cmd>CellularAutomaton make_it_rain<CR>", "Make it rain (FML)" },
  },
}

M.focus = {
  n = {
    ["<F3>"] = { "<cmd> FocusMaximise <CR>", "Focus current window" },
  },
}

M.grug_far = {
  n = {
    ["<leader>gf"] = { "<cmd> GrugFar <CR>", "GrugFar: Find and Replace" },
  },
}

M.leap = {
  [{ "n", "x", "o" }] = {
    ["-"] = { "<Plug>(leap-forward-to)", "Leap: forward-to" },
    ["+"] = { "<Plug>(leap-backward-to)", "Leap: backward-to" },
    ["gl"] = { "<Plug>(leap-cross-window)", "Leap: cross-window" },
  },
  [{ "x", "o" }] = {
    ["g-"] = { "<Plug>(leap-forward-till)", "Leap: forward-till" },
    ["g+"] = { "<Plug>(leap-backward-till)", "Leap: backward-till" },
  }
}

M.leap_ast = {
  [{ 'n', 'x', 'o' }] = { ["<A-n>"] = { function() require("leap-ast").leap() end, "Leap: AST node" } },
}

M.lspconfig = {
  n = {
    ["<leader>fmt"] = {
      function()
        vim.lsp.buf.format { async = true }
      end,
      "lsp formatting",
    },
  },
}

M.namu = {
  n = {
    ["<leader>ew"] = {  ":Namu symbols<cr>", "Namu - LSP Symbols" },
    ["<leader>sw"] = {  ":Namu workspace<cr>", "Namu - Workspace LSP Symbols" },
  }
}

local tcpresent, tree_climber = pcall(require, "tree-climber")

if tcpresent then
  local tc_func = function(func_name, opts)
    return function() return tree_climber[func_name](opts) end
  end
  local tc_highlight = function(func_name) return tc_func(func_name, { highlight = true, skip_comments = true }) end
  local tc_skipcomments = function(func_name) return tc_func(func_name, { skip_comments = true }) end

  M.tree_climber = {
    [{ "n", "v", "o" }] = {
      ["<A-k>"] = { tc_highlight("goto_parent"), "Go to parent Treesitter node" },
      ["<A-j>"] = { tc_highlight("goto_child"), "Go to child Treesitter node" },
      ["<A-l>"] = { tc_skipcomments("goto_next"), "Go to next Treesitter node" },
      ["<A-h>"] = { tc_skipcomments("goto_prev"), "Go to previous Treesitter node" },
    },
    [{ "v", "o" }] = {
      ["ie"] = { tree_climber.select_node, "Select inside treesitter node" },
    },
    ["n"] = {
      ["<C-l>"] = { tree_climber.swap_next, "Swap with next Treesitter node" },
      ["<C-h>"] = { tree_climber.swap_prev, "Swap with previous Treesitter node" },
      ["<C-H>"] = { tree_climber.highlight_node, "Highlight Treesitter node" },
    }
  }
end

M.trouble = {
  n = {
    ["<leader>tc"] = { "<cmd> TroubleToggle <CR>", "Toggle Trouble (Diagnostics)" },
  },
}

-- M.wordmotion = {
--   [{"n", "x", "o"}] = {
--     ["<A-w>"] = {"<Plug>WordMotion_w", "WordMotion: Move 1 word forwards."},
--     ["<A-b>"] = {"<Plug>WordMotion_b", "WordMotion: Move 1 word backwards."},
--     ["<A-e>"] = {"<Plug>WordMotion_e", "WordMotion: Move to next end of word."},
--     ["<A-g><A-e>"] = {"<Plug>WordMotion_ge", "WordMotion:<C-S-T> Move to end of previous word."},
--   },
--   [{"x", "o"}] = {
--     ["<A-i><A-w>"] = { "<Plug>WordMotion_iw", "WordMotion: Inner word"},
--     ["<A-a><A-w>"] = { "<Plug>WordMotion_aw", "WordMotion: Around word"},
--   }
-- }

M.undoquit = {
  n = {
    ["<C-S-T>"] = { "<cmd> Undoquit <CR>", "Undo last quit window" },
  },
}

M.zen_mode = {
  n = {
    ["<S-F3>"] = { "<cmd> ZenMode <CR>", 'Toggle "Total Zen" mode' },
  },
}

return M
