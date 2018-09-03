; BlockCapsLock - BlockCapsLock.ahk
; author: Oliver Lipkau
; created: 2016 11 12

/**
 * Callback function for when the user presses CapsLock
 *
 * @return
 */
BlockCapsLock_callback()
{
    ; Key was pressed for at least 0.3s
    Keywait, CapsLock, T0.3
    if ErrorLevel
    {
        ; Toggle key state
        SetCapsLockstate, % GetKeyState("CapsLock","T") ? "Off":"On"
        WriteDebug("BlockCaps: Toggled", "", "debug", "BlockCapsLock")
    } else {
        WriteDebug("BlockCaps: Blocked Capslock", "", "debug", "BlockCapsLock")
    }
}
