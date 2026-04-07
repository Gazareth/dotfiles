local Hydra = require("hydra")

local action = require("configs.hydra.common.action")
local hint = require("configs.hydra.common.hint")

local M = {}

local function resolve_section_spec(spec_or_fn)
  local spec = spec_or_fn

  if type(spec_or_fn) == "function" then
    local ok, result = pcall(spec_or_fn)
    if not ok then
      vim.notify("Failed to resolve dynamic menu section: " .. tostring(result), vim.log.levels.ERROR)
      return nil, true
    end
    spec = result
  end

  if type(spec) == "table" and spec.__abort_open == true then
    local message = spec.__abort_message or "Menu could not be opened for the current context."
    vim.notify(message, vim.log.levels.WARN)
    return nil, true
  end

  if type(spec) ~= "table" then
    vim.notify("Invalid menu section spec. Expected table.", vim.log.levels.ERROR)
    return nil, true
  end

  return spec, false
end

local function resolve_sections(menu_spec)
  local resolved = {}

  for _, section_spec in ipairs(menu_spec.sections or {}) do
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

local function build_heads(rendered)
  local heads = {}

  for _, section in ipairs(rendered.sections) do
    for _, item in ipairs(section.items or {}) do
      if type(item._resolved_key) == "string" then
        heads[#heads + 1] = {
          item._resolved_key,
          function()
            action.execute(item)
          end,
          { exit = true, desc = false },
        }
      end
    end
  end

  heads[#heads + 1] = { "q", nil, { exit = true, desc = false } }
  heads[#heads + 1] = { "<Esc>", nil, { exit = true, desc = false } }

  return heads
end

function M.open(menu_spec)
  local sections = resolve_sections(menu_spec)
  if sections == nil or #sections == 0 then
    return
  end

  -- Hint render options
  local rendered = hint.build(sections, {
    title = menu_spec.title,
  })
  local heads = build_heads(rendered)

  local hydra = Hydra({
    name = menu_spec.title or "Actions",
    mode = "n",
    hint = rendered.hint,
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

return M
