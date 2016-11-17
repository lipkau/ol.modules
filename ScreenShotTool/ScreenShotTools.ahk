; ScreenShotTool - ScreenShotTools.ahk
; author: Oliver Lipkau
; created: 2016 11 13

#include lib\ahklib\CPrompt.ahk
#include lib\ahklib\CNotification.ahk

/**
 * TODO:
 *   * mouse cursor?
 *   * default file format in UI?
 *   * [bug] Fix area selection (size grows incorrectly)
 *   * [bug] Fix full screen shot
 */

 /**
  * Fake Debug function while a2 doesn't offer a global one
  */
  WriteDebug(Title, InputObject = "", Delimiter = "`n", prefiex = "[a2] ")
 {
     if (Settings.Debug.Enabled)
     {
         OutputDebug % prefix Title
         if (InputObject)
         {
             Loop, Parse, InputObject, %Delimiter%
                 WriteDebug("    " A_LoopField)
         }
     }
}

/**
 * Class to manage the ScreenShot behavior
 */
class ScreenShotTool
{
    static _pTkoen := ""
    static defaultQuality := 95
    static defaultScale := 1.00
    static FileExtension := "png" ; TODO
    static defaultTargetPath := A_AppData "\a2\ol.modules\ScreenShotTool"

    /**
     * Perform some initial setup when the module is loaded
     */
    Init()
    {
        FileCreateDir % this.defaultTargetPath
        this._pToken := Gdip_Startup()
    }

    /**
     * Entry point for htokeys
     *     Take a screenshot depending on the hotkey
     *     Store the screenshot
     *     Open in ImageConverter
     */
    TakeScreenShot(option = "")
    {
        option := option ? option : "All"

        WriteDebug("Triggered Screenshot with option:", option)
        WriteDebug("UI Settings for Screenshot:", "Flash: "this.visualFeedback "|ShutteShound: " this.audioFeedback "|SaveToClip: " this.saveToClipboard "|TargetPath: " targetPath "|OpenInManager: " this.openInManager "|Scale: " this.scale "|Delay: " this.delay "|LastArea: " this.lastArea "|SoundFile: " this.soundFile, "|")
        filePath := this.Capture(option)
        if (!(filePath))
            return

        Notify("Screenshot captured", "Screenshot was captured and stored.", 2, NotifyIcons.Success)

        if (this.openInManager)
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
     * ScreenShot := new ScreenShotTool()
     * ScreenShot.delay := 3                  ; Wait for 3 seconds before capturing the screen
     * TODO
     *
     * @param  string   type    Allowed values:
     *                              "All":      Screenshot of the entire desktop (multiple monitors, if so)
     *                              "Window":   Screenshot of the currently active window
     *                              "Area":     Screenshot of the area the customer marked
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
            ; Critical, Off
            ; SetBatchLines, -1
            MaxProgress := this.delay * 100
            if (MaxProcess == 100)
                MaxProcess := 60
            Progress, 5:H50 R0-%MaxProgress% B2 P%MaxProgress%,,%lng_scr_DelayProgress%
            SetBatchLines, 2
            Loop % MaxProgress
                Progress % "5:" MaxProgress-A_Index
            Progress, 5:Off
            ; SetBatchLines,-1
            Sleep, 50
        }

        if (type == "All")
        {
            ; Capture FullScreen
            this._flash()
            this._shutter()
            pBitmap := Gdip_BitmapFromScreen()
        } else if (type == "Window")
        {
            ; Capture the active window
            pBitmap := Gdip_BitmapFromHWND(WinExist("A"))
            this._flash()
            this._shutter()
        } else if (type == "Area")
        {
            ; Capture the Area choosen by the user
            coords := coords ? coords : this._markArea()
            pBitmap := Gdip_BitmapFromScreen(coords)
            this._flash()
            this._shutter()
        } else if (type == "LastArea")
        {
            ; Capture the last Area choosen by the user
            if (!(this.lastArea))
            {
                Notify("Error", "No previous area could be found.`nPlease capture a Screenshot by defining an area before using this again", 3, NotifyIcons.Error)
                return false
            }
            pBitmap := Gdip_BitmapFromScreen(this.lastArea)
            this._flash()
            this._shutter()
        } else if (type == "Monitor")
        {
            ; Capture the Monitor on which the ActiveWindow is located on
            monitorId := GetMonitorIndexFromWindow(WinExist("A"))
            monitorId := monitorId ? monitorId : 0
            pBitmap := Gdip_BitmapFromScreen(monitorId)
            this._flash()
            this._shutter()
        } else
        {
            Notify("Error", "Invalid Screenshot Area", 4, NotifyIcons.Error)
            return false
        }

        ; Scale Image
        nW := Gdip_GetImageWidth(pBitmap)
        nH := Gdip_GetImageHeight(pBitmap)
        nSW := Round(nW * this.scale)
        nSH := Round(nH * this.scale)
        nScaledBitmap := Gdip_CreateBitmap(nSW, nSH)
        canvas := Gdip_GraphicsFromImage(nScaledBitmap)
        Gdip_SetSmoothingMode(canvas, 4)
        Gdip_SetInterpolationMode(canvas, 7)
        Gdip_DrawImage(canvas, pBitmap, 0, 0, nSW, nSH) ;, 0, 0, nW, nH)

        Gdip_DisposeImage(pBitmap)
        Gdip_DeleteGraphics(canvas)

        if (!(this.targetPath))
        {
            Notify("Error", "The path to where the Screenshots should be saved either doesn't exist or can't be accessed.", 3, NotifyIcons.Error)
            return
        }

        storedFile := ExpandPathPlaceholders(this.targetPath "\" this.fileName)
        Gdip_SaveBitmapToFile(nScaledBitmap, storedFile, this.quality)
        Gdip_DisposeImage(nScaledBitmap)

        ; Save to Clipboard
        if (this.saveToClipboard)
        {
            pBitmap := Gdip_CreateBitmapFromFile(storedFile)
            if (pBitmap)
            {
                hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
                WinClip.Clear()
                WinClip.SetBitmap(hbitmap)
                DeleteObject(hBitmap)
            }
            Gdip_DisposeImage(pBitmap)
        }

        return storedFile
    }

    /**
     * Property for the output file name
     *
     * @type string
     */
    fileName[]
    {
        get {
            global ScreenShotTool_AutoNaming

            If (!(CPrompt)) {
                WriteDebug("Screenshot: CPrompt is not available")
                ScreenShotTool_AutoNaming := true
            }

            if (this._fileName) {
                WriteDebug("Screenshot: filename was set to: " this._fileName)
                return this._fileName
            }
            else if (ScreenShotTool_AutoNaming == true) {
                WriteDebug("Screenshot: Filename is autogenerated")
                return "ScreenShot_" A_Now ".png"
            }
            else {
                WriteDebug("Screenshot: about to prompt user for Filename")
                global ScreenShotTools_PromptObject
                ScreenShotTools_PromptObject := new CPrompt()
                ScreenShotTools_PromptObject.Text := "Enter a filename for the screenshot (without extension)"
                ScreenShotTools_PromptObject.Title := "Enter filename"
                ScreenShotTools_PromptObject.Placeholder := "NewName"
                ScreenShotTools_PromptObject.Cancel := true
                return ScreenShotTools_PromptObject.prompt() ".png"
            }
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
            return (value == true) ? true : false
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
            global ScreenShotTool_StoreInClipboard
            if (this._saveToClip)
                return this._saveToClip
            else
                return (ScreenShotTool_StoreInClipboard == true) ? true : false
        }
        set {
            return this._saveToClip := (value == true) ? true : false
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
                return this._targetPath
            else if (ScreenShotTool_TargetPath)
                return ScreenShotTool_TargetPath
            else
                return this.defaultTargetPath
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
                WriteDebug("Screenshot: Setting was overwirtten:", "ImageConverter is not available")
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
                return this.defaultScale
        }
        set {
            if (IsNumeric(value))
                return this._delay := value
            else
                return this._scale := this.defaultScale
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

    /**
     * Private Method
     * Record the start and end coordinates the user marks, while showing a transperancy for visualization of the area
     */
    _markArea()
    {
        Loop
        {
            if (GetKeyState("Escape", "p") == "D")
            {
                Gui, % this.tmpGuiNum0 ": Destroy"
                Gui, % this.tmpGuiNum ": Destroy"
                this.Remove("tmpMX")
                this.Remove("tmpMY")
                this.Remove("tmpGuiNum")
                this.Remove("tmpGuiNum0")
                this.Remove("tmpGuiNum1")
                this.Remove("tmpState")
                return false
            }
            if(!this.tmpState)
            {
                this.tmpState := 1
                ;Credits of code below go to sumon/Learning one
                CoordMode, Mouse ,Screen
                this.tmpGuiNum0 := GetFreeGUINum(10)
                Gui % this.tmpGuiNum0 ": Default"
                Gui, +AlwaysOnTop -caption -Border +ToolWindow +LastFound
                Gui, Color, White
                Gui, Font, s50 c0x5090FF, Verdana
                Gui, Add, Text, % "x0 y" (A_ScreenHeight/10) " w" A_ScreenWidth " Center", Drag a rectangle around the area you want to capture!
                WinSet, TransColor, White
                this.tmpGuiNum := GetFreeGUINum(10)
                Gui % this.tmpGuiNum ": Default"
                SysGet, VirtualX, 76
                SysGet, VirtualY, 77
                SysGet, VirtualW, 78
                SysGet, VirtualH, 79
                Gui, +AlwaysOnTop -caption +Border +ToolWindow +LastFound
                WinSet, Transparent, 1
                Gui % this.tmpGuiNum0 ":Show", X%VirtualX% Y%VirtualY% W%VirtualW% H%VirtualH%
                Gui, Show, X%VirtualX% Y%VirtualY% W%VirtualW% H%VirtualH%
                this.tmpGuiNum1 := GetFreeGUINum(10)
                Gui % this.tmpGuiNum1 ": Default"
                Gui, +AlwaysOnTop -caption +Border +ToolWindow +LastFound
                WinSet, Transparent, 120
                Gui, Color, 0x5090FF
                continue
            }
            else if(this.tmpState = 1) ;Wait for mouse down
            {
                if (GetKeyState("LButton", "p") == "D")
                {
                    this.tmpState := 2
                    MouseGetPos, MX, MY
                    this.tmpMX := MX
                    this.tmpMY := MY
                }
                continue
            }
            else if(this.tmpState = 2) ;Dragging
            {
                MouseGetPos, MXend, MYend
                w := abs(this.tmpMX - MXend)
                h := abs(this.tmpMY - MYend)
                If ( this.tmpMX < MXend )
                    X := this.tmpMX
                Else
                    X := MXend
                If ( this.tmpMY < MYend )
                    Y := this.tmpMY
                Else
                    Y := MYend
                Gui, % this.tmpGuiNum1 ": Show", x%X% y%Y% w%w% h%h%
                if(GetKeyState("LButton", "p") == "D") ;Resize selection rectangle
                   continue
                else ;Mouse release
                {
                    Gui, % this.tmpGuiNum1 ": Destroy"
                    If ( this.tmpMX > MXend )
                    {
                       temp := this.tmpMX
                       this.tmpMX := MXend
                       MXend := temp
                    }
                    If ( this.tmpMY > MYend )
                    {
                       temp := this.tmpMY
                       this.tmpMY := MYend
                       MYend := temp
                    }
                    Gui, % this.tmpGuiNum0 ": Destroy"
                    Gui, % this.tmpGuiNum ": Destroy"
                    this.lastArea := this.tmpMX "|" this.tmpMY "|" w "|" h
                    this.Remove("tmpMX")
                    this.Remove("tmpMY")
                    this.Remove("tmpGuiNum")
                    this.Remove("tmpGuiNum0")
                    this.Remove("tmpGuiNum1")
                    this.Remove("tmpState")
                    WriteDebug("ScreenShot: user selected area: " this.lastArea)
                    return this.lastArea
                }
            }
        }
    }

    /**
     * Private Method
     * Wrapper for conditional flashing
     *
     * TODO: make flash only affect area that was captured
     */
    _flash()
    {
        SysGet, nL, 76  ; virtual screen left & top
        SysGet, nT, 77
        SysGet, nW, 78  ; virtual screen width and height
        SysGet, nH, 79

        if (this.visualFeedback)
        {
            this._flashArea(nL,nT,nW,nH)
        }
    }

    /**
     * Private Method
     * Wrapper for conditional shutter
     */
    _shutter()
    {
        if (this.audioFeedback)
            IfExist % this.soundFile
                SoundPlay, % this.soundFile
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
        this.tmpFlashGui := GuiNum
        Gui,%GuiNum%:Destroy
        Gui,%GuiNum%:+LabelFlash +AlwaysOnTop -Caption -Border +ToolWindow -Resize +Disabled
        Gui,%GuiNum%:+LastFound
        Gui,%GuiNum%:Color, FFFFFF
        ; If scr_DisableTransparency2 = 0
            ; WinSet,Transparent,196
        Gui,%GuiNum%:Show, X%nL% Y%nT% W%nW% H%nH% NA

        SetTimer, ScreenShotTool_CloseHighlight, 100
    }
    _flashAreaOff()
    {
        Gui, % this.tmpFlashGui ": Destroy"
        this.Remove("tmpGuiNum")
    }
}

ScreenShotTool_CloseHighlight:
    SetTimer, ScreenShotTool_CloseHighlight, Off
    ScreenShotTool._flashAreaOff()
return
