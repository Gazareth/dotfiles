#Requires AutoHotkey v2.0
#Include ../lib/Enum.ahk
#Include ../lib/AppSuite.ahk
#Include appDefs.ahk

AppSuiteId := Enum([
    "Default",
    "Browse",
    "CodeJS",
    "Gaming"
])

apps := APP_DEFS

AppSuites := Map(
    AppSuiteId.Default, {
        name: "Default (blank workspace)",
        apps: []
    },
    AppSuiteId.Browse, { 
        name: "Browsing",
        apps: [
            "Edge"
        ]
    },
    AppSuiteId.CodeJS, {
        name: "Code (JS)",
        apps: [
            "Edge",
            "Chrome",
            "Neovide",
            "Terminal"
        ],
    },
    AppSuiteId.Gaming, {
        name: "Gaming (Steam)",
        apps: [
            "Steam"
        ]
    },
)

;; Map raw app names into actual WindowsApp instances if there are any
for suite_id, suite_def in AppSuites {
    if suite_def.apps.Length > 0 {
        suite_def.apps.Map((appName) => APP_DEFS[appName])
    }
    AppSuites[suite_id] := AppSuite(suite_def.name, suite_def.apps)
}
