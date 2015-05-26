http = require 'http'
urlKit = require 'url'
colors = require 'colors'
replace = require 'replacestream'
zlib = require 'zlib'
Promise = require 'bluebird'
kit = require './kit'
ip = kit.getIp()[0] or '127.0.0.1'

TEXT_MIME = [
    'application/json'
    'application/javascript'
]

# Uppercase first char of headers key
formatHeaders = (headers) ->
    newHeaders = {}
    for k, v of headers
        nk = k.replace(/(\w)(\w*)/g, (m, p1, p2) -> p1.toUpperCase() + p2)
        newHeaders[nk] = v
    newHeaders

createReplaceStream = (conf, sub) ->
    r = []

    if kit.isObject conf
        for k, v of conf
            r.push replace(k, String(v))

    else if kit.isArray conf
        confLen = conf.length
        if sub
            if conf.length >= 2
                r.push replace(conf[0], String(conf[1]))
        else
            if conf.length >= 2 and !kit.isArray(conf[0]) and kit.isString(conf[1])
                r.concat createReplaceStream(conf, true)
            for n, i in conf
                # handle replaceBody: [{}, [], {}, []]
                r.concat createReplaceStream(n, true)
    r

isReplaceContent = (opts, resHeaders) ->
    contentType = resHeaders['content-type']
    if !kit.isEmptyOrNotObject opts.replaceBody and
    ( contentType.substr(0, 5) is 'text/' or contentType in TEXT_MIME) and
    ( !+opts.replaceLimit or resHeaders['content-length'] < opts.replaceLimit )
        return true

    return false

# replace cookie domain
cookieReplace = (cookieArr, fromHostname, toHostname) ->
    matchedCookie = '.' + toHostname
    REX = /;\s*domain=([^;]+)\s*(;|$)/
    cookieArr = cookieArr.map (cookie) ->
        if matchedArr = REX.exec cookie
            matched = matchedArr[1]
            index = matchedCookie.lastIndexOf(matched)
            if ~~index and index is matchedCookie.length - matched.length
                r = cookie.replace REX, (str, p1, p2, offset) ->
                    return "; domain=#{fromHostname}#{p2}"
                return r
        return undefined
    kit.compact cookieArr

resInnerError = (res) ->
    res.statusCode = 500
    res._headers = null
    res.end()

proxy = (opts) ->
    if !opts.url
        throw new Error('No proxy url specified!')

    to = opts.url
    if kit.isObject to
        to.protocol ?= 'http:'
    else
        if to.indexOf('http') != 0
            to = 'http://' + to
        to = urlKit.parse to
        to.protocol ?= 'http:'
        delete to.host

    (req, res) ->
        resPipeError = (err) ->
            res.end()
            reject err

        new Promise (resolve, reject) ->
            # url replace
            { pathname, search } = urlKit.parse req.url
            if !kit.isEmptyOrNotObject opts.urlMap
                pathname = opts.urlMap[pathname] or pathname
            search = if search then search else ''
            path = pathname + search

            # handle req headers
            from = urlKit.parse 'http://' + req.headers.host
            reqHeaders = opts.handleReqHeaders(req.headers, path) || {}
            reqHeaders = formatHeaders reqHeaders
            reqHeaders.Host = to.hostname
            if reqHeaders.Referer
                reqHeaders.Referer = reqHeaders.Referer.replace "http://#{from.host}/", "http://#{to.hostname}/"

            toHost = "#{to.hostname}:#{to.port or 80}#{path}"
            kit.log 'proxy >> '.yellow + toHost

            requestParam = {
                hostname: to.hostname
                port: to.port
                method: req.method
                path
                headers: reqHeaders
            }
            opts.beforeProxy and opts.beforeProxy(requestParam)

            proxyReq = http.request requestParam, (proxyRes) ->
                resHeaders = proxyRes.headers

                if !isReplaceContent(opts, resHeaders)
                    proxyRes.pipe res

                # replace body
                else
                    allStream = createReplaceStream opts.replaceBody
                    upStream = proxyRes

                    # decode body
                    switch resHeaders['content-encoding']
                        when 'gzip'
                            unzip = zlib.createGunzip()
                            zip = zlib.createGzip()
                        when 'deflate'
                            unzip = zlib.createInflate()
                            zip = zlib.createDeflate()
                        else
                            unzip = null
                    if unzip
                        unzip.on 'error', resPipeError
                        allStream.unshift unzip
                        allStream.push zip

                    allStream.push res
                    allStream.forEach (stream) ->
                        upStream = upStream.pipe stream

                    proxyRes.on 'error', resPipeError
                    res.on 'error', resPipeError
                    res.on 'finish', ->
                        kit.log ' done << '.green + toHost
                        resolve res

            proxyReq.on 'response', (proxyRes) ->
                opts.proxyRes and opts.proxyRes(proxyRes)
                resHeaders = opts.handleResHeaders proxyRes.headers, path
                if !kit.isEmptyOrNotObject resHeaders
                    if resHeaders['set-cookie']
                        resHeaders['set-cookie'] = cookieReplace resHeaders['set-cookie'], from.hostname, to.hostname
                    resHeaders = formatHeaders resHeaders, path

                res.writeHead proxyRes.statusCode, resHeaders

            req.on 'error', resPipeError

            req.pipe proxyReq

module.exports = proxy
