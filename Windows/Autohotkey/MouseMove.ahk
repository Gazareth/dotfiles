#Requires AutoHotkey v2.0

SetCapslockState "AlwaysOff"

MOMENTUM_BASE := 0.5
MOMENTUM_RAMP_UP := 0.015
MOMENTUM_MAX := 150

ELAPSED_DECAY_FACTOR := 3

global mouse_left := 0
global mouse_down := 0
global mouse_right := 0
global mouse_up := 0
global elapsed_x := 0
global elapsed_y := 0

Momentum(elapsed) {
    return (((1 - Exp(-MOMENTUM_RAMP_UP * elapsed ** 1.2)) * MOMENTUM_MAX) + MOMENTUM_BASE)
}

Elapsed() {
    global elapsed_x
    global elapsed_y
    return Max(elapsed_x, elapsed_y)
}

loop {
    dir_x := mouse_right - mouse_left
    dir_y := mouse_down - mouse_up

    if dir_x != 0 {
        elapsed_x += 1
        MouseMove dir_x * Momentum(Elapsed()), 0, 1, "R"
    } else {
        if dir_y == 0
            elapsed_x /= ELAPSED_DECAY_FACTOR
    }

    if dir_y != 0 {
        elapsed_y += 1
        MouseMove 0, dir_y * Momentum(Elapsed()), 1, "R"
    } else {
        if dir_x == 0
            elapsed_y /= ELAPSED_DECAY_FACTOR
    }

    DllCall("Sleep", "UInt", 5)  ; Must use DllCall instead of the Sleep function.
}

~Capslock & F1:: {
    global mouse_up := 1
}

~Capslock & F1 Up:: {
    global mouse_up := 0
}

~Capslock & F2:: {
    global mouse_left := 1
}

~Capslock & F2 Up:: {
    global mouse_left := 0
}

~Capslock & F3:: {
    global mouse_down := 1
}

~Capslock & F3 Up:: {
    global mouse_down := 0
}

~Capslock & F4:: {
    global mouse_right := 1
}

~Capslock & F4 Up:: {
    global mouse_right := 0
}

~Capslock & F5:: {
    send "{WheelUp 1}"
}

~Capslock & F6:: {
    send "{WheelDown 1}"
}
