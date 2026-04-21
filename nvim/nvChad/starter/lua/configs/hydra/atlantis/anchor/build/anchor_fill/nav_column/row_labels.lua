local labels = require("configs.hydra.atlantis.anchor.build.anchor_fill.nav_column.labels")
local menu_schema = require("configs.hydra.atlantis.schema.menu")

local navigate_cfg = menu_schema.navigate

local M = {}

-- Row label helpers (from jump_row_labels)

function M.relation(relation)
  local t = navigate_cfg.relation_phrase and navigate_cfg.relation_phrase[relation]
  if type(t) == "string" then
    return t
  end
  return "To " .. string.gsub(relation or "target", "_", " ")
end

function M.with_quoted(phrase, quoted)
  if type(quoted) ~= "string" or quoted == "" then
    return phrase
  end
  return string.format("%s - %s", phrase, quoted)
end

function M.spec(which)
  for _, row in ipairs(navigate_cfg.items or {}) do
    if row.context == which then
      return row
    end
  end
  return nil
end

function M.nav_context_higher_in_chain()
  return navigate_cfg.nav_context.higher_in_chain
end

function M.neighbor(candidate_index, candidate, jump_labels)
  if type(candidate) ~= "table" or type(candidate.node_info) ~= "table" then
    return nil
  end
  local q = jump_labels and jump_labels[candidate_index]
  if type(q) == "string" and q ~= "" then
    return q
  end
  return labels.quoted_for_node(candidate.node_info, candidate.parsed)
end

-- Group heading helpers (from jump_row_group_heading)

function M.append(items, group_id)
  local label = navigate_cfg.group_labels and navigate_cfg.group_labels[group_id]
  if type(label) ~= "string" or label == "" then
    return
  end
  items[#items + 1] = { separator = true }
  items[#items + 1] = { separator = true, label = label }
  items[#items + 1] = { separator = true }
end

function M.append_label(items, label)
  if type(label) ~= "string" or label == "" then
    return
  end
  items[#items + 1] = { separator = true }
  items[#items + 1] = { separator = true, label = label }
  items[#items + 1] = { separator = true }
end

return M
