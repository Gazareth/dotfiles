local M = {}

M.flick_command = function(flickAmountMultiplier)
  return function()
    local winHeight = vim.fn.winheight(0)
    local cursorJumpAmount = math.abs(math.floor(flickAmountMultiplier * tonumber(winHeight) / 4))
    local cursorJumpDir = "j"

    if(string.sub(flickAmountMultiplier,1,1) == "-") then
      cursorJumpDir = "k"
    end
    vim.cmd("normal "..cursorJumpAmount..cursorJumpDir)
    vim.cmd("normal zz")
  end
end

return M

