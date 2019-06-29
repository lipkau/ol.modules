/**
 * Checks if a point is in a rectangle

 @param  Int   px  X coordinate of point
 @param  Int   py  Y coordinate of point
 @param  Int   x   X coordinate of area
 @param  Int   w   width of area
 @param  Int   h   height of area
 @return bool
 */
IsInArea(px, py, x, y, w, h) {
    return (px > x && py > y && px < x + w && py < y + h)
}

/**
 * Helper Function
 *     Returns a free identifier for a GUI
 *     v0.81 by majkinetor  Licenced under BSD <http://creativecommons.org/licenses/BSD/>
 *
 * @sample
 *     GetFreeGuiNum(0)         ; returns the first integer that is not used by a GUI
 * @sample
 *     GetFreeGuiNum(10, "Foo") ; returns "Foo10" or the next higher integer that is not used by a GUI
 *
 * @param   integer     start   Number from where to start counting up
 * @param   string      prefix  String to help the GUI identifier to be unique
 * @return  string
 */
GetFreeGuiNum(start, prefix = "") {
    loop
    {
        Gui %prefix%%start%:+LastFoundExist
        IfWinNotExist
            return prefix start
        start++
        if (start = 100)
            return 0
    }
    return 0
}

/**
 * Helper Function
 *     Evaluate if the input is a number
 *
 * @sample
 *     IsNumertic(4) ;true
 * @sample
 *     IsNumertic("foo") ;false
 *
 * @param   any     InputObject     Content to be evaluated
 * @return  bool
 */
IsNumeric(InputObject) {
   If InputObject is number
      Return 1
   Return 0
}

; Gets ClassNN from hwnd
HWNDToClassNN(hwnd) {
    win := DllCall("GetParent", "PTR", hwnd, "PTR")
    WinGet ctrlList, ControlList, ahk_id %win%
    ; Built an array indexing the control names by their hwnd
    Loop Parse, ctrlList, `n
    {
        ControlGet hwnd1, Hwnd, , %A_LoopField%, ahk_id %win%
        if (hwnd1=hwnd)
            return A_LoopField
    }
}


/**
 * Helper Function
 *     Starts a timer that can cal functions and object methods
 *
 * @param   func    Function     A function or method reference to be called
 * @param   integer Period      Period/Timer in ms to call the Fcunction / value "OFF" deactivates a timer
 * @param           ParmObject
 * @param           Priority
 * @return
 */
SetTimerF( Function, Period=0, ParmObject=0, Priority=0 ) {
    Static current,tmrs:=Object() ;current will hold timer that is currently running
    If IsFunc( Function ) || IsObject( Function ) {
        if IsObject(tmr:=tmrs[Function]) ;destroy timer before creating a new one
            ret := DllCall( "KillTimer", UInt,0, UInt, tmr.tmr)
                , DllCall("GlobalFree", UInt, tmr.CBA)
                , tmrs.Remove(Function)
        if (Period = 0 || Period ? "off")
            return ret ;Return as we want to turn off timer
        ; create object that will hold information for timer, it will be passed trough A_EventInfo when Timer is launched
        tmr:=tmrs[Function]:=Object("func",Function,"Period",Period="on" ? 250 : Period,"Priority",Priority
                            ,"OneTime",(Period<0),"params",IsObject(ParmObject)?ParmObject:Object()
                            ,"Tick",A_TickCount)
        tmr.CBA := RegisterCallback(A_ThisFunc,"F",4,&tmr)
        return !!(tmr.tmr  := DllCall("SetTimer", UInt,0, UInt,0, UInt
                            , (Period && Period!="On") ? Abs(Period) : (Period := 250)
                            , UInt,tmr.CBA)) ;Create Timer and return true if a timer was created
                            , tmr.Tick:=A_TickCount
    }
    tmr := Object(A_EventInfo) ;A_Event holds object which contains timer information
    if IsObject(tmr) {
        DllCall("KillTimer", UInt,0, UInt,tmr.tmr) ;deactivate timer so it does not run again while we are processing the function
        If (!tmr.active && tmr.Priority<(current.priority ? current.priority : 0)) ;Timer with higher priority is already current so return
           Return (tmr.tmr:=DllCall("SetTimer", UInt,0, UInt,0, UInt, 100, UInt,tmr.CBA)) ;call timer again asap
        current:=tmr
        tmr.tick:=ErrorLevel :=Priority ;update tick to launch function on time
        func := tmr.func.(tmr.params*) ;call function
        current= ;reset timer
        if (tmr.OneTime) ;One time timer, deactivate and delete it
           return DllCall("GlobalFree", UInt,tmr.CBA)
                 ,tmrs.Remove(tmr.func)
        tmr.tmr:= DllCall("SetTimer", UInt,0, UInt,0, UInt ;reset timer
                ,((A_TickCount-tmr.Tick) > tmr.Period) ? 0 : (tmr.Period-(A_TickCount-tmr.Tick)), UInt,tmr.CBA)
    }
}

/**
 * Helper Function
 *     Returns the monitor the mouse or the active window is in
 *
 * @param   var    hWndOrMouseX  Window handler or Mouse X coords from which to guess the monitor in question
 * @param   var    MouseY                          Mouse Y coords from which to guess the monitor in question
 * @return  int   MonitorID
 */
GetActiveMonitor(hWndOrMouseX, MouseY = "") {
    if (MouseY="")
    {
        WinGetPos,x,y,w,h,ahk_id %hWndOrMouseX%
        if (!x && !y && !w && !h)
        {
            MsgBox GetActiveMonitor(): invalid window handle!
            return -1
        }
        x := x + Round(w/2)
        y := y + Round(h/2)
    }
    else
    {
        x := hWndOrMouseX
        y := MouseY
    }
    ; Loop through every monitor and calculate the distance to each monitor
    iBestD := 0xFFFFFFFF
    SysGet, Mon0, MonitorCount
    Loop %Mon0% { ;Loop through each monitor
        SysGet, Mon%A_Index%, Monitor, %A_Index%
        Mon%A_Index%MidX := Mon%A_Index%Left + Ceil((Mon%A_Index%Right - Mon%A_Index%Left) / 2)
        Mon%A_Index%MidY := Mon%A_Index%Top + Ceil((Mon%A_Index%Top - Mon%A_Index%Bottom) / 2)
    }
    Loop % Mon0 {
      D := Sqrt((x - Mon%A_Index%MidX)**2 + (y - Mon%A_Index%MidY)**2)
      If (D < iBestD) {
         iBestD := D
         iMonitor := A_Index
      }
   }
   return iMonitor
}

/**
 * Helper Function
 *     Returns the workspace area covered by the active monitor
 *
 * @param   var    MonLeft       Variable in which to write the monitor's left coords
 * @param   var    MonTop        Variable in which to write the monitor's top coords
 * @param   var    MonW          Variable in which to write the monitor's height
 * @param   var    MonH          Variable in which to write the monitor's height
 * @param   var    hWndOrMouseX  Window handler or Mouse X coords from which to guess the monitor in question
 * @param   var    MouseY                          Mouse Y coords from which to guess the monitor in question
 */
GetActiveMonitorWorkspaceArea(ByRef MonLeft, ByRef MonTop, ByRef MonW, ByRef MonH,hWndOrMouseX, MouseY = "") {
    mon := GetActiveMonitor(hWndOrMouseX, MouseY)
    if (mon>=0)
    {
        SysGet, Mon, MonitorWorkArea, %mon%
        MonW := MonRight - MonLeft
        MonH := MonBottom - MonTop
    }
}
TranslateMUI(resDll, resID) {
    VarSetCapacity(buf, 256)
    hDll := DllCall("LoadLibrary", "str", resDll, "Ptr")
    Result := DllCall("LoadString", "Ptr", hDll, "uint", resID, "str", buf, "int", 128)
    return buf
}

/**
 * Helper Function
 *     Extract an icon from an executable, DLL or icon file.
 *
 * @sample
 *     ExtractIcon("C:\windows\system32\system.dll", 1)
 *
 * @param   string  Filename    Name of the ico, dll or exe from which to extract the icon
 * @param   integer IconNumber  Index of the icon in the file
 * @param   integer IconSize    Resolution of the icon
 * @return  bitmap
 */
ExtractIcon(Filename, IconNumber = 0, IconSize = 64) {
    r := DllCall("Shell32.dll\SHExtractIconsW", "str", Filename, "int", IconNumber-1, "int", IconSize, "int", IconSize, "Ptr*", h_icon, "Ptr*", pIconId, "uint", 1, "uint", 0, "int")
    If (!ErrorLevel && r != 0)
        return h_icon
    return 0
}

/**
 * Helper Function
 *     Expand path placeholders
 *     It's basically ExpandEnvironmentStrings() with some additional directories
 *
 * @sample
 *     ExpandPathPlaceholders("%ProgramFiles%")
 * @sample
 *     ExpandPathPlaceholders("Temp")
 * @sample
 *     ExpandPathPlaceholders("%Desktop%")
 *
 * @param   string  InputString     The path to be resolved
 * @return  string
 *
 * @docu   https://msdn.microsoft.com/en-us/library/windows/desktop/ms724265(v=vs.85).aspx
 */
ExpandPathPlaceholders(InputString) {
    static Replacements := {  "Desktop" :             GetFullPathName(A_Desktop)
                            , "MyDocuments" :        GetFullPathName(A_MyDocuments)
                            , "StartMenu" :            GetFullPathName(A_StartMenu)
                            , "StartMenuCommon" :     GetFullPathName(A_StartMenuCommon)
                            , "a2Dir" :            A_ScriptDir "\.."}

    for Placeholder, Replacement in Replacements
        while(InStr(InputString, Placeholder) && A_Index < 10)
            StringReplace, InputString, InputString, % "%" Placeholder "%", % Replacement, All

    ; get the required size for the expanded string
    SizeNeeded := DllCall("ExpandEnvironmentStrings", "Str", InputString, "PTR", 0, "Int", 0)
    if (SizeNeeded == "" || SizeNeeded <= 0)
        return InputString ; unable to get the size for the expanded string for some reason

    ByteSize := SizeNeeded * 2 + 2
    VarSetCapacity(TempValue, ByteSize, 0)

    ; attempt to expand the environment string
    if (!DllCall("ExpandEnvironmentStrings", "Str", InputString, "Str", TempValue, "Int", SizeNeeded))
        return InputString ; unable to expand the environment string
    return TempValue
}

/**
 * Helper Function
 *     Converts the specified path to its long form.
 *
 * @sample
 *     GetFullPathName("C:\Progr~1")  -> "C:\Program Files"
 *
 * @param   string  sPath       The path to be converted.
 * @return  string
 *
 * @docu    https://msdn.microsoft.com/en-us/library/windows/desktop/aa364980(v=vs.85).aspx
 */
GetFullPathName(sPath) {
    VarSetCapacity(lPath,A_IsUnicode ? 520 : 260, 0)
    DllCall("GetLongPathName", Str, sPath, Str, lPath, UInt, 260)
    return lPath
}