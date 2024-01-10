local g = vim.g
g.comfortable_motion_no_default_key_mappings = 1
g.comfortable_motion_interval = 1000.0 / 120.0
g.comfortable_motion_friction = 240.0
g.comfortable_motion_air_drag = 16.0

g.comfortable_motion_impulse_multiplier = 4  -- Feel free to increase/decrease this value.

local flickCommand = function(flickAmountMultiplier)
  return function()
    local winHeight = vim.fn.winheight(0)
    local cursorJumpAmount = math.abs(math.floor(flickAmountMultiplier * tonumber(winHeight) / 4))
    local cursorJumpDir = "j"

    if(string.sub(flickAmountMultiplier,1,1) == "-") then
      cursorJumpDir = "k"
    end
    vim.cmd("normal "..cursorJumpAmount..cursorJumpDir)
    vim.cmd(":call comfortable_motion#flick(g:comfortable_motion_impulse_multiplier * winheight(0) * "..flickAmountMultiplier..")")
  end
end

vim.keymap.set('n', '<C-d>', flickCommand("2.15"), { desc = "Jump down by half a screen" })
vim.keymap.set('n', '<C-u>', flickCommand("-2.15"), { desc = "Jump up by half a screen" })

