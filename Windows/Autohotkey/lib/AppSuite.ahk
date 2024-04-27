#Requires AutoHotkey v2.0

class AppSuite {
    ; Apps is an array of Strings corresponding to WindowsApp objects
    __New(Name, Apps) {
        this.Name := Name
        this.Apps := Apps
    }
    IsInSuite() {
        for app in this.Apps {
            if !app.isRunning()
                return false
        }
        return true
    }
}

class AppSuiteManager {
    __New(appSuites, defaultSuite) {
        this.DefaultSuite := defaultSuite
        this.Suites := AppSuites

        this.CurrentSuite := this.DetectCurrentSuite()
    }
    DetectCurrentSuite() {
        max_apps := Map("num", 0, "suiteId", this.DefaultSuite)
        for suite_id, suite in this.suites {
            len := suite.Apps.Length
            if suite.IsInSuite() && len > max_apps["num"] {
                max_apps["num"] := len
                max_apps.suiteId := suite_id
            }
        }
        return max_apps.suiteId
    }
    CurrentSuiteName() {
        return this.Suites[this.CurrentSuite].Name
    }
    SwitchSuite(newSuite) {
        new_mode_apps := this.Suites[newSuite].Apps
        old_mode_apps := this.Suites[this.CurrentSuite].Apps
        old_mode_apps_running := []

        for o_m_a in old_mode_apps {
            if o_m_a.IsRunning() {
                old_mode_apps_running.Push(o_m_a)
            }
        }

        apps_to_close := new_mode_apps.Subtract(old_mode_apps_running)
        apps_to_open := old_mode_apps_running.Subtract(new_mode_apps)
    
        for app in apps_to_close {
            if app.IsRunning() {
                MsgBox "Closing " . app.Name
                ; app.Close()
            }
        }

        for app in apps_to_open {
            MsgBox "Should open? " . app.Name
            if app.ShouldOpen() {
                MsgBox "Opening " . app.Name
                ; Run app.Path
            }
        }
    
        this.CurrentSuite := newSuite
    }
}