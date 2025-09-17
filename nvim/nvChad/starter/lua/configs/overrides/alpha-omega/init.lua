local alpha_omega_config = function()
    local present, alpha_omega = pcall(require, "alpha-omega")

    local dashboard = require("alpha.themes.dashboard")

    local base_dashboard = require("configs.overrides.alpha-omega.base")
    local project_dashboard = require("configs.overrides.alpha-omega.project")
    local settings_dashboard = require("configs.overrides.alpha-omega.settings")

    local dashboards = {
        base = base_dashboard,
        settings = settings_dashboard,
        project = project_dashboard
    }

    alpha_omega.setup({
        dashboards = dashboards,
        default_dashboard = "base"
    })
end

return alpha_omega_config
