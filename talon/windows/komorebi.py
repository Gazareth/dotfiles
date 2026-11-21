import atexit
import ctypes
from ctypes import wintypes
import json
import os
from pathlib import Path
import subprocess
import threading
import time

from talon import Module, actions, app, cron, ui

try:
    from ..dotfiles_sync import find_source_dir
except ImportError:
    from user.dotfiles_sync import find_source_dir

mod = Module()

CREATE_NO_WINDOW = 0x08000000


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


def _is_komorebi_running() -> bool:
    """Checks if komorebi.exe is currently running."""
    if app.platform != "windows":
        return False
    try:
        res = subprocess.run(
            ["tasklist", "/FI", "IMAGENAME eq komorebi.exe", "/NH"],
            capture_output=True,
            text=True,
            creationflags=CREATE_NO_WINDOW,
            timeout=2,
        )
        return "komorebi.exe" in res.stdout.lower()
    except Exception:
        return False


def _is_komorebi_ahk_running() -> bool:
    """Checks if komorebi.ahk is currently running."""
    if app.platform != "windows":
        return False
    try:
        ps_check = (
            "Get-CimInstance Win32_Process | "
            "Where-Object { $_.Name -match 'AutoHotkey' -and $_.CommandLine -like '*komorebi.ahk*' } | "
            "Select-Object -ExpandProperty ProcessId -First 1"
        )
        res = subprocess.run(
            ["powershell", "-NoProfile", "-Command", ps_check],
            capture_output=True,
            text=True,
            creationflags=CREATE_NO_WINDOW,
            timeout=3,
        )
        return bool(res.stdout.strip())
    except Exception:
        return False


def _start_komorebi() -> None:
    """Launches the komorebi AutoHotkey script if not already running."""
    if app.platform != "windows":
        return

    script_path = _find_komorebi_script()
    if not script_path:
        print("[komorebi] Could not locate Windows/Autohotkey/komorebi.ahk.")
        return

    if _is_komorebi_running() and _is_komorebi_ahk_running():
        print("[komorebi] komorebi and komorebi.ahk are already running.")
        cron.after("1s", _trigger_arrange_desktops)
        return

    print(f"[komorebi] Starting komorebi via {script_path}...")
    os.startfile(str(script_path))
    cron.after("4s", _trigger_arrange_desktops)


def _stop_komorebi() -> None:
    """Restores all windows and exits komorebi and komorebi.ahk."""
    if app.platform != "windows":
        return

    print("[komorebi] Stopping komorebi and restoring windows...")

    # 1. Restore all windows and stop komorebic daemon
    try:
        subprocess.run(
            ["komorebic", "restore-windows"],
            creationflags=CREATE_NO_WINDOW,
            timeout=2,
        )
    except Exception:
        pass

    try:
        subprocess.run(
            ["komorebic", "stop"],
            creationflags=CREATE_NO_WINDOW,
            timeout=2,
        )
    except Exception:
        pass

    # 2. Stop komorebi.ahk AutoHotkey process
    try:
        ps_stop_ahk = (
            "Get-CimInstance Win32_Process | "
            "Where-Object { $_.Name -match 'AutoHotkey' -and $_.CommandLine -like '*komorebi.ahk*' } | "
            "ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"
        )
        subprocess.run(
            ["powershell", "-NoProfile", "-Command", ps_stop_ahk],
            creationflags=CREATE_NO_WINDOW,
            timeout=3,
        )
    except Exception:
        pass

    # 3. Ensure komorebi.exe process is closed
    try:
        subprocess.run(
            ["powershell", "-NoProfile", "-Command", "Stop-Process -Name 'komorebi' -Force -ErrorAction SilentlyContinue"],
            creationflags=CREATE_NO_WINDOW,
            timeout=2,
        )
    except Exception:
        pass

    print("[komorebi] Stopped.")


def _get_current_workspace() -> int:
    """Returns currently focused Komorebi workspace index (0-based), or -1 if unknown."""
    if app.platform != "windows":
        return -1
    try:
        res = subprocess.run(
            ["komorebic", "query", "focused-workspace-index"],
            capture_output=True,
            text=True,
            creationflags=CREATE_NO_WINDOW,
            timeout=1,
        )
        if res.returncode == 0:
            return int(res.stdout.strip())
    except Exception:
        pass
    return -1


def _get_komorebi_state() -> dict | None:
    """Returns the parsed komorebic state JSON, or None on failure."""
    if app.platform != "windows":
        return None
    try:
        res = subprocess.run(
            ["komorebic", "state"],
            capture_output=True,
            text=True,
            creationflags=CREATE_NO_WINDOW,
            timeout=2,
        )
        if res.returncode == 0 and res.stdout.strip():
            return json.loads(res.stdout)
    except Exception as e:
        print(f"[komorebi] Error getting state: {e}")
    return None


def _focus_hwnd(hwnd: int) -> None:
    """Brings a window to the foreground and focuses it."""
    try:
        for w in ui.windows():
            for attr in ("handle", "hwnd", "id"):
                if getattr(w, attr, None) == hwnd:
                    w.focus()
                    break
    except Exception:
        pass

    user32 = ctypes.windll.user32
    user32.ShowWindow(hwnd, 9)  # SW_RESTORE
    user32.SetForegroundWindow(hwnd)


def _find_window_in_komorebi(exe: str = "", title: str = "") -> tuple[int, int] | None:
    """
    Finds a window in Komorebi state across all workspaces.
    Returns (workspace_index, hwnd) or None.
    """
    state = _get_komorebi_state()
    if not state:
        return None
    try:
        focused_mon = state.get("monitors", {}).get("focused", 0)
        monitors = state.get("monitors", {}).get("elements", [])
        if not monitors or focused_mon >= len(monitors):
            return None
        workspaces = monitors[focused_mon].get("workspaces", {}).get("elements", [])
        for ws_idx, ws in enumerate(workspaces):
            for container in ws.get("containers", {}).get("elements", []):
                for win in container.get("windows", {}).get("elements", []):
                    w_exe = win.get("exe", "").lower()
                    w_title = win.get("title", "").lower()
                    if exe and exe.lower() in w_exe:
                        return ws_idx, win.get("hwnd", 0)
                    if title and title.lower() in w_title:
                        return ws_idx, win.get("hwnd", 0)
    except Exception:
        pass
    return None


def _is_edge_main(w: dict) -> bool:
    """Checks if a window object belongs to the Main Edge profile."""
    exe = (w.get("exe") or "").lower()
    title = (w.get("title") or "").lower()
    if "msedge" in exe:
        if "main" in title:
            return True
        if "gamedev" not in title:
            return True
    return False


def _is_code_primary(w: dict) -> bool:
    """Checks if a window object is Antigravity (preferred primary for workspace 6)."""
    exe = (w.get("exe") or "").lower()
    return "antigravity" in exe


def _arrange_workspace(ws_idx: int, is_primary_fn) -> bool:
    """
    Arranges all windows on a workspace into a single stack and guarantees
    the primary window (matching is_primary_fn) is at index 0 (leftmost tab).
    """
    # 1. Switch to target workspace
    subprocess.run(
        ["komorebic", "focus-workspace", str(ws_idx)],
        creationflags=CREATE_NO_WINDOW,
        timeout=1,
    )
    time.sleep(0.15)

    state = _get_komorebi_state()
    if not state:
        return False

    focused_mon = state.get("monitors", {}).get("focused", 0)
    monitors = state.get("monitors", {}).get("elements", [])
    if not monitors or focused_mon >= len(monitors):
        return False

    workspaces = monitors[focused_mon].get("workspaces", {}).get("elements", [])
    if ws_idx >= len(workspaces):
        return False

    ws = workspaces[ws_idx]
    containers = ws.get("containers", {}).get("elements", [])
    all_windows = [
        w for c in containers for w in c.get("windows", {}).get("elements", [])
    ]

    if len(all_windows) < 2:
        return False

    # 2. If windows are separated across multiple containers, stack them together
    if len(containers) > 1:
        subprocess.run(
            ["komorebic", "stack-all"],
            creationflags=CREATE_NO_WINDOW,
            timeout=1,
        )
        time.sleep(0.2)
        state = _get_komorebi_state()
        if not state:
            return False
        workspaces = state.get("monitors", {}).get("elements", [])[focused_mon].get("workspaces", {}).get("elements", [])
        ws = workspaces[ws_idx]
        containers = ws.get("containers", {}).get("elements", [])

    if not containers:
        return False

    stack_windows = containers[0].get("windows", {}).get("elements", [])
    if len(stack_windows) < 2:
        return False

    # 3. Find the current index of the primary window in the stack
    primary_idx = None
    for idx, w in enumerate(stack_windows):
        if is_primary_fn(w):
            primary_idx = idx
            break

    # If the primary window is not at index 0, cycle it to index 0
    if primary_idx is not None and primary_idx > 0:
        subprocess.run(
            ["komorebic", "focus-stack-window", str(primary_idx)],
            creationflags=CREATE_NO_WINDOW,
            timeout=1,
        )
        time.sleep(0.1)
        for _ in range(primary_idx):
            subprocess.run(
                ["komorebic", "cycle-stack-index", "previous"],
                creationflags=CREATE_NO_WINDOW,
                timeout=1,
            )
            time.sleep(0.08)

    # 4. Ensure index 0 (primary window) has focus
    subprocess.run(
        ["komorebic", "focus-stack-window", "0"],
        creationflags=CREATE_NO_WINDOW,
        timeout=1,
    )
    time.sleep(0.1)
    return True


_arranging_lock = threading.Lock()


def _arrange_desktops() -> None:
    """
    Arranges Desktop 1 (Edge Main + GameDev) and Desktop 6 (Antigravity + VSCode):
    - On Desktop 1, guarantees Edge Main is index 0 (leftmost tab).
    - On Desktop 6, guarantees Antigravity is index 0 (leftmost tab).
    - Returns focus to Desktop 1.
    """
    if app.platform != "windows":
        return

    _arrange_workspace(0, _is_edge_main)
    _arrange_workspace(5, _is_code_primary)

    # Return focus to Desktop 1 (Workspace 0)
    subprocess.run(
        ["komorebic", "focus-workspace", "0"],
        creationflags=CREATE_NO_WINDOW,
        timeout=1,
    )


def _arrange_desktops_worker() -> None:
    if not _arranging_lock.acquire(blocking=False):
        return
    try:
        _arrange_desktops()
    finally:
        _arranging_lock.release()


def _trigger_arrange_desktops() -> None:
    """Launches _arrange_desktops in a background thread if not already running."""
    threading.Thread(target=_arrange_desktops_worker, daemon=True).start()


def _find_terminal_hwnds() -> tuple[int, int] | tuple[None, None]:
    """Finds (terminal_hwnd, xaml_hwnd) for Windows Terminal."""
    user32 = ctypes.windll.user32
    hdesk = user32.OpenInputDesktop(0, False, 0x01FF)
    if hdesk:
        user32.SetThreadDesktop(hdesk)

    hwnds = []
    WNDENUMPROC = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)

    def cb(h, l):
        buf = ctypes.create_unicode_buffer(256)
        user32.GetClassNameW(h, buf, 256)
        if buf.value == "CASCADIA_HOSTING_WINDOW_CLASS":
            hwnds.append(h)
        return True

    user32.EnumDesktopWindows(hdesk, WNDENUMPROC(cb), 0)
    if not hwnds:
        return None, None

    wt = hwnds[0]
    xaml = user32.FindWindowExW(wt, 0, "Windows.UI.Composition.DesktopWindowContentBridge", None)
    return wt, xaml


def _switch_or_check_terminal_tab(xaml_hwnd: int, target_title: str) -> tuple[bool, str]:
    """
    Single-shot PowerShell UIA helper:
    - If a tab title contains target_title (case-insensitive), selects it and returns (True, tab_name).
    - If not found, returns (False, active_tab_name).
    """
    ps_code = """
Add-Type -TypeDefinition '
using System;
using System.Runtime.InteropServices;
public class WinUtil {
    [DllImport("user32.dll")]
    public static extern IntPtr OpenInputDesktop(uint dwFlags, bool fInherit, uint dwDesiredAccess);
    [DllImport("user32.dll")]
    public static extern bool SetThreadDesktop(IntPtr hDesktop);
}
'
$hdesk = [WinUtil]::OpenInputDesktop(0, $false, 0x01FF)
if ($hdesk -ne [IntPtr]::Zero) {
    [WinUtil]::SetThreadDesktop($hdesk) | Out-Null
}

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$h = [IntPtr][int64]$env:TARGET_HWND
$target = $env:TARGET_TITLE
$root = [System.Windows.Automation.AutomationElement]::FromHandle($h)
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)
$tabs = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)

$activeTab = $null
$foundTab = $null

for ($i = 0; $i -lt $tabs.Count; $i++) {
    $t = $tabs[$i]
    $sel = $false
    try {
        $sel = $t.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Current.IsSelected
    } catch {}
    if ($sel) { $activeTab = $t }
    if ($target -and $t.Current.Name.ToLower().Contains($target.ToLower())) {
        $foundTab = $t
        break
    }
}

if ($foundTab) {
    try {
        $foundTab.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
        Write-Output ("FOUND:" + $foundTab.Current.Name)
    } catch {
        Write-Output ("ERR_SELECT:" + $_)
    }
} else {
    $name = if ($activeTab) { $activeTab.Current.Name } else { "" }
    Write-Output ("NOT_FOUND:" + $name)
}
"""
    env = os.environ.copy()
    env["TARGET_HWND"] = str(xaml_hwnd)
    env["TARGET_TITLE"] = target_title
    res = subprocess.run(
        ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", ps_code],
        env=env,
        capture_output=True,
        text=True,
        creationflags=CREATE_NO_WINDOW,
        timeout=3,
    )
    out = res.stdout.strip()
    if out.startswith("FOUND:"):
        return True, out[6:]
    elif out.startswith("NOT_FOUND:"):
        return False, out[10:]
    return False, out


def _is_tab_idle(title: str) -> bool:
    """Checks if a tab title represents an idle shell."""
    title_lower = title.strip().lower()
    idle_keywords = ["powershell", "pwsh", "cmd", "command prompt", "bash", "zsh", "wsl"]
    for kw in idle_keywords:
        if kw in title_lower:
            return True
    return False


@mod.action_class
class Actions:
    def start_komorebi():
        """Launches the komorebi AutoHotkey script if not already running."""
        _start_komorebi()

    def stop_komorebi():
        """Restores windows and exits komorebi and komorebi.ahk."""
        _stop_komorebi()

    def komorebi_focus_workspace(workspace: int):
        """Switches Komorebi to target workspace index (0-based)."""
        if app.platform != "windows" or workspace < 0:
            return
        try:
            subprocess.run(
                ["komorebic", "focus-workspace", str(workspace)],
                check=False,
                creationflags=CREATE_NO_WINDOW,
                timeout=1,
            )
        except Exception:
            if 0 <= workspace <= 7:
                actions.key(f"f{13 + workspace}")

    def komorebi_focus_last_workspace():
        """Switches Komorebi to the last focused workspace."""
        if app.platform != "windows":
            return
        try:
            subprocess.run(
                ["komorebic", "focus-last-workspace"],
                check=False,
                creationflags=CREATE_NO_WINDOW,
                timeout=1,
            )
        except Exception as e:
            print(f"[komorebi] Error focusing last workspace: {e}")

    def focus_or_open(
        exe: str = "",
        title: str = "",
        workspace: int = -1,
        launch: str = "",
    ) -> bool:
        """
        Generic focus-or-open action:
        1. Checks running windows (Talon ui.windows and Komorebi state).
        2. If running: switches to target/window workspace and focuses the window.
        3. If not running: switches to target workspace and launches executable.
        """
        if app.platform != "windows":
            return False

        # 1. Search in Talon ui.windows()
        target_win = None
        for w in ui.windows():
            try:
                w_exe = (w.app.exe or w.app.name or "").lower()
                w_title = (w.title or "").lower()
                if exe and exe.lower() in w_exe:
                    target_win = w
                    break
                if title and title.lower() in w_title:
                    target_win = w
                    break
            except Exception:
                continue

        # 2. Search in Komorebi state (covers cloaked/hidden windows across all workspaces)
        komo_info = _find_window_in_komorebi(exe=exe, title=title)

        if target_win or komo_info:
            target_ws = workspace if workspace >= 0 else (komo_info[0] if komo_info else -1)
            if target_ws >= 0:
                actions.user.komorebi_focus_workspace(target_ws)
                actions.sleep("100ms")

            if target_win:
                target_win.focus()
            elif komo_info:
                hwnd = komo_info[1]
                user32 = ctypes.windll.user32
                user32.ShowWindow(hwnd, 9)  # SW_RESTORE
                user32.SetForegroundWindow(hwnd)
            return True

        # 3. Not running: switch to workspace and launch
        if workspace >= 0:
            actions.user.komorebi_focus_workspace(workspace)
            actions.sleep("150ms")

        if launch:
            try:
                ui.launch(path=launch)
            except Exception:
                try:
                    subprocess.Popen(launch, shell=True)
                except Exception as e:
                    print(f"[focus_or_open] Failed to launch {launch}: {e}")
        return False

    def focus_or_open_terminal(
        command: str = "",
        tab_title: str = "",
        workspace: int = 6,
    ):
        """
        Specialized terminal focus-or-open:
        - Switches to workspace 6 (Terminal) and focuses Windows Terminal.
        - If matching tab is open, switches to it.
        - If no matching tab: runs command in an idle tab, or opens a new tab (ctrl-shift-t) if active tab is busy.
        """
        if app.platform != "windows":
            return

        # 1. Focus or launch Windows Terminal on workspace 6
        wt_hwnd, xaml_hwnd = _find_terminal_hwnds()
        if not wt_hwnd:
            actions.user.focus_or_open(
                exe="WindowsTerminal.exe",
                workspace=workspace,
                launch="wt.exe",
            )
            if command:
                actions.sleep("500ms")
                actions.insert(f"{command}\n")
            return

        # Terminal is running: switch workspace and focus
        if workspace >= 0:
            actions.user.komorebi_focus_workspace(workspace)
            actions.sleep("100ms")

        user32 = ctypes.windll.user32
        user32.ShowWindow(wt_hwnd, 9)  # SW_RESTORE
        user32.SetForegroundWindow(wt_hwnd)
        actions.sleep("100ms")

        # 2. Tab management via UIA
        if not xaml_hwnd:
            xaml_hwnd = user32.FindWindowExW(wt_hwnd, 0, "Windows.UI.Composition.DesktopWindowContentBridge", None)

        if not xaml_hwnd or not command:
            return

        target_title = tab_title if tab_title else command
        found, active_tab_title = _switch_or_check_terminal_tab(xaml_hwnd, target_title)

        if found:
            # Successfully selected the tab!
            return

        # No matching tab found: check if active tab is idle
        if _is_tab_idle(active_tab_title):
            actions.insert(f"{command}\n")
        else:
            # Active tab is busy: create a fresh tab
            actions.key("ctrl-shift-t")
            actions.sleep("250ms")
            actions.insert(f"{command}\n")

    def focus_or_open_lazygit():
        """Focuses or opens Lazygit in Windows Terminal on Workspace 6."""
        actions.user.focus_or_open_terminal(
            command="lazygit",
            tab_title="lazygit",
            workspace=6,
        )

    def komorebi_arrange_desktops():
        """Arranges Desktop 1 (Edge Main + GameDev) and Desktop 6 (Antigravity + VSCode) into stacks."""
        _trigger_arrange_desktops()


def _on_ready() -> None:
    """Auto-start komorebi when Talon initializes."""
    if app.platform == "windows":
        _start_komorebi()


def _on_exit() -> None:
    """Auto-stop komorebi when Talon exits."""
    if app.platform == "windows":
        _stop_komorebi()


app.register("ready", _on_ready)
atexit.register(_on_exit)
