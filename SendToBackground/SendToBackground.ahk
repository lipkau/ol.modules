; SendToBackground - SendToBackground.ahk
; author: Oliver Lipkau <https://github.com/lipkau>
; created: 2018 9 3

#include lib\ahklib\ModuleModel.ahk
#include lib\ahklib\CNotification.ahk

class SendToBackground extends ModuleModel
{
    /**
     * property in which to store the PID of the target window
     */
    static TargetWindow := ""

    /**
     * Method to initialize the module
     */
    Init()
    {
        this.base.__New(A_LineFile)

        ; Only debug message
        WriteDebug("Initializing module", "", "i", this.moduleName)
    }

    /**
     * Method for determining the window that will receive the command
     */
    SetTarget()
    {
        this.TargetWindow := ""
        WriteDebug("cleared target window", "", "i", this.moduleName)

        WinGet, active_pid, PID, A
        WinGetTitle, active_title, ahk_pid %active_pid%

        this.TargetWindow := active_pid
        if (this.TargetWindow)
        {
            Notify(this.moduleName ": Stored new Taget Window", "Stored a new target window:`n" active_title, 4, NotifyIcons.Success)
            WriteDebug("stored new target window", "", "i", this.moduleName)
            WriteDebug("stored window:", "[" active_pid "] " active_title, "debug", this.moduleName)
        }
        else
        {
            Notify(this.moduleName ": Failed to store new Target Window", "", 4, NotifyIcons.Error)
            WriteDebug("failed to store new target window", "", "i", this.moduleName)
        }
    }

    /**
     * Method to trigger the command to be sent
     */
    Trigger()
    {
        if (!this._command)
        {
            WriteDebug("missing command", "", "error", this.moduleName)
            Notify(this.moduleName ": Missing a command", "No command has been defined that should be sent.", 4, NotifyIcons.Error)
            return
        }

        if (!this.TargetWindow)
        {
            WriteDebug("missing target window", "", "error", this.moduleName)
            Notify(this.moduleName ": Missing a target Window", "No Target Window has been set.", 4, NotifyIcons.Error)
            return
        }

        MsgBox, % "Hurray"
        if (this._continuously)
        {
            ; loop
                ; ControlSend, , % this.command, ahk_pid % this.TargetWindow
                ; sleep this._interval
        }
        else
        {
            ; ControlSend, , % this.command, ahk_pid % this.TargetWindow
        }
    }

    /**
     * Private Property
     *     Command to be sent
     *
     * @type  string
     */
    _command[]
    {
        get {
            global SendToBackground_Command
            return SendToBackground_Command
        }
    }

    _continuously[]
    {
        get {
            global SendToBackground_Continuously
            return SendToBackground_Continuously
        }
    }

    _interval[]
    {
        get {
            global SendToBackground_Interval
            return SendToBackground_Interval
        }
    }
}
