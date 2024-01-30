#Requires AutoHotkey v2.0+
#SingleInstance Force

WorkspaceNumber := 9

ArrayFromZero(Length){
  temp := []
  Loop Length {
    temp.Push(A_Index-1)
  }
  return temp
}

Join(s, h, t*)
{
	for _,x in t
		h .= s . x
	return h
}

RunKomorebiC(CommandString) {
  return RunWait("komorebic " . CommandString, ,"Hide")
}

; Set workspaces (start from 0)
; ArrayFromZero(9) => [0,1,2,3,4,5,6,7,8]
global numbers := ArrayFromZero(WorkspaceNumber)

init() {
  RunKomorebiC("start")
  ;; focus-follows-mouse feels buggy
  ; RunKomorebiC("focus-follows-mouse disable")

  settings := [
    "remove-title-bar exe neovide.exe",
    "alt-focus-hack enable",
    "window-hiding-behaviour cloak",  ;; prevent flashing when switching workspaces
    "active-window-border-color 56 189 248"
    "active-window-border enable"
  ]

  for SettingsCommand in settings {
    RunKomorebiC(SettingsCommand)
  }

  blacklist := [
    ["class", "SunAwtDialog"], ; Always float IntelliJ popups, matching on class
    ["title", '"Control Panel"'],
    ["class", "TaskManagerWindow"],
    ["exe", "onTopReplica"],
    ["exe", "Vial.exe"],
    ["exe", "Updater.exe"],
  ]

  for blacklistItem in blacklist {
    RunKomorebiC(Join(" ", "float-rule", blacklistItem*))
  }

  tray_blacklist := [
    ["exe", "Discord.exe"],
    ["exe", "Telegram.exe"],
    ["exe", "cloudmusic.exe"],
    ["exe", "everything.exe"],
    ["exe", "GoldenDict.exe"],
    ["exe", "'Clash for Windows.exe'"],
  ]

  for tray_item in tray_blacklist {
    RunKomorebiC(Join(" ", "identify-tray-application", tray_item*))
  }

  ;; IDM can't not be handle properly 
  ;; I don't like it tiling anyway. So I just comment it
  ;; Run("komorebic manage-rule exe IDMan.exe",,"Hide")
  RunKomorebiC("ensure-workspaces 0 " . WorkspaceNumber)

  ; set the padding to all the workspaces
  for num in numbers {
    RunKomorebiC("workspace-padding 0 " . num . " 10")
    RunKomorebiC("container-padding 0 " . num . " 8")
  }

  ;; Setup workspace rules
  workspace_apps := [
    ["exe", "msedge.exe", 0, 0],
    ["exe", "explorer.exe", 0, 1],
    ["exe", "notepad++.exe", 0, 1],
    ["title", "Apple Music", 0, 2],
    ["exe", "chrome.exe", 0, 3],
    ["exe", "Code.exe", 0, 4],
    ["exe", "neovide.exe", 0, 4],
    ["exe", "wt.exe", 0, 5]
  ]

  for workspace_app in workspace_apps {
    RunKomorebiC( Join(" ", "workspace-rule", workspace_app*))
  }
 
  RunKomorebiC("toggle-title-bars")
}

;; run init function at start
init()


directions := ["left", "down", "up", "right"]
rhs_direction_keys := ["w", "i", "u", "a"]
lhs_direction_keys := ["n", "t", "m", "y"]

DirectionalGenerator(Command, Direction) {
  return (_) => RunKomorebiC(Command . " " . Direction)
}

;; Create hotkeys to run command in each direction of Keys
GenerateDirectionalCommands(Modifier, Keys, Command) {
  for key in Keys {
    direction := directions[A_Index]
    Hotkey(Modifier . key, DirectionalGenerator(Command, direction))
  }
}

; Change the focused window, Alt + RHS direction keys
GenerateDirectionalCommands("!", rhs_direction_keys, "focus")

; Move the focused window in a given direction, Alt + Shift + RHS direction keys
GenerateDirectionalCommands("+!", rhs_direction_keys, "move")

; Stack the focused window in a given direction, ,Alt + LHS direction keys
GenerateDirectionalCommands("!", lhs_direction_keys, "stack")

; Float the focused window Alt + T
global discrete_hotkeys := [
  ["!q", "toggle-float"],

  ; Toggle Tiling for workspace. Alt + Shift + T
  ["!+q", "toggle-tiling"],

  ; Pause responding to any window events or komorebic commands Alt + P
  ["!p", "toggle-pause"],

  ; Unstack the focused window
  ["!h", "unstack"],

  ["!g", "cycle-stack next"],
  ; ![::RunKomorebiC("cycle-stack previous")

  ; Promote the focused window to the top of the tree, ,Alt + Shift + Enter
  ["!+Enter", "promote"],

  ; Toggle the Monocle layout for the focused window, ,Alt + Shift + F
  ; Monocle is similar to maximizing, but it will pinned the focused
  ; window down
  ["!+f", "toggle-monocle"],

  ; Use Alt + F to toggle maximize window
  ; You should always use this shortcut to maximize
  ; or komorebi won't handle it like issue #12
  ; https://github.com/LGUG2Z/komorebi/issues/12
  ["!f", "komorebic toggle-maximize"],


  ; Switch to an equal-height
  ["!+l", "change-layout rows"],
  ; Switch to an equal-width.
  ["!+d", "change-layout columns"],
  ; famous binary space partition
  ["!+p", "change-layout bsp"],

  ; Force a retile if things get janky Ctrl + Shift + R
  ["^+r", "retile"],

  ["!+q", "stop" ],

]

ActionFunction(key) {
  global discrete_hotkeys

  for hk in discrete_hotkeys 
  {
    if( hk[1] == key ) {
        RunKomorebiC(hk[2])
        break
    }
  }
}

for ka in discrete_hotkeys {
  Hotkey(ka[1], ActionFunction)
}

; Awkward hotkeys (these have to be written explicitly 🤷‍♂️)
Hotkey("!,", (key) => RunKomorebiC("flip-layout horizontal"))
Hotkey("!.", (key) => RunKomorebiC("flip-layout vertical"))

; Switch to workspace
; Alt + 1~9
; Equal to bind key !1 to !9 to workspace 0 ~ 8
For num in numbers{
  Hotkey("!" . (num+1), (key) => RunKomorebiC("focus-workspace " . Integer(SubStr(key, 2))-1))
}

; Move window to workspace
; Alt + Shift + 1~9
; Equal to bind key !+1 to !+9 to workspace 0 ~ 8
For num in numbers{
  Hotkey("!+" . (num+1), (key) => RunKomorebiC("move-to-workspace " . Integer(SubStr(key, 3))-1))
}


;; Close Focused Window Alt + X
!x::{
  WinClose("A")
}


;; Restart komorebi in a hard way
!+z::{
  RunKomorebiC("restore-windows")
  RunWait("powershell " . "Stop-Process -Name 'komorebi'",,"Hide")
  RunWait("komorebic start") ;; intend to not hide it
  ;; Delay 1000 milisecond
  Sleep(1000)
  init()
}

;; Get Window Info
;; Helpful for debugging
!+h::{
  window_id := ""
  MouseGetPos(,,&window_id)
  window_title := WinGetTitle(window_id)
  window_class := WinGetClass(window_id)
  MsgBox(window_id "`n" window_class "`n" window_title)
}


;; this is a global state. 
;; ? how to moddify it to a functional style?
global minimized_window := ""
;; Window should not be minimized
global FilterOutClass := ["WorkerW", "Shell_TrayWnd", "NotifyIconOverflowWindow"]
;; Alt + M
;; toggle minimize
;; minimize window will be saved until restore
;; useful when a window (especially vscode) get stuck
!d::{
  try {
    ;; If there is a window under the cursor then active it
    window_id := ""
    MouseGetPos(,,&window_id)
    WinActivate(window_id)
    ;; then process
    active_id := WinGetID("A")
    window_state := WinGetMinMax("A")
    if (minimized_window != ""){
      WinRestore(minimized_window)
      global minimized_window := ""
    } else {
      for filter in FilterOutClass{
        if(WinGetClass(active_id) == filter){
          ;; break out of the function
          return
        }
      }
      WinMinimize(active_id)
      global minimized_window := active_id
    }
  } catch as e {
    ;; If there's an error, it likely is cannot find focused window
    ;; this will focus a window under mouse cursor
    ;; I don't think this catch is meaningful
    window_id := ""
    MouseGetPos(,,&window_id)
    WinActivate(window_id)
  }
}
