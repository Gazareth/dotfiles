# Mouse click & key aliases from Talon 1.0 tutorial
click mouse:
    tracking.zoom_cancel()
    mouse_click(0)
    user.grid_close()
    user.mouse_drag_end()

enter that:
    key(enter)

space key:
    key(space)

tab key:
    key(tab)

# Correction window triggers
correct that | correct this | correct [the] selection:
    correct.show()

correct [the word] <edit.target>:
    correct.target(edit.target)

# On-screen text target selection, deletion, navigation & editing (<edit.target>)
select <edit.target>:
    edit.target_select(edit.target)

delete <edit.target>:
    edit.target_delete(edit.target)

clear <edit.target>:
    edit.target_clear(edit.target)

cut <edit.target>:
    edit.target_cut(edit.target)

copy <edit.target>:
    edit.target_copy(edit.target)

uppercase <edit.target>:
    edit.target_upper(edit.target)

lowercase <edit.target>:
    edit.target_lower(edit.target)

capitalize <edit.target>:
    edit.target_title(edit.target)

replace <edit.target> with <phrase> | change <edit.target> to <phrase>:
    edit.target_replace(edit.target, "{phrase}")

bold <edit.target>:
    edit.target_bold(edit.target)

italicize <edit.target>:
    edit.target_italic(edit.target)

underline <edit.target>:
    edit.target_underline(edit.target)

insert <phrase> after <edit.target>:
    edit.target_insert_after(edit.target, " {phrase}")

insert <phrase> before <edit.target>:
    edit.target_insert_before(edit.target, "{phrase} ")

put [curly] braces around <edit.target>:
    edit.target_wrap(edit.target, "{", "}")

put [double] quotes around <edit.target>:
    edit.target_wrap(edit.target, '"', '"')

put parentheses around <edit.target>:
    edit.target_wrap(edit.target, "(", ")")

put single quotes around <edit.target>:
    edit.target_wrap(edit.target, "'", "'")

put [square] brackets around <edit.target>:
    edit.target_wrap(edit.target, "[", "]")

move after <edit.target> | insert after <edit.target>:
    edit.target_caret_after(edit.target)

move before <edit.target> | insert before <edit.target>:
    edit.target_caret_before(edit.target)
