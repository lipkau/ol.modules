; BlockCapsLock - BlockCapsLock.ahk
; author: Oliver Lipkau
; created: 2016 11 12

; CapsLock::

BlockCapsLock_callback()
{
    Keywait, CapsLock, T0.3
    if ErrorLevel
    {
        SetCapsLockstate,% GetKeyState("CapsLock","T") ? "Off":"On"
        ; tt("[DEBUG.BlockCapsLock] Toggled CapsLock")
    } else {
        ; tt("[DEBUG.BlockCapsLock] Blocked CapsLock")
    }
}
