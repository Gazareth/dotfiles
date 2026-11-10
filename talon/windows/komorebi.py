import os
from pathlib import Path
from talon import Module, app

try:
    from ..dotfiles_sync import find_source_dir
except ImportError:
    from user.dotfiles_sync import find_source_dir

mod = Module()


def _find_komorebi_script() -> Path | None:
    """Locate Windows/Autohotkey/komorebi.ahk in the dotfiles repository."""
    talon_source = find_source_dir()
    if talon_source:
        candidate = talon_source.parent / "Windows" / "Autohotkey" / "komorebi.ahk"
        if candidate.is_file():
            return candidate

    repo_candidate = (
        Path(__file__).resolve().parents[2]
        / "Windows"
        / "Autohotkey"
        / "komorebi.ahk"
    )
    if repo_candidate.is_file():
        return repo_candidate

    return None


@mod.action_class
class Actions:
    def start_komorebi():
        """Launches the komorebi AutoHotkey script."""
        if app.platform != "windows":
            return

        script_path = _find_komorebi_script()
        if not script_path:
            print("[komorebi] Could not locate Windows/Autohotkey/komorebi.ahk.")
            return

        os.startfile(str(script_path))
