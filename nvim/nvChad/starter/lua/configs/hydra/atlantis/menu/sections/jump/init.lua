local build_node_info = require("configs.hydra.atlantis.anchor.probe.treesitter.node_info").build_node_info
local parse_node = require("configs.hydra.atlantis.anchor.probe")
local anchor = require("configs.hydra.atlantis.anchor")

-- Role label text
local function format_role_label(parsed)
  local raw = nil
  if type(parsed) == "table" then
    raw = parsed.node_kind or parsed.semantic_kind or parsed.node_type
  end

  raw = tostring(raw or "node")
  raw = raw:gsub("_", " ")
  return (raw:gsub("(%a)([%w_']*)", function(a, b)
    return string.upper(a) .. string.lower(b)
  end))
end

-- Node display name text
local function format_node_name(node_info, parsed)
  if type(parsed) == "table" and type(parsed.function_name) == "string" then
    local function_name = vim.trim(parsed.function_name)
    if function_name ~= "" and function_name ~= "anonymous" then
      return function_name
    end
  end

  local text = type(parsed) == "table" and parsed.text or nil
  if type(text) ~= "string" or text == "" then
    text = node_info and node_info.text or ""
  end

  text = vim.trim((text or ""):gsub("\n+", " "))
  if text == "" then
    return type(parsed) == "table" and tostring(parsed.display_name or parsed.node_type or "node") or "node"
  end

  if #text > 40 then
    text = text:sub(1, 40) .. "..."
  end

  return text
end

-- Anchor label text
local function build_anchor_label(node_info, parsed)
  local name = format_node_name(node_info, parsed)
  local role = format_role_label(parsed)
  return "[" .. role .. "] " .. name
end

-- Cursor jump action
local function jump_to_node_info(target_node_info)
  return function()
    if not target_node_info then
      return
    end

    local row = (target_node_info.start_row or 0) + 1
    local col = target_node_info.start_col or 0
    pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
  end
end

-- Related node resolver
local function resolve_target_node_info(selected_node_info, relation)
  if not selected_node_info or not selected_node_info.node then
    return nil
  end

  local node = selected_node_info.node
  local target = nil

  if relation == "parent" then
    target = node:parent()
    if not target then
      target = node:prev_named_sibling()
    end
  elseif relation == "prev_sibling" then
    target = node:prev_named_sibling()
  elseif relation == "next_sibling" then
    target = node:next_named_sibling()
  elseif relation == "child" then
    target = node:named_child(0)
  end

  if not target then
    return nil
  end

  return build_node_info({
    bufnr = selected_node_info.bufnr,
    node = target,
  })
end

-- Jump row builder
local function build_target_jump_item(key, icon, target_node_info)
  if not target_node_info then
    return nil
  end

  local target_parsed = parse_node(target_node_info)
  return {
    key = key,
    icon = icon,
    label = build_anchor_label(target_node_info, target_parsed),
    action = jump_to_node_info(target_node_info),
  }
end

-- Jump column section
local function build_jump_column()
  local cursor_node_info = build_node_info()
  local selected_node_info = anchor.select_node_info(cursor_node_info)
  local items = {}

  local parent_target = resolve_target_node_info(selected_node_info, "parent")
  local prev_sibling_target = resolve_target_node_info(selected_node_info, "prev_sibling")
  local next_sibling_target = resolve_target_node_info(selected_node_info, "next_sibling")
  local child_target = resolve_target_node_info(selected_node_info, "child")

  -- Parent child group
  items[#items + 1] = { separator = true }
  items[#items + 1] = {
    separator = true,
    label = " ↥ Parent / Child",
  }
  items[#items + 1] = { separator = true }

  local parent_item = build_target_jump_item("n", "⬆", parent_target)
  if parent_item then
    items[#items + 1] = parent_item
  end

  local child_item = build_target_jump_item("y", "⬇", child_target)
  if child_item then
    items[#items + 1] = child_item
  end

  -- Sibling group
  items[#items + 1] = { separator = true }
  items[#items + 1] = {
    separator = true,
    label = " ↔ Sibling",
  }
  items[#items + 1] = { separator = true }

  local prev_item = build_target_jump_item("m", "⬅", prev_sibling_target)
  if prev_item then
    items[#items + 1] = prev_item
  end

  local next_item = build_target_jump_item("t", "➡", next_sibling_target)
  if next_item then
    items[#items + 1] = next_item
  end

  local candidates = anchor.get_candidates(cursor_node_info)
  local selected_index = anchor.find_candidate_index(candidates, selected_node_info)

  -- Context group
  local has_context_items = false
  if type(selected_index) == "number" then
    if selected_index < #candidates then
      local higher = candidates[selected_index + 1]
      local higher_parsed = higher and parse_node(higher.node_info) or nil
      if not has_context_items then
        items[#items + 1] = { separator = true }
        items[#items + 1] = {
          separator = true,
          label = " ⇧ Context",
        }
        items[#items + 1] = { separator = true }
        has_context_items = true
      end
      items[#items + 1] = {
        key = "h",
        icon = "⬆",
        label = build_anchor_label(higher and higher.node_info, higher_parsed),
        action = jump_to_node_info(higher and higher.node_info),
      }
    end

    if selected_index > 1 then
      local lower = candidates[selected_index - 1]
      local lower_parsed = lower and parse_node(lower.node_info) or nil
      if not has_context_items then
        items[#items + 1] = { separator = true }
        items[#items + 1] = {
          separator = true,
          label = " ⇧ Context",
        }
        items[#items + 1] = { separator = true }
        has_context_items = true
      end
      items[#items + 1] = {
        key = "l",
        icon = "⬇",
        label = build_anchor_label(lower and lower.node_info, lower_parsed),
        action = jump_to_node_info(lower and lower.node_info),
      }
    end
  end

  return {
    title = " 󰌑 Jump",
    items = items,
  }
end

return build_jump_column
