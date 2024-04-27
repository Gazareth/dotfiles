#Requires AutoHotkey v2.0
#Include lib/Enum.ahk
#Include lib/Array.ahk
#Include lib/App.ahk ; WindownApp

#Include appDefs.ahk ; APP_DEFS

global modeIndex := 1

global modes := Enum([
    "Default",
    "Browse",
    "CodeJS",
    "Gaming"
])

global mode_names := Map(
    modes.Default, "Default (blank workspace)",
    modes.Browse, "Browsing",
    modes.CodeJS, "Code (JS)",
    modes.Gaming, "Gaming (Steam)"
)

global apps := Map()

for app_cfg in APP_DEFS {
    apps[app_cfg[1]] := WindowsApp(app_cfg*)
}

global mode_apps := Map()

mode_apps[modes.Default] := []

mode_apps[modes.Browse] := [
    apps["Edge"]
]

mode_apps[modes.CodeJS] := [
    apps["Edge"],
    apps["Chrome"],
    apps["Neovide"],
    apps["Terminal"]
]

mode_apps[modes.Gaming] := [
    apps["Steam"]
]

isAllRunning(AppList) {
    for app in AppList {
        if app.isRunning() == 0
            return 1
        else
            return 0
    }
}

SwitchMode(newMode) {
    global current_mode

    new_mode_apps := mode_apps[newMode]
    old_mode_apps := mode_apps[current_mode]
    old_mode_apps_running := []
    for o_m_a in old_mode_apps {
        if o_m_a.IsRunning() {
            old_mode_apps_running.Push(o_m_a)
        }
    }

    apps_to_close := new_mode_apps.Subtract(old_mode_apps_running)
    apps_to_open := old_mode_apps_running.Subtract(new_mode_apps)

    for app in apps_to_close {
        if app.IsRunning() {
            MsgBox "Closing " . app.Name
            ; app.Close()
        }
    }

    for app in apps_to_open {
        MsgBox "Should open? " . app.Name
        if app.ShouldOpen() {
            MsgBox "Opening " . app.Name
            ; Run app.Path
        }
    }

    trayMenu.Uncheck(mode_names[current_mode])
    trayMenu.Check(mode_names[newMode])
    current_mode := newMode
}

;; Detect if mode is code mode!
global current_mode := isAllRunning(mode_apps[modes.CodeJS]) ? modes.CodeJS : modes.Default

MsgBox "Started app suite organiser! `nMode: [" . mode_names[current_mode] . "]"

;; Set up tray menu items
global trayMenu := A_TrayMenu

HandleTrayItemClick(ItemName, ItemPos, ParentMenu) {
    for mi, mn in mode_names {
        if ItemName == mn
            return SwitchMode(mi)
    }
}

for mode_index, mode_name in mode_names {
    options := A_Index == 1 ? "BarBreak" : ""

    trayMenu.Add(mode_name, HandleTrayItemClick, options)
}

trayMenu.Check(mode_names[current_mode])

Hotkey("^!1", (key) => SwitchMode(modes.Default))
Hotkey("^!2", (key) => SwitchMode(modes.CodeJS))

; @todo: Identify current mode on startup and close any apps not from that mode