/*
query := "?"
if (options.Contains(nOptions)) {
    nString := nString "n:" country

    p_89:<string> --> specify the brand
    p_8:<int>- --> minumum discount
    p_72:<[1-5]>- --> minimum rating
    p_85:2470955011 --> Prime Eligible
    p_n_is_pantry:8417613011 --> Prime Pantry Eligible
    p_76:2661625011 --> Shipping: Eligible for Free Shipping
    p_n_shipping_option-bin:3242350011 --> Shipping: International Shipping
    p_n_shipping_option-bin:3242350011,p_n_is_free_international_shipping:10236242011 --> Shipping Free International Shipping

    for key, value in options
        nString := nString "," key ":" value
}
query := query encodeURL(nString)

field-keywords=<string> --> Keywords
field-title=<string> --> Title
hidden-keywords=<string> --> Hidden keywords
low-price=<int> --> Minimum Price
high-price=<int> --> Maximum Price
sort=relevancerank --> Sort By Relevance
sort=price-asc-rank --> Sort By Price: Low to High
sort=price-desc-rank --> Sort By Price: High to Low
sort=review-rank --> Sort By Avg. Customer Rating
sort=date-desc-rank --> Sort By Newset Arrivals
sort=titlerank --> Sort Alphabetical: A to Z
sort=-titlerank --> Sort Alphabetical: Z to A
bbn=10158976011 --> Show Only Amazon Warehouse Deals*/


; AdvancedAmazonSearch - AdvancedAmazonSearch.ahk
; author: Oliver Lipkau <https://github.com/lipkau>
; created: 2017 06 18

#include lib\ahklib\Array.ahk
#include lib\ahklib\CNotification.ahk

/**
 * TODO:
 */

class AdvancedAmazonSearch extends ModuleModel
{
    /**
     * Constructor
     *     Populates the `counter` property from a2.db
     */
    __New()
    {
        this.base.__New(A_LineFile)  ; call constructor of parent
        return this
    }

    /**
     * Entry point
     * By calling this, the URL to be shortend will be read out of the clipboard
     */
    Execute()
    {
        WriteDebug("Triggered Screenshot with option:", option, "debug", this.moduleName)

        if (false)
        {
        } else {
            WriteDebug("invalid long URL:", longURL, "debug", this.moduleName)
            Notify("No valid URL", "Clipboard does not contain a valid URL to shorten.", 2, NotifyIcons.Error)
        }
    }

    query[]
    {
        get {
            return "?" URLencode("n:" this.nString.ToString(",")) this.GETparameters.ToString("&")
        }
    }

    nString[]
    {
        get {
            global stuff
            return CArray(stuff)
        }
    }

    GETparameters[]
    {
        get {
            global stuff
            return CArray(stuff)
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

        WriteDebug("HTTPRequest request HEADER:", Headers, "debug", this.moduleName)
        WriteDebug("HTTPRequest request Options:", Options, "debug", this.moduleName)

        HTTPRequest(ApiURi , POSTdata, Headers, Options)

        WriteDebug("HTTPRequest response HEADER:", Headers, "debug", this.moduleName)
        WriteDebug("HTTPRequest response BODY:", POSTdata, "debug", this.moduleName)

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
        ; Headers .= Settings.Proxy.Authentication.Username && Settings.Proxy.Authentication.Password ? "Proxy-Authorization: Basic " Base64Encode(Settings.Proxy.Authentication.Username ":" Settings.Proxy.Authentication.Password) : ""  ; TODO decrypt pw?

        Options := "Charset: UTF-8`n"
        Options .= Settings.Proxy.Enabled ? "Proxy: " Settings.Proxy.Address ":" Settings.Proxy.Port "`n" : ""

        apiURi .= "?action=shorturl&format=json&&url=" longURL
        WriteDebug("HTTPRequest request HEADER:", Headers, "debug", this.moduleName)
        WriteDebug("HTTPRequest request Options:", Options, "debug", this.moduleName)

        HTTPRequest(ApiURi , POSTdata, Headers, Options)

        WriteDebug("HTTPRequest response HEADER:", Headers, "debug", this.moduleName)
        WriteDebug("HTTPRequest response BODY:", POSTdata, "debug", this.moduleName)

        obj := Jxon_Load(POSTdata)
        if (obj.statusCode == 200)
            return % obj.shorturl
        return false
    }
}
