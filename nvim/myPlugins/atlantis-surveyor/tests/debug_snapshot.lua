local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  '',
  'local function add(x, y)',
  '',
  '  local sum = x + y',
  '  if sum > 0 then',
  '    return sum',
  '  end',
  'end',
})
vim.bo[buf].filetype = 'lua'
vim.api.nvim_set_current_buf(buf)
local parser = vim.treesitter.get_parser(buf, 'lua')
parser:parse()
local node = vim.treesitter.get_node({ bufnr = buf, pos = { 4, 0 } })
print('node type', node and node:type() or 'nil')
local cur = node
while cur do
  local sr, sc, er, ec = cur:range()
  print('anc', cur:type(), sr, sc, er, ec)
  cur = cur:parent()
end
local target_type = 'block'
local target_start_row, target_start_col = 3, 2
cur = node
while cur do
  local sr, sc = cur:range()
  if cur:type() == target_type and sr == target_start_row and sc == target_start_col then
    print('found target')
    break
  end
  cur = cur:parent()
end
if not cur then
  print('target not found')
else
  local ok_txt, txt = pcall(vim.treesitter.get_node_text, cur, buf)
  print('ok_txt', ok_txt, txt)
  print('children count')
  for child, fname in cur:iter_children() do
    if child:named() then
      local csr, csc, cer, cec = child:range()
      local ok_ct, ct = pcall(vim.treesitter.get_node_text, child, buf)
      print('child', child:type(), csr, csc, cer, cec, fname, ok_ct, ct)
    end
  end
end
