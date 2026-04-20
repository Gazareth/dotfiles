-- Helpers for nav / outline (container) mode tests.

local column_titles = require("configs.hydra.atlantis.menu.column_titles")

local M = {}

function M.find_section(spec, title)
  for _, sec in ipairs(spec.sections or {}) do
    if type(sec) == "table" and sec.title == title then
      return sec
    end
  end
  return nil
end

function M.jump_section(spec)
  return M.find_section(spec, column_titles.jump())
end

function M.navigate_section(spec)
  return M.find_section(spec, column_titles.navigate())
end

--- Map key string -> true for keyed menu rows (Hydra heads).
function M.collect_keys(items)
  local keys = {}
  for _, it in ipairs(items or {}) do
    if type(it.key) == "string" and it.key ~= "" then
      keys[it.key] = true
    end
  end
  return keys
end

function M.keys_list(keys_map)
  local out = {}
  for k in pairs(keys_map) do
    out[#out + 1] = k
  end
  table.sort(out)
  return out
end

--- All keys declared on jump schema rows (navigation + relation + context slots).
function M.jump_schema_key_set()
  local jump_cfg = require("configs.hydra.atlantis.schema.menu").jump
  local allowed = {}
  for _, row in ipairs(jump_cfg.items or {}) do
    if type(row.key) == "string" and row.key ~= "" then
      allowed[row.key] = true
    end
  end
  return allowed
end

function M.find_jump_item_by_key(items, key)
  for _, it in ipairs(items or {}) do
    if it.key == key then
      return it
    end
  end
  return nil
end

--- Concatenate navigable labels (headings + row labels) for substring search.
function M.navigate_labels_blob(items)
  local parts = {}
  for _, it in ipairs(items or {}) do
    if type(it.label) == "string" and it.label ~= "" then
      parts[#parts + 1] = it.label
    end
    if type(it.heading) == "string" and it.heading ~= "" then
      parts[#parts + 1] = it.heading
    end
  end
  return table.concat(parts, "\n")
end

function M.stub_atlantis_open()
  local atlantis = require("configs.hydra.atlantis")
  local orig = atlantis.open
  local captured = {}
  atlantis.open = function(menu_opts, hydra_opts)
    captured[#captured + 1] = {
      menu_opts = menu_opts,
      hydra_opts = hydra_opts,
    }
  end
  return captured, function()
    atlantis.open = orig
  end
end

return M
