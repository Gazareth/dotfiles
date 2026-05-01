return function(result)
  local node = result.variant.node
  local current_name = node and node.state and node.state.name or ""
  vim.ui.input({ prompt = "Rename: ", default = current_name }, function(new_name)
    if not new_name or new_name == "" or new_name == current_name then return end
    -- LSP rename at the node's start position
    local range = result.range
    if range then
      vim.api.nvim_win_set_cursor(0, { range.start_row + 1, range.start_col })
    end
    vim.lsp.buf.rename(new_name)
  end)
end
