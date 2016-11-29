; urlShortener - urlShortener.ahk
; author: olive_000
; created: 2016 11 13

#include lib\ahklib\jxon.ahk
#include lib\ahklib\base64.ahk
#include lib\ahklib\HTTPRequest.ahk
#include lib\ahklib\CNotification.ahk

/**
 * TODO:
 *   * add more services?
 *       - bit.ly - needs auth
 */

/**
 * Class to control the shortening of URLs
 */
class urlShortener
{
    static _defaultService := "goo.gl"

    /**
     * Entry point
     * By calling this, the URL to be shortend will be read out of the clipboard
     */
    Execute()
    {
        ; Read clipboard
        longURL := clipboard

        ; Validate clip as url
        if (isURL(longURL))
        {
            if (this.service == "goo.gl")
            {
                ; Shorten URL using goo.gl
                shortURL := this._googleShortening(longURL)
            } else if (this.service == "tny.im")
            {
                ; Shorten URL using tny.im
                shortURL := this._tnyimShortening(longURL)
            }

            if (shortURL)
            {
                ; Store shortend URL in clipboard
                Clipboard := ShortURL

                Notify("URL shortened!", "URL shortened and copied to clipboard!", 2, NotifyIcons.Success)
                return 1
            } else {
                Notify("Failed to shorten URL", "An error occured while trying to connect to the server.", 2, NotifyIcons.Error)
                return 0
            }
        } else
            Notify("No valid URL", "Clipboard does not contain a valid URL to shorten.", 2, NotifyIcons.Error)
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
        Headers .= Settings.Proxy.Authentication.Username && Settings.Proxy.Authentication.Password ? "Proxy-Authorization: Basic " Base64Encode(Settings.Proxy.Authentication.Username ":" Settings.Proxy.Authentication.Password) : ""  ; TODO decrypt pw?

        Options := "Method: POST`n"
        Options .= "Charset: UTF-8`n"
        Options .= Settings.Proxy.Enabled ? "Proxy: " Settings.Proxy.Address ":" Settings.Proxy.Port "`n" : ""

        POSTdata := "{""longUrl"": """ longURL """}"

        WriteDebug("HTTPRequest request HEADER:", Headers, "`n")
        WriteDebug("HTTPRequest request Options:", Options, "`n")

        HTTPRequest(ApiURi , POSTdata, Headers, Options)

        WriteDebug("HTTPRequest response HEADER:", Headers)
        WriteDebug("HTTPRequest response BODY:", POSTdata)

        obj := Jxon_Load(POSTdata)
        return % obj.id
    }

    _tnyimShortening(longURL)
    {
        ApiURi := "http://tny.im/yourls-api.php"

        Headers := "Content-Type: application/json`n"
        Headers .= "Referer: https://github.com/lipkau/ol.modules`n"
        ; Headers .= Settings.Proxy.Authentication.Username && Settings.Proxy.Authentication.Password ? "Proxy-Authorization: Basic " Base64Encode(Settings.Proxy.Authentication.Username ":" Settings.Proxy.Authentication.Password) : ""  ; TODO decrypt pw?

        Options := "Charset: UTF-8`n"
        Options .= Settings.Proxy.Enabled ? "Proxy: " Settings.Proxy.Address ":" Settings.Proxy.Port "`n" : ""

        apiURi .= "?action=shorturl&format=json&&url=" longURL
        WriteDebug("HTTPRequest request HEADER:", Headers, "`n")
        WriteDebug("HTTPRequest request Options:", Options, "`n")

        HTTPRequest(ApiURi , POSTdata, Headers, Options)

        WriteDebug("HTTPRequest response HEADER:", Headers)
        WriteDebug("HTTPRequest response BODY:", POSTdata)

        obj := Jxon_Load(POSTdata)
        if (obj.statusCode == 200)
            return % obj.shorturl
        return false
    }
}
