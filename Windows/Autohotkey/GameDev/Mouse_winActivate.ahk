#Requires AutoHotkey v2.0

;; deactivate capslock completely
SetCapslockState "AlwaysOff"


global windowToggles := Map()

QuickSort(arr) {
    if arr.Length <= 1
        return arr

    pivot := arr.RemoveAt(1)  ; Pick first element as pivot
    left := [], right := []

    for n in arr {
        if n <= pivot
            left.Push(n)
        else
            right.Push(n)
    }

    return QuickSort(left) + [pivot] + QuickSort(right)
}

FindWindows(windowClass := "") {
    filter := windowClass ? "ahk_class " windowClass : ""
    return WinGetList(filter)
}

FindWindowByIndex(windows, titleContains := "", matchIndex := 1) {
    pidGroups := Map()
    sortedPIDs := []

    for win in windows {
        try {
            title := WinGetTitle("ahk_id " win)
            if titleContains && !InStr(title, titleContains)
                continue

            pid := WinGetPID("ahk_id " win)
            if !pidGroups.Has(pid)
                pidGroups[pid] := []
            pidGroups[pid].Push(win)
        } catch {
            continue
        }
    }

	sortedPIDs := []
	for key in pidGroups
		sortedPIDs.Push(key)

    if sortedPIDs.Length = 0
        return 0

    sortedPIDs := QuickSort(sortedPIDs)

    if matchIndex > sortedPIDs.Length  ; Corrected indexing logic
        return 0

    selectedPID := sortedPIDs[matchIndex]  ; Adjusting for AHK 1-based indexing
    return pidGroups[selectedPID][1]
}



ToggleWindowOnTopByHwnd(hwnd) {
    if !hwnd {
        MsgBox "Invalid window handle."
        return
    }

    toggle := windowToggles.Has(hwnd) ? windowToggles[hwnd] : false

    if toggle {
        DllCall("SetWindowPos", "ptr", hwnd, "ptr", 0
            , "int", 0, "int", 0, "int", 0, "int", 0
            , "uint", 0x0001 | 0x0002 | 0x0040)
        WinActivate("ahk_id " hwnd)
    } else {
        DllCall("SetWindowPos", "ptr", hwnd, "ptr", 1
            , "int", 0, "int", 0, "int", 0, "int", 0
            , "uint", 0x0001 | 0x0002 | 0x0040)
    }

    windowToggles[hwnd] := !toggle
}

ToggleWindowOnTop(titleContains, windowClass := "", matchIndex := 1) {
    windows := FindWindows(windowClass)
    hwnd := FindWindowByIndex(windows, titleContains, matchIndex)
    if hwnd
        ToggleWindowOnTopByHwnd(hwnd)
    else
        MsgBox "No window found with the given parameters."
}

; --- Hotkeys ---

~CapsLock & 5::ToggleWindowOnTop("Unreal Editor", "UnrealWindow", 1)
~CapsLock & 1::ToggleWindowOnTop("", "Chrome_WidgetWin_1", 1)
~CapsLock & 2::ToggleWindowOnTop("", "Chrome_WidgetWin_1", 2)

