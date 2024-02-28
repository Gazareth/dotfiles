#Requires AutoHotkey v2.0

;; based on @babygau's answer here https://stackoverflow.com/a/40559502
#UseHook
#SingleInstance force

;; deactivate capslock completely
SetCapslockState "AlwaysOff"

;; remap capslock to hyper
;; if capslock is toggled, remap it to esc

;; note: must use tidle prefix to fire hotkey once it is pressed
;; not until the hotkey is released
~Capslock:: {
    ;; downtemp tells subsequent sends that the key is not permanently down, and may be released whenever a keystroke calls for it.
    Send "{Ctrl DownTemp}{Shift DownTemp}{Alt DownTemp}{LWin DownTemp}"
    KeyWait "CapsLock"
    Send "{Ctrl Up}{Shift Up}{Alt Up}{LWin Up}"
    if (A_PriorKey = "CapsLock") {
        Send "{Esc}"
    }
}


~Capslock & b:: { 
  Send "^{Home}" 
}

~Capslock & w:: { 
    Send "^{Left}" 
}

~Capslock & a:: { 
    Send "^{Right}"
}

~Capslock & i:: { 
    Send "{Down}"
}

~Capslock & r:: { 
    Send "^{End}"
}


;; Hyper+c/v to copy/paste
; ~Capslock & c:: Send ^{c}
;;~Capslock & v:: Send ^{v} ;map to ditto instead

;; Hyper+a to set window to always on top
~Capslock & u:: {
    WinsetAlwaysontop -1
}
