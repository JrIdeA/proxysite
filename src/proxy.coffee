http = require 'http'
urlKit = require 'url'
kit = require './kit'
colors = require 'colors'
ip = kit.getIp()[0] or '127.0.0.1'

class SiteProxy
    constructor: (opts) ->
        if !opts.url
            throw new Error('No proxy url specified!')

        if url.indexOf('http') != 0
            url = 'http://' + url

        # FIXME 感觉url的处理还是有点疑问
        # if kit.isObject url
        #     url.protocol ?= 'http:'
        # else
        #     url = urlKit.parse url
        #     url.protocol ?= 'http:'
        #     delete url.host
        #
        # request = null
        # switch url.protocol
        #     when 'http:'
        #         { request } = require 'http'
        #     when 'https:'
        #         { request } = require 'https'
        #     else
        #         throw new Error('Protocol not supported: ' + opts.protocol)

        @opts = opts

    request: ->



module.exports = (opts) ->
    if !opts.url
        throw new Error('No proxy url specified!')

    server = http.createServer (req, res) ->

    port = opts.port
    server.listen port
    kit.log 'Server start at '.cyan + "#{ip}:#{port}"
