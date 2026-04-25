local function build_tree(items)
  if #items == 0 then return {} end
  if #items == 1 then return { { is_leaf = true, name = items[1].name, ok = items[1].ok } } end

  local lcp_all = items[1].name
  for i = 2, #items do
    lcp_all = word_lcp2(lcp_all, items[i].name)
  end

  if lcp_all ~= "" then
    local sub_items = {}
    for _, item in ipairs(items) do
      table.insert(sub_items, { name = strip_prefix(item.name, lcp_all), ok = item.ok })
    end
    return { { is_leaf = false, heading = lcp_all, children = build_tree(sub_items) } }
  end

  local groups = {}
  local i = 1
  while i <= #items do
    if i == #items then
      table.insert(groups, { is_leaf = true, name = items[i].name, ok = items[i].ok })
      break
    end

    local p = word_lcp2(items[i].name, items[i+1].name)
    if p ~= "" then
      local j = i + 1
      local current_p = p
      while j < #items do
        local next_p = word_lcp2(current_p, items[j+1].name)
        if next_p == "" then break end
        current_p = next_p
        j = j + 1
      end
      local sub_items = {}
      for k = i, j do
        table.insert(sub_items, { name = strip_prefix(items[k].name, current_p), ok = items[k].ok })
      end
      table.insert(groups, { is_leaf = false, heading = current_p, children = build_tree(sub_items) })
      i = j + 1
    else
      table.insert(groups, { is_leaf = true, name = items[i].name, ok = items[i].ok })
      i = i + 1
    end
  end
  return groups
end

local function print_tree(nodes, indent)
  for _, node in ipairs(nodes) do
    if node.is_leaf then
      local status = node.ok and "o" or "x"
      local name = node.name == "" and "<test>" or node.name
      io.write(string.format("%s%s  %s\n", indent, status, name))
    else
      local heading = node.heading:match("^(.-)%s*%-?%s*$") or node.heading
      if heading == "" then heading = node.heading end
      io.write(string.format("%s%s\n", indent, heading))
      print_tree(node.children, indent .. "  ")
    end
  end
end
