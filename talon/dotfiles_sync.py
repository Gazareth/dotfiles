import os
import re
import shutil
from pathlib import Path
from talon import app, fs

USER_DIR = Path(__file__).resolve().parent
MARKER_FILE = USER_DIR / ".dotfiles_source"
IGNORED_NAMES = {".git", ".dotfiles_source", "__pycache__"}


def find_source_dir() -> Path | None:
    if MARKER_FILE.is_file():
        try:
            candidate = Path(MARKER_FILE.read_text(encoding="utf-8").strip())
            if candidate.is_dir():
                return candidate
        except OSError:
            pass

    workspace = os.environ.get("WORKSPACE")
    if workspace:
        candidate = Path(workspace) / "dotfiles" / "talon"
        if candidate.is_dir():
            return candidate

    ps_profile = (
        Path.home() / "Documents" / "PowerShell" / "Microsoft.PowerShell_profile.ps1"
    )
    if ps_profile.is_file():
        try:
            content = ps_profile.read_text(encoding="utf-8")
            match = re.search(r"\$WORKSPACE\s*=\s*'([^']+)'", content, re.IGNORECASE)
            if match:
                candidate = Path(match.group(1)) / "dotfiles" / "talon"
                if candidate.is_dir():
                    return candidate
        except OSError:
            pass

    return None


def is_ignored(rel_path: Path) -> bool:
    return any(part in IGNORED_NAMES for part in rel_path.parts)


def sync_single_path(source_root: Path, changed_path: Path) -> None:
    try:
        rel_path = changed_path.relative_to(source_root)
    except ValueError:
        return

    if is_ignored(rel_path):
        return

    dest_path = USER_DIR / rel_path

    try:
        if changed_path.is_file():
            dest_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(changed_path, dest_path)
        elif not changed_path.exists():
            if dest_path.is_file():
                dest_path.unlink()
            elif dest_path.is_dir():
                shutil.rmtree(dest_path, ignore_errors=True)
    except OSError as e:
        print(f"[dotfiles_sync] Error syncing {rel_path}: {e}")


def initial_incremental_sync(source_root: Path) -> None:
    for src_file in source_root.rglob("*"):
        if not src_file.is_file():
            continue
        try:
            rel_path = src_file.relative_to(source_root)
        except ValueError:
            continue
        if is_ignored(rel_path):
            continue

        dest_file = USER_DIR / rel_path
        try:
            if not dest_file.is_file() or (
                src_file.stat().st_mtime > dest_file.stat().st_mtime + 0.5
                or src_file.stat().st_size != dest_file.stat().st_size
            ):
                dest_file.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src_file, dest_file)
        except OSError as e:
            print(f"[dotfiles_sync] Startup sync error for {rel_path}: {e}")


def on_ready() -> None:
    if app.platform != "windows":
        return

    source_root = find_source_dir()
    if not source_root:
        print("[dotfiles_sync] Could not locate dotfiles/talon source directory.")
        return

    try:
        if source_root.resolve() == USER_DIR.resolve():
            return
    except OSError:
        return

    initial_incremental_sync(source_root)
    fs.watch(str(source_root), lambda path, _flags: sync_single_path(source_root, Path(path)))
    print(f"[dotfiles_sync] Watching {source_root} -> {USER_DIR}")


app.register("ready", on_ready)
