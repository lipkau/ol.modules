; ExplorerExtension - ExplorerExtension.ahk
; author: Lipkau
; created: 2016 11 28

#include lib\ahklib\CQueue.ahk
#include lib\ahklib\Navigation.ahk
#include lib\ahklib\WaitForEvent.ahk
#include lib\ahklib\CNotification.ahk

/**
 * TODO:
 *     * Need ShellMessage hook:
 *         - AUto select first file
 *         - Open Explorer in last active window
 *     * Advanced Statusbar
 *     * ScrollTreeUnderMouse
 *     * AutoCheckApplyToAllFiles
 *     * make AlignNewExplorer more reliable (need shellMessage hook?)
 *     * ImproveEnter
 *     * MouseGestures
 *
 */

IsMouseOverDesktop()
{
    MouseGetPos, , ,Window , UnderMouse
    WinGetClass, winclass , ahk_id %Window%
    if (winclass="WorkerW"||winclass="Progman")
        return true
    return false
}

InFileList()
{
    if (WinVer >= WIN_7)
        ControlGetFocus focussed, A
    else
        focussed:=XPGetFocussed()

    if (WinActive("ahk_group ExplorerGroup"))
    {
        if ((WinVer >= WIN_7 && focussed="DirectUIHWND3") || (WinVer < WIN_7 && focussed="SysListView321"))
            return true
    }
    else if ((x:=IsDialog())=1)
    {
        if ((WinVer >= WIN_7 && focussed="DirectUIHWND2") || (WinVer < WIN_7 && focussed="SysListView321"))
            return true
    }
    else if (x=2)
    {
        if (focussed="SysListView321")
            return true
    }
    return false
}

IsMouseOverFileList()
{
    CoordMode,Mouse,Relative
    MouseGetPos, MouseX, MouseY,Window , UnderMouse
    WinGetClass, winclass , ahk_id %Window%
    if (WinVer >= WIN_7 && (winclass = "CabinetWClass" || winclass = "ExploreWClass")) ;Win7 Explorer
    {
        ControlGetPos , cX, cY, Width, Height, DirectUIHWND3, A
        ; Offsets are estimated values in my windows skin and don't need to be correct for everyone. They're used to prevent catching double clicks on the column headers.
        if (IsInArea(MouseX, MouseY, cX, cY + 25,Width, Height - 25))
            return true
    }
    else if ((z := IsDialog(window)) = 1) ;New dialogs
    {
        ControlGetPos , cX, cY, Width, Height, DirectUIHWND2, A
        ; Offsets are estimated values in my windows skin and don't need to be correct for everyone. They're used to prevent catching double clicks on the column headers.
        if (IsInArea(MouseX, MouseY, cX, cY + 25, Width, Height - 25)) ;Checking for area because rename might be in process and mouse might be over edit control
            return true
    }
    else if (winclass="CabinetWClass" || winclass="ExploreWClass" || z = 2) ;Old dialogs or Vista/XP
    {
        ControlGetPos , cX, cY, Width, Height, SysListView321, A
        if (IsInArea(MouseX, MouseY, cX, cY, Width, Height) && UnderMouse = "SysListView321") ;Additional check needed for XP because of header
            return true
    }
    return false
}

InTree()
{
    if (WinActive("ahk_group ExplorerGroup")||IsDialog()=1) ;Explorer or new dialog
    {
        if (WinVer >= WIN_7)
            ControlGetFocus focussed, A
        else
            focussed := XPGetFocussed()
        if (focussed = "SysTreeView321")
            return true
    }
    return false
}
IsRenaming()
{
    if (WinVer >= WIN_7)
        ControlGetFocus focussed, A
    else
        focussed := XPGetFocussed()
    if (WinActive("ahk_group ExplorerGroup")) ;Explorer
    {
        if (InStr(focussed, "Edit") = 1)
        {
            if (WinVer >= WIN_7)
                ControlGetPos, X, Y, Width, Height, DirectUIHWND3, A
            else
                ControlGetPos , X, Y, Width, Height, SysListView321, A
            ControlGetPos, X1, Y1, Width1, Height1, %focussed%, A
            if (IsInArea(X1, Y1, X, Y, Width, Height)&&IsInArea(X1 + Width1, Y1, X, Y, Width, Height) && IsInArea(X1, Y1 + Height1, X, Y, Width, Height) && IsInArea(X1 + Width1, Y1 + Height1, X, Y, Width, Height))
                return focussed
        }
    }
    else if (WinActive("ahk_group DesktopGroup")) ;Desktop
    {
        if (focussed = "Edit1")
            return focussed
    }
    else if ((x := IsDialog())) ;FileDialogs
    {
        if (InStr(focussed, "Edit1") = 1)
        {
            ; figure out if the the edit control is inside the DirectUIHWND2 or SysListView321
            if (x = 1 && WinVer >= WIN_7) ;New Dialogs
                ControlGetPos, X, Y, Width, Height, DirectUIHWND2, A
            else ;Old Dialogs
                ControlGetPos, X, Y, Width, Height, SysListView321, A
            ControlGetPos, X1, Y1, Width1, Height1, %focussed%, A
            if (IsInArea(X1, Y1, X, Y, Width, Height) && IsInArea(X1 + Width1, Y1, X, Y, Width, Height) && IsInArea(X1, Y1 + Height1, X, Y, Width, Height) && IsInArea(X1 + Width1, Y1 + Height1, X, Y, Width, Height))
                return focussed
        }
    }
    return false
}
IsInAddressBar()
{
    if (WinVer >= WIN_7)
        ControlGetFocus focussed, A
    else
        focussed := XPGetFocussed()
    if (WinActive("ahk_group ExplorerGroup")) ;Explorer
    {
        if (focussed = "Edit1" && !IsRenaming()) ;Renaming Control can be Edit1 when rename is made before addressbar is focussed
            return true
    }
    else if (IsDialog() = 1) ;New Dialogs
    {
        if (focussed = "Edit2") ;Seems to be Edit2 all the time...
            return true
    }
    return false
}
SetFocusToFileView()
{
    if (WinActive("ahk_group ExplorerGroup"))
    {
        if (WinVer = WIN_7)
            ControlFocus DirectUIHWND3, A
        else ;XP, Vista
            ControlFocus SysListView321, A
    }
    else if ((x := IsDialog())=1) ;New Dialogs
    {
        if (WinVer >= WIN_7)
            ControlFocus DirectUIHWND2, A
        else
            ControlFocus SysListView321, A
    }
    else if (x = 2) ;Old Dialogs
        ControlFocus SysListView321, A
    return
}

FixExplorerConfirmationDialogs()
{
    ; Check if a confirmation dialog is active, if it is -> check the checkbox!
    hwnd := WinActive("ahk_class #32770")
    hParent := GetParent(GetParent(hwnd))
    if (hwnd && hParent && (InStr("ExploreWClass,CabinetWClass", WinGetClass("ahk_id " hParent)) || IsDialog(hParent)))
    {
        WinGet ctrlList, ControlList, A
        ; Find the checkbox!
        Loop Parse, ctrlList, `n
        {
            ControlGet hwnd, Hwnd, , %A_LoopField%, A
            if (InStr(WinGetClass("ahk_id " hwnd), "Button") = 1)
            {
                WinGet, style, style, ahk_id %hwnd%
                WinGetTitle, title, ahk_id %hwnd%
                WinGetPos, , , w, h, ahk_id %hwnd%
                if (!title || w = 0 || h = 0)
                    continue
                for i, s in [0x2,0x4]
                    if (style & s && style & 0x10000000) ;WS_VISIBLE
                    {
                        Control, Check , ,, ahk_id %hwnd%
                        return
                    }
            }
        }
    }
}

; Enhanced renaming
; For tip only
; #if InFileList() && !IsRenaming()
; F2::
; ; ShowTip(9)
; Send {F2}
; return
; #if
#if ExplorerExtension_EnhancedRenaming && IsRenaming()
F2::EnhancedRenaming()
#if
EnhancedRenaming()
{
    static EM_GETSEL:=0x00B0,EM_SETSEL:=0x00B1
    EditControl := IsRenaming()
    SendMessage, EM_GETSEL,,, %EditControl%, A
    start := ErrorLevel & 0xFFFF
    end := (ErrorLevel & 0xFFFF0000) >> 16
    ControlGetText, Text, %EditControl%, A
    SelectedText := SubStr(Text, start + 1, end - start)
    if (!pos := InStr(Text, ".", 0, 0))
        return
    if (Text = SelectedText)
        SendMessage, EM_SETSEL, 0, pos - 1, %EditControl%, A
    else if (SelectedText = SubStr(Text, 1, pos - 1))
        SendMessage, EM_SETSEL, pos, StrLen(Text), %EditControl%, A
    else if (SelectedText = SubStr(Text, pos + 1))
        SendMessage, EM_SETSEL, 0, StrLen(Text), %EditControl%, A
}

; Mouse "gestures" (hold left/right and click right/left)
#if ExplorerExtension_MouseGestures && GetKeyState("RButton") && (WinActive("ahk_group ExplorerGroup")||IsDialog()) && IsMouseOverFileList()
LButton::
SuppressRButtonUp := true
Navigation.GoBack()
return
#if

#if ExplorerExtension_MouseGestures && SuppressRButtonUp
~RButton UP::
SuppressRButtonUp := false
Send, {Esc}
Return
#if

#if ExplorerExtension_MouseGestures && GetKeyState("LButton","P") && (WinActive("ahk_group ExplorerGroup")||IsDialog()) && IsMouseOverFileList()
RButton::
Navigation.GoForward()
SuppressRButtonUp := true
Return
#if

; Enter:Execute focussed file
#if ExplorerExtension_ImproveEnter && WinActive("ahk_group ExplorerGroup") && InFileList() && !IsRenaming() && !IsContextMenuActive()
Enter::
NumpadEnter::
ExecuteFocusedFile()
SetTimerF("ExplorerPathChanged", -100)
return
#if

; Register path changes caused by pressing enter. This is done in addition to the shell message that gets sent when the path changes because it does not work for all paths.
; #if WinActive("ahk_group ExplorerGroup") && !IsRenaming()
; ~LButton::
; ~Enter::
; ~NumpadEnter::
; ~!Up::
; ~!Left::
; ~!Right::
; ~Backspace::
;    SetTimerF("ExplorerPathChanged", -100)
;    return
; #if

ExecuteFocusedFile()
{
    files := Navigation.GetSelectedFilePaths()
    msgbox % files
    focused := Navigation.GetFocussedFilename()
    if (!files && focused)
        Send {Space}{Enter}
    else
        Send {Enter}
}

; Function(s) to align explorer windows side by side and to launch explorer with last used directory
#if ExplorerExtension_AlignNewExplorer && WinActive("ahk_group ExplorerGroup")
#e::RunExplorer()
#if
RunExplorer()
{
    global ExplorerExtension_AlignNewExplorer
   active := WinActive("ahk_group ExplorerGroup")
   if (active && ExplorerExtension_AlignNewExplorer)
   {
       WinRestore ahk_id %active%
       if (WinVer >= WIN_7)
       {
           WinGetPos, x,y,w,h,ahk_id %active%
           x++
           WinMove, ahk_id %active%,, %x%, %y%
           Send #{Left}
       }
       Else
       {
           GetActiveMonitorWorkspaceArea(x,y,w,h,active)
           w := Round(w/2)
           WinMove, ahk_id %active%,, %x%,%y%,%w%,%h%
       }
   }
   if (active && ExplorerExtension_AlignNewExplorer)
       Run, % "Explorer """ Navigation.GetPath() """"
   else if (ExplorerExtension_RememberPath && Settings.Explorer.CurrentPath)
       Run, % "Explorer """ Settings.Explorer.CurrentPath """"
   else
       run, % "Explorer C:"
   if (ExplorerExtension_AlignNewExplorer && active)
   {
       WinWaitNotActive ahk_id %active%
       Timeout := 10000
       Start := A_TickCount
       Loop ;Make sure new window is really active
       {
           Sleep 10
           active2 := WinActive("ahk_group ExplorerGroup")
           if ((active2 && active2 != active) || A_TickCount - Start > Timeout)
           Break
       }
       Start := A_TickCount
       Loop ;Wait until new window is visible
       {
           Sleep 10
           WinGet,visible,style, ahk_id %active2%
           if (visible & 0x10000000 || A_TickCount - Start > Timeout)
           break
       }
       if (WinVer >= WIN_7)
           Send #{Right}
       else
       {
           x += w
           WinMove, ahk_id %active2%,, %x%,%y%,%w%,%h%
       }
   }
   Return
}

; Scroll tree list with mouse wheel
#if (ExplorerExtension_ScrollTreeUnderMouse && ((IsWindowUnderCursor("#32770") && IsDialog()) || IsWindowUnderCursor("CabinetWClass") || IsWindowUnderCursor("ExploreWClass")) && !IsRenaming()) || (CAccessor.Instance.GUI.GUINum && IsWindowUnderCursor(CAccessor.Instance.GUI.hwnd))
WheelUp::
WheelDown::
Wheel()
return
Wheel()
{
    tt("ahoi")
   WasCritical := A_IsCritical
   Critical
   CoordMode, Mouse, Screen
   MouseGetPos, MouseX, MouseY
   DllCall("SendMessage", "PTR", DllCall("WindowFromPoint", "INT64", MouseX | (MouseY << 32), "Ptr"), "UInt", 0x20A, "PTR", (120 * (A_ThisHotkey = "WheelUp" ? 1 : -1)) << 16, "PTR", (MouseY << 16) | MouseX)
   if (!WasCritical)
   Critical, Off
   return
}
#if

InitExplorerWindows()
{
    global ExplorerWindows, ExplorerHistory
    Settings.Explorer := {}
    FileCreateDir % A_AppData "\a2\ol.modules\ExplorerExtension"
    ExplorerWindows := Array()
    ExplorerHistory := new CExplorerHistory()
    RegisterExplorerWindows()
    TabContainerList := Array()
    if (WinVer >= WIN_Vista)
        TabContainerList.Font := "Segoe UI"
    Else
        TabContainerList.Font := "Tahoma"
    TabContainerList.FontSize := 12
    TabContainerList.hPadding := 4
    TabContainerList.vPadding := 2
    TabContainerList.height := 20
    TabContainerList.TabWidth := 100
    TabContainerList.InActiveHeightDifference := 2
    TabContainerList.MinWidth := 40
    ExplorerWindows.TabContainerList := TabContainerList
    if (WinVer = WIN_7)
    {
        ExplorerWindows.InfoGUI_FreeText := TranslateMUI(shell32MUIpath,12336) ;Aquire a translated version of "free"
        ExplorerWindows.InfoGUI_FreeText := SubStr(ExplorerWindows.InfoGUI_FreeText, InStr(ExplorerWindows.InfoGUI_FreeText, " ", 0, 0) + 1)
    }
}

; Explorer history publically only displays the first 100 entries. The rest is used for collecting frequent entries
Class CExplorerHistory extends CQueue
{
   MaxSize := 200
   Unique := false
   __new()
   {
       this.Load()
   }
   Load()
   {
       if (FileExist(AppData "\a2\ol.modules\ExplorerExtension\ExplorerHistory.xml"))
       {
           FileRead, xml, % AppData "\a2\ol.modules\ExplorerExtension\ExplorerHistory.xml"
           XMLObject := XML_Read(xml)
           ; Convert empty and single arrays to real array
           if (!XMLObject.List.MaxIndex())
           XMLObject.List := IsObject(XMLObject.List) ? Array(XMLObject.List) : Array()

           Loop % min(XMLObject.List.MaxIndex(), this.MaxSize)
           {
               XMLEntry := XMLObject.List[A_Index]
               entry := RichObject()
               for key, value in XMLEntry
               entry[key] := value
               this[A_Index] := entry
           }
       }
   }
   Save()
   {
       FileDelete, % AppData "\a2\ol.modules\ExplorerExtension\ExplorerHistory.xml"

       XMLObject := Object("List", Array())
       Loop % min(this.MaxIndex(), this.MaxSize)
       {
           entry := this[A_Index]
           XMLEntry := {}
           for key, value in entry
           XMLEntry[key] := value
           XMLObject.List[A_Index] := XMLEntry
       }
       XML_Save(XMLObject, AppData "\a2\ol.modules\ExplorerExtension\ExplorerHistory.xml")
       return
   }
   __get(key)
   {
       if (key = "History")
       {
           History := Array()
           Loop % min(this.MaxIndex(), this.MaxSize / 2)
           History[A_Index] := {Path : this[A_Index].Path, Name : this[A_Index].Name}
           return History
       }
       else if (key = "FrequentPaths")
       {
           FrequentIndices := ""
           Loop % min(this.MaxIndex(), this.MaxSize)
           FrequentIndices .= (A_Index = 1 ? "" : ",") A_Index
           Sort, FrequentIndices, F ExplorerPathFrequencySort D`,
           FrequentPaths := Array()
           Loop, Parse, FrequentIndices, `,
           FrequentPaths[A_Index] := {Path : this[A_LoopField].Path, Name : this[A_LoopField].Name}
           return FrequentPaths
       }
   }
   ; Puts an item in the queue
   Push(item)
   {
       WriteDebug("Pusinhing item to Queue", item)
       itemPosition := this.IndexOfEqual(item, 0, "Path")
       if (!itemPosition)
       {
           this.Insert(1, item)
           if (this.MaxIndex() = this.MaxSize + 1)
           this.Remove()
       }
       else
       this.Move(itemPosition, 1)
       return this[1]
   }
}
ExplorerPathFrequencySort(index1, index2)
{
   global ExplorerHistory
   return ExplorerHistory[index2].Usage - ExplorerHistory[index1].Usage
}

#if IsDialog()
~Enter::
~NumpadEnter::
~LButton::
SetTimer, CheckFileDialogFolder, -200
return
#if

CheckFileDialogFolder:
CheckFileDialogFolder()
return
CheckFileDialogFolder()
{
   global ExplorerHistory
   if (IsDialog())
   if ((Path := Navigation.GetPath()) != ExplorerHistory[1].Path)
   {
       entry := RichObject()
       entry.Path := Path
       SplitPath, Path, Name
       entry.Name := Name
       entry.Usage := 1
       entry := ExplorerHistory.Push(entry)
       entry.Usage++
   }
}
; Find all explorer windows, register them in ExplorerWindows array and set up events and info gui
RegisterExplorerWindows()
{
   global ExplorerWindows
   ; for item in ComObjCreate("Shell.Application").Windows
   ; ComObjConnect(item, "Explorer")
   ; ShellWindows := ComObjCreate("Shell.Application").Windows
   ; ComObjConnect(ShellWindows, "Explorer")
   WinGet, hWndList, List, ahk_group ExplorerGroup
   Loop % hwndList
   {
       if (!ExplorerWindows.FindKeyWithValue("hwnd", hWndList%A_Index%+0))
       ExplorerWindows.Insert(new CExplorerWindow(hwndList%A_Index%+0))
   }
   SetTimer, WaitForClose, 1000
}

; Registers all explorer windows for SelectionChanged events. Called when explorer changes path
RegisterSelectionChangedEvents()
{
   global ExplorerWindows
   Loop % ExplorerWindows.MaxIndex()
   ExplorerWindows[A_Index].RegisterSelectionChangedEvent()
}
 /*
 ; Unregister an explorer window for SelectionChanged events
 UnregisterSelectionChangedEvents(hwnd)
 {
     global RegisteredSelectionChangedWindows
     i := RegisteredSelectionChangedWindows.FindKeyWithValue("hwnd", hwnd)
     if (i > 0)
         RegisteredSelectionChangedWindows.Delete(i)
 }
 */
 RestoreExplorerSelection()
 {
   global ExplorerWindows
   hwnd := WinActive("ahk_group ExplorerGroup")+0
   if (hwnd)
   {
       ExplorerWindow := ExplorerWindows.GetItemWithValue("hWnd",hwnd)
       if (!IsObject(ExplorerWindow.Selection.History))
       WriteDebug("Explorer window " hwnd " is not registered!")
       if (ExplorerWindow.Selection.History.MaxIndex() > 1)
       {
           WriteDebug("Explorer window " hwnd "restore selecion")
           Selection := ExplorerWindow.Selection.History[ExplorerWindow.Selection.History.MaxIndex() - 1]
           ; A SelectionChanged event will be fired 2 times that needs to be suppressed?
           ; Why is it fired 2 times instead of one time for each file? -> Probably because of timing
           ExplorerWindow.Selection.IgnoreNextEvent := 2
           WriteDebug("Explorer window " hwnd " expecting " ExplorerWindow.Selection.IgnoreNextEvent " selection events.")
           Navigation.SelectFiles(Selection, hwnd)
           ExplorerWindow.Selection.History.Delete(ExplorerWindow.Selection.History.MaxIndex())
       }
       else
       WriteDebug("Explorer window " hwnd " is registered but has no history")
   }
}

; ===============;
; Explorer related Events;
; ===============;

; Called when an explorer window is activated.
ExplorerActivated(hwnd)
{
   global ExplorerWindows
   if (!ExplorerWindows.FindKeyWithValue("hwnd",hwnd))
   ExplorerWindows.Insert(new CExplorerWindow(hwnd))
   RegisterSelectionChangedEvents() ;Is this needed? only as backup probably
}

; This routine polls the existance of explorer windows since they disappear rather randomly.
WaitForClose:
CheckForClosedExplorerWindows()
return
CheckForClosedExplorerWindows()
{
   global ExplorerWindows, ToolWindows
   DetectHiddenWindows, On
   for index, ExplorerWindow in ExplorerWindows
   {
       if (!WinExist("ahk_id " ExplorerWindow.hwnd))
       {
           ExplorerDestroyed(ExplorerWindow.hwnd)
           Loop % ToolWindows.MaxIndex() ;This code from Messagehooks.ahk is added here again since explorer close events don't work properly and need to be handled this way
           {
               if (ToolWindows[A_Index].hParent = ExplorerWindow.hwnd && ToolWindows[A_Index].AutoClose)
               {
                   WinClose % "ahk_id " ToolWindows[A_Index].hGui
                   ToolWindows.Remove(A_Index)
                   break
               }
           }
           SlideWindows.WindowClosed(ExplorerWindow.hwnd)
           break
       }
   }
   return
}

; Called when an explorer window gets deactivated.
ExplorerDeactivated(hwnd)
{
   global ExplorerWindows
   ; Explicitly redraw the tab bar window when an explorer window gets deactivated.
   ; This is needed to make sure the window isn't visible anymore when an Explorer window is closed.
   ; Explorer window hides first so we check if all explorer windows from that tab container are hidden.
   TabContainer := ExplorerWindows.GetItemWithValue("hwnd", hwnd + 0).TabContainer
   for index, window in TabContainer.Tabs
   {
       WinGet, Style, Style, % "ahk_id " window.hwnd
       if (!(Style & 0x10000000)) ;WS_VISIBLE
       TabContainer.UpdateTabPosition()
   }
}
; TODO: Continue here, implement delete method and check draw timer deactivation
; Called when an explorer window gets destroyed.
ExplorerDestroyed(hwnd)
{
   global ExplorerWindows
   TabContainer := ExplorerWindows.GetItemWithValue("hwnd", hwnd + 0).TabContainer
   if (index := ExplorerWindows.FindKeyWithValue("hwnd", hwnd))
   ExplorerWindows.Remove(index) ;This will destroy the info gui as well
   if (ExplorerWindows.TabContainerList.TabCloseInProgress) ;If this is set, then this event was caused by a tab closing action and must not trigger further tab close functions
   {
       ExplorerWindows.TabContainerList.TabCloseInProgress := false
       return
   }
   if (!TabContainer)
   return
   TabContainer.TabClosed(hwnd)
   if (Settings.Explorer.Tabs.TabWindowClose = 1)
   TabContainer.CloseAllTabs()
   return
}
ExplorerMoved(hwnd)
{
   global ExplorerWindows
   if (!IsObject(ExplorerWindows))
   return
   ExplorerWindow := ExplorerWindows.GetItemWithValue("hwnd", hwnd)
   if (IsObject(ExplorerWindow))
   {
       if (Settings.Explorer.Tabs.UseTabs && IsObject(ExplorerWindow.TabContainer) && IsObject(ExplorerWindows.TabContainerList) &&  !ExplorerWindows.TabContainerList.TabActivationInProgress)
           ExplorerWindow.TabContainer.UpdatePosition()
       if (ExplorerExtension_AdvancedStatusBarInfo && WinVer >= WIN_7)
           ExplorerWindow.InfoGUI.UpdateInfoPosition()
   }
}
; Called when active explorer changes its path.
ExplorerPathChanged(ExplorerWindow)
{
   global ExplorerHistory, ExplorerWindows, ExplorerExtension_AutoSelectFirstFile
   if (!IsObject(ExplorerWindow))
   {
       ExplorerWindow := ExplorerWindows.GetItemWithValue("hwnd", WinExist("A"))
       if (!ExplorerWindow)
       return
   }
   WriteDebug("path change")
   OldPath := ExplorerWindow.Path
   ExplorerWindow.RegisterSelectionChangedEvent() ;This will also refresh the path in ExplorerWindow
   Path := ExplorerWindow.Path
   if (OldPath = Path)
   return
   ExplorerWindow.DisplayName := Navigation.GetDisplayName(ExplorerWindow.hwnd)

   WriteDebug("change from " oldpath " to " path)
   Entry := RichObject()
   Entry.Path := Path
   Entry.Usage := 0
   Entry.Name := ExplorerWindow.DisplayName
   Entry := ExplorerHistory.Push(Entry) ;This can return a different entry that already exists in the list!
   Entry.Usage++

   if (Settings.Explorer.Tabs.UseTabs && IsObject(ExplorerWindow.TabContainer))
   ExplorerWindow.TabContainer.UpdateTabs()
   ; focus first file
   if (ExplorerExtension_AutoSelectFirstFile)
   {
       SplitPath, Path, name, dir,,,drive
       x := Navigation.GetSelectedFilepaths()
       if (!x.MaxIndex() && dir && (WinVer < WIN_Vista || SubStr(Path, 1 ,40) != "::{26EE0668-A00A-44D7-9371-BEB064C98683}"))
       {
           if (WinVer >= WIN_7)
           {
               ControlGetFocus focussed, A
               ControlFocus DirectUIHWND3, A
               ControlSend DirectUIHWND3, {Home}{Space},A
           }
           else
           {
               focussed := XPGetFocussed()
               ControlFocus SysListView321, A
               ControlSend SysListView321, {Home},A
           }
           Sleep 50 ;Better wait some time
           ControlFocus %focussed%, A
       }
   }
}
; Called when selection changes in an explorer window. If the shell is restarted, old windows won't be recognized anymore.
ExplorerSelectionChanged(ExplorerCOMObject)
{
   global ExplorerWindows
   Critical, Off
   Loop % ExplorerWindows.MaxIndex()
   {
       if (ExplorerWindows[A_Index].Selection.COMObject = ExplorerCOMObject)
       {
           index := A_Index
           break
       }
   }
   if (!index)
   return
   if (ExplorerWindows[index].Selection.IgnoreNextEvent > 0)
   {
       ExplorerWindows[index].Selection.IgnoreNextEvent := ExplorerWindows[index].Selection.IgnoreNextEvent - 1
       return
   }

   ; ShowTip({Min : 10, Max : 11}, 0.1)

   ExplorerWindows[index].Selection.History.Insert(Navigation.GetSelectedFilenames(ExplorerWindows[index].hwnd))
   if (ExplorerWindows[index].Selection.History.MaxIndex() > 10)
   ExplorerWindows[index].Selection.History.Delete(1)
   if (WinVer = WIN_7)
   ExplorerWindows[index].InfoGUI.UpdateInfos(ExplorerWindows[index]) ;Update the info GUI to reflect selection change
}

; This class displays additional information in the status bar of explorer windows
Class InfoGUI
{
   __New(hParent)
   {
       if (WinVer != WIN_7)
       return 0
       GuiNum := GetFreeGuiNum(1, this.__Class)
       this.GuiNum := GuiNum
       Gui, %GuiNum%: font, s9, Segoe UI
       Gui, %GuiNum%: Add, Text, x60 y0 w70 h12, %A_Space%
       Gui, %GuiNum%: Add, Text, x0 y0 w60 h12, %A_Space%
       Gui, %GuiNum%: -Caption  +LastFound +ToolWindow
       Gui, %GuiNum%: Color, FFFFFF
       Gui, %GuiNum%: +LastFound
       WinSet, TransColor, FFFFFF
       AttachToolWindow(hParent, GuiNum, true)
       this.hWnd := WinExist() +0
       this.hParent := hParent+0
   }
   __Delete()
   {
       Gui % this.GuiNum ":Destroy"
   }
   UpdateInfos(ExplorerWindow)
   {
       global ExplorerWindows
       if (WinVer != WIN_7)
       return
       totalsize := 0
       realfiles := false ;check if only folders are selected
       History := ExplorerWindow.Selection.History[ExplorerWindow.Selection.History.MaxIndex()]
       Loop % History.MaxIndex()
       {
           FileGetSize, size, % ExplorerWindow.Path "\" History[A_Index]
           if (!realfiles)
           realfiles := !InStr(FileExist(ExplorerWindow.Path "\" History[A_Index]), "D")
           totalsize += size
       }
       DriveSpaceFree, free, % ExplorerWindow.Path
       free := FormatFileSize(free * 1048576, free < 1000 ? 0 : 1)
       GuiControl % this.GUINum ":Text", Static1, % free " " ExplorerWindows.InfoGUI_FreeText
       if (realfiles)
       {
           totalsize := FormatFileSize(totalsize)
           GuiControl % this.GUINum ":Text", Static2, %totalsize%
       }
       else
       GuiControl % this.GUINum ":Text", Static2, %A_Space%
       this.UpdateInfoPosition()
   }
   UpdateInfoPosition()
   {
       ControlGet, visible, visible, , msctls_statusbar321, % "ahk_id " this.hParent ;Check if status bar is visible
       if (visible)
       {
           WinGetPos , X, Y, Width, Height, % "ahk_id " this.hParent
           ControlGetPos , , cY, , cHeight, msctls_statusbar321, % "ahk_id " this.hParent
           InfoX := X + Width - 370
           InfoY := Round(Y + cY + cHeight / 2 - 6) ; +Height-26
           if (Width > 540)
               Gui, % this.GuiNum ":Show", AutoSize NA x%InfoX% y%InfoY%
       }
       else
       {
           Gui, % this.GuiNum ": Hide"
       }
   }
}

; TODO: Figure out how to receive explorer close event and proper path change
; This class represents an explorer window in 7plus and stores data about it.
Class CExplorerWindow
{
   __New(hWnd, Path="")
   {
       this.hWnd := hWnd
       this.Path := Path ? Path : Navigation.GetPath(hWnd)
       this.DisplayName := Navigation.GetDisplayName(hWnd)
       if (WinVer = WIN_7)
       this.InfoGUI := new InfoGUI(hWnd)
       this.Selection := Object()
       this.RegisterSelectionChangedEvent()
   }
   RegisterSelectionChangedEvent()
   {
       global ExplorerWindows
       if (Settings.General.DontRegisterSelectionChanged)
       return
       for Item in ComObjCreate("Shell.Application").Windows
       {
           try
           {
               if (Item.hWnd != this.hWnd)
               continue
               if (!this.Selection.COMObject) ;New explorer window
               {
                   doc := Item.Document
                   if (!doc)
                   return 0
                   ComObjConnect(doc, "Explorer")
                   this.Selection.COMObject := doc
                   this.Selection.History := Array(Navigation.GetSelectedFilenames(this.hwnd))
               }
               else ;explorer window is already registered, lets see if its view changed
               {
                   doc := Item.Document
                   if (!doc)
                   continue
                   Path := doc.Folder.Self.path
                   if (!Path)
                   continue
                   if (this.Path != Path) ;Compare by path since the COM wrapper objects are different
                   {
                       ComObjConnect(doc, "Explorer")
                       this.Selection.COMObject := doc
                       this.Selection.History := Array(Navigation.GetSelectedFilenames(this.hwnd)) ;Recreate array to remove selection history from previous folder
                       this.Path := Path
                   }
               }
           }
           catch e
           {
           }
       }
   }
}

; Gets focused control in XP to prevent blocking double clicks like with ControlGetFocus
XPGetFocussed()
{
  WinGet ctrlList, ControlList, A
  ctrlHwnd:=GetFocusedControl()
  ; Built an array indexing the control names by their hwnd
  Loop Parse, ctrlList, `n
  {
    ControlGet hwnd, Hwnd, , %A_LoopField%, A
    hwnd += 0   ; Convert from hexa to decimal
    if (hwnd=ctrlHwnd)
    return A_LoopField
}
}

; This script retrieves the ahk_id (HWND) of the active window's focused control.
; This script requires Windows 98+ or NT 4.0 SP3+.
/*
typedef struct tagGUITHREADINFO {
  DWORD cbSize;
  DWORD flags;
  HWND  hwndActive;
  HWND  hwndFocus;
  HWND  hwndCapture;
  HWND  hwndMenuOwner;
  HWND  hwndMoveSize;
  HWND  hwndCaret;
  RECT  rcCaret;
} GUITHREADINFO, *PGUITHREADINFO;
*/
GetFocusedControl()
{
 guiThreadInfoSize := 8 + 6 * A_PtrSize + 16
 VarSetCapacity(guiThreadInfo, guiThreadInfoSize, 0)
 NumPut(GuiThreadInfoSize, GuiThreadInfo, 0)
 ; DllCall("RtlFillMemory" , "PTR", &guiThreadInfo, "UInt", 1 , "UChar", guiThreadInfoSize)   ; Below 0xFF, one call only is needed
 if (DllCall("GetGUIThreadInfo" , "UInt", 0   ; Foreground thread
   , "PTR", &guiThreadInfo) = 0)
 {
  ErrorLevel := A_LastError   ; Failure
  Return 0
}
focusedHwnd := NumGet(guiThreadInfo,8+A_PtrSize, "Ptr") ; *(addr + 12) + (*(addr + 13) << 8) +  (*(addr + 14) << 16) + (*(addr + 15) << 24)
Return focusedHwnd
}

; checks if a point is in a rectangle
IsInArea(px, py, x, y, w, h)
{
    return (px > x && py > y && px < x + w && py < y + h)
}

IsDialog(window=0,ListViewSelected = False)
{
    result:=0
    if (window)
    window:="ahk_id " window
    else
    window:="A"
    if (WinGetClass(window)="#32770")
    {
        ; Check for new FileOpen dialog
        ControlGet, hwnd, Hwnd , , DirectUIHWND3, %window%
        if (hwnd)
        {
            ControlGet, hwnd, Hwnd , , SysTreeView321, %window%
            if (hwnd)
            {
                ControlGet, hwnd, Hwnd , , Edit1, %window%
                if (hwnd)
                {
                    ControlGet, hwnd, Hwnd , , Button2, %window%
                    if (hwnd)
                    {
                        ControlGet, hwnd, Hwnd , , ComboBox2, %window%
                        if (hwnd)
                        {
                            ControlGet, hwnd, Hwnd , , ToolBarWindow323, %window%
                            if (hwnd)
                            result:=(!ListViewSelected||IsControlActive("DirectUIHWND2")||IsControlActive("SysTreeView321"))
                        }
                    }
                }
            }
        }
        ; Check for old FileOpen dialog
        if (!result)
        {
            ControlGet, hwnd, Hwnd , , ToolbarWindow321, %window%
            if (hwnd)
            {
                ControlGet, hwnd, Hwnd , , SysListView321, %window%
                if (hwnd)
                {
                    ControlGet, hwnd, Hwnd , , ComboBox3, %window%
                    if (hwnd)
                    {
                        ControlGet, hwnd, Hwnd , , Button3, %window%
                        if (hwnd)
                        {
                            ControlGet, hwnd, Hwnd , , SysHeader321 , %window%
                            if (hwnd)
                            result:=(!ListViewSelected||IsControlActive("DirectUIHWND2")||IsControlActive("SysTreeView321")) ? 2 : 0
                        }
                    }
                }
            }
        }
    }
    return result
}

; Checks if a specific control class is active. Matches by start of ClassNN.
IsControlActive(controlclass)
{
    if (WinVer >= WIN_7)
    ControlGetFocus active, A
    else
    active := XPGetFocussed()
    if (InStr(active, controlclass))
    return true
    return false
}
; Adds a tooltip to a control.
AddToolTip(con, text, Modify = 0)
{
    Static TThwnd,GuiHwnd
    l_DetectHiddenWindows := A_DetectHiddenWindows
    if (!TThwnd)
    {
        Gui, +LastFound
        GuiHwnd := WinExist()
        TThwnd := CreateTooltipControl(GuiHwnd)
        Varsetcapacity(TInfo, 6 * 4 + 6 * A_PtrSize, 0)
        Numput(6 * 4 + 6 * A_PtrSize, TInfo, "UInt")
        Numput(1 | 16, TInfo, 4, "UInt")
        Numput(GuiHwnd, TInfo, 8, "PTR")
        Numput(GuiHwnd, TInfo, 8 + A_PtrSize, "PTR")
        ; Numput(&text,TInfo,36)
        Detecthiddenwindows, on
        Sendmessage, 1028, 0, &TInfo, , ahk_id %TThwnd%
        SendMessage, 1048, 0, 300, , ahk_id %TThwnd%
    }
    Varsetcapacity(TInfo, 6 * 4 + 6 * A_PtrSize, 0)
    Numput(6 * 4 + 6 * A_PtrSize, TInfo, "UInt")
    Numput(1 | 16, TInfo, 4, "UInt")
    Numput(GuiHwnd, TInfo, 8, "PTR")
    Numput(con, TInfo, 8 + A_PtrSize, "PTR")
    VarSetCapacity(ANSItext, StrPut(text, ""))
    StrPut(text, &ANSItext, "")
    Numput(&ANSIText, TInfo, 6 * 4 + 3 * A_PtrSize, "PTR")

    Detecthiddenwindows, on
    if (Modify)
    SendMessage, 1036, 0, &TInfo, , ahk_id %TThwnd%
    else
    {
        Sendmessage, 1028, 0, &TInfo, , ahk_id %TThwnd%
        SendMessage, 1048, 0, 300, , ahk_id %TThwnd%
    }
    DetectHiddenWindows %l_DetectHiddenWindows%
}
; Append two paths together and treat possibly double or missing backslashes
AppendPaths(BasePath, RelativePath)
{
    if (!BasePath)
    return RelativePath
    if (!RelativePath)
    return BasePath
    return StringTrimLeft(BasePath, "\") "\" StringTrimLeft(RelativePath, "\")
}

; Gets ClassNN from hwnd
HWNDToClassNN(hwnd)
{
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
CreateTooltipControl(hwind)
{
    Ret := DllCall("CreateWindowEx"
        ,"Uint", 0
        ,"Str", "TOOLTIPS_CLASS32"
        ,"PTR", 0
        ,"Uint", 2147483648 | 3
        ,"Uint", -2147483648
        ,"Uint", -2147483648
        ,"Uint", -2147483648
        ,"Uint", -2147483648
        ,"PTR", hwind
        ,"PTR", 0
        ,"PTR", 0
        ,"PTR", 0, "PTR")
    return Ret
}

/*
HWND WINAPI GetParent(
  __in  HWND hWnd
);
*/
GetParent(hWnd)
{
    return DllCall("GetParent", "Ptr", hWnd, "Ptr")
}

; Checks if a context menu is active and has focus
; Need to check if other context menus are active (trillian, browsers,...)
IsContextMenuActive()
{
    GuiThreadInfoSize := 24 + 6 * A_PtrSize
    VarSetCapacity(GuiThreadInfo, GuiThreadInfoSize)
    NumPut(GuiThreadInfoSize, GuiThreadInfo, 0)
    if not DllCall("GetGUIThreadInfo", uint, 0, "Ptr", &GuiThreadInfo)
    {
      ; MsgBox GetGUIThreadInfo() indicated a failure.
      return
  }
  ; GuiThreadInfo contains a DWORD flags at byte 4
  ; Bit 4 of this flag is set if the thread is in menu mode. GUI_INMENUMODE = 0x4
  if (NumGet(GuiThreadInfo, 4) & 0x4)
  return true
  return false
}

; This stuff doesn't properly use COM.ahk yet :(
/*
Executes context menu entries of shell items without showing their menus
Usage:
ShellContextMenu("Desktop",1)            ;Calls "Next Desktop background" in Win7
1st parameter can be "Desktop" for empty selection desktop menu, a path, or an idl
Leave 2nd parameter empty to show context menu and extract idn by clicking on an entry (shows up in debugview)
*/
ShellContextMenu(sPath,idn=0)
{
    result := DllCall(Settings.DllPath "\Explorer.dll\ExecuteContextMenuCommand", "Str", sPath, "Int", idn, "PTR", A_ScriptHwnd)
    if (Errorlevel != 0)
    Notify("Couldn't execute context menu command!", "Error Calling ExecuteContextMenuCommand() in Explorer.dll!", 5, NotifyIcons.Error)
}

; Checks if a specific window is under the cursor.
IsWindowUnderCursor(hwnd)
{
    MouseGetPos, , , win
    if hwnd is number
    return win = hwnd
    else
    return InStr(WinGetClass("ahk_class " win), hwnd)
}

; Checks if a specific control is under the cursor and returns its ClassNN if it is.
IsControlUnderCursor(ControlClass)
{
    MouseGetPos, , , , control
    if (InStr(Control, ControlClass))
    return control
    return false
}

; Attaches a window as a tool window to another window from a different process. QUESTION: Is this still needed?
AttachToolWindow(hParent, GUINumber, AutoClose)
{
    global ToolWindows
    WriteDebug("AttachToolWindow " GUINumber " to " hParent)
    if (!IsObject(ToolWindows))
    ToolWindows := Object()
    if (!WinExist("ahk_id " hParent))
    return false
    Gui %GUINumber%: +LastFoundExist
    if (!(hGui := WinExist()))
    return false
    ; SetWindowLongPtr is defined as SetWindowLong in x86
    if (A_PtrSize = 4)
    DllCall("SetWindowLong", "Ptr", hGui, "int", -8, "PTR", hParent) ;This line actually sets the owner behavior
    else
    DllCall("SetWindowLongPtr", "Ptr", hGui, "int", -8, "PTR", hParent) ;This line actually sets the owner behavior
    ToolWindows.Insert(Object("hParent", hParent, "hGui", hGui,"AutoClose", AutoClose))
    Gui %GUINumber%: Show, NoActivate
    return true
}

DeAttachToolWindow(GUINumber)
{
    global ToolWindows
    Gui %GUINumber%: +LastFoundExist
    if (!(hGui := WinExist()))
    return false
    Loop % ToolWindows.MaxIndex()
    {
        if (ToolWindows[A_Index].hGui = hGui)
        {
            ; SetWindowLongPtr is defined as SetWindowLong in x86
            if (A_PtrSize = 4)
            DllCall("SetWindowLong", "Ptr", hGui, "int", -8, "PTR", 0) ;Remove tool window behavior
            else
            DllCall("SetWindowLongPtr", "Ptr", hGui, "int", -8, "PTR", 0) ;Remove tool window behavior
            DllCall("SetWindowLongPtr", "Ptr", hGui, "int", -8, "PTR", 0)
            ToolWindows.Remove(A_Index)
            break
        }
    }
}
