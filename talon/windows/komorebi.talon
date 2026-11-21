os: windows
-
(start up | start) komorebi: user.start_komorebi()
stop komorebi: user.stop_komorebi()
restart komorebi:
    user.stop_komorebi()
    sleep(1000ms)
    user.start_komorebi()

[go] (browser | chrome | edge): key(f13)
[go] (notes | files): key(f14)
[go] media: key(f15)
[go] obsidian: key(f16)
[go] (test | app): key(f17)
[go] code: key(f18)
[go] terminal: key(f19)
[go] comms: key(f20)
[go] (lazy git | lazygit): user.focus_or_open_lazygit()

desktop one: key(f13)
desktop two: key(f14)
desktop three: key(f15)
desktop four: key(f16)
desktop five: key(f17)
desktop six: key(f18)
desktop seven: key(f19)
desktop eight: key(f20)

flip: key(alt-g)
switch app: key(alt-tab)
switch [desktop]: user.komorebi_focus_last_workspace()
(arrange | stack) (desktops | windows): user.komorebi_arrange_desktops()
