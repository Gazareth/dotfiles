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

function M.open(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  local scan, err = collect_ancestry(bufnr, row, col)
  if not scan then
    vim.notify("[atlantis] " .. (err or "failed to scan"), vim.log.levels.WARN)
    return
  end

  local results = surveyor.resolve(bufnr, scan)

  if #results == 0 then
    vim.notify("[atlantis] nothing here", vim.log.levels.INFO)
    return
  end

  local primary = results[1]
  if primary.variant.kind == "error" then
    vim.notify("[atlantis] " .. primary.variant.message, vim.log.levels.WARN)
    return
  end

  if primary.variant.kind == "unrecognised" or not primary.available_actions or #primary.available_actions == 0 then
    -- Try to find the first supported node if the innermost is unrecognised
    for i=2, #results do
      if results[i].variant.kind ~= "unrecognised" then
        primary = results[i]
        break
      end
    end
  end

  if primary.variant.kind == "unrecognised" then
    vim.notify("[atlantis] nothing here", vim.log.levels.INFO)
    return
  end

  menu.open(primary, results)
end

return M
