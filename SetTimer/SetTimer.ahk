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
            timerType := this.Prompt("timerType")
            if (timerType == -1)
                return
            timerDuration := this.Prompt("duration")
            if (timerDuration == -1)
                return
            timerAction := this.Prompt(timerType)
            if (timerAction == -1)
                return

            Settings.Timer.Insert(new CTimer(timerType, timerDuration, timerAction))
            this.timer := Settings.Timer[Settings.Timer.MaxIndex()]
            this.timer.Title := this.moduleName
            this.timer.Text  := "Lorem ipsum dolor sum"
            this.timer.ShowTimer()
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
        } else if (arg == "Message timer") {
            Prompt.Title := this.moduleName " - Message text"
            Prompt.Text := "Enter message text:"
            Prompt.DataType := "Text"
            Prompt.Cancel := true
            return Prompt.prompt()
        } else if (arg == "Shutdown timer") {
            return true
        } else if (arg == "Run program timer") {
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

class CTimer
{
    static Time := ""
    static Text := ""
    static ShowProgress := 1
    static Restart := 1

    __New(type, duration, action)
    {
        if (!this.tmpGUINum)
            this.tmpGUINum := GetFreeGuiNum(10)
    }

    ShowTimer()
    {
        GUINum := this.tmpGUINum
        Gui, %GUINum%:Add, Text, hwndEventName w200,% this.Text
        Gui, %GUINum%:Add, Progress, hwndProgress w200 -Smooth, 100
        GUI, %GUINum%:Add, Text, hwndText w200, Time left:
        GUI, %GUINum%:Add, Button, hwndStartPause gTimer_StartPause y4 w100, Pause
        GUI, %GUINum%:Add, Button, hwndStop gTimer_Stop y+4 w100, Stop
        GUI, %GUINum%:Add, Button, hwndReset gTimer_Reset y+4 w100, Reset
        GUI, %GUINum%:+AlwaysOnTop -SysMenu -Resize
        Sleep 10
        GUI, %GUINum%:Show,, % this.Title
        this.tmpProgress := Progress
        this.tmpText := Text
        this.tmpStartPause := StartPause
        this.tmpStop := Stop
        this.tmpResetHandle := Reset
        this.tmpEventName := EventName
        SetTimer, UpdateTimerProgress, 1000
    }

    StartPause()
    {
        if (this.tmpIsPaused)
            this.Start()
        else
            this.Pause()
    }

    Start()
    {
        if (!this.tmpIsPaused)
        {
            this.tmpStart := A_TickCount
            this.tmpStartNice := A_Now
        }
        else
        {
            this.tmpStart := A_TickCount - this.tmpIsPaused ;Also stores time that passed already
            nicetime := A_Now
            nicetime += -this.tmpIsPaused * 1000, seconds
            this.tmpStartNice := nicetime
        }
        this.tmpIsPaused := false
        if (this.ShowProgress && this.tmpGUINum)
        {
            hwndStartPause := this.tmpStartPause
            if (!this.tmpReset)
                ControlSetText,,Pause, ahk_id %hwndStartPause%
        }
    }

    Pause()
    {
        if (this.ShowProgress && this.tmpGUINum)
        {
            hwndStartPause := this.tmpStartPause
            if (!this.tmpReset)
                ControlSetText,,Start, ahk_id %hwndStartPause%
        }
        if (!this.tmpIsPaused)
            this.tmpIsPaused := A_TickCount - this.tmpStart
    }

    Stop(Event)
    {
        Event.SetEnabled(false)
        Event.Trigger.Disable(Event)
    }

    Reset()
    {
        this.tmpReset := 1
        if (this.tmpIsPaused)
            this.tmpIsPaused := 0.001 ;one millisecond shouldn't be too bad :)
        this.tmpStart := A_TickCount
        this.tmpStartNice := A_Now
    }
}

Timer_StartPause:
TimerEventFromGUINumber().StartPause()
return
Timer_Stop:
TimerEventFromGUINumber().Stop(TimerEventFromGUINumber())
return
Timer_Reset:
TimerEventFromGUINumber().Reset()
return
TimerEventFromGUINumber()
{
    for index, Timer in Settings.Timer
        if (Timer.Is(CTimer) && Timer.tmpGUINum = A_GUI)
            return Timer
    return 0
}

; Called once a second to update the progress on all timer windows and trigger the timers whose time has come
UpdateTimerProgress:
UpdateTimerProgress()
EventSystem.OnTrigger(new CTimerTrigger())
return

UpdateTimerProgress()
{
    for index, Event in EventSystem.Events
        GoSub UpdateTimerProgress_InnerLoop
    for index, Event in EventSystem.TemporaryEvents
        GoSub UpdateTimerProgress_InnerLoop
    return

    UpdateTimerProgress_InnerLoop:
    if (Event.Trigger.Is(CTimerTrigger)) ;Update all timers
    {
        timer := Event.Trigger
        if (Event.Enabled && (!timer.tmpIsPaused || timer.tmpReset) && timer.ShowProgress && timer.tmpGUINum)
        {
            GUINum := timer.tmpGUINum
            progress := Round(100 - (A_TickCount - timer.tmpStart)/timer.Time * 100)
            hours := max(Floor((timer.Time - (A_TickCount - timer.tmpStart)) / 1000 / 3600),0)
            minutes := max(Floor(((timer.Time - (A_TickCount - timer.tmpStart)) / 1000 - hours * 3600)/60),0)
            seconds := max(Floor(((timer.Time - (A_TickCount - timer.tmpStart)) / 1000 - hours * 3600 - minutes * 60))+1,0)
            Time := "Time left: " (strLen(hours) = 1 ? "0" hours : hours) ":" (strLen(minutes) = 1 ? "0" minutes : minutes) ":" (strLen(seconds) = 1 ? "0" seconds : seconds)
            hwndProgress := timer.tmpProgress
            SendMessage, 0x402, progress,0,, ahk_id %hwndProgress%
            hwndtext := timer.tmpText
            ControlSetText,,%Time%, ahk_id %hwndtext%
            hwndEventName := timer.tmpEventName
            timer.tmpReset := 0
        }
    }
    return
}
