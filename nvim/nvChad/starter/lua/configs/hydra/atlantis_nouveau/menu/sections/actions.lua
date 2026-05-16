local registry         = require("configs.hydra.atlantis_nouveau.ops.registry")
local tna_action       = require("configs.hydra.atlantis_nouveau.ops.actions.ts_node_action")
local swap             = require("configs.hydra.atlantis_nouveau.ops.actions.swap_sibling")
local lsp_code_actions = require("configs.hydra.atlantis_nouveau.ops.actions.lsp_code_actions")
local refactor         = require("configs.hydra.atlantis_nouveau.ops.actions.refactor")

local M = {}

local named_nodes      = { ["function"] = true, assignment = true, parameter = true }
local structural_nodes = { ["function"] = true, call = true, loop = true, conditional = true,
                           parameter_list = true, expression_list = true }

-- Surveyor actions shown in the base strip only, not repeated here
local base_filter = { yank = true, delete = true, change = true, substitute = true, exchange = true }

function M.build(result)
  local items = {}
  local node_type = result.node and result.node.node and result.node.node.type

  local caser_loaded = vim.fn.maparg("gsc", "n") ~= ""
  local recase_shown = caser_loaded and (
    (node_type and named_nodes[node_type]) or result.node_type == "identifier"
  )

  -- ── Tier 1: Classification-specific ──────────────────────────────────────

  -- Rename (from surveyor available_actions)
  for _, action_key in ipairs(result.available_actions or {}) do
    if not base_filter[action_key] then
      local entry = registry[action_key]
      if entry then
        items[#items + 1] = {
          key    = entry.key,
          icon   = entry.icon,
          label  = entry.label,
          action = function() entry.fn(result) end,
        }
      end
    end
  end

  -- Transform (ts-node-action — label reflects what's available at this node)
  local tna_ok, tna = pcall(require, "ts-node-action")
  if tna_ok then
    local r = result.range
    local tna_actions = {}
    if r then
      local saved = vim.api.nvim_win_get_cursor(0)
      vim.api.nvim_win_set_cursor(0, { r.start_row + 1, r.start_col })
      tna_actions = tna.available_actions() or {}
      vim.api.nvim_win_set_cursor(0, saved)
    end
    local function is_named(a)
      return a.title and not a.title:lower():find("anonymous")
    end
    tna_actions = vim.tbl_filter(function(a)
      if recase_shown and a.title and a.title:lower():find("case") then return false end
      return is_named(a)
    end, tna_actions)
    local count = #tna_actions
    if count == 1 then
      items[#items + 1] = {
        key    = "T",
        icon   = "󰬪",
        label  = tna_actions[1].title,
        action = function() tna_action.run(result) end,
      }
    elseif count > 1 then
      items[#items + 1] = {
        key    = "T",
        icon   = "󰬪",
        label  = "Transform…",
        action = function() tna_action.run(result) end,
      }
    end
  end

  -- Re-case (named identifier nodes only; vim-caser is vimscript, check via keymap)
  if recase_shown then
    local entry = registry.recase
    items[#items + 1] = {
      key    = entry.key,
      icon   = entry.icon,
      label  = entry.label,
      action = function() entry.fn(result) end,
    }
  end

  -- ── Tier 2: Layout-specific ───────────────────────────────────────────────

  -- Split/Join (structural nodes + treesj loaded)
  local treesj_ok = pcall(require, "treesj")
  if treesj_ok and node_type and structural_nodes[node_type] then
    local entry = registry.split_join
    items[#items + 1] = {
      key    = entry.key,
      icon   = entry.icon,
      label  = entry.label,
      action = function() entry.fn(result) end,
    }
  end

  -- ── Tier 3: Generic (sibling-based) ──────────────────────────────────────

  local nav = result.navigation

  local before_generic = #items
  if before_generic > 0 and nav and (nav.prev_sibling or nav.next_sibling) then
    items[#items + 1] = { separator = true }
  end

  if nav and nav.prev_sibling then
    local entry = registry.swap_prev
    items[#items + 1] = {
      key    = entry.key,
      icon   = entry.icon,
      label  = entry.label,
      action = function() swap.with_prev(result) end,
    }
  end

  if nav and nav.next_sibling then
    local entry = registry.swap_next
    items[#items + 1] = {
      key    = entry.key,
      icon   = entry.icon,
      label  = entry.label,
      action = function() swap.with_next(result) end,
    }
  end

  -- ── Tier 4: Code Tools ────────────────────────────────────────────────

  local lsp_attached = next(vim.lsp.get_clients({ bufnr = result.bufnr })) ~= nil
  local refactor_ok  = pcall(require, "refactoring")
  if #items > 0 and (lsp_attached or refactor_ok) then
    items[#items + 1] = { separator = true }
  end
  if lsp_attached then
    items[#items + 1] = {
      key    = "A",
      icon   = "",
      label  = "LSP Actions",
      action = function() lsp_code_actions.run(result) end,
    }
  end

  if refactor_ok then
    items[#items + 1] = {
      key    = "R",
      icon   = "",
      label  = "Refactor",
      action = function() refactor.run(result) end,
    }
  end

  if #items == 0 then return nil end

  return { title = "Actions", items = items }
end

return M
