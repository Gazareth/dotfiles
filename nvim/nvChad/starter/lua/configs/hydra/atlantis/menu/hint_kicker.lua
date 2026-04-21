local M = {}

local ATLANTIS_ICON = "🔱"

function M.default()
  return ATLANTIS_ICON .. " Atlantis " .. ATLANTIS_ICON
end

function M.container()
  return ATLANTIS_ICON .. " Atlantis (Container) " .. ATLANTIS_ICON
end

return M
