; NoScreensaver - NoScreensaver.ahk
; author: Oliver Lipkau
; created: 2016 11 10

/**
 * NoScreensaver is an Object which controls the functionality of the module
 */
class NoScreensaver {
    /**
     * current state of the module
     *
     * @type {[bool]}
     */
    active := false

    /**
     * method to initialize the module
     */
    onLoad()
    {
        ; tt("[DEBUG.NoScreensaver] Loaded")
        if (this.defaultState)
            this.Activate()
    }

    /**
     * method to reset the PC's idle time when it reaches a threshold
     */
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
        SetTimer, ResetTimeIdle, 2000
        this.active := true
        ; tt("[DEBUG.NoScreensaver] Activeted")
    }

    Deactivate()
    {
        SetTimer, ResetTimeIdle, Off
        this.active := false
        ; tt("[DEBUG.NoScreensaver] Deactivated")
    }

    /**
     * method to toggle the active state of the module
     */
    Toggle()
    {
        if (this.active)
        {
            this.Deactivate()
        } else {
            this.Activate()
        }
    }

    /**
     * threshold for when to reset idle time
     */
    timeout[]
    {
        get {
            ; Get value from a2UI.py UI
            global NoScreensaver_timeout
            return NoScreensaver_timeout * 1000 * 60
        }
    }

    /**
     * user choice if the module should be active by default
     */
    defaultState[]
    {
        get {
            ; Get value from a2UI.py UI
            global NoScreensaver_defaultState
            return NoScreensaver_defaultState
        }
    }
}
