; Proxy - Proxy.ahk
; author: Lipkau
; created: 2016 11 17

/**
 * TODO:
 *     *
 */

Proxy_Init()
{
    If (!(IsObject(Settings))) {
        a2log_error("Proxy: Settings class does not exist or was not instanciated", "Proxy")
        return false
    }
    Settings.Proxy := new CProxy()
    a2log_info("Proxy: Proxy injected in Settings", "Proxy")
}

class CProxy
{
    static Enabled := false
    static Address := ""
    static Port := ""
    static Type := "HTTP"
    static Authentication := false

    __New()
    {
        global Proxy_Address
        global Proxy_Port
        global Proxy_Protocol
        global Proxy_Authentication

        this.Enabled := true
        this.Address := Proxy_Address
        this.Port := Proxy_Port
        this.Type := (Proxy_Protocol) ? Proxy_Protocol : "HTTP"
        this.Authentication := new this.CAuthentication()
    }

    class CAuthentication
    {
        static Enabled := false
        static Type := false
        static Username := false
        static Password := false

        __New()
        {
            global Proxy_UseAuthentication
            global Proxy_Authentication_Type
            global Proxy_Authentication_User
            global Proxy_Authentication_Password

            if (Proxy_UseAuthentication == true)
            {
                this.Enabled := true
                this.Type := (Proxy_Authentication_Type) ? Proxy_Authentication_Type : "Basic"
                this.Username := (Proxy_Authentication_User) ? Proxy_Authentication_User : false
                this.Password := (Proxy_Authentication_Password) ? Proxy_Authentication_Password : false  ; TODO -> decrypt?
            }
        }
    }
}
