; SetTimer - SetTimer.ahk
; author: Lipkau
; created: 2016 12 1

#include lib\ahklib\CPrompt.ahk
#include lib\ahklib\CNotification.ahk

/**
 * TODO:
 *     * Create CTimer class
 */

class SetTimer
{
    static moduleBundle := "ol.modules"
    static moduleName   := "SetTimer"
    static moduleHelp   := "https://github.com/lipkau/ol.modules/wiki/SetTimer"

    Init()
    {
        Settings.Timer := {}
    }

    Execute(method)
    {
        if ((method == "overClock" && this._IsMouseOverClock()) OR (method == "show"))
        {
            if (timerType := this.Prompt("timerType") == -1)
                return
            if (timerDuration := this.Prompt("duration") == -1)
                return
            if (timerAction := this.Prompt(timerType, timerDuration) == -1)
                return

            Settings.Timer.Insert(new CTimer(timerType, timerDuration, timerAction))
            this.timer := Settings.Timer[Settings.Timer.MaxIndex()]
            this.timer.Show()
        }
    }

    Prompt(arg, duration = false)
    {
        if (arg == "timerType") {
            Prompt.Title := this.moduleName
            Prompt.Text := "What type of timer would you like to start?"
            Prompt.DataType := "Selection"
            Prompt.Selection := "Message timer|Shutdown timer|Run program timer"
            Prompt.Cancel := true
            return Prompt.prompt()
        } else if (arg == "duration") {
            Prompt.Title := this.moduleName " - Enter time"
            Prompt.Text := "Enter time [HH:MM:SS]:"
            Prompt.DataType := "Time"
            Prompt.Cancel := true
            return Prompt.prompt()
        } else if (arg == "Message timer" && duration) {
            Prompt.Title := this.moduleName " - Message text"
            Prompt.Text := "Enter message text:"
            Prompt.DataType := "Text"
            Prompt.Cancel := true
            return Prompt.prompt()
        } else if (arg == "Shutdown timer" && duration) {
            return true
        } else if (arg == "Run program timer" && duration) {
            Prompt.Title := this.moduleName " - Select program"
            Prompt.Text := "Enter program to launch"
            Prompt.DataType := "File"
            Prompt.Cancel := true
            return Prompt.prompt()
        }
    }

    _IsMouseOverClock()
    {
        CoordMode, Mouse, Screen
        MouseGetPos, , , , ControlUnderMouse
        result := false
        if (ControlUnderMouse = "TrayClockWClass1")
            result := true
        WriteDebug("IsMouseOverClock()? " result)
        return result
    }
}
