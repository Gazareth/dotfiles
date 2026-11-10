from talon import Module, ctrl, ui

mod = Module()

_DIRECTION_SIGNS = {
    "left": (-1, 0),
    "right": (1, 0),
    "up": (0, -1),
    "down": (0, 1),
}


def _move_relative_percent(dx_pct: float, dy_pct: float) -> None:
    x, y = ctrl.mouse_pos()
    rect = ui.screen_containing(x, y).rect
    new_x = max(rect.left, min(rect.right - 1, round(x + rect.width * (dx_pct / 100))))
    new_y = max(rect.top, min(rect.bot - 1, round(y + rect.height * (dy_pct / 100))))
    ctrl.mouse_move(new_x, new_y)


@mod.action_class
class Actions:
    def mouse_move_relative_percent(dx_pct: float, dy_pct: float):
        """Move the mouse cursor by a percentage of the current screen size"""
        _move_relative_percent(dx_pct, dy_pct)

    def mouse_nudge_percent(direction: str, pct: float):
        """Move the mouse cursor in a cardinal direction by a percentage of the current screen size"""
        dx_sign, dy_sign = _DIRECTION_SIGNS[direction]
        _move_relative_percent(dx_sign * pct, dy_sign * pct)
