local menu_labels = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.menu_labels")
local menu_schema = require("configs.hydra.atlantis.schema.menu")

local jump_cfg = menu_schema.jump

local jump_row_labels = {}

function jump_row_labels.relation(relation)
  local t = jump_cfg.relation_phrase and jump_cfg.relation_phrase[relation]
  if type(t) == "string" then
    return t
  end
  return "To " .. string.gsub(relation or "target", "_", " ")
end

function jump_row_labels.with_quoted(phrase, quoted)
  if type(quoted) ~= "string" or quoted == "" then
    return phrase
  end
  return string.format("%s - %s", phrase, quoted)
end

function jump_row_labels.spec(which)
  for _, row in ipairs(jump_cfg.items or {}) do
    if row.context == which then
      return row
    end
  end
  return nil
end

function jump_row_labels.context(which)
  local t = jump_cfg.context_phrase and jump_cfg.context_phrase[which]
  if type(t) == "string" then
    return t
  end
  return which == "higher" and "To higher in context" or "To lower in context"
end

function jump_row_labels.neighbor(candidate_index, candidate, jump_labels)
  if type(candidate) ~= "table" or type(candidate.node_info) ~= "table" then
    return nil
  end
  local q = jump_labels and jump_labels[candidate_index]
  if type(q) == "string" and q ~= "" then
    return q
  end
  return menu_labels.quoted_for_node(candidate.node_info, candidate.parsed)
end

return jump_row_labels
