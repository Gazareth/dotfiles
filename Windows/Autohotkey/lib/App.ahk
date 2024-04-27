#Requires AutoHotkey v2.0

class WindowsApp {
    __New(Name, Exe, Path, Title := 0) {
        this.Name := Name
        this.Exe := Exe
        this.Path := Path
        this.Title := Title ?? false
        this.Supplemental := false ; supplemental apps will be closed but not opened on mode switch
    }
    IsSupplemental() {
        supplementalApp := this.Clone()
        supplementalApp.Supplemental := true
        return supplementalApp
    }
    ShouldOpen() {
        return !this.Supplemental && !this.IsRunning()
    }
    IsRunning() {
        if this.Title != 0 and WinExist(this.Title) {
            return WinGetPID(this.Title)
        } else {
         return ProcessExist(this.Exe)
        }
    }
    Close() {
        PIDOrName := this.Title != 0 and ProcessExist(this.Title) ? this.Title : this.Exe
        While ProcessExist(PIDOrName)
            ProcessClose PIDOrName
    }
}
