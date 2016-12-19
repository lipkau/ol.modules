; ScreenShotTool - ScreenShotTools.ahk
; author: Oliver Lipkau
; created: 2016 11 13

#include lib\ahklib\gdip.ahk
#include lib\ahklib\_Struct.ahk
#include lib\ahklib\CPrompt.ahk
#include lib\ahklib\CManifest.ahk
#include lib\ahklib\CNotification.ahk
Struct(Structure, pointer:=0, init:=0) {
    return new _Struct(Structure,pointer,init)
}
/**
 * TODO:
 *     * cursor?
 *     * append to name if already exists
 */

 class CScreenShotToolModel
 {
    static moduleBundle, moduleName, moduleHelp
    static manifest := new CManifest(A_LineFile)

    __New()
    {
        this.modulePack := this.manifest.metaData.package
        this.moduleName := this.manifest.metaData.name
        this.moduleHelp := this.manifest.metaData.url
        return this
    }
 }

/**
 * Class to manage the ScreenShot behavior
 */
class CScreenShotTool extends CScreenShotToolModel
{
    static counter

    __New()
    {
        this.base.__New()
        this.Counter := a2.db.get(this.modulePack, this.moduleName, "counter")
        return this
    }

    __Delete()
    {
        ; msgbox % "destructor"
    }

    /**
     * Perform some initial setup when the module is loaded
     */
    Init()
    {
        global ScreenShotTool := new CScreenShotTool()
        ; Ensure default values are saved in DB
        ; inputFields := [
        ;     , "ScreenShotTool_TargetPath"
        ;     , "ScreenShotTool_this.fileNameType"
        ;     , "ScreenShotTool_FileNamePattern"
        ;     , "ScreenShotTool_FileNamePattern_Time"
        ;     , "ScreenShotTool_FileFormat"
        ;     , "ScreenShotTool_Quality"
        ;     , "ScreenShotTool_Scaling"
        ;     , "ScreenShotTool_SaveToClipboard"
        ;     , "ScreenShotTool_CaptureCursor"
        ;     , "ScreenShotTool_AcusticFeedback"
        ;     , "ScreenShotTool_VisualFeedback"
        ;     , "ScreenShotTool_Timer"
        ;     , "ScreenShotTool_openInManager"
        ;     , "ScreenShotTool_DisableFontSmoothing"
        ;     , "ScreenShotTool_DisableClearType"
        ;     , "ScreenShotTool_CatchContextMenu"
        ;     , "ScreenShotTool_NoOverlappingWindows"
        ;     , "ScreenShotTool_DisableTransparency1"
        ;     , "ScreenShotTool_DisableTransparency2"]
        ; for i,v in inputFields
        ; {
        ;     element := this.manifest.findUIElementByKey("name", v)
        ;     if (element.typ != "combo")
        ;         value := element.value
        ;     else
        ;         value := element.items[1]
            ; a2.db.delete(this.modulePack, this.moduleName, v)
            ; a2.db.set(this.modulePack, this.moduleName, v, value)
        ; }

        ; a2.db.increment(this.modulePack, this.moduleName, "counter")
        ; read screenshot counter from DB
        ; a2.db.delete(this.modulePack, this.moduleName, "counter")
    }

    /**
     * Entry point for hotkeys
     *     Take a screenshot depending on the hotkey
     *     Store the screenshot
     *     Open in ImageConverter
     */
    TakeScreenShot(option = "")
    {
        option := option ? option : "All"

        WriteDebug("Triggered Screenshot with option:", option, "debug", this.moduleName)

        filePath := this.Capture(option)

        if (!filePath)
            return ; failed to capture screen. Showing an error must be handled in the Capture() method

        Notify("Screenshot captured", "Screenshot was captured and stored.", 2, NotifyIcons.Success)

        if ((this.openInManager) && (FileExist(filePath)))
        {
            ImageConverter := new CImageConverterAction()
            ImageConverter.Files := filePath
            ImageConverter.ReuseWindow := true
            ImageConverter.Execute()
        }
    }

    /**
     * Capture the screen (or part of it) and store it in a temp file
     *
     * Sample:
     *     if (ScreenShotTool)    ; Check if class is available in runtime
     *     {
     *         ScreenShot                      := new ScreenShotTool()
     *         ScreenShot.delay                := 3
     *         ScreenShot.visualFeedback       := false
     *         ScreenShot.audioFeedback        := false
     *         ScreenShot.saveToClipboard      := false
     *         ScreenShot.saveToFile           := true
     *         ScreenShot.disableFontSmoothing := true
     *         ScreenShot.disableClearType     := false
     *         ScreenShot.quality              := 95
     *         ScreenShot.fileName             := "myFile.jpg"
     *         ScreenShot.targetPath           := myModule.Path
     *         ScreenShot.openInManager        := false
     *         ScreenShot.catchContextMenu     := false
     *         ScreenShot.scale                := 1.5
     *         ScreenShot.captureCursor        := false
     *         ssFilePath := ScreenShot.Capture("Window")
     *     }
     *
     * @param  string   type    Allowed values:
     *                              "All":      Screenshot of the entire desktop (multiple monitors, if so)
     *                              "Window":   Screenshot of the currently active window
     *                              "Area":     Screenshot of the area. If no area is provided in param "coords",
     *                                          the user gets a interaction screen to select the area
     *                              "LastArea": Screenshot of the last area the customer marked
     *                              "Monitor":  Screenshot of the Monitor on which the currently active window is
     * @param  string   coords  Coordinates of the area the customer selected. Format:
     *                              coordX|coordY|width|height
     */
    Capture(type, coords = "")
    {
        ; delay the capturing
        if (IsNumeric(this.delay) && this.delay > 0)
        {
            MaxProgress := this.delay * 100
            if (MaxProcess == 100)
                MaxProcess := 60
            Progress, 5:H50 R0-%MaxProgress% B2 P%MaxProgress%, , ScreenShot Delay
            Loop % MaxProgress
                Progress % "5:" MaxProgress-A_Index
            Progress, 5:Off
            Sleep, 50
        }

        if (type == "All")
        {
            ; Capture FullScreen
            this.screenShotMode := "FullScreen"
            ; foo := this.CaptureScreen.Exec(, this.captureCursor, , this.quality)
            storedFile := this._captureFromScreen()
        }
        else if (type == "Window")
        {
            ; Capture the active window
            this.screenShotMode := "Window"
            storedFile := this._captureFromScreen("A")
        }
        else if (type == "Area")
        {
            ; Capture the Area choosen by the user
            this.screenShotMode := "Area"
            coords := coords ? coords : this.SelectArea()
            storedFile := this._captureFromScreen(coords)
        }
        else if (type == "LastArea")
        {
            ; Capture the last Area choosen by the user
            this.screenShotMode := "Area"
            if (!(this.lastArea))
            {
                Notify("Error", "No previous area could be found.`nPlease capture a Screenshot by defining an area before using this again", 3, NotifyIcons.Error)
                return false
            }
            ; TODO: scr_sub_Hotkey_LastInteractive
            storedFile := this._captureFromScreen(this.lastArea)
        }
        else if (type == "Monitor")
        {
            ; Capture the Monitor on which the ActiveWindow is located on
            this.screenShotMode := "Monitor"
            storedFile := this._captureFromScreen(1)
        }
        else
        {
            Notify("Error", "Invalid Screenshot Type", 4, NotifyIcons.Error)
            return false
        }

        return storedFile
    }

    SelectArea()
    {
        ; TODO:
        ; scr_sub_Hotkey_Interactive
        ; scr_sub_GetFrameBounds
        ; scr_sub_MoveWithKeys
        ; scr_tim_MouseWatch
    }

    _captureFromScreen(aRect = 0)
    {
        this._disableFontSmoothing()

        if (!aRect)  ; Capture the entire "virtual" desktop
        {
            GetVirtualScreenCoordinates(nL, nT, nW, nH)
        }
        else if (aRect == 1) ; Capture the active windows
        {
            WinGetPos, nL, nT, nW, nH, A
            fixMaximizedScreenCoord("A", nL, nT, nW, nH)
        }
        else if (aRect = 2)  ; Capture the client area of the active window
        {
            WinGet, hWnd, ID, A
            VarSetCapacity(rt, 16, 0)
            DllCall("GetClientRect" , "Uint", hWnd, "Uint", &rt)
            DllCall("ClientToScreen", "Uint", hWnd, "Uint", &rt)
            nL := NumGet(rt, 0, "int")
            nT := NumGet(rt, 4, "int")
            nW := NumGet(rt, 8)
            nH := NumGet(rt,12)
        } else if (WinExist(aRect)) {
            WinGet, sWinID, ID, % aRect
            WinGetPos, nL, nT, nW, nH, % aRect
            If ((aRect = "A") AND (this.catchContextMenu == true)) {
                DetectHiddenWindows, Off
                WinGet, sWinList, List
                WinGetClass, sWinClass, ahk_id %sWinList1%
                If (((sWinClass = "#32768") OR (sWinClass = "MozillaDropShadowWindowClass")) AND (sWinList1 != sWinID)) {
                    WinGetClass, sWinClass, ahk_id %sWinList2%
                    If (sWinClass == SysShadow)
                        sWinList1 := sWinList2
                    WinGetPos, nLcontext, nTcontext, nWcontext, nHcontext, ahk_id %sWinList1%
                    If (nLcontext < nL) {
                        this.noOverlappingWindows := true
                        nL := nLcontext
                    }
                    If (nTcontext < nT) {
                        this.noOverlappingWindows := true
                        nT := nTcontext
                    }
                    If (nLcontext - nL + nWcontext > nW) {
                        this.noOverlappingWindows := true
                        nW := nLcontext - nL + nWcontext
                    }
                    If (nTcontext - nT + nHcontext > nH) {
                        this.noOverlappingWindows := true
                        nH := nTcontext - nT + nHcontext
                    }
                }
            }
        }
        else  ; Capture the coordinates provided
        {
            StringSplit, rt, aRect, `,, %A_Space%%A_Tab%
            nL := rt1
            nT := rt2
            nW := rt3 ; - rt1
            nH := rt4 ; - rt2
            znW := rt5
            znH := rt6
        }

        ; Do not capture screen parts outside of the virtual desktop
        If (!sWinID) {
            GetVirtualScreenCoordinates(MonitorAreaLeft, MonitorAreaTop, MonitorAreaRight, MonitorAreaBottom)
            If (nL < MonitorAreaLeft)
                nL := MonitorAreaLeft
            If (nT < MonitorAreaTop)
                nT := MonitorAreaTop
            If (nL+nW > MonitorAreaRight)
                nW := MonitorAreaRight-nL
            If (nT+nH > MonitorAreaBottom)
                nH := MonitorAreaBottom-nT
        }

        WinGet, bExStyle, ExStyle, ahk_id %sWinID%
        If ((sWinID) AND (!(bExStyle & 0x80000)) AND (!InStr(scr_Class,"SunAwt")) AND (!InStr(scr_Class,"javax.swing")) AND (this.noOverlappingWindows == false)) ; WS_EX_LAYERED
        {
            ncL := nL
            ncT := nT
            ncW := nW
            ncH := nH
            WriteDebug("Capturing Bitmap ALT", "x: " ncL ", y: " ncT ", w: " ncW ", h: " ncH, "debug", this.moduleName)

            hDC := DllCall("GetDC", "Uint", 0)
            mDC := DllCall("CreateCompatibleDC", "Uint", hDC)
            hBM := DllCall("CreateCompatibleBitmap", "Uint", hDC, "int", nW, "int", nH)
            oBM := DllCall("SelectObject", "Uint", mDC, "Uint", hBM)
            fixMaximizedScreenCoord( aRect, ncL, ncT, ncW, ncH, 1 )
            DllCall("PrintWindow", "UInt",sWinID, "UInt",mDC, "UInt",0)
            if (this.captureCursor)
                this._captureCursor(mDC, nL, nT)
            DllCall("SelectObject", "Uint", mDC, "Uint", oBM)
            DllCall("DeleteDC", "Uint", mDC)
            hBM := this._clipBitmap(hDC, hBM, ncL, ncT, ncW, ncH)
        }
        else
        {
            WriteDebug("Capturing Bitmap", "x: " nL ", y: " nT ", w: " nW ", h: " nH, "debug", this.moduleName)

            hDC := DllCall("GetDC", "Uint", 0)
            mDC := DllCall("CreateCompatibleDC", "Uint", hDC)
            hBM := DllCall("CreateCompatibleBitmap", "Uint", hDC, "int", nW, "int", nH)
            oBM := DllCall("SelectObject", "Uint", mDC, "Uint", hBM)
            DllCall("BitBlt", "Uint", mDC, "int", 0, "int", 0, "int", nW, "int", nH, "Uint", hDC, "int", nL, "int", nT, "Uint", 0x40000000 | 0x00CC0020)

            if (this.captureCursor)
                this._captureCursor(mDC, nL, nT)
            DllCall("SelectObject", "Uint", mDC, "Uint", oBM)
            DllCall("DeleteDC", "Uint", mDC)
        }

        If (this.scale != 1)
        {
            znW := Round(nW * this.scale)
            znH := Round(nH * this.scale)
            ; What does this do?
            ; StringSplit, rt, sZoom, `,*x, %A_Space%%A_Tab%
            ; znW := rt1
            ; znH := rt2

            ; replace * wildcards
            ; If znH = *
                ; znH := nH
            ; If znW = *
                ; znW := nW

            ; StringReplace, znW, znW, `:, /
            ; Support resultions ie: "1/2"
            ; IfInString znW, /
            ; {
            ;     StringSplit, znW, znW, /
            ;     znH := Round(nH*znW1/znW2)
            ;     znW := Round(nW*znW1/znW2)
            ; }
            ; Support scalling in % string ie: "120%"
            ; Else IfInString znW, `%
            ; {
            ;     StringReplace, znW, znW, `%
            ;     znH := Round(nH*znW/100)
            ;     znW := Round(nW*znW/100)
            ; }
            ; Else
            ; {
            ;     ; support resultions ie: "640/?"
            ;     If (znW = "" OR znW = "?")
            ;         znW = 0
            ;     If (znH = "" OR znH = "?")
            ;         znH = 0
            ;     If ((nW <= znW OR znW = 0) AND (nH <= znH OR znH = 0))
            ;     {
            ;         znW =
            ;         znH =
            ;     }
            ;     Else
            ;     {
            ;         If znW = 0
            ;         {
            ;             zF := znH/nH
            ;             znW := Round(nW * zF)
            ;         }
            ;         Else If znH = 0
            ;         {
            ;             zF := znW/nW
            ;             znH := Round(nH * zF)
            ;         }
            ;         Else
            ;         {
            ;             zF := znW/nW
            ;             If ((nH * zF) > znH)
            ;             zF := znH/nH
            ;             znH := Round(nH * zF)
            ;             znW := Round(nW * zF)
            ;         }
            ;     }
            ; }
        }
        If (znW && znH)
            hBM := this._scaleBitmap(hDC, hBM, nW, nH, znW, znH)

        this.Flash(nL,nT,nW,nH)
        this.Shutter()

        this.counter := a2.db.increment(this.modulePack, this.moduleName, "counter")
        file := this.targetPath "\" this.filename
        If (this.saveToClipboard)
            this._storeToClipboard(hBM)
        If (this.saveToFile)
            this._storeToFile(hBM, file)
        DllCall("DeleteObject", "Uint", hBM)
        DllCall("ReleaseDC", "Uint", 0, "Uint", hDC)

        this._enableFontSmoothing()
        this._refreshWindows()

        return (this.saveToFile) ? file : -1
    }

    _storeToFile(sFileFr = "", sFileTo = "")
    {
        WriteDebug("File stored to", sFileTo, "debug", this.moduleName)

        Ptr := A_PtrSize ? "UPtr" : "UInt"

        If !sFileTo
            sFileTo := A_LineFile . "\screen.bmp"
        SplitPath, sFileTo, , , sExtTo
        Extension := "." sExtTo

        hGdiPlus := DllCall("LoadLibrary", "str", "gdiplus.dll")
        VarSetCapacity(si, 16, 0), si := Chr(1)
        DllCall("gdiplus\GdiplusStartup", "UintP", pToken, "Uint", &si, "Uint", 0)
        DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", nCount, "uint*", nSize)
        VarSetCapacity(ci, nSize)
        DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, Ptr, &ci)
        if !(nCount && nSize)
            return -2

        If (A_IsUnicode){
            StrGet_Name := "StrGet"
            Loop, %nCount%
            {
                sString := %StrGet_Name%(NumGet(ci, (idx := (48+7*A_PtrSize)*(A_Index-1))+32+3*A_PtrSize), "UTF-16")
                if !InStr(sString, "*" Extension)
                    continue

                pCodec := &ci+idx
                break
            }
        } else {
            Loop, %nCount%
            {
                Location := NumGet(ci, 76*(A_Index-1)+44)
                nSize := DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "uint", 0, "int",  0, "uint", 0, "uint", 0)
                VarSetCapacity(sString, nSize)
                DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "str", sString, "int", nSize, "uint", 0, "uint", 0)
                if !InStr(sString, "*" Extension)
                    continue

                pCodec := &ci+76*(A_Index-1)
                break
            }
        }

        If !sFileFr
        {
            DllCall("OpenClipboard", "Uint", 0)
            If DllCall("IsClipboardFormatAvailable", "Uint", 2) && (hBM:=DllCall("GetClipboardData", "Uint", 2))
                DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Uint", hBM, "Uint", 0, "UintP", pImage)
            DllCall("CloseClipboard")
        }
        Else If sFileFr Is Integer
            DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Uint", sFileFr, "Uint", 0, "UintP", pImage)
        Else
            DllCall("gdiplus\GdipLoadImageFromFile", "Uint", this._unicode4Ansi(wFileFr,sFileFr), "UintP", pImage)
        If pImage
        {
            Quality := (this.quality < 0) ? 0 : (this.quality > 100) ? 100 : this.quality
            if Extension in .JPG,.JPEG,.JPE,.JFIF
            {
                VarSetCapacity(EncoderParameters, nSize, 0)
                DllCall("gdiplus\GdipGetEncoderParameterList", Ptr, pImage, Ptr, pCodec, "uint", nSize, Ptr, &EncoderParameters)
                Loop, % NumGet(EncoderParameters, "UInt")      ;%
                {
                    elem := (24+(A_PtrSize ? A_PtrSize : 4))*(A_Index-1) + 4 + (pad := A_PtrSize = 8 ? 4 : 0)
                    if (NumGet(EncoderParameters, elem+16, "UInt") = 1) && (NumGet(EncoderParameters, elem+20, "UInt") = 6)
                    {
                        p := elem+&EncoderParameters-pad-4
                        NumPut(Quality, NumGet(NumPut(4, NumPut(1, p+0)+20, "UInt")), "UInt")
                        break
                    }
                }
            }
            Else
                xParam = 0

            DllCall("gdiplus\GdipSaveImageToFile", "Uint", pImage, "Uint", &sFileTo, "Uint", pCodec, "Uint", xParam)
            DllCall("gdiplus\GdipDisposeImage", "Uint", pImage)
        }

        DllCall("gdiplus\GdiplusShutdown" , "Uint", pToken)
        DllCall("FreeLibrary", "Uint", hGdiPlus)
    }

    _storeToClipboard(hMem, nFormat = 2)
    {
        WriteDebug("Storing bitmap to clipboard", "", "debug", this.moduleName)
        DetectHiddenWindows, On
        Process, Exist
        WinGet, hAHK, ID, ahk_pid %ErrorLevel%
        DllCall("OpenClipboard", "Uint", hAHK)
        DllCall("EmptyClipboard")
        DllCall("SetClipboardData", "Uint", nFormat, "Uint", hMem)
        DllCall("CloseClipboard")
    }

    _unicode4Ansi(ByRef wString, sString)
    {
        nSize := DllCall("MultiByteToWideChar", "Uint", 0, "Uint", 0, "Uint", &sString, "int", -1, "Uint", 0, "int", 0)
        VarSetCapacity(wString, nSize * 2)
        DllCall("MultiByteToWideChar", "Uint", 0, "Uint", 0, "Uint", &sString, "int", -1, "Uint", &wString, "int", nSize)
        Return &wString
    }

    _scaleBitmap(hDC, hBM, nW, nH, znW, znH)
    {
        WriteDebug("Rescaling from", "w: " nW ", h: " nH, "debug", this.moduleName)
        WriteDebug("Rescaling to", "w: " znW ", h: " znH, "debug", this.moduleName)

        mDC1 := DllCall("CreateCompatibleDC", "Uint", hDC)
        mDC2 := DllCall("CreateCompatibleDC", "Uint", hDC)
        zhBM := DllCall("CreateCompatibleBitmap", "Uint", hDC, "int", znW, "int", znH)
        oBM1 := DllCall("SelectObject", "Uint", mDC1, "Uint", hBM)
        oBM2 := DllCall("SelectObject", "Uint", mDC2, "Uint", zhBM)
        DllCall("SetStretchBltMode", "Uint", mDC2, "int", 4)
        DllCall("StretchBlt", "Uint", mDC2, "int", 0, "int", 0, "int", znW, "int", znH, "Uint", mDC1, "int", 0, "int", 0, "int", nW, "int", nH, "Uint", 0x00CC0020)
        DllCall("SelectObject", "Uint", mDC1, "Uint", oBM1)
        DllCall("SelectObject", "Uint", mDC2, "Uint", oBM2)
        DllCall("DeleteDC", "Uint", mDC1)
        DllCall("DeleteDC", "Uint", mDC2)
        DllCall("DeleteObject", "Uint", hBM)
        Return zhBM
    }

    _clipBitmap(hDC, hBM, nL, nT, nW, nH)
    {
        WriteDebug("clipping bitmap", "", "debug", this.moduleName)
        mDC1 := DllCall("CreateCompatibleDC", "Uint", hDC)
        mDC2 := DllCall("CreateCompatibleDC", "Uint", hDC)
        zhBM := DllCall("CreateCompatibleBitmap", "Uint", hDC, "int", nW, "int", nH)
        oBM1 := DllCall("SelectObject", "Uint", mDC1, "Uint", hBM)
        oBM2 := DllCall("SelectObject", "Uint", mDC2, "Uint", zhBM)
        DllCall("BitBlt", "Uint", mDC2, "int", 0, "int", 0, "int", nW, "int", nH, "Uint", mDC1, "int", nL, "int", nT, "Uint", 0x40000000 | 0x00CC0020)
        DllCall("SelectObject", "Uint", mDC1, "Uint", oBM1)
        DllCall("SelectObject", "Uint", mDC2, "Uint", oBM2)
        DllCall("DeleteDC", "Uint", mDC1)
        DllCall("DeleteDC", "Uint", mDC2)
        DllCall("DeleteObject", "Uint", hBM)
        Return zhBM
    }

    _captureCursor(hDC, nL, nT)
    {
        WriteDebug("adding cursor to bitmap", "", "debug", this.moduleName)

        NumPut(VarSetCapacity(CURSORINFO, A_PtrSize + 16, 0), CURSORINFO, "Uint")
        DllCall("GetCursorInfo", "ptr", &CURSORINFO)
        VarSetCapacity(ICONINFO, A_PtrSize * 2 + 12)
        DllCall("GetIconInfo", "ptr", hCursor := NumGet(CURSORINFO, 8), "ptr", &ICONINFO)
        if ((hbmColor := NumGet(ICONINFO, A_PtrSize * 2 + 8, "ptr")))
            DllCall("DeleteObject", "ptr", hbmColor)
        bShow := NumGet(CURSORINFO, 4, "UInt")
        x := NumGet(CURSORINFO, 8 + A_PtrSize, "Int") - NumGet(ICONINFO, A_PtrSize, "Uint")
        y := NumGet(CURSORINFO, 12 + A_PtrSize, "Int") - NumGet(ICONINFO, A_PtrSize + 4, "Uint")

        If (bShow)
            DllCall("DrawIcon", "Uint", hDC, "Int", x - nL, "Int", y - nT, "Uint", hCursor)
        If hBMMask
            DllCall("DeleteObject", "Uint", hBMMask)
        If hBMColor
            DllCall("DeleteObject", "Uint", hBMColor)
    }

    _refreshWindows()
    {
        DetectHiddenWindows, Off
        WinGet, windowList, List
        WriteDebug("Refreshing Windows", windowList, "debug", this.moduleName)

        Loop, %windowList%
        {
            DllCall("RedrawWindow","uint",windowList%A_Index%,"uint",0,"uint",0,"uint",0x787)
            WinSet, Redraw,, % "ahk_id " windowList%A_Index%
        }
    }

    _enableFontSmoothing()
    {
        If ((this.disableFontSmoothing) AND (this._originalFontSmoothing)) {
            WriteDebug("Enabling FontSmoothing", "", "debug", this.moduleName)
            DllCall("SystemParametersInfo", UInt, 75, UInt, this._originalFontSmoothing, Char, 0, UInt,1 ) ; SPI_SETFONTSMOOTHING = 75
        }
        If ((this.disableClearType) AND (this._originalFontSmoothingType)) {
            WriteDebug("Enabling ClearType", "", "debug", this.moduleName)
            DllCall("SystemParametersInfo", UInt, 0x200B, UInt, 0, Char, this._originalFontSmoothingType, UInt,1 ) ; SPI_SETFONTSMOOTHINGTYPE = 0x200B
        }
    }

    _disableFontSmoothing()
    {
        If (this.disableFontSmoothing) {
            WriteDebug("Disabling FontSmoothing", "", "debug", this.moduleName)
            ; save the current fontsmoothing
            VarSetCapacity(scr_Result, 1)
            DllCall("SystemParametersInfo", UInt, 74, UInt, 0, Char, &scr_Result, UInt,1 ) ; SPI_GETFONTSMOOTHING = 74
            this._originalFontSmoothing := NumGet(scr_Result)
            WriteDebug("FontSmoothing: " this._originalFontSmoothing, "", "debug", this.moduleName)
            ; disable font smoothing
            DllCall("SystemParametersInfo", UInt, 75, UInt, 0, Char, 0, UInt,1 ) ; SPI_SETFONTSMOOTHING = 75
        }
        If (this.disableClearType) {
            WriteDebug("Disabling ClearType", "", "debug", this.moduleName)
            ; save the current ClearType
            VarSetCapacity(scr_Result, 1)
            DllCall("SystemParametersInfo", UInt, 0x200A, UInt, 0, Char, &scr_Result, UInt,1 ) ; SPI_GETFONTSMOOTHINGTYPE = 0x200A
            this._originalFontSmoothingType := NumGet(scr_Result)
            WriteDebug("ClearType: " this._originalFontSmoothingType, "", "debug", this.moduleName)
            ; disable ClearType
            DllCall("SystemParametersInfo", UInt, 0x200B, UInt, 0, Char, 1, UInt,1 ) ; SPI_SETFONTSMOOTHINGTYPE = 0x200B
        }
    }

    fileNameType[]
    {
        get {
            global ScreenShotTool_FileNameType

            If (inArray(this._fileNameType, ["Auto Generated","Follows a Pattern","Prompted"]))
                fileNameType := this._fileNameType

            If (!inArray(ScreenShotTool_FileNameType, ["Auto Generated","Follows a Pattern","Prompted"]))
            {
                fileNameType := this.manifest.findUIElementByKey("name", "ScreenShotTool_FileNameType")
                fileNameType := fileNameType.items[1]
            }
            else
                fileNameType := ScreenShotTool_FileNameType
            return fileNameType

        }
        set {
            If (!inArray(value, ["Auto Generated","Follows a Pattern","Prompted"]))
            {
                fileNameType := this.manifest.findUIElementByKey("name", "ScreenShotTool_FileNameType")
                return this._fileNameType := fileNameType.items[1]
            }
            else
                return this._fileNameType := value
        }
    }

    fileNamePattern[]
    {
        get {
            global ScreenShotTool_FileNamePattern

            if (this._fileNamePattern)
                return this._fileNamePattern

            If (!ScreenShotTool_FileNamePattern)
                return this.manifest.findUIElementByKey("name", "ScreenShotTool_FileNamePattern")
            else
                return ScreenShotTool_FileNamePattern

        }
        set {
            return this._fileNamePattern := value
        }
    }

    timePattern[]
    {
        get {
            global ScreenShotTool_FileNamePattern_Time

            if (this._timePattern)
                return this._timePattern

            If (!ScreenShotTool_FileNamePattern_Time)
                return this.manifest.findUIElementByKey("name", "ScreenShotTool_FileNamePattern_Time")
            else
                return ScreenShotTool_FileNamePattern_Time

        }
        set {
            return this._timePattern := value
        }
    }

    fileFormat[]
    {
        get {
            global ScreenShotTool_FileFormat

            If (inArray(this._fileFormat, ["png", "jpg", "gif", "tif", "bmp"]))
                return this._fileFormat

            If (inArray(ScreenShotTool_FileFormat, ["png", "jpg", "gif", "tif", "bmp"]))
            {
                fileFormat := ScreenShotTool_FileFormat
            }
            else
            {
                fileFormat := this.manifest.findUIElementByKey("name", "ScreenShotTool_FileFormat")
                fileFormat := fileFormat.items[1]
            }
            return fileFormat
        }
        set {
            If (!inArray(this._fileFormat, ["png", "jpg", "gif", "tif", "bmp"]))
            {
                fileFormat := this.manifest.findUIElementByKey("name", "ScreenShotTool_FileFormat")
                return this._fileFormat := fileFormat.items[1]
            }
            else
                return this._fileFormat := value
        }
    }

    /**
     * Property for the output file name
     *
     * @type string
     */
    fileName[]
    {
        get {
            illigalChars = (\||\/|\\|\?|`%|\*|:|"|<|>|`n|`r|`t)

            ; if fileName[] was already set in instance, use that value
            if (this._fileName) {
                WriteDebug("Filename was set to:", this._fileName, "debug", this.moduleName)
                fileName := this._fileName
            }

            ; decide what method to use for naming the file
            if (this.fileNameType == "Auto Generated") {
                WriteDebug("Filename is autogenerated", "", "debug", this.moduleName)
                fileName := "ScreenShot_" A_Now "." this.fileFormat
            }
            else if (this.fileNameType == "Follows a Pattern") {
                WriteDebug("Filename is generated from pattern", "", "debug", this.moduleName)
                fileName := this.fileNamePattern "." this.fileFormat
                if (InStr(fileName, "\n")) {
                    counter := StringRight(repeat("0", 9), 9 - StrLen(this.counter)) "" this.counter
                    fileName := StringReplace(fileName, "\n", counter, "A")
                }
                if (InStr(fileName, "\d")) {
                    fileName := StringReplace(fileName, "\d", FormatTime("", this.timePattern), "A")
                }
                if (InStr(fileName, "\t")) {
                    if (this.screenShotMode == "Window")
                        screenShotMode := this.screenShotMode "_" WinGetActiveTitle()
                    else
                        screenShotMode := this.screenShotMode

                    fileName := StringReplace(fileName, "\t", screenShotMode, "A")
                }
            } else {
                global ScreenShotTools_PromptObject

                WriteDebug("Filename is prompted to user", "debug", this.moduleName)

                ScreenShotTools_PromptObject := new CPrompt()
                ScreenShotTools_PromptObject.Text := "Enter a filename for the screenshot (without extension)"
                ScreenShotTools_PromptObject.Title := "Enter filename"
                ScreenShotTools_PromptObject.Placeholder := "NewName"
                ScreenShotTools_PromptObject.Cancel := true
                fileName := ScreenShotTools_PromptObject.prompt()

                fileName := fileName "." this.fileFormat
            }

            ; remove invalid chars
            fileName := RegExReplace(fileName, illigalChars,"_")
            ; did fileName end up empty?
            if (!fileName) {
                WriteDebug("Filename is autogenerated", "", "debug", this.moduleName)
                fileName := "ScreenShot_" A_Now "." this.fileFormat
            }

            ; does file already exist?
            ; TODO

            return fileName
        }
        set {
            return this._fileName := value
        }
    }

    /**
     * Property for wheter the user should receive a visual feedback from the screenshot, aka a flash
     *
     * @type boolean
     */
    visualFeedback[]
    {
        get {
            global ScreenShotTool_VisualFeedback
            if (this._visualFeedback)
                return this._visualFeedback
            else
                return (ScreenShotTool_VisualFeedback == true) ? true : false
        }
        set {
            return this._visualFeedback := (value == true) ? true : false
        }
    }

    /**
     * Property for wheter the user should receive an acustic feedback from the screenshot, aka a shutter sound
     *
     * @type boolean
     */
    audioFeedback[]
    {
        get {
            global ScreenShotTool_AcusticFeedback
            if (this._audioFeedback)
                return this._audioFeedback
            else
                return (ScreenShotTool_AcusticFeedback == true) ? true : false
        }
        set {
            return this._audioFeedback := (value == true) ? true : false
        }
    }

    /**
     * Property for wheter the image should be stored in the clipboard
     *
     * @type boolean
     */
    saveToClipboard[]
    {
        get {
            global ScreenShotTool_SaveToClipboard
            if (this._saveToClipboard)
                return this._saveToClipboard
            else
                return (ScreenShotTool_SaveToClipboard == true) ? true : false
        }
        set {
            return this._saveToClipboard := (value == true) ? true : false
        }
    }

    saveToFile[]
    {
        get {
            global ScreenShotTool_SaveToFile
            if (this._saveToFile)
                return this._saveToFile
            else
                return (ScreenShotTool_SaveToFile == true) ? true : false
        }
        set {
            return this._saveToFile := (value == true) ? true : false
        }
    }

    disableFontSmoothing[]
    {
        get {
            global ScreenShotTool_DisableFontSmoothing
            if (this._disableFontSmoothing)
                return this._disableFontSmoothing
            else
                return (ScreenShotTool_DisableFontSmoothing == true) ? true : false
        }
        set {
            return this._disableFontSmoothing := (value == true) ? true : false
        }
    }

    disableClearType[]
    {
        get {
            global ScreenShotTool_DisableClearType
            if (this._disableClearType)
                return this._disableClearType
            else
                return (ScreenShotTool_DisableClearType == true) ? true : false
        }
        set {
            return this._disableClearType := (value == true) ? true : false
        }
    }

    quality[]
    {
        get {
           global ScreenShotTool_Quality

           if (this._quality)
               return this._quality
           else if (IsNumeric(ScreenShotTool_Quality))
               return ScreenShotTool_Quality
           else
               return this.manifest.findUIElementByKey("name", "ScreenShotTool_Quality")
       }
       set {
           if (IsNumeric(value))
               return this._quality := value
           else
               return this._quality := this.manifest.findUIElementByKey("name", "ScreenShotTool_Quality")
       }
    }

    /**
     * Property for the folder on the filesystem where the screenshot should be stored
     *
     * @type string
     */
    targetPath[]
    {
        get {
            global ScreenShotTool_TargetPath

            if (this._targetPath)
                targetPath := this.targetPath
            else if (ScreenShotTool_TargetPath)
                targetPath := ScreenShotTool_TargetPath
            else
                targetPath := this.manifest.findUIElementByKey("name", "ScreenShotTool_TargetPath")

            targetPath := ExpandPathPlaceholders(targetPath)

            FileCreateDir % targetPath
            if (FileExist(targetPath))
                return targetPath
            else
                return -1
        }
        set {
            return this._targetPath := value
        }
    }

    /**
     * Property for wheter the image should be opened in the ImageConverter
     * ImageConverter must be available in runtime
     *
     * @type boolean
     */
    openInManager[]
    {
        get {
            global ScreenShotTool_openInManager
            If (!(CImageConverterAction)) {
                WriteDebug("Screenshot: Setting was overwirtten:", "ImageConverter is not available", "debug", "ScreenShotTool")
                return false
            }

            if (this._openInManager)
                return this._openInManager
            else
                return (ScreenShotTool_openInManager == true) ? true : false
        }
        set {
            If (!(CImageConverterAction))
                return false
            return ScreenShotTool_openInManager := this._openInManager := (value == true) ? true : false
        }
    }

    catchContextMenu[]
    {
        get {
            global ScreenShotTool_CatchContextMenu
            if (this._catchContextMenu)
                return this._catchContextMenu
            else
                return (ScreenShotTool_CatchContextMenu == true) ? true : false
        }
        set {
            return this._catchContextMenu := (value == true) ? true : false
        }
    }

    /**
     * Property for how the screenshot should be scaled.
     * examples:
     *     1.00:    No  change
     *     0.5:     Image will be half the real size
     *     2.0:     Image will be double the real size
     *
     * @type integer
     */
    scale[]
    {
        get {
            global ScreenShotTool_Scaling

            if (this._scale)
                return this._scale
            else if (IsNumeric(ScreenShotTool_Scaling))
                return ScreenShotTool_Scaling / 100
            else
                return this.manifest.findUIElementByKey("name", "ScreenShotTool_Scaling")
        }
        set {
            if (IsNumeric(value))
                return this._scale := value
            else
                return this._scale := this.manifest.findUIElementByKey("name", "ScreenShotTool_Scaling")
        }
    }

    /**
     * Property for how long to wait before captureing the screen in seconds
     *
     * @type integer
     */
    delay[]
    {
        get {
            global ScreenShotTool_Timer

            if (this._delay)
                return this._delay
            else if (IsNumeric(ScreenShotTool_Timer))
                return ScreenShotTool_Timer
            else
                return 0
        }
        set {
            if (IsNumeric(value))
                return this._delay := value
            else
                return 0
        }
    }

    /**
     * Property for the coordinates of the last area the user has marked
     *
     * @type string (coords as string)
     */
    lastArea[]
    {
        get {
            global ScreenShotTool_lastArea
            if (this._lastArea)
                return this._lastArea
            else
                return ScreenShotTool_lastArea
        }
        set {
            return this._lastArea := value
        }
    }

    /**
     * Property for the path to the shutter sound effect
     *
     * @type string
     */
    soundFile[]
    {
        get {
            ; TODO: must be done better
            file := A_ScriptDir "\..\modules\ol.modules\ScreenShotTool\resources\cameraShutter.wav"
            if (FileExist(file))
                return file
            else
                return false
        }
    }

    captureCursor[]
    {
        get {
            global ScreenShotTool_CaptureCursor
            if (this._captureCursor)
                return this._captureCursor
            else
                return (ScreenShotTool_CaptureCursor == true) ? true : false
        }
        set {
            return this._captureCursor := (value == true) ? true : false
        }
    }

    noOverlappingWindows[]
    {
        get {
            global ScreenShotTool_NoOverlappingWindows
            if (this._noOverlappingWindows)
                return this._noOverlappingWindows
            else
                return (ScreenShotTool_NoOverlappingWindows == true) ? true : false
        }
        set {
            return this._noOverlappingWindows := (value == true) ? true : false
        }
    }

    class cCursor
    {
        static pAppstarting := 32650
        static pHand := 32649
        static pArrow := 32512
        static pCross := 32515
        static pIbeam := 32513
        static pIcon := 32641
        static pNo := 32648
        static pSize := 32640
        static pSizeall := 32646
        static pSizenesw := 32643
        static pSizens := 32645
        static pSizenwse := 32642
        static pSizewe := 32644
        static pUparrow := 32516
        static pWait := 32514
        static pHelp := 32651

        cross[]
        {
            get {
                if (FileExist(A_LineFile "\..\resoureces\cross.cur"))
                    hCursor := DllCall("LoadCursorFromFile", Str, A_LineFile "\..\resoureces\cross.cur")
                else if (FileExist(A_WinDir "\cursors\cross_rl.cur"))
                    hCursor := DllCall("LoadCursorFromFile", Str, A_WinDir "\cursors\cross_rl.cur")
                else
                    hCursor := DllCall("LoadCursor","UInt",NULL, "Int", this.pCross)

                cursor := DllCall("CopyImage", "UInt", hCursor, "uint",2, "int",0, "int",0, "uint",0)
                DllCall("DestroyCursor","Uint",hCursor)

                return cursor
            }
        }

        arrow[]
        {
            get {
                hCursor := DllCall("LoadCursor","UInt",NULL, "Int", this.pArrow)
                cursor := DllCall("CopyImage", "UInt", hCursor, "uint",2, "int",0, "int",0, "uint",0)
                DllCall("DestroyCursor","Uint",hCursor)

                return cursor
            }
        }

        sizeAll[]
        {
            get {
                hCursor := DllCall("LoadCursor","UInt",NULL, "Int", this.pSizeAll)
                cursor := DllCall("CopyImage", "UInt", hCursor, "uint",2, "int",0, "int",0, "uint",0)
                DllCall("DestroyCursor","Uint",hCursor)

                return cursor
            }
        }

        hand[]
        {
            get {
                hCursor := DllCall("LoadCursor","UInt",NULL, "Int", this.pHand)
                cursor := DllCall("CopyImage", "UInt", hCursor, "uint",2, "int",0, "int",0, "uint",0)
                DllCall("DestroyCursor","Uint",hCursor)

                return cursor
            }
        }
    }

    /**
     * Private Method
     * Wrapper for conditional flashing
     *
     * TODO: make flash only affect area that was captured
     */
    Flash(nL, nT, nW, nH)
    {
        if (!(nL AND nT AND nW AND nH))
        {
            SysGet, nL, 76  ; virtual screen left & top
            SysGet, nT, 77
            SysGet, nW, 78  ; virtual screen width and height
            SysGet, nH, 79
        }

        if (this.visualFeedback)
        {
            WriteDebug("Flashing area:", "x: " nL ", y: " nT ", w: " nW ", h: " nH, "debug", this.moduleName)
            this._flashArea(nL,nT,nW,nH)
        }
    }

    /**
     * Private Method
     * Wrapper for conditional shutter
     */
    Shutter()
    {
        if (this.audioFeedback)
            IfExist % this.soundFile
            {
                WriteDebug("Shutter sound", "", "debug", this.moduleName)
                SoundPlay, % this.soundFile
            }
    }

    /**
     * Private Method
     * Flashes the screen in the specified coordinates
     *
     * Thanks to Michael (activ'Aid Screenshot)
     */
    _flashArea(nL, nT, nW, nH)
    {
        GuiNum:=GetFreeGUINum(1, "Flash")
        this._tmpFlashGui := GuiNum
        Gui,%GuiNum%:Destroy
        Gui,%GuiNum%:+LabelFlash +AlwaysOnTop -Caption -Border +ToolWindow -Resize +Disabled
        Gui,%GuiNum%:+LastFound
        Gui,%GuiNum%:Color, FFFFFF
        ; If scr_DisableTransparency2 = 0
            ; WinSet,Transparent,196
        Gui,%GuiNum%:Show, X%nL% Y%nT% W%nW% H%nH% NA

        if (!this.timerCloseHighlight)
            this.timerCloseHighlight := ObjBindMethod(this, "_flashAreaOff")
        timer := this.timerCloseHighlight
        SetTimer % timer, 120
    }

    _flashAreaOff()
    {
        timer := this.timerCloseHighlight
        SetTimer % timer, Off

        Gui, % this._tmpFlashGui ": Destroy"
        this.Remove("tmpGuiNum")
    }
}
