local function print_tree(nodes, indent)
  for _, node in ipairs(nodes) do
    if node.is_leaf then
      local parts = {}
      for p in node.name:gmatch("(.-) %- ") do
        table.insert(parts, p)
      end
      local last_part = node.name:match(".* %- (.*)") or node.name
      
      local cur_indent = indent
      for _, p in ipairs(parts) do
        print(string.format("%s%s", cur_indent, p))
        cur_indent = cur_indent .. "  "
      end

      local status = node.ok and "o" or "x"
      local name = last_part == "" and "<test>" or last_part
      print(string.format("%s%s  %s", cur_indent, status, name))
    else
      local heading = node.heading:match("^(.-)%s*%-?%s*$") or node.heading
      if heading == "" then heading = node.heading end
      
      local parts = {}
      for p in heading:gmatch("(.-) %- ") do
        table.insert(parts, p)
      end
      local last_part = heading:match(".* %- (.*)") or heading

      local cur_indent = indent
      for _, p in ipairs(parts) do
        print(string.format("%s%s", cur_indent, p))
        cur_indent = cur_indent .. "  "
      end
      
      print(string.format("%s%s", cur_indent, last_part))
      print_tree(node.children, cur_indent .. "  ")
    end
  end
end

local nodes = {
  {
    is_leaf = false,
    heading = "Main grid - Navigate - Sibling",
    children = {
      { is_leaf = true, name = "wrap-around - last anchor", ok = true },
      { is_leaf = true, name = "something else", ok = true }
    }
  },
  {
    is_leaf = true, name = "Navigate - Column exposes keys", ok = true
  }
}

print_tree(nodes, "")
