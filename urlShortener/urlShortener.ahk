; urlShortener - urlShortener.ahk
; author: olive_000
; created: 2016 11 13

/**
 * TODO:
 *   * allow user to choose between services?
 *       - bit.ly - needs auth
 *       - http://tny.im/aboutapi.php
 */

/**
 * Class to control the shortening of URLs
 */
class urlShortener
{
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
            ; Shorten URL using goo.gl
            shortURL := this.googleShortening(longURL)

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

    /**
     * Call the goo.gl API to shorten URL
     */
    googleShortening(longURL)
    {
        apikey := "AIzaSyDGT9QHcU4vE8zuOiGK9t-3CPaoFJ9sDYY"
        ApiURi := "https://www.googleapis.com/urlshortener/v1/url"
        ApiURi .= "?fields=id&key=" apikey

        Headers := "Content-Type: application/json`n"
        Headers .= "Referer: http://github.com/lipkau/ol.modules`n"

        Options := "Method: POST`n"
        Options .= "Charset: UTF-8`n"

        POSTdata := "{""longUrl"": """ longURL """}"

        ; WriteDebug("HTTPRequest request HEADER:", Headers, "`n")
        ; WriteDebug("HTTPRequest request Options:", Options, "`n")

        HTTPRequest(ApiURi , POSTdata, Headers, Options)

        ; WriteDebug("HTTPRequest response HEADER:", Headers)
        ; WriteDebug("HTTPRequest response BODY:", POSTdata)

        obj := Jxon_Load(POSTdata)
        return % obj.id
    }
}
