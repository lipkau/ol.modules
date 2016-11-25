; VolumeManager - VolumeManager.ahk
; author: Lipkau
; created: 2016 11 24

#include lib\ahklib\VA.ahk

/**
 * TODO:
 *     *
 */

class VolumeManager
{
    static _defaultStepSize := 5

    Execute(command, hwnd = false)
    {
        if (hwnd)
            if (this._WindowIsOverMouse(hwnd))
                this.ChangeVolume(command)
            else
                this._defaultBehavior(A_ThisHotkey)
        else if (command)
            this.ChangeVolume(command)
        else
            this._defaultBehavior(A_ThisHotkey)
    }

    ChangeVolume(newValue)
    {
        ; Need to check for sign before and after expansion because AHK will swallow the + sign on numeric strings and turn it into a number.
        Current := 0
        Action := newValue
        if (WinVer >= WIN_Vista)
        {
            if (InStr(Action, "+") = 1 || InStr(Action, "-") = 1) {
                Action .= this._stepSize
                Current := VA_GetMasterVolume()
            }
            if (Action = "mute")
                VA_SetMasterMute(1)
            else if (Action = "unmute")
                VA_SetMasterMute(0)
            else if (Action = "toggle" && VA_GetMasterMute())
                VA_SetMasterMute(0)
            else if (Action = "toggle")
                VA_SetMasterMute(1)
            else
            {
                VA_SetMasterMute(0) ;If setting volume we probably don't want to stay muted.
                VA_SetMasterVolume(Current+Action)
            }
            if (this._showNotification)
            {

                if (!Settings.VolumeManager_NotificationWindow)
                    Settings.VolumeManager_NotificationWindow := Notify("Volume","","", VA_GetMasterMute() ? NotifyIcons.SoundMute : NotifyIcons.Sound, "ToggleMute", {min : 0, max : 0, value : VA_GetMasterVolume()})
                Else
                    Settings.VolumeManager_NotificationWindow.Progress := VA_GetMasterVolume()
                SetTimer, ClearNotifyID, -1500
            }
        }
        else
        {
            if (InStr(Action, "+") = 1 || InStr(Action, "-") = 1)
                SoundGet, Current
            if (Action = "mute")
                SoundSet, 1,, Mute
            else if (Action = "unmute")
                SoundSet, 0,, Mute
            else if (Action = "toggle" && SoundGet("","Mute"))
                SoundSet, 1,, Mute
            else if (Action = "toggle")
                SoundSet, 0,, Mute
            else
            {
                SoundSet, 0,, Mute ;If setting volume we probably don't want to stay muted.
                SoundSet, % Current + Action
            }
            if (this._showNotification)
            {
                if (!Settings.VolumeManager_NotificationWindow)
                    Settings.VolumeManager_NotificationWindow := Notify("Volume","","", SoundGet("", "Mute") ? NotifyIcons.SoundMute : NotifyIcons.Sound, "ToggleMute", {min : 0, max : 0, value : SoundGet("", "Volume")})
                else
                    Settings.VolumeManager_NotificationWindow.Progress := SoundGet("", "Volume")
                SetTimer, ClearNotifyID, -1500
            }
        }
        return 1
    }



    _WindowIsOverMouse(hwnd)
    {
        MouseGetPos,,,TargetWindow
        class := WinGetClass("ahk_id " TargetWindow)
        return (class == hwnd) ? true : false
    }

    _defaultBehavior(key)
    {
        Send, {%key%}
    }

    _showNotification[]
    {
        get {
            global VolumeManager_ShowNotification
            return (VolumeManager_ShowNotification == true) ? true : false
        }
    }

    _stepSize[]
    {
        get {
            global VolumeManager_StepSize
            return (IsNumeric(VolumeManager_StepSize)) ? VolumeManager_StepSize : this._defaultStepSize
        }
    }
}

ClearNotifyID:
    Settings.VolumeManager_NotificationWindow.Close()
    Settings.Remove("VolumeManager_NotificationWindow")
return
