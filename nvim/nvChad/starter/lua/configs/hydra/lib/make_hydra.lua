local Hydra = require("hydra")

local action = require("configs.hydra.lib.action")
local hint = require("configs.hydra.lib.hint")

local M = {}

local function position_at_anchor(anchor_node_info)
  if not anchor_node_info or not anchor_node_info.node then
    return
  end

  local ok, err = pcall(function()
    if anchor_node_info.bufnr and vim.api.nvim_buf_is_valid(anchor_node_info.bufnr) then
      vim.api.nvim_set_current_buf(anchor_node_info.bufnr)
    end

    local row = (anchor_node_info.start_row or 0) + 1
    local col = anchor_node_info.start_col or 0
    vim.api.nvim_win_set_cursor(0, { row, col })
    vim.cmd("normal! zz")
  end)

  if not ok then
    vim.notify("Failed to position cursor at anchor: " .. tostring(err), vim.log.levels.WARN)
  end
end

local function resolve_section_spec(spec_or_fn)
  local spec = spec_or_fn

  if type(spec_or_fn) == "function" then
    local ok, result = pcall(spec_or_fn)
    if not ok then
      vim.notify("Failed to resolve dynamic Hydra section: " .. tostring(result), vim.log.levels.ERROR)
      return nil, true
    end
    spec = result
  end

  if type(spec) == "table" and spec.__abort_open == true then
    local message = spec.__abort_message or "Hydra could not be opened for the current context."
    vim.notify(message, vim.log.levels.WARN)
    return nil, true
  end

  if type(spec) ~= "table" then
    vim.notify("Invalid Hydra section spec. Expected table.", vim.log.levels.ERROR)
    return nil, true
  end

  return spec, false
end

local function resolve_sections(spec)
  local resolved = {}

  for _, section_spec in ipairs(spec.sections or {}) do
    local section, should_abort = resolve_section_spec(section_spec)
    if should_abort then
      return nil
    end

    if section ~= nil then
      resolved[#resolved + 1] = section
    end
  end

  return resolved
end

local function append_action_head_for_item(heads, item)
  if type(item._resolved_key) ~= "string" then
    return
  end
  heads[#heads + 1] = {
    item._resolved_key,
    function()
      action.execute(item)
    end,
    { exit = true, desc = false },
  }
end

local function build_heads(rendered, on_toggle_hint)
  local heads = {}

  for _, section in ipairs(rendered.sections) do
    for _, item in ipairs(section.items or {}) do
      append_action_head_for_item(heads, item)
    end
  end

  heads[#heads + 1] = { "q", nil, { exit = true, desc = false } }
  heads[#heads + 1] = { "<Esc>", nil, { exit = true, desc = false } }
  heads[#heads + 1] = {
    "?",
    function()
      if type(on_toggle_hint) == "function" then
        on_toggle_hint()
      end
    end,
    { exit = true, desc = false },
  }

  return heads
end

function M.open(spec, opts)
  opts = type(opts) == "table" and opts or {}
  if type(spec.merge_ui_opts) == "function" then
    opts = spec.merge_ui_opts(spec, opts)
  end
  local show_hint = opts.show_hint ~= false
  local sections = resolve_sections(spec)
  if sections == nil or #sections == 0 then
    return
  end

  if spec.anchor_node_info then
    position_at_anchor(spec.anchor_node_info)
  end

  local rendered = hint.build(sections, {
    title = spec.title,
    footer = {
      left = "[?] toggle hint",
      right = "[q]/[Esc] exit",
    },
  })
  local heads = build_heads(rendered, function()
    vim.schedule(function()
      M.open(spec, {
        show_hint = not show_hint,
      })
    end)
  end)

  local hydra = Hydra({
    name = spec.title or "Hydra",
    mode = "n",
    hint = show_hint and rendered.hint or false,
    heads = heads,
    config = {
      color = "red",
      invoke_on_body = false,
      hint = {
        position = "middle",
        border = "rounded",
      },
    },
  })

  hydra:activate()
end

local HydraHandle = {}

function HydraHandle:open(opts_override)
  local base = vim.tbl_extend("force", {}, self._default_hydra_opts)
  local merged = vim.tbl_extend("force", base, type(opts_override) == "table" and opts_override or {})
  M.open(self._spec, merged)
end

return setmetatable(M, {
  __call = function(_, spec, default_hydra_opts)
    default_hydra_opts = type(default_hydra_opts) == "table" and default_hydra_opts or {}
    return setmetatable({
      _spec = spec,
      _default_hydra_opts = default_hydra_opts,
    }, { __index = HydraHandle })
  end,
})
