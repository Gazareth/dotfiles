local surveyor = require("atlantis_surveyor")
local menu     = require("configs.hydra.atlantis_nouveau.menu")

local M = {}

local function node_data(bufnr, n)
  local sr, sc, er, ec = n:range()
  local data = {
    node_type = n:type(),
    start_row = sr, start_col = sc,
    end_row   = er, end_col   = ec,
    fields    = {},
    children  = {},
  }
  for child, fname in n:iter_children() do
    if child:named() then
      local csr, csc, cer, cec = child:range()
      local entry = {
        node_type = child:type(),
        start_row = csr, start_col = csc,
        end_row   = cer, end_col   = cec,
      }
      if csr == cer then
        local ok_t, t = pcall(vim.treesitter.get_node_text, child, bufnr)
        if ok_t then entry.text = t end
      end
      if fname then
        data.fields[fname] = entry
      else
        table.insert(data.children, entry)
      end
    end
  end
  return data
end

local function collect_ancestry(bufnr, row, col)
  local ft = vim.bo[bufnr].filetype
  local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr, ft)
  if not ok_parser or not parser then
    return nil, "no parser for filetype: " .. ft
  end
  parser:parse()

  local node = vim.treesitter.get_node({ bufnr = bufnr, pos = { row, col } })
  if not node then
    return nil, "no node at position"
  end

  local ancestry = {}
  local cur = node
  while cur do
    table.insert(ancestry, node_data(bufnr, cur))
    cur = cur:parent()
  end

  return { filetype = ft, ancestry = ancestry }
end

function M.open(bufnr, row, col)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  row = row or (cursor[1] - 1)  -- nvim cursor is 1-based; surveyor expects 0-based
  col = col or cursor[2]

  local scan, err = collect_ancestry(bufnr, row, col)
  if not scan then
    vim.notify("[atlantis] " .. (err or "failed to scan"), vim.log.levels.WARN)
    return
  end

  local result = surveyor.resolve(bufnr, scan)

  if result.variant.kind == "error" then
    vim.notify("[atlantis] " .. result.variant.message, vim.log.levels.WARN)
    return
  end

  if result.variant.kind == "unrecognised" or not result.available_actions or #result.available_actions == 0 then
    vim.notify("[atlantis] nothing here", vim.log.levels.INFO)
    return
  end

  menu.open(result)
end

return M
