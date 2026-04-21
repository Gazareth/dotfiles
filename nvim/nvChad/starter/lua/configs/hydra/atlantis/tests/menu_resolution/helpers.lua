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

function M.navigate_section(spec)
  return M.find_section(spec, column_titles.navigate())
end

function M.interact_section(spec)
  return M.find_section(spec, column_titles.interact())
end

function M.create_section(spec)
  return M.find_section(spec, column_titles.create())
end

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

function M.navigate_schema_key_set()
  local navigate_cfg = require("configs.hydra.atlantis.schema.menu").navigate
  local allowed = {}
  for _, row in ipairs(navigate_cfg.items or {}) do
    if type(row.key) == "string" and row.key ~= "" then
      allowed[row.key] = true
    end
  end
  local nh = navigate_cfg.next_highest
  if type(nh) == "table" and type(nh.key) == "string" and nh.key ~= "" then
    allowed[nh.key] = true
  end
  return allowed
end

function M.find_item_by_key(items, key)
  for _, it in ipairs(items or {}) do
    if it.key == key then
      return it
    end
  end
  return nil
end

function M.labels_blob(items)
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

M.jump_schema_key_set = M.navigate_schema_key_set

function M.jump_items_with_key(items)
  local out = {}
  for _, it in ipairs(items or {}) do
    if type(it) == "table" and type(it.key) == "string" and it.key ~= "" then
      out[#out + 1] = it
    end
  end
  return out
end

local menu_actions_schema = require("configs.hydra.atlantis.schema.actions.menu")

function M.action_ids_to_labels(render_spec)
  local map = {}
  for _, r in ipairs(render_spec.action_rows or {}) do
    if type(r) == "table" and type(r.action_id) == "string" then
      map[r.action_id] = r.label
    end
  end
  return map
end

function M.expected_menu_label(action_id)
  local spec = menu_actions_schema.action_menu_item[action_id]
  if type(spec) == "table" and type(spec.label) == "string" then
    return spec.label
  end
  return nil
end

function M.quoted_fragment(label)
  if type(label) ~= "string" then
    return nil
  end
  local _, b = label:match('^(.-) %- "(.*)"$')
  if not b then
    return nil
  end
  return b
end

--- Floating hint string: same title + default footer merge as `configs.hydra.lib.make_hydra` before Hydra opens.
function M.build_atlantis_hint_string(spec)
  local hint_mod = require("configs.hydra.lib.hint")
  local hint_opts = vim.tbl_extend("force", {
    title = spec.title,
    footer = {
      left = "[?] toggle hint",
      right = "[q]/[Esc] exit",
    },
  }, type(spec.hint_opts) == "table" and spec.hint_opts or {})
  return hint_mod.build(spec.sections or {}, hint_opts).hint
end

return M
