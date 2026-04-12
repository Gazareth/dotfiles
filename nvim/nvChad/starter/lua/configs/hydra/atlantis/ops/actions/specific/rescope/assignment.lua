local M = {}

local function rescope_lua(bufnr, node)
  local sr, _, er, _ = node:range()
  local lines = vim.api.nvim_buf_get_lines(bufnr, sr, er + 1, false)
  if #lines == 0 then
    return
  end
  local first = lines[1]
  if first:match("^%s*local%s+") then
    lines[1] = (first:gsub("^(%s*)local%s+", "%1"))
  else
    lines[1] = (first:gsub("^(%s*)", "%1local "))
  end
  vim.api.nvim_buf_set_lines(bufnr, sr, er + 1, false, lines)
end

local function keyword_child(decl)
  local n = decl:named_child_count()
  for i = 0, n - 1 do
    local c = decl:named_child(i)
    local t = c:type()
    if t == "const" or t == "let" or t == "var" then
      return c, t
    end
  end
  return nil, nil
end

local function cycle_js_keyword(bufnr, node)
  local kw_node, t = keyword_child(node)
  if not kw_node then
    vim.notify("Re-scope: could not find const/let/var.", vim.log.levels.WARN)
    return
  end
  local next_kw = t == "const" and "let" or t == "let" and "var" or "const"
  local sr, sc, er, ec = kw_node:range()
  vim.api.nvim_buf_set_text(bufnr, sr, sc, er, ec, { next_kw })
end

function M.build(ctx)
  local node_info = type(ctx) == "table" and ctx.node_info or nil
  local node = node_info and node_info.node or nil
  if not node then
    return nil
  end

  local bufnr = node_info.bufnr or 0
  local ft = vim.bo[bufnr].filetype

  return function()
    if ft == "lua" then
      rescope_lua(bufnr, node)
      return
    end

    if ft == "javascript" or ft == "typescript" or ft == "tsx" or ft == "jsx" then
      local nt = node:type()
      if nt == "variable_declaration" or nt == "lexical_declaration" then
        cycle_js_keyword(bufnr, node)
        return
      end
      vim.notify("Re-scope: use on a variable declaration.", vim.log.levels.WARN)
      return
    end

    vim.notify("Re-scope: not implemented for filetype " .. tostring(ft), vim.log.levels.WARN)
  end
end

return M
