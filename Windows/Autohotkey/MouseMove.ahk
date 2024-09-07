#Requires AutoHotkey v2.0

MOMENTUM_BASE := 4
MOMENTUM_MULTIPLIER := 1.1

global mouse_x := 0
global mouse_y := 0
global momentum := 0

loop {
    if mouse_x != 0 {
        momentum *= MOMENTUM_MULTIPLIER
        MouseMove mouse_x * momentum, 0, 2, "R"
    }

    if mouse_y != 0 {
        momentum *= MOMENTUM_MULTIPLIER
        MouseMove 0, mouse_y * momentum, 2, "R"
    }

    Sleep 1
}

!^+#F1:: {
    global mouse_y := -1
}

!^+#F1 Up:: {
    global mouse_y := 0
    global momentum := MOMENTUM_BASE
}

!^+#F2:: {
    global mouse_x := -1
}

!^+#F2 Up:: {
    global mouse_x := 0
    global momentum := MOMENTUM_BASE
}

!^+#F3:: {
    global mouse_y := 1
}

!^+#F3 Up:: {
    global mouse_y := 0
    global momentum := MOMENTUM_BASE
}

!^+#F4:: {
    global mouse_x := 1
}

!^+#F4 Up:: {
    global mouse_x := 0
    global momentum := MOMENTUM_BASE
}
