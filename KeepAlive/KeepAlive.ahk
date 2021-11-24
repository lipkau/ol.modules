; KeepAlive - KeepAlive.ahk
; author: Oliver Lipkau <https://github.com/lipkau>
; created: 2016 11 13

/**
 * TODO:
 *     *
 */

#include <ModuleModel>

class KeepAlive extends ModuleModel
{
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
        this.base.__New(A_LineFile)
        a2log_info("Initializing module", this.module.Name)

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
            a2log_info("Reset A_TimeIdle", this.module.Name)

            SendInput {ScrollLock}{ScrollLock}
        }
    }

    Activate()
    {
        a2log_info("Activating module", this.module.Name)
        a2log_debug("Using timeout of: " this.timeout, this.module.Name)

        timer := this.timer
        SetTimer, % timer, 2000
        this.active := true
        notify(module.Name, "KeepAlive activated", 2, NotifyIcons.Success)
    }

    Deactivate()
    {
        a2log_info("Deactivating module", this.module.Name)

        timer := this.timer
        SetTimer % timer, 2000
        this.active := false
        notify(module.Name, "KeepAlive dectivated", 2, NotifyIcons.Success)
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
