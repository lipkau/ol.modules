class NoScreensaver {
    active := false

    onLoad()
    {
        ListVars
        ; tt("[DEBUG.NoScreensaver] Loaded")
        if (this.defaultState)
            this.Activate()
    }

    ResetTimeIdle()
    {
        ; tt("[DEBUG.NoScreensaver] idle counter: " . A_TimeIdle)
        if (A_TimeIdle > this.timeout) {
            ; tt("[DEBUG.NoScreensaver] tiggered!")
            SendInput {ScrollLock}{ScrollLock}
        }
    }

    Activate()
    {
        SetTimer, MoveMouseOnIdle, 2000
        this.active := true
        ; tt("[DEBUG.NoScreensaver] Activeted")
    }

    Deactivate()
    {
        SetTimer, MoveMouseOnIdle, Off
        this.active := false
        ; tt("[DEBUG.NoScreensaver] Deactivated")
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
            global NoScreensaver_timeout
            return NoScreensaver_timeout * 1000 * 60
        }
    }

    defaultState[]
    {
        get {
            global NoScreensaver_defaultState
            return NoScreensaver_defaultState
        }
    }
}

MoveMouseOnIdle:
    NoScreensaver.ResetTimeIdle()
return
