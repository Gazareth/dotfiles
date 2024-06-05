#Requires AutoHotkey v2.0
#Include lib/Enum.ahk
#Include lib/Array.ahk
#Include lib/AppSuite.ahk ; AppSuiteManager

#Include cfg/suiteDefs.ahk ; AppSuites, AppSuiteId


global ASM := AppSuiteManager(AppSuites, AppSuiteId.Default)

;; Detect if mode is code mode!
MsgBox "Started AppSuiteManager! `nMode: [" . AppSuites[ASM.CurrentSuite].Name . "]"

;; Set up tray menu items
global trayMenu := A_TrayMenu

HandleSuiteTrayItemClick(ItemName, ItemPos, ParentMenu) {
    for sId, suite in AppSuites {
        sNm := suite.Name
        if ItemName == sNm {
            if sId != ASM.CurrentSuite {
                trayMenu.Uncheck(ASM.CurrentSuiteName())
                ASM.SwitchSuite(sId)
                trayMenu.Check(sNm)
            }
        }
    }
}

;; Populate tray menu
for suite_id, suite in AppSuites {
    options := A_Index == 1 ? "BarBreak" : ""

    trayMenu.Add(suite.Name, HandleSuiteTrayItemClick, options)
}

;; Mark the current suite tray item
trayMenu.Check(ASM.CurrentSuiteName())

;; Add tray item to toggle debug mode
global debug := false
global DEBUG_STR := "Debug"

ToggleDebugMode(ItemName, ItemPos, ParentMenu) {
    global debug
    global ASM
    if debug {
        ASM.SetDebug(false)
        return trayMenu.Uncheck(DEBUG_STR)
    } else {
        ASM.SetDebug(true)
        return trayMenu.Check(DEBUG_STR)
    }
}

trayMenu.Add() ; Add separator
trayMenu.Add(DEBUG_STR, ToggleDebugMode)

Hotkey("^!1", (key) => ASM.SwitchSuite(AppSuiteId.Default))
Hotkey("^!2", (key) => ASM.SwitchSuite(AppSuiteId.CodeJS))

; @todo: Identify current mode on startup and close any apps not from that mode