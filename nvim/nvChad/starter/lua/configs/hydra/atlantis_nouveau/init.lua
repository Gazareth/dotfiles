local surveyor = require("atlantis_surveyor")
local menu     = require("configs.hydra.atlantis_nouveau.menu")

local M = {}

local function node_data(n)
  local sr, sc, er, ec = n:range()
  return {
    node_type = n:type(),
    start_row = sr, start_col = sc,
  }
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
    table.insert(ancestry, node_data(cur))
    cur = cur:parent()
  end

  return { filetype = ft, ancestry = ancestry }
end

function M.open(bufnr, focus_mode, target_node_type, target_start_row, target_start_col)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  local scan, err = collect_ancestry(bufnr, row, col)
  if not scan then
    vim.notify("[atlantis] " .. (err or "failed to scan"), vim.log.levels.WARN)
    return
  end

  if target_node_type then
    scan.target_node_type  = target_node_type
    scan.target_start_row  = target_start_row
    scan.target_start_col  = target_start_col
  end

  local result = surveyor(scan, focus_mode)
  result.bufnr = bufnr

  if result.kind == "err" then
    vim.notify("[atlantis] " .. result.message, vim.log.levels.WARN)
    return
  end

  menu.open(result)
end

return M
