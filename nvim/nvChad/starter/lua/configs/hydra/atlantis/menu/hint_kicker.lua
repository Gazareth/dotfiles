local M = {}

local ATLANTIS_ICON = "🔱"

function M.default()
  return ATLANTIS_ICON .. " Atlantis " .. ATLANTIS_ICON
end

function M.navigation()
  return ATLANTIS_ICON .. " Atlantis (Navigation) " .. ATLANTIS_ICON
end

return M
