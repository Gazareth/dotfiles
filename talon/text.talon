enter <user.prose>$:
    user.insert_formatted(prose, "NOOP")
    key(enter)
enter <user.prose> {user.phrase_ender}:
    user.insert_formatted(prose, "NOOP")
    insert(phrase_ender)
    key(enter)
