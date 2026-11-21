"""Custom floating mode HUD scaled to display DPI with icons matching Talon HUD."""

from dataclasses import dataclass
from typing import Callable, Optional

import skia
from skia import Canvas as SkiaCanvas
from talon import Module, actions, app, cron, registry, scope, settings, storage, ui
from talon.canvas import Canvas, MouseEvent
from talon.types import Point2d, Rect

mod = Module()

mod.setting(
    "custom_hud_scale",
    type=float,
    default=0.0,
    desc="Custom HUD scale multiplier (0 = auto-detect from display scale)",
)

HUD_BASE_WIDTH = 276.0
HUD_BASE_HEIGHT = 72.0
STORAGE_KEY_POS = "user.custom_hud_pos"
STORAGE_KEY_SHOW = "user.custom_hud_show"
STORAGE_KEY_SCALE = "user.custom_hud_user_scale"

canvas: Optional[Canvas] = None
last_mouse_pos: Optional[Point2d] = None
is_dragging = False
_hud_x: float = 0.0
_hud_y: float = 0.0

# Colors (Catppuccin Mocha themed - 6-character RRGGBB hex)
COLOR_BG = "181825"                  # Dark background
COLOR_BORDER = "585b70"              # Subtle outline
COLOR_BTN_INACTIVE_BG = "313244"     # Inactive button surface
COLOR_BTN_BORDER_INACTIVE = "45475a" # Inactive border
COLOR_TEXT_INACTIVE = "cdd6f4"       # Clean readable icon

# Highlights
# Active when Whisper is enabled -> Purple-Pink (Mauve / Pink)
COLOR_ACTIVE_WHISPER_BG = "5c2966"       # Deep purple-pink fill
COLOR_ACTIVE_WHISPER_BORDER = "cba6f7"   # Mauve border
COLOR_ACTIVE_WHISPER_ICON = "f5c2e7"     # Vibrant Pink icon

# Active when Whisper is disabled -> Classic Blue
COLOR_ACTIVE_DEFAULT_BG = "1e3a5f"       # Deep blue fill
COLOR_ACTIVE_DEFAULT_BORDER = "89b4fa"   # Blue border
COLOR_ACTIVE_DEFAULT_ICON = "89b4fa"     # Blue icon


@dataclass
class HudButton:
    id: str
    rect: Rect
    is_active: bool
    on_click: Callable[[], None]


def _get_scale() -> float:
    user_scale = storage.get(STORAGE_KEY_SCALE, 0.0)
    if user_scale and float(user_scale) > 0.2:
        return float(user_scale)

    cfg_scale = settings.get("user.custom_hud_scale", 0.0)
    if cfg_scale and float(cfg_scale) > 0.2:
        return float(cfg_scale)

    try:
        main_screen = ui.main_screen()
        s = float(main_screen.scale)
        if s > 0.2:
            return s
    except Exception:
        pass
    return 1.8 if ui.main_screen().rect.width >= 3000 else 1.0


def _get_dimensions(scale: float) -> tuple[float, float]:
    return (float(int(HUD_BASE_WIDTH * scale)), float(int(HUD_BASE_HEIGHT * scale)))


def _get_current_mode() -> str:
    """Returns 'sleep', 'dictation', 'mixed', or 'command'."""
    try:
        if not actions.speech.enabled():
            return "sleep"
    except Exception:
        pass

    modes = scope.get("mode") or []
    if "sleep" in modes:
        return "sleep"
    if "dictation" in modes and "command" not in modes:
        return "dictation"
    if "dictation" in modes and "command" in modes:
        return "mixed"
    return "command"


def _is_whisper_active() -> bool:
    try:
        return actions.user.whisper_is_enabled()
    except Exception:
        return False


def _get_buttons(rect: Rect, scale: float) -> list[HudButton]:
    current_mode = _get_current_mode()
    whisper_on = _is_whisper_active()

    pad_y = 8.0 * scale
    btn_gap = 8.0 * scale
    btn_h = rect.height - (pad_y * 2)
    btn_w = btn_h  # Square buttons (1:1 aspect ratio)

    # 20.0 * scale reserved on the left for the drag handle dots
    handle_w = 20.0 * scale
    start_x = rect.x + handle_w

    btn_defs = [
        ("sleep", current_mode == "sleep", _toggle_sleep),
        ("command", current_mode in ("command", "mixed"), actions.user.command_mode),
        ("dictation", current_mode == "dictation", actions.user.dictation_mode),
        ("whisper", whisper_on, actions.user.whisper_toggle),
    ]

    buttons = []
    x_offset = start_x
    y_offset = rect.y + pad_y
    for btn_id, active, callback in btn_defs:
        b_rect = Rect(x_offset, y_offset, btn_w, btn_h)
        buttons.append(HudButton(id=btn_id, rect=b_rect, is_active=active, on_click=callback))
        x_offset += btn_w + btn_gap

    return buttons


def _draw_drag_handle(c: SkiaCanvas, rect: Rect, scale: float):
    c.paint.style = c.paint.Style.FILL
    c.paint.color = "6c7086"  # Muted grip dots (Catppuccin overlay)

    dot_r = 1.4 * scale
    col1_x = rect.x + 8.0 * scale
    col2_x = rect.x + 12.0 * scale

    center_y = rect.y + rect.height / 2.0
    row_gap = 5.5 * scale
    rows_y = [center_y - row_gap, center_y, center_y + row_gap]

    for y in rows_y:
        c.draw_circle(col1_x, y, dot_r)
        c.draw_circle(col2_x, y, dot_r)


def _toggle_sleep():
    try:
        if actions.speech.enabled():
            actions.speech.disable()
        else:
            actions.speech.enable()
    except Exception:
        pass


# Official Talon default HUD & library SVG paths
PATH_MIC_STAND = skia.Path.from_svg("M5 11C5 17 8 20 12 20S19 17 19 11M12 20V23M8 23H16")
PATH_WAVE = skia.Path.from_svg("M2 10v3 M6 6v11 M10 3v18 M14 8v7 M18 5v13 M22 10v3")


def _draw_box(c: SkiaCanvas, rect: Rect, r: float):
    try:
        c.draw_round_rect(rect, r, r)
    except Exception:
        c.draw_rect(rect)


def _draw_mic_icon(c: SkiaCanvas, ox: float, oy: float, s: float, is_awake: bool, color: str, stroke_w: float):
    c.paint.color = color

    # Microphone capsule from Talon default HUD (rect x=8, y=2, w=8, h=14, rx=4)
    capsule = Rect(ox + 8.0 * s, oy + 2.0 * s, 8.0 * s, 14.0 * s)
    if is_awake:
        c.paint.style = c.paint.Style.FILL
        _draw_box(c, capsule, 4.0 * s)
    c.paint.style = c.paint.Style.STROKE
    c.paint.stroke_width = stroke_w
    _draw_box(c, capsule, 4.0 * s)

    # Microphone stand & cradle from Talon default HUD (evaluated in 24x24 space)
    c.save()
    c.translate(ox, oy)
    c.scale(s, s)
    c.paint.stroke_width = stroke_w / s
    c.draw_path(PATH_MIC_STAND)
    c.restore()

    # Diagonal slash when sleeping/muted
    if not is_awake:
        c.paint.stroke_width = stroke_w * 1.1
        c.draw_line(ox + 3.0 * s, oy + 21.0 * s, ox + 21.0 * s, oy + 3.0 * s)


def _draw_command_icon(c: SkiaCanvas, ox: float, oy: float, s: float, color: str, stroke_w: float):
    c.paint.style = c.paint.Style.STROKE
    c.paint.stroke_width = stroke_w
    c.paint.color = color

    # Chevron '>'
    c.draw_line(ox + 4.0 * s, oy + 5.0 * s, ox + 11.0 * s, oy + 12.0 * s)
    c.draw_line(ox + 11.0 * s, oy + 12.0 * s, ox + 4.0 * s, oy + 19.0 * s)

    # Underscore cursor '_'
    c.draw_line(ox + 13.0 * s, oy + 19.0 * s, ox + 20.0 * s, oy + 19.0 * s)


def _draw_dictation_icon(c: SkiaCanvas, ox: float, oy: float, s: float, color: str, stroke_w: float):
    c.paint.style = c.paint.Style.STROKE
    c.paint.stroke_width = stroke_w
    c.paint.color = color

    # Serif 'T'
    # Top horizontal crossbar
    c.draw_line(ox + 4.0 * s, oy + 4.0 * s, ox + 20.0 * s, oy + 4.0 * s)
    # Left serif drop
    c.draw_line(ox + 4.0 * s, oy + 4.0 * s, ox + 4.0 * s, oy + 6.5 * s)
    # Right serif drop
    c.draw_line(ox + 20.0 * s, oy + 4.0 * s, ox + 20.0 * s, oy + 6.5 * s)

    # Vertical stem
    c.draw_line(ox + 12.0 * s, oy + 4.0 * s, ox + 12.0 * s, oy + 20.0 * s)

    # Bottom serif base
    c.draw_line(ox + 8.0 * s, oy + 20.0 * s, ox + 16.0 * s, oy + 20.0 * s)


def _draw_whisper_icon(c: SkiaCanvas, ox: float, oy: float, s: float, is_active: bool, color: str, stroke_w: float):
    c.paint.style = c.paint.Style.STROKE
    c.paint.color = color

    # Audio sound wave from Talon's official icon set (evaluated in 24x24 space)
    c.save()
    c.translate(ox, oy)
    c.scale(s, s)
    c.paint.stroke_width = stroke_w / s
    c.draw_path(PATH_WAVE)
    c.restore()


def on_draw(c: SkiaCanvas):
    try:
        scale = _get_scale()
        box_r = 12.0 * scale
        btn_r = 10.0 * scale
        border_stroke = 1.5 * scale

        # Optional rounded stroke caps/joins
        try:
            c.paint.stroke_cap = c.paint.StrokeCap.ROUND
            c.paint.stroke_join = c.paint.StrokeJoin.ROUND
        except Exception:
            pass

        # 1. Background bar
        c.paint.style = c.paint.Style.FILL
        c.paint.color = COLOR_BG
        _draw_box(c, c.rect, box_r)

        # Background border
        c.paint.style = c.paint.Style.STROKE
        c.paint.stroke_width = border_stroke
        c.paint.color = COLOR_BORDER
        _draw_box(c, c.rect, box_r)

        # Drag handle grip dots
        _draw_drag_handle(c, c.rect, scale)

        # 2. Draw buttons
        whisper_active = _is_whisper_active()
        speech_enabled = False
        try:
            speech_enabled = actions.speech.enabled()
        except Exception:
            pass

        buttons = _get_buttons(c.rect, scale)

        for btn in buttons:
            if btn.is_active:
                if whisper_active:
                    fill_color = COLOR_ACTIVE_WHISPER_BG
                    border_color = COLOR_ACTIVE_WHISPER_BORDER
                    icon_color = COLOR_ACTIVE_WHISPER_ICON
                else:
                    fill_color = COLOR_ACTIVE_DEFAULT_BG
                    border_color = COLOR_ACTIVE_DEFAULT_BORDER
                    icon_color = COLOR_ACTIVE_DEFAULT_ICON
                btn_stroke = 2.0 * scale
            else:
                fill_color = COLOR_BTN_INACTIVE_BG
                border_color = COLOR_BTN_BORDER_INACTIVE
                icon_color = COLOR_TEXT_INACTIVE
                btn_stroke = 1.2 * scale

            # Button Fill
            c.paint.style = c.paint.Style.FILL
            c.paint.color = fill_color
            _draw_box(c, btn.rect, btn_r)

            # Button Border
            c.paint.style = c.paint.Style.STROKE
            c.paint.stroke_width = btn_stroke
            c.paint.color = border_color
            _draw_box(c, btn.rect, btn_r)

            # Draw Button Icon
            icon_box_size = 28.0 * scale
            ox = btn.rect.x + (btn.rect.width - icon_box_size) / 2.0
            oy = btn.rect.y + (btn.rect.height - icon_box_size) / 2.0
            s = icon_box_size / 24.0
            icon_stroke = 1.6 * scale

            if btn.id == "sleep":
                _draw_mic_icon(c, ox, oy, s, is_awake=speech_enabled, color=icon_color, stroke_w=icon_stroke)
            elif btn.id == "command":
                _draw_command_icon(c, ox, oy, s, color=icon_color, stroke_w=icon_stroke)
            elif btn.id == "dictation":
                _draw_dictation_icon(c, ox, oy, s, color=icon_color, stroke_w=icon_stroke)
            elif btn.id == "whisper":
                _draw_whisper_icon(c, ox, oy, s, is_active=whisper_active, color=icon_color, stroke_w=icon_stroke)

    except Exception as e:
        import traceback
        print(f"[custom_hud] on_draw exception: {e}")
        traceback.print_exc()


def on_mouse(e: MouseEvent):
    global last_mouse_pos, is_dragging, _hud_x, _hud_y
    if not canvas:
        return

    scale = _get_scale()
    if e.event == "mousedown" and e.button == 0:
        clicked_button = None
        for btn in _get_buttons(canvas.rect, scale):
            if btn.rect.x <= e.gpos.x <= (btn.rect.x + btn.rect.width) and \
               btn.rect.y <= e.gpos.y <= (btn.rect.y + btn.rect.height):
                clicked_button = btn
                break

        if clicked_button:
            print(f"[custom_hud] Button clicked: {clicked_button.id}")
            clicked_button.on_click()
            refresh_hud()
        else:
            is_dragging = True
            last_mouse_pos = e.gpos

    elif e.event == "mousemove" and is_dragging and last_mouse_pos:
        dx = e.gpos.x - last_mouse_pos.x
        dy = e.gpos.y - last_mouse_pos.y
        last_mouse_pos = e.gpos
        _hud_x += dx
        _hud_y += dy
        canvas.move(_hud_x, _hud_y)
        storage.set(STORAGE_KEY_POS, [int(_hud_x), int(_hud_y)])

    elif e.event == "mouseup" and e.button == 0:
        is_dragging = False
        last_mouse_pos = None


def refresh_hud():
    if canvas:
        canvas.freeze()


def show_hud():
    global canvas, _hud_x, _hud_y
    scale = _get_scale()
    hud_w, hud_h = _get_dimensions(scale)

    if canvas:
        if int(canvas.rect.width) != int(hud_w) or int(canvas.rect.height) != int(hud_h):
            hide_hud()
        else:
            refresh_hud()
            return

    main_screen = ui.main_screen()
    default_x = main_screen.rect.x + (main_screen.rect.width - hud_w) / 2
    default_y = main_screen.rect.y + (40 * scale)

    pos = storage.get(STORAGE_KEY_POS, [default_x, default_y])
    _hud_x = float(pos[0])
    _hud_y = float(pos[1])
    print(f"[custom_hud] Creating Canvas at ({_hud_x}, {_hud_y}, {hud_w}, {hud_h}) with scale {scale}")

    canvas = Canvas.from_rect(Rect(_hud_x, _hud_y, hud_w, hud_h))
    canvas.blocks_mouse = True
    canvas.draggable = True
    canvas.register("draw", on_draw)
    canvas.register("mouse", on_mouse)
    canvas.freeze()
    storage.set(STORAGE_KEY_SHOW, True)


def hide_hud():
    global canvas
    if canvas:
        canvas.unregister("draw", on_draw)
        canvas.unregister("mouse", on_mouse)
        canvas.close()
        canvas = None
    storage.set(STORAGE_KEY_SHOW, False)


def _recreate_hud():
    hide_hud()
    show_hud()


@mod.action_class
class Actions:
    def custom_hud_show():
        """Show custom mode HUD."""
        show_hud()

    def custom_hud_hide():
        """Hide custom mode HUD."""
        hide_hud()

    def custom_hud_toggle():
        """Toggle custom mode HUD visibility."""
        if canvas:
            hide_hud()
        else:
            show_hud()

    def custom_hud_scale_up():
        """Increase custom HUD scale by 0.2."""
        current = _get_scale()
        new_scale = round(current + 0.2, 1)
        storage.set(STORAGE_KEY_SCALE, new_scale)
        print(f"[custom_hud] Scale up -> {new_scale}")
        _recreate_hud()

    def custom_hud_scale_down():
        """Decrease custom HUD scale by 0.2."""
        current = _get_scale()
        new_scale = max(0.8, round(current - 0.2, 1))
        storage.set(STORAGE_KEY_SCALE, new_scale)
        print(f"[custom_hud] Scale down -> {new_scale}")
        _recreate_hud()

    def custom_hud_scale_reset():
        """Reset custom HUD scale to default."""
        storage.set(STORAGE_KEY_SCALE, 0.0)
        print("[custom_hud] Scale reset to auto-detect")
        _recreate_hud()


def _hide_default_hud_safely():
    try:
        actions.gui.toggle_hud(False)
    except Exception:
        pass


def on_ready():
    show_hud()
    cron.after("1s", _hide_default_hud_safely)
    registry.register("update_contexts", lambda: refresh_hud())
    cron.interval("500ms", refresh_hud)


app.register("ready", on_ready)

# Initialize immediately if Talon is already running
if not canvas:
    show_hud()
    cron.after("1s", _hide_default_hud_safely)
