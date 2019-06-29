; BlockCapsLock - BlockCapsLock.ahk
; author: Oliver Lipkau
; created: 2016 11 12

/**
 * Callback function for when the user presses CapsLock
 *
 * @return
 */

a2log_info("Initializing module", "", "BlockCapsLock")

BlockCapsLock_callback()
{
    ; Key was pressed for at least 0.3s
    Keywait, CapsLock, T0.3
    if ErrorLevel
    {
        ; Toggle key state
        SetCapsLockstate, % GetKeyState("CapsLock","T") ? "Off":"On"
        a2log_debug("BlockCaps: Toggled", "", "BlockCapsLock")
    } else {
        a2log_debug("BlockCaps: Blocked Capslock", "", "BlockCapsLock")
    }
}
