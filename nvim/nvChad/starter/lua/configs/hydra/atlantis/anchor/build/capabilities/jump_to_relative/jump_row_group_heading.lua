local menu_schema = require("configs.hydra.atlantis.schema.menu")

local jump_cfg = menu_schema.jump

local jump_row_group_heading = {}

function jump_row_group_heading.append(items, group_id)
  local label = jump_cfg.group_labels and jump_cfg.group_labels[group_id]
  if type(label) ~= "string" or label == "" then
    return
  end
  items[#items + 1] = { separator = true }
  items[#items + 1] = { separator = true, label = label }
  items[#items + 1] = { separator = true }
end

return jump_row_group_heading
