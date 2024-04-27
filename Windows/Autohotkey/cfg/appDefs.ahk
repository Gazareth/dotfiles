#Requires AutoHotkey v2.0

#Include ../lib/App.ahk ; WindowsApp

APP_DEFS_RAW := [
    ["Edge", "msedge.exe", "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"],
    ["Chrome", "chrome.exe", "C:\Program Files\Google\Chrome\Application\chrome.exe"],
    ["Neovide", "neovide.exe", "C:\Program Files\Neovide\neovide.exe"],
    ["Terminal", "WindowsTerminal.exe", "C:\Users\Gareth\AppData\Local\Microsoft\WindowsApps\wt.exe", "PowerShell"],
    ["Steam", "steam.exe", "X:\Steam"]
]

APP_DEFS := Map()

for app_cfg in APP_DEFS_RAW {
    APP_DEFS[app_cfg[1]] := WindowsApp(app_cfg*)
}
