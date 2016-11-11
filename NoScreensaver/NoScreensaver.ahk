class NoScreensaver {
    active := false

    onLoad()
    {
        this.Activate()
    }

    ResetTimeIdle()
    {
        if (A_TimeIdle > this.timeout) {
            SendInput {ScrollLock}{ScrollLock}
        }
    }

    Activate()
    {
        SetTimer, MoveMouseOnIdle, 2000
        this.active := true
        tt("Active: " . this.active)
    }

    Deactivate()
    {
        SetTimer, MoveMouseOnIdle, Off
        this.active := false
        tt("Deactive: " . this.active)
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
            return Timeout_Number * 1000
        }
    }
}

foo()
{
    NoScreensaver.onLoad()
}

bar()
{
    NoScreensaver.Toggle()
}

MoveMouseOnIdle:
    NoScreensaver.ResetTimeIdle()
return
