; KeepAlive - KeepAlive.ahk
; author: Oliver Lipkau <https://github.com/lipkau>
; created: 2016 11 13

#include lib\ahklib\CNotification.ahk

/**
 * TODO:
 *     *
 */

class KeepAlive {
    /**
     * Module properties
     */
    static moduleBundle := "ol.modules"
    static moduleName   := "KeepAlive"
    static moduleHelp   := "https://github.com/lipkau/ol.modules/wiki/KeepAlive"

    /**
     * current state of the module
     *
     * @type bool
     */
    static Active := false

    /**
     * Bound Method for the SetTimer
     *
     * @type BoundMethod
     */
    static timer

    /**
     * method to initialize the module
     */
    Init()
    {
        WriteDebug("Initialized module", "", "i", this.moduleName)

        this.timer := ObjBindMethod(this, "ResetTimeIdle")
        if (this._enabledByDefault)
            this.Activate()
    }

    /**
     * method to reset the PC's idle time when it reaches a threshold
     */
    ResetTimeIdle()
    {
        if (A_TimeIdle > this.timeout) {
            WriteDebug("Reset A_TimeIdle", "", "i", this.moduleName)

            SendInput {ScrollLock}{ScrollLock}
        }
    }

    Activate()
    {
        WriteDebug("Activating module", "", "i", this.moduleName)
        WriteDebug("Using timeout of:", this.timeout, "debug", this.moduleName)

        timer := this.timer
        SetTimer % timer, 2000
        this.active := true
        Notify("KeepAlive activated", "", 2, NotifyIcons.Success)
    }

    Deactivate()
    {
        WriteDebug("Deactivating module", "", "i", this.moduleName)

        timer := this.timer
        SetTimer % timer, 2000
        this.active := false
        Notify("KeepAlive dectivated", "", 2, NotifyIcons.Success)
    }

    /**
     * method to toggle the active state of the module
     */
    Toggle()
    {
        if (this.active)
            this.Deactivate()
        else
            this.Activate()
    }

    /**
     * threshold for when to reset idle time
     */
    timeout[]
    {
        get {
            global Timeout_Number
            return Timeout_Number * 1000 * 60
        }
    }

    /**
     * user choice if the module should be active by default
     */
    _enabledByDefault[]
    {
        get {
            global NoScreensaver_EnabledByDefault
            return (NoScreensaver_EnabledByDefault == true) ? true : false
        }
    }
}
