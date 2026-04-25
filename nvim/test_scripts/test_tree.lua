local function raw_lcp(a, b)
  local n = math.min(#a, #b)
  for i = 1, n do
    if a:sub(i, i) ~= b:sub(i, i) then return a:sub(1, i - 1) end
  end
  return a:sub(1, n)
end

local function word_lcp2(a, b)
  if a == "" or b == "" then return "" end
  local p = raw_lcp(a, b)
  if p == a or p == b then return p end
  return p:match("^(.*) ") or ""
end

local function strip_prefix(s, prefix)
  if prefix == "" then return s end
  local rest = s:sub(#prefix + 1)
  return rest:match("^%s*(.-)%s*$") or rest
end

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
      print(string.format("%s%s  %s", indent, status, name))
    else
      local heading = node.heading:match("^(.-)%s*%-?%s*$") or node.heading
      if heading == "" then heading = node.heading end
      print(string.format("%s%s", indent, heading))
      print_tree(node.children, indent .. "  ")
    end
  end
end

local items = {
  {name="[Standard mode] Footer standard mode uses default Hydra footer strings", ok=true},
  {name="[Standard mode] Footer container mode uses the same default footer strings", ok=true},
  {name="[Standard mode] Title Assignment uses Assignment badge for local binding", ok=true},
  {name="[Standard mode] Title Boolean expression builds a bracketed title", ok=true},
  {name="[Standard mode] Main grid - Navigate - Sibling - wrap-around last anchor shows To first", ok=true},
  {name="[Standard mode] Main grid - Navigate - Sibling - wrap-around last anchor first action", ok=true},
}

local tree = build_tree(items)
print_tree(tree, "")
