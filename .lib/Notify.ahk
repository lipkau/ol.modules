global NotifyIcons := new NotifyIcons()

Notify(Title, Text, Timeout = "", Icon = "") {
    if (Timeout > 30)   ; TrayTip has a max value of 30 seconds
        Timeout := 30   ; For longer TrayTip, the module has to handle it with a timer
    if ((Timeout == "") OR (!(IsNumeric(Timeout))))
        Timeout := 5   ; fallback to a default value

    _icon := 0
    if (Icon == NotifyIcons.Info)
        _icon := _icon + 1 + 32
    if (Icon == NotifyIcons.Warning)
        _icon := _icon + 2 + 32
    if (Icon == NotifyIcons.Error)
        _icon := _icon + 3 + 32

    TrayTip, % Title, % Text, % Timeout, % _icon
}

Class NotifyIcons
{
    Info := ExtractIcon(ResolvePath("%WINDIR%\System32\shell32.dll"), WinVer >= WIN_Vista ? 222 : 136)
    Error := ExtractIcon(ResolvePath("%WINDIR%\System32\shell32.dll"), WinVer >= WIN_Vista ? 78 : 110)
    Warning := ExtractIcon(ResolvePath("%WINDIR%\System32\shell32.dll"), 78)
    Success := ExtractIcon(ResolvePath("%WINDIR%\System32\shell32.dll"), WinVer >= WIN_Vista ? 145 : 136)
    Internet := ExtractIcon(ResolvePath("%WINDIR%\System32\shell32.dll"), 136)
    Sound := ExtractIcon(ResolvePath("%WINDIR%\System32\SndVol.exe"), 2)
    SoundMute := ExtractIcon(ResolvePath("%WINDIR%\System32\SndVol.exe"), 3)
    Question := ExtractIcon(ResolvePath("%WINDIR%\System32\shell32.dll"), 24)
}
