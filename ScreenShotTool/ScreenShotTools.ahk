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
class ScreenShotTool
{
    static Quality := 95
    static TargetPath := ""
    static defaultTargetPath := A_AppData "\a2\ol.modules\ScreenShotTool"

    /**
     * Hotkey entry point:
     *     Take the screenshot
     */
    TakeScreenShot(option = "")
    {
        msgbox % FindMonitorFromMouseCursor()
        if (option == "Window")
            pBitmap := this.captureWindow()
        else if (option == "Area")
            pBitmap := this.captureArea()
        else
            pBitmap := this.captureScreen()

        this.store(pBitmap)

        if (this.openInManager)
        {
            ; TODO
        }
    }

    /**
     * Capture the full screen and store it
     */
    captureScreen()
    {
        return Gdip_BitmapFromScreen()
    }

    /**
     * Capture the active Window and store it
     */
    captureWindow()
    {
        return Gdip_BitmapFromHWND(WinExist("A"))
    }

    /**
     * Capture the area selected by the user and store it
     */
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
        return pBitmap
    }

    /**
     * Method to store a Bitmap to the file system
     */
    store(pBitmap)
    {
        pathName := this.validatePath(this.targetStorePath)
        if (!(pathName))
        {
            ;message error to user
            msgbox % "fail!"
            return
        }

        fileName := this.fileName
        if (fileName == "-1.png")
        {
            ;message error to user
            msgbox % "fail!"
            return
        }
        Gdip_SaveBitmapToFile(pBitmap, pathName "\" fileName, this.Quality)
        Gdip_DisposeImage(pBitmap)
    }

    validatePath(path)
    {
        if InStr(FileExist(path), "D")
            return % path
        else {
            FileCreateDir % path
            if (Errorlevel)
                return % false
            else
                return % path
        }
    }

    fileName[]
    {
        get {
            global ScreenShotTool_AutoNaming
            if (ScreenShotTool_AutoNaming)
            {
                return "ScreenShot_" A_Now ".png"
            } else {
                global ScreenShotTools_PromptObject
                ScreenShotTools_PromptObject := new Prompt()
                ScreenShotTools_PromptObject.Text := "Enter a filename for the screenshot (without extension)"
                ScreenShotTools_PromptObject.Title := "Enter filename"
                ScreenShotTools_PromptObject.Placeholder := "NewName"
                ScreenShotTools_PromptObject.Cancel := true
                return ScreenShotTools_PromptObject.prompt() ".png"
            }
        }
    }

    targetStorePath[]
    {
        get {
            global ScreenShotTool_TargetPath
            if (this.TargetPath)
                return this.TargetPath
            else if (ScreenShotTool_TargetPath)
                return ScreenShotTool_TargetPath
            else
                return this.defaultTargetPath
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

/**
 * Object to Prompt the user for input
 *
 * Usage:
 *     fileName := new Prompt()           ; Create an instance of Prompt
 *     fileName.Cancel := true            ; Add "Cancel" button to UI
 *     fileName.Placeholder := ""         ; Set a placeholder in the text area
 *     fileName.DataType := "Text"        ; Set input type. Can be: Text (default), Path, File, Number, Time, Selection
 *     fileName.Validation := true        ; Validate field before allow user to click "OK"
 *     fileName.Title := "Select file"    ; Title of the Prompt window
 *     fileName.Text := "chose you file"  ; Text to display in the Prompt window
 *     fileName.Width := 200              ; Width of the Prompt window
 *     fileName.Rows := 1                 ; Rows the Prompt windows shoud have in height
 *     fileName.prompt()                  ; Execute the Prompt
 */
class Prompt
{
    static Cancel := false
    static Placeholder := "Input"
    static DataType := "Text"
    static Validate := true
    static Selection := "Default Selection"
    static Text := ""
    static Title := ""
    static Width := 200
    static Rows := 1
    response := false

    /**
     * entry point:
     *     This method calls the UI and waits for the response
     */
    prompt()
    {
        this.DisplayDialog()

        Loop
            if (this.response)
                return % this.response
    }

    /**
     * Build UI to show to the user
     */
    DisplayDialog()
    {
        Title := this.Title
        Text  := this.Text
        GuiNum:=GetFreeGUINum(1, "InputBox")
        this.tmpGuiNum := GuiNum
        StringReplace, Text, Text, ``n, `n
        Gui,%GuiNum%:Destroy
        Gui,%GuiNum%:Add,Text,y10,%Text%

        if (this.DataType = "Text" || this.DataType = "Path" || this.DataType = "File")
        {
            Gui,%GuiNum%:Add, Edit, % "x+10 yp-4 w" this.Width " hwndEdit gAction_Input_Edit" (this.Rows > 1 ? " R" this.Rows " Multi" : "")
            this.tmpEdit := Edit
            if (this.DataType = "Path" || this.DataType = "File")
            {
                Gui,%GuiNum%:Add, Button, x+10 w80 hwndButton gInputBox_Browse, Browse
                this.tmpButton := Button
            }
        }
        else if (this.DataType = "Number")
        {
            Gui,%GuiNum%:Add, Edit, x+10 yp-4 w200 hwndEdit Number
            this.tmpEdit := Edit
        }
        else if (this.DataType = "Time")
        {
            Gui, %GuiNum%:Add, Edit, x+2 yp-4 w30 hwndHours Number, 00
            Gui, %GuiNum%:Add, Text, x+2 yp+4, :
            Gui, %GuiNum%:Add, Edit, x+2 yp-4 w30 hwndMinutes Number, 10
            Gui, %GuiNum%:Add, Text, x+2 yp+4, :
            Gui, %GuiNum%:Add, Edit, x+2 yp-4 w30 hwndSeconds Number, 00
            this.tmpHours := Hours
            this.tmpHours := Minutes
            this.tmpSeconds := Seconds
        }
        else if (this.DataType = "Selection")
        {
            Selection := this.Selection
            Loop, Parse, Selection, |
            {
                Gui, %GuiNum%:Add, Radio, % "hwndRadio" (A_Index = 1 ? " Checked" : ""), %A_LoopField%
                this["tmpRadio" A_Index] := Radio
            }
        }
        ; ~ Gui, %GuiNum%:Add, Text, x+-80 y+10 hwndTest, test
        ; ~ ControlGetPos, PosX, PosY,,,,ahk_id %Test%
        ; ~ WinKill, ahk_id %Test%

        Gui, %GuiNum%:Show, Autosize Hide
        Gui, %GuiNum%:+LastFound
        x := max(GetClientRect(WinExist()).w - (this.Cancel ? 180 : 90), 10)
        Gui, %GuiNum%:Add, Button, % "Default x" x " y+10 w80 hwndhOK gInputBox_OK " (this.Validate && (this.DataType = "Text" || this.DataType = "Path" || this.DataType = "File") ? "Disabled" : ""), OK
        if (this.Cancel)
            Gui, %GuiNum%:Add, Button, x+10 w80 gInputBox_Cancel, Cancel
        Gui,%GuiNum%:-MinimizeBox -MaximizeBox +LabelInputbox
        Gui,%GuiNum%:Show,Autosize,%Title%

        return
    }

    /**
     * Callback function for when the user clicks on "Browse"
     */
    InputBoxBrowse()
    {
        if (this.DataType = "Path")
        {
            FileSelectFolder, result,, 3, Select Folder
            if (!Errorlevel)
                ControlSetText, Edit1, %result%, A
        }
        else if (this.DataType = "File")
        {
            FileSelectFile, result,,, Select File
            if (!Errorlevel)
                ControlSetText, Edit1, %result%, A
        }
    }

    /**
     * Callback function for when the user uses a Text field
     */
    InputBoxEdit()
    {
        if (this.Validate)
        {
            ControlGetText, input, Edit1
            if (this.DataType = "Text")
            {
                if (input = "")
                    Control, Disable,, Button1
                else
                    Control, Enable,, Button1
            }
            else if (this.DataType = "File" || this.DataType = "Path")
            {
                if (FileExist(input))
                    Control, Enable,, Button2
                else
                    Control, Disable,, Button2
            }
        }
    }

    /**
     * Callback function to close Prompt GUI
     */
    InputBoxCancel()
    {
        if (!this.Cancel)
            return
        Gui, Destroy

        this.response := -1

        return
    }

    /**
     * Callback function for when the user clicks on "OK"
     */
    InputBoxOK()
    {
        if (this.DataType = "Text" || this.DataType = "Number" || this.DataType = "Path" || this.DataType = "File")
            ControlGetText, input, Edit1
        else if (this.DataType = "Time")
        {
            ControlGetText, Hours, Edit1
            ControlGetText, Minutes, Edit2
            ControlGetText, Seconds, Edit3
            input := (SubStr("00" Hours, -1) ":" SubStr("00" Minutes, -1) ":" SubStr("00" Seconds, -1))
        }
        else if (this.DataType = "Selection")
        {
            Loop
            {
                ControlGet, Selected, Checked, , , % "ahk_id " this["tmpRadio" A_Index]
                if (Errorlevel)
                    break
                if (Selected)
                {
                    ControlGetText, input, , % "ahk_id " this["tmpRadio" A_Index]
                    break
                }
            }
        }
        Gui, Destroy

        this.response := input
        return
    }
}

Action_Input_Edit:
    ScreenShotTools_PromptObject.InputBoxEdit()
return
InputBox_Browse:
    ScreenShotTools_PromptObject.InputBoxBrowse()
return
InputboxClose:
InputboxEscape:
InputBox_Cancel:
    ScreenShotTools_PromptObject.InputBoxCancel()
return
InputBox_OK:
    ScreenShotTools_PromptObject.InputBoxOK()
return
