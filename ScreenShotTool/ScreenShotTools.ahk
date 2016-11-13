; ScreenShotTool - ScreenShotTools.ahk
; author: Oliver Lipkau
; created: 2016 11 13

/**
 * TODO:
 *   * PATH behavior?
 *   * 7plus Image COnverter
 *       - own plugin
 *       - context menu
 */

/**
 * Class to manage the ScreenShot behavior
 */
class ScreenShot
{
    static Quality := 95
    ; static defaultTargetPath := A_AppData "\a2\ol.modules\ScreenShotTool"

    captureScreen()
    {
        pBitmap := Gdip_BitmapFromScreen()
        this.store(pBitmap)
    }

    captureWindow()
    {
        pBitmap := Gdip_BitmapFromHWND(WinExist("A"))
        this.store(pBitmap)
    }

    captureArea()
    {
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
            return -1
        }
        else if(this.tmpState = 1) ;Wait for mouse down
        {
            if(GetKeyState("LButton", "p"))
            {
                this.tmpState := 2
                MouseGetPos, MX, MY
                this.tmpMX := MX
                this.tmpMY := MY
            }
            return -1
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
            if(GetKeyState("LButton", "p")) ;Resize selection rectangle
               return -1
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
                pBitmap := Gdip_BitmapFromScreen(this.tmpMX "|" this.tmpMY "|" w "|" h)
                this.Remove("tmpMX")
                this.Remove("tmpMY")
                this.Remove("tmpGuiNum")
                this.Remove("tmpGuiNum0")
                this.Remove("tmpGuiNum1")
                this.Remove("tmpState")
            }
        }
        this.store(pBitmap)
    }

    store(pBitmap)
    {
        Gdip_SaveBitmapToFile(pBitmap, this.targetPath "\" this.fileName, this.Quality)
        Gdip_DisposeImage(pBitmap)
    }

    fileName[]
    {
        get {
            global ScreenShotTool_AutoNaming
            if (ScreenShotTool_AutoNaming)
            {
                return "ScreenShot_" A_Now ".png"
            } else {
                ; TODO
                ;    ask for name
            }
        }
    }

    targetPath[]
    {
        get {
            global ScreenShotTool_TargetPath
            ; TODO
            ; if (ScreenShotTool_TargetPath)
            ; {
                return ScreenShotTool_TargetPath
            ; } else {
                ; return this.defaultTargetPath
            ; }
        }
    }

    openInManager[]
    {
        get {
            global ScreenShotTool_openInManager
            return ScreenShotTool_openInManager
        }
    }
}

