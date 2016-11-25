; dynSnip - dynSnip.ahk
; author: Oliver Lipkau
; created: 2016 11 11

/**
 * TODO:
 *     *
 */

class dynSnips
{
    static ScriptName := "dynSnips"
    static h_menu
    static _defaultSnipPath := "%AppData%\a2\ol.modules\dynSnips"
    static Settings := new SnipSettings()
    static _menuClicker
    static SnipExtenstion := "snip"

    Init()
    {
        snip_path_run := this.snipPath
        if (!(InStr(FileExist(this.snipPath), "D"))) {
            ; FileCreateDir % this.snipPath
            this.createTemplate()
        }

        this._menuClicker := ObjBindMethod(this, "MenuClick")

        _icon := this.scriptPath . "\a2icon.ico"
        Menu, snip_Root, Add,     % this.ScriptName, noOp
        Menu, snip_Root, default, % this.ScriptName
        Menu, snip_Root, Icon,    % this.ScriptName, %_icon%
        Menu, snip_Root, Add

        snip_level := 0
        snip_menu_lvl%snip_level%_name := "snip_Root"
        snip_lvl%snip_level%_LongFileName := snip_path_run
        i := 1
        ;~ First level
        Loop, %snip_path_run%\*.*,2, 0 ; Get only Folders
        {
            snip_level := 1
            snip_plevel := snip_level -1
            snip_lvl%snip_level%_LongFileName := A_LoopFileLongPath

            snip_menu_lvl%snip_level%_name := this.PopulateSnipList(snip_level, snip_lvl%snip_level%_LongFileName, snip_menu_lvl%snip_plevel%_name, i)
            this.PopulateCategoryList(snip_menu_lvl%snip_level%_name, snip_lvl%snip_level%_LongFileName)
            j := 1
            ;~ Secound level
            Loop, % snip_lvl%snip_level%_LongFileName . "\*.*", 2, 0 ; Get only Folders
            {

                snip_level := 2
                snip_plevel := snip_level - 1
                snip_lvl%snip_level%_LongFileName := A_LoopFileLongPath

                snip_menu_lvl%snip_level%_name := this.PopulateSnipList(snip_level, snip_lvl%snip_level%_LongFileName, snip_menu_lvl%snip_plevel%_name, j)
                this.PopulateCategoryList(snip_menu_lvl%snip_level%_name, snip_lvl%snip_level%_LongFileName)
                j++
            }
            i++
        }
        Menu, snip_Root, Add
        this.PopulateCategoryList("snip_Root", snip_path_run)

        Menu, snip_Root, Color, 0xe0e0e0
        this.h_menu := "snip_Root"
    }

    ShowMenu()
    {
        h_menu := this.h_menu
        Menu, %h_menu%, Show
    }

    createTemplate()
    {
        thisPath := this.scriptPath
        targetPath := this.snipPath
        FileCopyDir, %thisPath%\Template, %targetPath%
    }

    MenuClick()
    {
        ;~ menu := RegExReplace(A_ThisMenu, "_", " ")
        menu := A_ThisMenu
        item := A_ThisMenuItem
        msgbox % menu "`n" item

        if (menu == "snip_Root")
           snip := item "." this.SnipExtenstion
        else if (RegExMatch(menu,"^snip_1(.+?)_2(.+?)$",m))
           snip := m1 "\" m2 "\" item "." this.SnipExtenstion
        else if (RegExMatch(menu,"^snip_1(.+?)$",m))
           snip := m1 "\" item "." this.SnipExtenstion
        else
           snip := item "." this.SnipExtenstion

        file := this.snipPath "\" snip
        if (!FileExist(file)){
           MsgBox, 48, File not found, The file requested could not be found.`nFile path: %file%
           return
        }

        ;~ clipdump := Clipboard
        FileRead, content, %file%
        Clipboard := content
        ClipWait, 1
        SendInput, ^v
        ;~ Clipboard := clipdump
    }

    PopulateSnipList(lvl, folder, root, indent="")
    {
        if (RegExMatch(folder, "^.*\\_(.+?)")) ;folders starting with _ are hidden
            return, false
        RegExMatch(folder, "^.*\\(.+?)$", name)

        if (lvl == 1)
            l_menuName := "snip_" . lvl . name1
        else
            l_menuName := root . "_" . lvl . name1

        Menu, %l_menuName%, Add
        Menu, %l_menuName%, DeleteAll

        Menu, %l_menuName%, Add,      %name1%     , noOp
        Menu, %l_menuName%, Disable,  %name1%
        Menu, %l_menuName%, Add

        if (indent)
            indent := "&" indent
        Menu, % root, Add, %indent% %name1%, :%l_menuName%

        iconpath := folder . "\icon.ico"
        if (FileExist(iconpath)) {
            Menu, %l_menuName%, Icon, %name1%         , %iconpath%
            Menu, %root%,       Icon, %indent% %name1%, %iconpath%
        }

        return l_menuName
    }

    PopulateCategoryList(menu, folder)
    {
        _menuClick := this._menuClicker
        ext := this.SnipExtenstion
       Loop, %folder%\*.%ext%, 0, 0
       {
            SplitPath, A_LoopFileName, snip_FileName, snip_FileDir, snip_FileExtension, snip_FileNameNoExt, snip_FileDrive
            Menu, %menu%, Add, %snip_FileNameNoExt%, % _menuClick
       }
    }

    snipPath[]
    {
        get {
            global DynSnip_path

            if (DynSnip_path)
                return ExpandPathPlaceholders(DynSnip_path)
            else
                return this._defaultSnipPath
        }
    }

    scriptPath[]
    {
        get {
            global a2Dir, a2_modules

            return a2Dir "\" a2_modules "\ol.modules\dynSnips"
        }
    }
}

noOp:
   noOp := true
return

; assosiate_snipExtension() {
;     Random, random
;     tmpfile := A_Temp . "\" . random . "snipfile.reg"

;     FileAppend, Windows Registry Editor Version 5.00, %tmpfile%

;     FileAppend,
;     (
;         [HKEY_CURRENT_USER\Software\Classes\.snip]
;         @="snip_auto_file"
;         "Content Type"="text/plain"
;         "PerceivedType"="text"

;         [HKEY_CURRENT_USER\Software\Classes\.snip\OpenWithProgids]
;         "snip_auto_file"=""

;         [HKEY_CURRENT_USER\Software\Classes\snip_auto_file]
;         @="Dynamic Snip file"
;         "PerceivedType"="text"

;         [HKEY_CURRENT_USER\Software\Classes\snip_auto_file\shell]

;         [HKEY_CURRENT_USER\Software\Classes\snip_auto_file\shell\edit]

;         [HKEY_CURRENT_USER\Software\Classes\snip_auto_file\shell\edit\command]
;         @=hex(2):25,00,53,00,79,00,73,00,74,00,65,00,6d,00,52,00,6f,00,6f,00,74,00,25,\
;           00,5c,00,73,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,00,5c,00,4e,00,4f,00,\
;           54,00,45,00,50,00,41,00,44,00,2e,00,45,00,58,00,45,00,20,00,25,00,31,00,00,\
;           00

;         [HKEY_CURRENT_USER\Software\Classes\snip_auto_file\shell\open]

;         [HKEY_CURRENT_USER\Software\Classes\snip_auto_file\shell\open\command]
;         @=hex(2):25,00,53,00,79,00,73,00,74,00,65,00,6d,00,52,00,6f,00,6f,00,74,00,25,\
;           00,5c,00,73,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,00,5c,00,4e,00,4f,00,\
;           54,00,45,00,50,00,41,00,44,00,2e,00,45,00,58,00,45,00,20,00,25,00,31,00,00,\
;           00

;         [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.snip]

;         [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.snip\OpenWithList]
;         "a"="Notepad.Exe"
;         "MRUList"="a"

;         [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.snip\OpenWithProgids]
;         "snip_file"=hex(0):
;         "snip_auto_file"=hex(0):

;         [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.snip\UserChoice]
;         "Progid"="snip_file"
;     ), %tmpfile%

;     ;~ |__RUN_AS_ADMIN_______________|
;     if (A_IsAdmin) {
;         FileAppend,
;         (
;             [HKEY_LOCAL_MACHINE\SOFTWARE\Classes\snip_auto_file]

;             [HKEY_LOCAL_MACHINE\SOFTWARE\Classes\snip_auto_file\DefaultIcon]
;             @="%SystemRoot%\system32\imageres.dll,97"
;         ), %tmpfile%
;     }

;     RunWait, %comspec% /c reg import "%tmpfile%", , Hide ErrorLevel
;     if (errorlevel)
;         MsgBox, 48, File Association Failed, Failed to associated .snip files to notepad.exe
;     FileDelete, %tmpfile%
;     MsgBox, 0, Success, Successfully associated .snip files to notepad.exe, 4
; }

; create_Examples() {
;     ; snip_path_run := snip_cleanVariables(snip_path)

;     ; If (!FileExist(snip_path_run))
;     ;    snip_createExamples(snip_path_run)
; }
