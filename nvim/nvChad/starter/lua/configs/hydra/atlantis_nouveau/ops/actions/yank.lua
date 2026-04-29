return function(result)
  if result.text then
    vim.fn.setreg('"', result.text)
    vim.notify("[atlantis] yanked: " .. result.text:gsub("\n.*", "…"), vim.log.levels.INFO)
  end
end
