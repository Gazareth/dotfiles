import ctypes
from ctypes import wintypes
import json
import os
from pathlib import Path
import subprocess
import time

from talon import Module, actions, app, ui

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


def _find_window_in_komorebi(exe: str = "", title: str = "") -> tuple[int, int] | None:
    """
    Finds a window in Komorebi state across all workspaces.
    Returns (workspace_index, hwnd) or None.
    """
    if app.platform != "windows":
        return None
    try:
        res = subprocess.run(
            ["komorebic", "state"],
            capture_output=True,
            text=True,
            creationflags=CREATE_NO_WINDOW,
            timeout=1,
        )
        if res.returncode != 0:
            return None
        state = json.loads(res.stdout)
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
        """Launches the komorebi AutoHotkey script."""
        if app.platform != "windows":
            return

        script_path = _find_komorebi_script()
        if not script_path:
            print("[komorebi] Could not locate Windows/Autohotkey/komorebi.ahk.")
            return

        os.startfile(str(script_path))

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
