http = require 'http'
urlKit = require 'url'
colors = require 'colors'
replace = require 'replacestream'
zlib = require 'zlib'
Promise = require 'bluebird'
kit = require './kit'
ip = kit.getIp()[0] or '127.0.0.1'

# class SiteProxy
#     constructor: (opts) ->
#         if !opts.url
#             throw new Error('No proxy url specified!')
#
#         if url.indexOf('http') != 0
#             url = 'http://' + url
#
#         # FIXME 感觉url的处理还是有点疑问
#         # if kit.isObject url
#         #     url.protocol ?= 'http:'
#         # else
#         #     url = urlKit.parse url
#         #     url.protocol ?= 'http:'
#         #     delete url.host
#         #
#         # request = null
#         # switch url.protocol
#         #     when 'http:'
#         #         { request } = require 'http'
#         #     when 'https:'
#         #         { request } = require 'https'
#         #     else
#         #         throw new Error('Protocol not supported: ' + opts.protocol)
#
#         @opts = opts
#
#     request: ->

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
isReplaceContent = (opts, proxyRes) ->
    contentType = proxyRes['content-type']
    if kit.isEmptyOrNotObject opts.replaceBody and
    ( contentType.substr(0, 5) is 'text/' or contentType in TEXT_MIME) and
    ( !+opts.replaceLimit or proxyRes['content-length'] < opts.replaceLimit )
        return true

    return false

resInnerError = (res) ->
    res.statusCode = 500
    res._headers = null
    res.end()






###*
 * @param opts
 *
 * ```coffee
    from: url object
    to: url object
    urlMap
    contentMap
    handleReqHeaders
    handleResHeaders
 * ```
###
proxy = (opts, req, res) ->
    { from, to } = opts

    # url replace
    { pathname, search } = urlKit.parse req.url
    if !kit.isEmptyOrNotObject opts.urlMap
        pathname = opts.urlMap[pathname] or pathname
        search = if search then search else ''
    path = pathname + search

    reqHeaders = opts.handleReqHeaders(req.headers) || {}
    reqHeaders = formatHeaders reqHeaders
    reqHeaders.referer = reqHeaders.referer.replace "http://#{from.hostname}/", "http://#{to.hostname}/"
    reqHeaders.host = to.hostname

    proxyReq = http.request {
        hostname: to.hostname # F1 处理 opts.host
        port: to.port
        method: req.method
        path
        headers: reqHeaders
    }, (proxyRes) ->
        isReplaceContent opts, proxyRes
            proxyRes.pipe res

        # replace body
        else

            # decode body
            switch proxyRes.headers['content-encoding']
                when 'gzip'
                    unzip = zlib.createGunzip()
                when 'deflate'
                    unzip = zlib.createInflat()
                else
                    unzip = null
            if unzip
                unzip.on 'error', (err) ->
                    resInnerError(res)



    proxyReq.on 'response', (proxyRes) ->
        # TODO 会不会额外输出，会headers被改变
        res.writeHead(
            proxyRes.statusCode
            opts.handleReqHeaders(proxyRes.headers)
        )

    res

request = ->
    http.request {
        hostname
        port
        method
        path # include querystring
        headers
        keepAlive
    }, (res) ->



proxy2 = (opts) ->
    { from, to } = opts
    replaceStreams = createReplaceStream opts.replaceBody

    (req, res) ->
        new Promise (resolve, reject) ->
            # url replace
            { pathname, search } = urlKit.parse req.url
            if !kit.isEmptyOrNotObject opts.urlMap
                pathname = opts.urlMap[pathname] or pathname
                search = if search then search else ''
            path = pathname + search

            # deal req headers
            reqHeaders = opts.handleReqHeaders(req.headers) || {}
            reqHeaders = formatHeaders reqHeaders
            reqHeaders.referer = reqHeaders.referer.replace "http://#{from.hostname}/", "http://#{to.hostname}/"
            reqHeaders.host = to.hostname

            proxyReq = http.request {
                hostname: to.hostname # F1 处理 opts.host
                port: to.port
                method: req.method
                path
                headers: reqHeaders
            }, (proxyRes) ->
                if !isReplaceContent(opts, proxyRes)
                    proxyRes.pipe res

                # replace body
                else
                    resPipeError = (err) ->
                        res.end()
                        reject err

                    allStream = replaceStreams.slice()
                    upStream = proxyRes

                    # decode body
                    switch proxyRes.headers['content-encoding']
                        when 'gzip'
                            unzip = zlib.createGunzip()
                        when 'deflate'
                            unzip = zlib.createInflat()
                        else
                            unzip = null
                    if unzip
                        unzip.on 'error', resPipeError
                        allStream.push unzip

                    allStream.push res
                    allStream.forEach (stream) ->
                        upStream = upStream.pipe stream

                    proxyRes.on 'error', resPipeError
                    res.on 'error', resPipeError
                    res.on 'finish', resolve res

module.exports = (opts) ->
    ## url 通用处理开始
    if !opts.url
        throw new Error('No proxy url specified!')

    if kit.isObject url
        url.protocol ?= 'http:'
    else
        url = urlKit.parse url
        url.protocol ?= 'http:'
        delete url.host

    opts.url = url
    ## url 通用处理结束

    server = http.createServer (req, res) ->
        # http.request

    port = opts.port
    server.listen port
    kit.log 'Server start at '.cyan + "#{ip}:#{port}"
