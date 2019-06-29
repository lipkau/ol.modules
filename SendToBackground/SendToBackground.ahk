; SendToBackground - SendToBackground.ahk
; author: Oliver Lipkau <https://github.com/lipkau>
; created: 2018 9 3

#include lib\ahklib\ModuleModel.ahk
#include %A_LineFile%\..\..\.lib\Notify.ahk

class SendToBackground extends ModuleModel
{
    /**
     * property in which to store the PID of the target window
     */
    static TargetWindow := ""

    /**
     * property to track if a continuouse job is running
     */
    static isRunning := False

    /**
     * Method to initialize the module
     */
    Init()
    {
        this.base.__New(A_LineFile)

        this.isRunning := False
        this.timer := ObjBindMethod(this, "SendCommand")

        a2log_info("Initializing module", "", this.moduleName)
    }

    /**
     * Method for determining the window that will receive the command
     */
    SetTarget()
    {
        this.TargetWindow := ""
        a2log_debug("cleared target window", "", this.moduleName)

        WinGet, active_pid, PID, A
        WinGetTitle, active_title, ahk_pid %active_pid%

        this.TargetWindow := active_pid
        if (this.TargetWindow)
        {
            notify(this.moduleName, "Stored a new target window:`n" active_title, 4, NotifyIcons.Success)
            a2log_debug("stored new target window", "", this.moduleName)
            a2log_debug("stored window:", "[" active_pid "] " active_title, "debug", this.moduleName)
        }
        else
        {
            notify(this.moduleName, "Failed to store new Target Window", 4, NotifyIcons.Error)
            a2log_debug("failed to store new target window", "", this.moduleName)
        }
    }

    /**
     * Method to trigger the command to be sent
     */
    Trigger()
    {
        if (!this._command)
        {
            a2log_error("missing command", "", this.moduleName)
            notify(this.moduleName, "No command has been defined that should be sent.", 4, NotifyIcons.Error)
            return
        }

        if (!this.TargetWindow)
        {
            a2log_error("missing target window", "", this.moduleName)
            notify(this.moduleName, "No Target Window has been set.", 4, NotifyIcons.Error)
            return
        }

        if (this._continuously)
        {
            interval := (this._interval) ? this._interval * 1000 : 50

            if (!this.isRunning)
            {
                timer := this.timer
                this.isRunning := True
                SetTimer % timer, % interval
            }
            else
            {
                timer := this.timer
                this.isRunning := False
                SetTimer % timer, Off
            }
        }
        else
        {
            this.SendCommand()
        }
    }

    /**
     * Method for sending the command
     * This can be used directly, or invoking with SetTimer
     */
    SendCommand()
    {
        _command := this._command
        _target := this.TargetWindow

        Transform, _command, deref, %_command%

        ControlSend, , %_command%, ahk_pid %_target%
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

    /**
     * Private Property
     *     If the command should be send repeatedly until trigger is toggled
     *
     * @type  bool
     */
    _continuously[]
    {
        get {
            global SendToBackground_CheckBoxContinuously
            return SendToBackground_CheckBoxContinuously
        }
    }

    /**
     * Private Property
     *     Interval (in seconds) between one repetition and the next
     *
     * @type  integer
     */
    _interval[]
    {
        get {
            global SendToBackground_Interval
            return SendToBackground_Interval
        }
    }
}
