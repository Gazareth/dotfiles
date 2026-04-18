local targets = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.targets")
local group_heading = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.jump_row_group_heading")
local jump_row_labels = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.jump_row_labels")

local context_rows = {}

local function append_neighbor(items, row_spec, direction, candidate_index, candidate, jump_labels)
  local default_key = direction == "higher" and "h" or "l"
  local default_icon = direction == "higher" and "⬆" or "⬇"
  items[#items + 1] = {
    key = row_spec and row_spec.key or default_key,
    icon = row_spec and row_spec.icon or default_icon,
    label = jump_row_labels.with_quoted(
      jump_row_labels.context(direction),
      jump_row_labels.neighbor(candidate_index, candidate, jump_labels)
    ),
    action = targets.jump_action(candidate and candidate.node_info),
    _atlantis_reopen_anchor_mode = true,
  }
end

function context_rows.append(items, candidates, selected_index, jump_labels)
  if type(selected_index) ~= "number" then
    return
  end

  local higher_spec = jump_row_labels.spec("higher")
  local lower_spec = jump_row_labels.spec("lower")
  local has_context_heading = false

  if selected_index < #candidates then
    if not has_context_heading then
      group_heading.append(items, "context")
      has_context_heading = true
    end
    append_neighbor(items, higher_spec, "higher", selected_index + 1, candidates[selected_index + 1], jump_labels)
  end

  if selected_index > 1 then
    if not has_context_heading then
      group_heading.append(items, "context")
      has_context_heading = true
    end
    append_neighbor(items, lower_spec, "lower", selected_index - 1, candidates[selected_index - 1], jump_labels)
  end
end

return context_rows
