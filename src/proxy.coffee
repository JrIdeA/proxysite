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

###*
 * 格式化 replaceBody 的配置
 * @return {Array|null} [ [replaceKey, replaceValue], ... ] 这样的格式
###
formatReplaceOpt = (opt, sub) ->
    r = []

    if kit.isObject opt
        for k, v of opt
            r.push [ k, String(v) ]

    else if kit.isArray opt
        optLen = opt.length
        if sub
            if opt.length >= 2
                r.push [ opt[0], String(opt[1]) ]
        else
            if opt.length >= 2 and !kit.isArray(opt[0]) and kit.isString(opt[1])
                r = r.concat formatReplaceOpt(opt, true)
            else
                for n, i in opt
                    # handle replaceBody: [{}, [], {}, []]
                    r = r.concat formatReplaceOpt(n, true)

    return if r.length > 0 or sub then r else null

createReplaceStream = (formatOpt) ->
    r = []
    for n, i in formatOpt
        console.log ' >> '.red + "key:#{n[0]}, value: #{n[1]}"
        r.push replace n[0], n[1]
    r

isReplaceContent = (opts, resHeaders) ->
    contentType = resHeaders['content-type']
    console.log ' >> isReplaceContent start'.red
    console.log opts.replaceBody
    console.log contentType
    console.log ( contentType.substr(0, 5) is 'text/' or contentType in TEXT_MIME)
    console.log ( !+opts.replaceLimit or resHeaders['content-length'] < opts.replaceLimit )


    if opts.replaceBody and
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

    opts.replaceBody = formatReplaceOpt opts.replaceBody
    if opts.replaceBody
        kit.log '\n>> replace body:'.cyan
        for n in opts.replaceBody
            kit.log '  '.cyan + n[0] + ' -> '.green + n[1]

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

                # XXX
                # 由于替换body时content-length不同于替换后的长度，会造成client端校验错误，
                # 现先删去 content-length, 若处理完所有body再返回header，body过大则会造成client很长时间的等待
                if opts.replaceBody
                    delete resHeaders['content-length']

                resHeaders = formatHeaders resHeaders
                res.writeHead proxyRes.statusCode, resHeaders

            req.on 'error', resPipeError

            req.pipe proxyReq

module.exports = proxy
