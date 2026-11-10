"""Workaround for Talon help windows (e.g. "help alphabet") growing wider on every refresh.

community's `GUI.refresh()` (community/core/gui/gui.py) runs every 500ms and calls
`self._window.resize(int(self._window.rect.width), ...)`. On Windows with display scaling,
the width read from `window.rect` and the width passed to `window.resize()` appear to use
different units, so the window gets wider on every tick (height is recomputed each time,
so only the width compounds).

This replaces the manual resize with Talon's built-in autosize, which is what sizes the
window correctly when it first opens. It lives outside the community submodule so the
submodule stays clean.
"""

from talon import app

try:
    from .community.core.gui import gui as community_gui
except ImportError:
    from user.community.core.gui import gui as community_gui


def _refresh_without_manual_resize(self):
    if not self._window:
        return
    if self._last_height_taken is not None and self._props.will_auto_size():
        self._window.autosize = True
        self._previous_height_taken = self._last_height_taken
    self._window.refresh()


if app.platform == "windows":
    community_gui.GUI.refresh = _refresh_without_manual_resize
