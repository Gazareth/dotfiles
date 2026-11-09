tag: labels.controls_active
-
drag [from] <labels.target> to <labels.target>:
    labels.mouse_move(labels.target_1)
    sleep(0.2)
    mouse_drag()
    sleep(0.2)
    labels.mouse_move(labels.target_2)
    sleep(0.2)
    mouse_release()
    labels.hide()

drop [at] <labels.target> | release mouse [at] <labels.target> | release hold [at] <labels.target> | end drag [at] <labels.target>:
    labels.mouse_move(labels.target)
    sleep(0.2)
    mouse_release()
    labels.hide()

click and hold [at] <labels.target> | press and hold [at] <labels.target>:
    labels.mouse_move(labels.target)
    mouse_drag()
    labels.hide()

<user.modifiers> click and hold [at] <labels.target>:
    key("{modifiers}:down")
    labels.mouse_move(labels.target)
    mouse_drag()
    labels.hide()
    key("{modifiers}:up")

click <labels.target> | press <labels.target> | tap <labels.target>:
    labels.select(labels.target)

<labels.target>:
    labels.select(labels.target)

<user.modifiers> click <labels.target>:
    key("{modifiers}:down")
    labels.mouse_move(labels.target)
    mouse_click()
    labels.hide()
    key("{modifiers}:up")

show menu for <labels.target>:
    labels.mouse_move(labels.target)
    mouse_click(1)
    labels.hide()

start drag [at] <labels.target>:
    labels.mouse_move(labels.target)
    mouse_drag()
