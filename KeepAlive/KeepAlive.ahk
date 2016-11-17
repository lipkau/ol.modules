; KeepAlive - KeepAlive.ahk
; author: Oliver Lipkau
; created: 2016 11 13

#include lib\ahklib\CNotification.ahk

/**
 * TODO:
 *     *
 */

class KeepAlive {
    static Active := false

    Init()
    {
        if (this._enabledByDefault)
            this.Activate()
    }

    ResetTimeIdle()
    {
        if (A_TimeIdle > this.timeout) {
            WriteDebug("KeepAlive: set idle time")
            SendInput {ScrollLock}{ScrollLock}
        }
    }

    Activate()
    {
        Func("KeepAlive_ResetTimeIdle").bind(this)
        SetTimer %KeepAlive_ResetTimeIdle%, 2000
        this.active := true
        Notify("KeepAlive activated", "", 2, NotifyIcons.Success)
    }

    Deactivate()
    {
        Func("KeepAlive_ResetTimeIdle").bind(this)
        SetTimer %KeepAlive_ResetTimeIdle%, 2000
        this.active := false
        Notify("KeepAlive dectivated", "", 2, NotifyIcons.Success)
    }

    Toggle()
    {
        if (this.active)
        {
            this.Deactivate()
        } else {
            this.Activate()
        }
    }

    timeout[]
    {
        get {
            global Timeout_Number
            return Timeout_Number * 1000 * 60
        }
    }

    _enabledByDefault[]
    {
        get {
            global NoScreensaver_EnabledByDefault
            return (NoScreensaver_EnabledByDefault == true) ? true : false
        }
    }
}

KeepAlive_ResetTimeIdle(obj)
{
    obj.ResetTimeIdle()
}
