tag: labels.grid_active
-
choose <labels.target>:
    labels.select(labels.target)
<labels.target>:
    labels.select(labels.target)
double click [at] <labels.target>:
    labels.mouse_move(labels.target)
    mouse_click()
    mouse_click()
    labels.hide()
<user.modifiers> double click [at] <labels.target>:
    key("{modifiers}:down")
    labels.mouse_move(labels.target)
    mouse_click()
    mouse_click()
    labels.hide()
    key("{modifiers}:up")
drag [from] <labels.target> to <labels.target>:
    labels.mouse_move(labels.target_1)
    sleep(200ms)
    mouse_drag()
    sleep(200ms)
    labels.mouse_move(labels.target_2)
    sleep(200ms)
    mouse_release()
    labels.hide()
drop [at] <labels.target> | release mouse [at] <labels.target> | release hold [at] <labels.target> | end drag [at] <labels.target>:
    labels.mouse_move(labels.target)
    sleep(200ms)
    mouse_release()
    labels.hide()
long press [at] <labels.target>:
    labels.mouse_move(labels.target)
    mouse_drag()
    sleep(1s)
    mouse_release()
    labels.hide()
<user.modifiers> long press [at] <labels.target>:
    key("{modifiers}:down")
    labels.mouse_move(labels.target)
    mouse_drag()
    sleep(1s)
    mouse_release()
    labels.hide()
    key("{modifiers}:up")
right click [at] <labels.target>:
    labels.mouse_move(labels.target)
    mouse_click(1)
    labels.hide()
<user.modifiers> right click [at] <labels.target>:
    key("{modifiers}:down")
    labels.mouse_move(labels.target)
    mouse_click(1)
    labels.hide()
    key("{modifiers}:up")
middle click [at] <labels.target>:
    labels.mouse_move(labels.target)
    mouse_click(2)
    labels.hide()
click [at] <labels.target>:
    labels.mouse_move(labels.target)
    mouse_click()
    labels.hide()
<user.modifiers> click [at] <labels.target>:
    key("{modifiers}:down")
    labels.mouse_move(labels.target)
    mouse_click()
    labels.hide()
    key("{modifiers}:up")
touch [at] <labels.target>:
    labels.mouse_move(labels.target)
    mouse_click()
    labels.hide()
<user.modifiers> touch [at] <labels.target>:
    key("{modifiers}:down")
    labels.mouse_move(labels.target)
    mouse_click()
    labels.hide()
    key("{modifiers}:up")
