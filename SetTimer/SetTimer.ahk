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

    /**
     * Instanciate Module on statup
     */
    Init()
    {
        ; Inject module into global Settings
        Settings.Timer := {}
    }

    /**
     * Entrance point for hotkeys
     *
     * @return void
     */
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
            this.timer.Start()
        }
    }

    /**
     * Open a Prompt to ask the user for conditional input
     *
     * @param   string  arg    contains the condition to decide what to prompt
     * @return  string
     */
    Prompt(arg)
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

    /**
     * Test if mouse is currently over the Clock in the SysTray
     *
     * @return  bool
     */
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

class CTimer extends CRichObject
{
    static Time := ""
    static Text := ""
    static ShowProgress := 1
    static Restart := 1
    static AddControl := Func("AddControl")
    static SubmitControls := Func("SubmitControls")
    static SelectFile := Func("SelectFile")
    static Browse := Func("Browse")

    /**
     * Constructor
     *
     * @param  string   type       Name of the Type of string -> this defines what to do with the action
     * @param  string   duration   Duration of the Timer (HH:MM:SS)
     * @param  string   action     Action for the timer to perform when it elapses
     * @return void
     */
    __New(type, duration, action)
    {
        if (!this.tmpGUINum)
            this.tmpGUINum := GetFreeGuiNum(10)
        this.Action := action
        this.Type := type
        this.tmptime := duration
        timeArray := StrSplit(this.tmptime, ":")
        hours := timeArray[1]
        minutes := timeArray[2]
        seconds := timeArray[3]
        this.Time := (hours * 3600 + minutes * 60 + seconds) * 1000
    }

    /**
     * Guilds a GUI for a Timer
     */
    ShowTimer()
    {
        GUINum := this.tmpGUINum
        Gui, %GUINum%:Add, Text, hwndEventName w200,% this.Text
        Gui, %GUINum%:Add, Progress, hwndProgress w200 -Smooth, 100
        GUI, %GUINum%:Add, Text, hwndText w200, Time left:
        GUI, %GUINum%:Add, Button, hwndStartPause gTimer_StartPause y4 w100, Pause
        GUI, %GUINum%:Add, Button, hwndStop gTimer_Stop y+4 w100, Stop
        GUI, %GUINum%:Add, Button, hwndReset gTimer_Reset y+4 w100, Reset
        GUI, %GUINum%:+AlwaysOnTop -MaximizeBox -Resize
        Sleep 10
        GUI, %GUINum%:Show, AutoSize, % this.Title
        this.tmpProgress := Progress
        this.tmpText := Text
        this.tmpStartPause := StartPause
        this.tmpStop := Stop
        this.tmpResetHandle := Reset
        this.tmpEventName := EventName
    }

/**
 * Starts a Timer
 */
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
        UpdateTimerProgress := Func("UpdateTimerProgress")
        SetTimer, UpdateTimerProgress, 1000
    }

    /**
     * Pause a Timer
     * This pauses a Timer and changes the UI accordingly
     *
     * @return void
     */
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
        UpdateTimerProgress := Func("UpdateTimerProgress")
        SetTimer, UpdateTimerProgress, Off
    }

    /**
     * Toggles the Timer
     *
     * @return void
     */
    StartPause()
    {
        if (this.tmpIsPaused)
            this.Start()
        else
            this.Pause()
    }

    /**
     * Stop a Timer
     * Stops the Timer (that runs every second) and closes the Timer Object
     *
     * @return void
     */
    Stop()
    {
        this.Disable()
        UpdateTimerProgress := Func("UpdateTimerProgress")
        SetTimer, UpdateTimerProgress, Off
    }

    /**
     * Reset a Timer
     * Reset a timer to the original value stored in this.Time
     *
     * @return void
     */
    Reset()
    {
        this.tmpReset := 1
        if (this.tmpIsPaused)
            this.tmpIsPaused := 0.001 ;one millisecond shouldn't be too bad :)
        this.tmpStart := A_TickCount
        this.tmpStartNice := A_Now
    }

    /**
     * Disable a Timer
     * This is done when the Timer runs out, or stopped.
     *
     * @return void
     *
     * TODO:
     *     * include in Close routing of GUI
     */
    Disable()
    {
        this.tmpStart := ""
        this.tmpStartNice := ""
        this.tmpIsPaused := 0
        TimerObj := TimerEventFromGUINumber(this.tmpGUINum)
        if (this.ShowProgress)
        {
            GUINum := this.tmpGUINum
            if (GUINum)
            {
                this.Remove("tmpGUINum")
                this.Remove("tmpProgress")
                this.Remove("tmpText")
                this.Remove("tmpEventName")
                GUI, %GUINum%:Destroy
            }
        }
        ; TODO: delete from Settings?
        ; Settings.Timer
        ; DebugObject("TimerObj")
    }

    /**
     * Check if Timer is run out
     * This is called once per second
     *
     * @return bool:false    if is not run out
     * @return void          if is run out
     */
    ; Called every second to check if time has run out yet
    IsRunOut()
    {
        if (this.tmpStart && !this.tmpIsPaused && A_TickCount > (this.tmpStart + this.Time))
        {
            if (this.Type == "Message timer") {
                ; TODO: send message
                Msgbox % this.Action
            } else if (this.Type == "Shutdown timer") {
                ; TODO: shut down pc
            } else if (this.Type == "Run program timer") {
                ; TODO: run program
                run, % this.Action
            }
            this.Disable()
        }
        return false
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
TimerEventFromGUINumber(guiNum = "")
{
    thisGUI := guiNum ? guiNum : A_GUI
    for index, Timer in Settings.Timer
        if (Timer.Is(CTimer) && Timer.tmpGUINum = thisGUI)
            return Timer
    return 0
}

UpdateTimerProgress()
{
    for index, Timer in Settings.Timer
        GoSub UpdateTimerProgress_InnerLoop
    return

    UpdateTimerProgress_InnerLoop:
        if (Timer.Is(CTimer))
        {
            if ((!timer.tmpIsPaused || timer.tmpReset) && timer.ShowProgress && timer.tmpGUINum)
            {
                GUINum := timer.tmpGUINum
                progress := Round(100 - (A_TickCount - timer.tmpStart)/timer.Time * 100)
                hours := max(Floor((timer.Time - (A_TickCount - timer.tmpStart)) / 1000 / 3600), 0)
                minutes := max(Floor(((timer.Time - (A_TickCount - timer.tmpStart)) / 1000 - hours * 3600)/60), 0)
                seconds := max(Floor(((timer.Time - (A_TickCount - timer.tmpStart)) / 1000 - hours * 3600 - minutes * 60))+1, 0)
                Time := "Time left: " (strLen(hours) = 1 ? "0" hours : hours) ":" (strLen(minutes) = 1 ? "0" minutes : minutes) ":" (strLen(seconds) = 1 ? "0" seconds : seconds)
                hwndProgress := timer.tmpProgress
                SendMessage, 0x402, progress, 0, , ahk_id %hwndProgress%
                hwndtext := timer.tmpText
                ControlSetText, , %Time%, ahk_id %hwndtext%
                timer.tmpReset := 0
                timer.IsRunOut()
            }
        }
    return
}
