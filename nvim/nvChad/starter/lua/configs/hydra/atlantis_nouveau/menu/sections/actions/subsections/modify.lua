local lib      = require("configs.hydra.atlantis_nouveau.menu.sections.actions.lib")
local actions  = require("configs.hydra.atlantis_nouveau.ops.actions")
local registry = require("configs.hydra.atlantis_nouveau.ops.registry")

local item     = lib.item
local from_reg = lib.from_reg
local modify   = actions.modify

local M = {}

local structural_nodes = { ["function"]=true, call=true, loop=true, conditional=true,
                            parameter_list=true, expression_list=true }

local named_nodes    = { ["function"]=true, assignment=true, parameter=true }
local common_actions = { yank=true, delete=true, change=true, substitute=true, exchange=true }
local create_tokens  = { prepend_append_statement=true, prepend_append_item=true, prepend_append_list=true }

function M.build(result, ctx)
  local items        = {}
  local node_type    = ctx.node_type
  local lsp_attached = ctx.lsp_attached

  -- vim-caser is a vimscript plugin so it can't be pcall'd as a Lua module.
  -- Probing for its keymap is the only reliable way to know if it's loaded.
  local caser_loaded = vim.fn.maparg("gsc", "n") ~= ""
  local recase_shown = caser_loaded and (
    (node_type and named_nodes[node_type]) or result.node_type == "identifier"
  )

  -- Tier 1: Classification-specific (rename etc.)
  for _, action_key in ipairs(result.available_actions or {}) do
    if not common_actions[action_key] and not create_tokens[action_key] then
      local entry = registry[action_key]
      if entry then items[#items + 1] = from_reg(entry, result) end
    end
  end

  -- Transform (ts-node-action)
  -- "Toggle Multiline" is suppressed when treesj is present — it handles split/join.
  local treesj_ok    = pcall(require, "treesj")
  local tna_ok, tna  = pcall(require, "ts-node-action")
  if tna_ok then
    local r = result.range
    local tna_actions = {}
    if r then
      local saved = vim.api.nvim_win_get_cursor(0)
      vim.api.nvim_win_set_cursor(0, { r.start_row + 1, r.start_col })
      tna_actions = tna.available_actions() or {}
      vim.api.nvim_win_set_cursor(0, saved)
    end
    tna_actions = vim.tbl_filter(function(a)
      local t = a.title and a.title:lower()
      if not t or t:find("anonymous")                    then return false end
      if recase_shown and t:find("case")                 then return false end
      if treesj_ok    and t:find("multiline")            then return false end
      return true
    end, tna_actions)
    local count = #tna_actions
    local label = count == 1 and tna_actions[1].title or (count > 1 and "Transform…" or nil)
    if label then
      items[#items + 1] = item("T", "󰬪", label, function() modify.transform.run(result) end)
    end
  end

  -- Re-case (named identifier nodes only)
  if recase_shown then
    items[#items + 1] = from_reg(registry.recase, result)
  end

  -- Tier 2: Layout-specific
  if treesj_ok and node_type and structural_nodes[node_type] then
    items[#items + 1] = from_reg(registry.split_join, result)
  end

  return items
end

return M
