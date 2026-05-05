local M = {}

-- Returns a function that jumps to the first non-comment named sibling following the
-- anchor comment node, or nil if no such sibling exists (which omits the menu row).
--
-- Comments are `extra` nodes in Lua treesitter: they appear via child() but not always
-- via named_child(), so we iterate all children and use named() to distinguish.
function M.build(ctx)
  local node_info = type(ctx) == "table" and ctx.node_info or nil
  local node = node_info and node_info.node
  if not node then return nil end

  local parent = node:parent()
  if not parent then return nil end

  local found_self = false
  local target = nil
  for i = 0, parent:child_count() - 1 do
    local child = parent:child(i)
    if found_self and child:type() ~= "comment" and child:named() then
      target = child
      break
    end
    if child:id() == node:id() then
      found_self = true
    end
  end

  if not target then return nil end

  local row, col = target:start()
  return function()
    pcall(vim.api.nvim_win_set_cursor, 0, { row + 1, col })
  end
end

return M
