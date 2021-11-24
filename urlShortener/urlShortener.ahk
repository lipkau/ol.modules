; urlShortener - urlShortener.ahk
; author: Oliver Lipkau <https://github.com/lipkau>
; created: 2016 11 13

/**
 * TODO:
 *   * add more services?
 *       - bit.ly - needs auth
 */

#include <ModuleModel>
#include %A_LineFile%\..\..\.lib\Notify.ahk

/**
 * Class to control the shortening of URLs
 */
class urlShortener extends ModuleModel
{
    static _defaultService := "goo.gl"

    /**
     * Entry point
     * By calling this, the URL to be shortend will be read out of the clipboard
     */
    Execute()
    {
        a2log_info("Executing ""urlShortener""", this.module.Name)
        a2log_debug("Using service: " this.service, this.module.Name)

        ; Read clipboard
        longURL := clipboard

        ; Validate clip as url
        if (string_is_web_address(longURL))
        {
            if (this.service == "goo.gl")          ; Shorten URL using goo.gl
                shortURL := this._googleShortening(longURL)
            else if (this.service == "tny.im")     ; Shorten URL using tny.im
                shortURL := this._tnyimShortening(longURL)

            if (shortURL)
            {
                a2log_debug("Short url: " shortURL, this.module.Name)

                ; Store shortend URL in clipboard
                Clipboard := ShortURL

                notify(this.module.Name, "URL shortened and copied to clipboard!", 2, NotifyIcons.Success)
                return 1
            } else {
                a2log_error("Failed to connect to service", this.module.Name)
                notify(this.module.Name, "An error occured while trying to connect to the server.", 2, NotifyIcons.Error)
                return 0
            }
        } else {
            a2log_error("invalid long URL: " longURL, this.module.Name)
            notify(this.module.Name, "Clipboard does not contain a valid URL to shorten.", 2, NotifyIcons.Error)
        }
    }

    service[]
    {
        get {
            global urlShortener_Service
            return (urlShortener_Service) ? urlShortener_Service : this._defaultService
        }
    }

    /**
     * Call the goo.gl API to shorten URL
     */
    _googleShortening(longURL)
    {
        apikey := "AIzaSyDGT9QHcU4vE8zuOiGK9t-3CPaoFJ9sDYY"
        ApiURi := "https://www.googleapis.com/urlshortener/v1/url"
        ApiURi .= "?fields=id&key=" apikey

        Headers := "Content-Type: application/json`n"
        Headers .= "Referer: https://github.com/lipkau/ol.modules`n"
        if (Settings.Proxy.Enabled) {
            Headers .= Settings.Proxy.Authentication.Username && Settings.Proxy.Authentication.Password ? "Proxy-Authorization: Basic " base64_encode(Settings.Proxy.Authentication.Username ":" Settings.Proxy.Authentication.Password) : ""  ; TODO decrypt pw?
        }

        Options := "Method: POST`n"
        Options .= "Charset: UTF-8`n"
        Options .= Settings.Proxy.Enabled ? "Proxy: " Settings.Proxy.Address ":" Settings.Proxy.Port "`n" : ""

        POSTdata := "{""longUrl"": """ longURL """}"

        a2log_debug("HTTPRequest request HEADER: " Headers, this.module.Name)
        a2log_debug("HTTPRequest request Options: " Options, this.module.Name)

        HTTPRequest(ApiURi , POSTdata, Headers, Options)

        a2log_debug("HTTPRequest response HEADER: " Headers, this.module.Name)
        a2log_debug("HTTPRequest response BODY: " POSTdata, this.module.Name)

        obj := Jxon_Load(POSTdata)
        return % obj.id
    }

    /**
     * Call the tny.om API to shorten URL
     */
    _tnyimShortening(longURL)
    {
        ApiURi := "http://tny.im/yourls-api.php"

        Headers := "Content-Type: application/json`n"
        Headers .= "Referer: https://github.com/lipkau/ol.modules`n"
        ; Headers .= Settings.Proxy.Authentication.Username && Settings.Proxy.Authentication.Password ? "Proxy-Authorization: Basic " base64_encode(Settings.Proxy.Authentication.Username ":" Settings.Proxy.Authentication.Password) : ""  ; TODO decrypt pw?

        Options := "Charset: UTF-8`n"
        Options .= Settings.Proxy.Enabled ? "Proxy: " Settings.Proxy.Address ":" Settings.Proxy.Port "`n" : ""

        apiURi .= "?action=shorturl&format=json&&url=" longURL
        a2log_debug("HTTPRequest request HEADER: " Headers, this.module.Name)
        a2log_debug("HTTPRequest request Options: " Options, this.module.Name)

        HTTPRequest(ApiURi , POSTdata, Headers, Options)

        a2log_debug("HTTPRequest response HEADER: " Headers, this.module.Name)
        a2log_debug("HTTPRequest response BODY: " POSTdata, this.module.Name)

        obj := Jxon_Load(POSTdata)
        if (obj.statusCode == 200)
            return % obj.shorturl
        return false
    }
}
