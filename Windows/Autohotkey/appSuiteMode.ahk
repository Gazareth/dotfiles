#Requires AutoHotkey v2.0

global modes := [
    "Default",
    "Code (JS)"
]

class WindowsApp {
    __New(Name, Exe, Path, Title := 0) {
        this.Name := Name
        this.Exe := Exe
        this.Path := Path
        this.Title := Title ?? false
    }
    IsRunning() {
        if this.Title != false {
            return WinGetPID(this.Title)
        } else {
        return ProcessExist(this.Exe)
        }
    }
    Close() {
        app_pid := 0
        if this.Title != 0 {
            app_pid := WinGetPID(this.Title)
        }
        ProcessClose(this.Title ? app_pid : this.Exe)
    }
}

;; === CONFIG ===
global apps_config := [
    ["Edge", "msedge.exe", "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"],
    ["Chrome", "chrome.exe", "C:\Program Files\Google\Chrome\Application\chrome.exe"],
    ["Neovide", "neovide.exe", "C:\Program Files\Neovide\neovide.exe"],
    ["Terminal", "wt.exe", "C:\Users\Gareth\AppData\Local\Microsoft\WindowsApps\wt.exe", "PowerShell"]
]

global apps := Map()

for app_cfg in apps_config {
    apps[app_cfg[1]] := WindowsApp(app_cfg*)
}

global mode_apps := Map()

mode_apps[modes[1]] := [
    apps["Edge"]
]

mode_apps[modes[2]] := [
    apps["Edge"],
    apps["Chrome"],
    apps["Neovide"],
    apps["Terminal"]
]

;; === UTILS ===
IndexOf(Array, Callback) {
    for item in Array {
        if Callback(item) == true {
            return A_Index
        }
    }
    return -1
}

;; Finds out which items from B are not in A
ArraySubtract(A, B) {
    C := []
    for b_app in B
    {
        for a_app in A {
            if (a_app == b_app) {
                continue 2
            }
        }
        C.Push(b_app)
    }

    return C
}

GetAppConfig(AppName) {
    app_index := IndexOf(apps_config, (app) => app.Name == AppName)
    return apps_config[app_index]
}

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
    old_mode_filtered := []
    for oma in old_mode_apps {
        if oma.IsRunning()
            old_mode_filtered.Push(oma)
    }

    apps_to_close := ArraySubtract(new_mode_apps, old_mode_filtered)
    apps_to_open := ArraySubtract(old_mode_filtered, new_mode_apps)

    for app in apps_to_close {
        app.Close()
    }

    for app in apps_to_open {
        Run app.Path
    }

    trayMenu.Uncheck(current_mode)
    trayMenu.Check(newMode)
    current_mode := newMode
}

;; Detect if mode is code mode!
global current_mode := modes[isAllRunning(mode_apps[modes[1]]) ? 2 : 1]

;; Set up tray menu items
global trayMenu := A_TrayMenu

for mode in modes {
    options := A_Index == 1 ? "BarBreak" : ""
    trayMenu.Add(mode, (ItemName, ItemPos, ParentMenu) => SwitchMode(ItemName), options)
    trayMenu.Check(current_mode)
}

Hotkey("^!1", (key) => SwitchMode(modes[1]))
Hotkey("^!2", (key) => SwitchMode(modes[2]))
