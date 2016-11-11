showMenu() {
    MI_ShowMenu(snip_h_menu)
}

assosiate_snipExtension() {
    Random, random
    tmpfile := A_Temp . "\" . random . "snipfile.reg"

    FileAppend, Windows Registry Editor Version 5.00, %tmpfile%

    FileAppend,
    (
        [HKEY_CURRENT_USER\Software\Classes\.snip]
        @="snip_auto_file"
        "Content Type"="text/plain"
        "PerceivedType"="text"

        [HKEY_CURRENT_USER\Software\Classes\.snip\OpenWithProgids]
        "snip_auto_file"=""

        [HKEY_CURRENT_USER\Software\Classes\snip_auto_file]
        @="Dynamic Snip file"
        "PerceivedType"="text"

        [HKEY_CURRENT_USER\Software\Classes\snip_auto_file\shell]

        [HKEY_CURRENT_USER\Software\Classes\snip_auto_file\shell\edit]

        [HKEY_CURRENT_USER\Software\Classes\snip_auto_file\shell\edit\command]
        @=hex(2):25,00,53,00,79,00,73,00,74,00,65,00,6d,00,52,00,6f,00,6f,00,74,00,25,\
          00,5c,00,73,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,00,5c,00,4e,00,4f,00,\
          54,00,45,00,50,00,41,00,44,00,2e,00,45,00,58,00,45,00,20,00,25,00,31,00,00,\
          00

        [HKEY_CURRENT_USER\Software\Classes\snip_auto_file\shell\open]

        [HKEY_CURRENT_USER\Software\Classes\snip_auto_file\shell\open\command]
        @=hex(2):25,00,53,00,79,00,73,00,74,00,65,00,6d,00,52,00,6f,00,6f,00,74,00,25,\
          00,5c,00,73,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,00,5c,00,4e,00,4f,00,\
          54,00,45,00,50,00,41,00,44,00,2e,00,45,00,58,00,45,00,20,00,25,00,31,00,00,\
          00

        [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.snip]

        [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.snip\OpenWithList]
        "a"="Notepad.Exe"
        "MRUList"="a"

        [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.snip\OpenWithProgids]
        "snip_file"=hex(0):
        "snip_auto_file"=hex(0):

        [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.snip\UserChoice]
        "Progid"="snip_file"
    ), %tmpfile%

    ;~ |__RUN_AS_ADMIN_______________|
    if (A_IsAdmin) {
        FileAppend,
        (
            [HKEY_LOCAL_MACHINE\SOFTWARE\Classes\snip_auto_file]

            [HKEY_LOCAL_MACHINE\SOFTWARE\Classes\snip_auto_file\DefaultIcon]
            @="%SystemRoot%\system32\imageres.dll,97"
        ), %tmpfile%
    }

    RunWait, %comspec% /c reg import "%tmpfile%", , Hide ErrorLevel
    if (errorlevel)
        MsgBox, 48, File Association Failed, Failed to associated .snip files to notepad.exe
    FileDelete, %tmpfile%
    MsgBox, 0, Success, Successfully associated .snip files to notepad.exe, 4
}

create_Examples() {
    ; snip_path_run := snip_cleanVariables(snip_path)

    ; If (!FileExist(snip_path_run))
    ;    snip_createExamples(snip_path_run)
}
