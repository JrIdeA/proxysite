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

# 根据参数创建文本替换流
createReplaceStream = (conf, sub) ->
    r = []

    if kit.isObject conf
        for k, v of conf
            r.push replace(k, String(v))

    else if kit.isArray conf
        for n, i in conf
            if !sub
                # handle replaceBody: [{}, [], {}, []]
                r.concat createReplaceStream(n, true)
            else
                continue if n.length < 2
                r.push replace(r[0], String(r[1]))
    r

# 是否替换body的判断
isReplaceContent = (opts, resHeaders) ->
    contentType = resHeaders['content-type']
    if kit.isEmptyOrNotObject opts.replaceBody and
    ( contentType.substr(0, 5) is 'text/' or contentType in TEXT_MIME) and
    ( !+opts.replaceLimit or resHeaders['content-length'] < opts.replaceLimit )
        return true

    return false

# 替换cookie domain
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

    replaceStreams = createReplaceStream opts.replaceBody

    kit.log to

    (req, res) ->
        new Promise (resolve, reject) ->
            # url replace
            { pathname, search } = urlKit.parse req.url
            if !kit.isEmptyOrNotObject opts.urlMap
                pathname = opts.urlMap[pathname] or pathname
            search = if search then search else ''
            path = pathname + search

            # deal req headers
            from = urlKit.parse 'http://' + req.headers.host
            reqHeaders = opts.handleReqHeaders(req.headers) || {}
            reqHeaders = formatHeaders reqHeaders
            reqHeaders.Host = to.hostname
            if reqHeaders.Referer
                reqHeaders.Referer = reqHeaders.Referer.replace "http://#{from.host}/", "http://#{to.hostname}/"

            # debug start
            kit.log 'req headers >>'
            kit.log 'path: ' + path
            kit.log 'pathname:' + pathname
            kit.log 'search:' + search
            kit.log reqHeaders
            kit.log 'req params >>'
            kit.log {
                hostname: to.hostname # F1 处理 opts.host
                port: to.port or 80
                method: req.method
                path
                headers: reqHeaders
            }
            # debug end

            proxyReq = http.request {
                hostname: to.hostname
                port: to.port
                method: req.method
                path
                headers: reqHeaders
            }, (proxyRes) ->
                # debug start
                kit.log 'proxy res >>'.yellow
                kit.log proxyRes.headers
                # debug end
                resHeaders = proxyRes.headers
                if !isReplaceContent(opts, resHeaders)
                    proxyRes.pipe res

                # replace body
                else
                    resPipeError = (err) ->
                        res.end()
                        reject err

                    allStream = replaceStreams.slice()
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

                    # stream
                    allStream.push res
                    allStream.forEach (stream) ->
                        upStream = upStream.pipe stream

                    proxyRes.on 'error', resPipeError
                    res.on 'error', resPipeError
                    res.on 'finish', resolve res

            proxyReq.on 'response', (proxyRes) ->
                # debug start
                kit.log 'response >> '.yellow
                kit.log proxyRes.statusCode
                kit.log proxyRes.headers
                # debug end

                resHeaders = opts.handleReqHeaders(proxyRes.headers)
                if !kit.isEmptyOrNotObject resHeaders
                    if resHeaders['set-cookie']
                        resHeaders['set-cookie'] = cookieReplace resHeaders['set-cookie'], from.hostname, to.hostname
                    resHeaders = formatHeaders(resHeaders)

                # TODO 会不会额外输出，会headers被改变
                res.writeHead(
                    proxyRes.statusCode
                    resHeaders
                )

            req.pipe proxyReq


module.exports = proxy
