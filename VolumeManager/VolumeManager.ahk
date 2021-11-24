; VolumeManager - VolumeManager.ahk
; author: Oliver Lipkau <https://github.com/lipkau>
; created: 2016 11 24

#MaxHotkeysPerInterval 200
#include <ModuleModel>
#include %A_LineFile%\..\..\.lib\Notify.ahk

/**
 * TODO:
 *     *
 */

class VolumeManager extends ModuleModel
{
    /**
     * Default value for the stepsize
     * @type int
     */
    static _defaultStepSize := 5
    static running := false

    /**
     * method to initialize the module
     */
    Init()
    {
        this.base.__New(A_LineFile)
        ; Only debug message
        a2log_info("Initializing module", this.module.Name)
    }

    /**
     * Entry point
     *
     * @param  string  command   Contains the command of what should be done to the volume
     * @param  string  hwnd      Window handler over wich the mouse must be
     */
    Execute(command, hwnd = false)
    {
        if (this.running)
            return false

        this.running := true
        if (hwnd)
            if (this._WindowIsOverMouse(hwnd))
                this.ChangeVolume(command)
            else {
                ; a2log_debug("Hotkey ignored " A_ThisHotkey ": Not over window " hwnd, this.module.Name)
                this._defaultBehavior(A_ThisHotkey)
            }
        else
            this.ChangeVolume(command)

        this.running := false

        return true
    }

    /**
     * Make changes to the system's volume
     *
     * @param  string  newValue  Contains the action to be performed on the volume
     */
    ChangeVolume(newValue)
    {
        _amount .= this._stepSize

        if (InStr(newValue, "+") == 1 || InStr(newValue, "-") == 1) {
            if (newValue == "+"){
                Send {volume_up %_amount%}
                a2log_debug("Changing volume: " newValue "" _amount, this.module.Name)
            }
            if (newValue == "-"){
                Send {volume_down %_amount%}
                a2log_debug("Changing volume: " newValue "" _amount, this.module.Name)
            }
        }
        if newValue in mute,unmute,toggle
        {
            Send {volume_mute}
            a2log_debug("Changing volume: " newValue, this.module.Name)
        }

        return 1
    }

    /**
     * Private Method
     *     Check if mouse is hovering a window
     *
     * @param  string  hwnd   Window handler
     * @return bool
     */
    _WindowIsOverMouse(hwnd)
    {
        MouseGetPos,,,TargetWindow
        class := WinGetClass("ahk_id " TargetWindow)
        return (class == hwnd) ? true : false
    }

    /**
     * Private Method
     *     Execute the default action of a key
     *
     * @param  string  key  Key to be executed
     */
    _defaultBehavior(key)
    {
        Send, {%key%}
    }

    /**
     * Private Property
     *     StepSize when changing the volume
     *
     * @type  int
     */
    _stepSize[]
    {
        get {
            global VolumeManager_StepSize
            return (IsNumeric(VolumeManager_StepSize)) ? VolumeManager_StepSize : this._defaultStepSize
        }
    }
}

; Routine to remove the Notification Window
ClearNotifyID:
    Settings.VolumeManager_NotificationWindow.Close()
    Settings.Remove("VolumeManager_NotificationWindow")
return
