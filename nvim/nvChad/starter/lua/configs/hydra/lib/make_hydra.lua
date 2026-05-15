local Hydra = require("hydra")

local action = require("configs.hydra.lib.action")
local hint = require("configs.hydra.lib.hint")

local M = {}

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
  local run = function()
    action.execute(item)
  end
  heads[#heads + 1] = {
    item._resolved_key,
    run,
    { exit = true, desc = false },
  }
  if type(item.key_alias) == "string" and item.key_alias ~= "" then
    heads[#heads + 1] = {
      item.key_alias,
      run,
      { exit = true, desc = false },
    }
  end
end

--- Toggle floating hint on the *current* hydra only (no second Hydra / no M.open recursion).
local function toggle_hint_window()
  local h = _G.Hydra
  if not h or type(h.hint) ~= "table" then
    return
  end
  if h.__hint_window_hidden then
    pcall(function()
      h.hint:show()
    end)
    h.__hint_window_hidden = false
  else
    pcall(function()
      h.hint:close()
    end)
    h.__hint_window_hidden = true
  end
end

local function build_heads(rendered, spec)
  local heads = {}

  for _, section in ipairs(rendered.sections) do
    for _, item in ipairs(section.items or {}) do
      append_action_head_for_item(heads, item)
    end
  end

  for _, actions in ipairs(rendered.header_actions or {}) do
    for _, item in ipairs(actions) do
      append_action_head_for_item(heads, item)
    end
  end

  heads[#heads + 1] = { "q", nil, { exit = true, desc = false } }
  heads[#heads + 1] = { "<Esc>", nil, { exit = true, desc = false } }
  -- exit = false: stay in hydra; only hide/show the hint window (avoids reopen race / double hint).
  heads[#heads + 1] = {
    "?",
    toggle_hint_window,
    { exit = false, desc = false },
  }

  for _, head in ipairs(type(spec) == "table" and spec.extra_heads or {}) do
    heads[#heads + 1] = head
  end

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

  local hint_opts = vim.tbl_extend("force", {
    title = spec.title,
    common_actions = spec.common_actions,
    header_actions = spec.header_actions,
    footer = {
      left = "[?] toggle hint",
      right = "[q]/[Esc] exit",
    },
  }, type(spec.hint_opts) == "table" and spec.hint_opts or {})
  local rendered = hint.build(sections, hint_opts)

  -- Always use ManualWindow hint text so hint:close() / hint:show() can restore the same UI.
  local hydra = Hydra({
    name = spec.title or "Hydra",
    mode = "n",
    hint = rendered.hint,
    heads = build_heads(rendered, spec),
    config = {
      color = "red",
      invoke_on_body = false,
      hint = {
        position = "bottom",
        border = "rounded",
      },
    },
  })

  -- Set on_exit after construction to bypass hydra's setfenv/tbl_deep_extend
  -- crash that occurs when on_exit captures _G via upvalues.
  -- Also reset eventignore: Hydra sets it to "all" during operation and may
  -- not restore it if our post-construction on_exit bypasses its normal cleanup path.
  local user_on_exit = spec.on_exit
  hydra.config.on_exit = function()
    vim.o.eventignore = ""
    if type(user_on_exit) == "function" then
      user_on_exit()
    end
  end

  hydra:activate()

  if not show_hint then
    hydra.__hint_window_hidden = true
    pcall(function()
      hydra.hint:close()
    end)
  else
    hydra.__hint_window_hidden = false
  end
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
