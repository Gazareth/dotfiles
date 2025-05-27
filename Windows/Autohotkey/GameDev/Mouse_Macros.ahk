#Requires AutoHotkey v2.0

;; deactivate capslock completely
SetCapslockState "AlwaysOff"

; --- Hotkeys ---

~CapsLock & S:: {
    Click ; Perform a mouse click at the current position
    Send("{F7}") ; Send F7 key
    Sleep(350)
    Send("^s") ; Send Ctrl + S
}
