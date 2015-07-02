assert = require 'assert'
request = require 'supertest'
http = require 'http'
proxy = require '../src/proxy'
{ _, fs } = require 'nokit'
{coffee} = require './helper'

configPath = './fixtures/config'

htmlObj = fs.readFileSync("#{__dirname}/fixtures/replacebody.html")
htmlLen = htmlObj.length
htmlOriginal = htmlObj.toString()
originalServer = http.createServer (req, res) ->
    res.writeHead 200, {
        "Content-Type": 'text/html'
        "Content-Length": htmlLen
        "Server": "nginx"
    }
    res.end(htmlOriginal)
originalServer.listen '7000'
originalServerUrl = 'http://127.0.0.1:7000'

conf = {
    url: originalServerUrl
    replaceBody: [
        {'old title': 'new title'}
        [/http:\/\/a\.com\/(.+)\.jpg(\W)/g,'/b.com/$1.png$2']
    ]
}
http.createServer proxy(conf)
.listen 7001

describe 'proxy', ->
    it 'proxy返回函数', ->
        assert.ok _.isFunction proxy {
            url: 'jrist.me'
        }

    it '没有指定url时报错', ->
        assert.throws proxy, /No proxy url specified/

    it 'replaceBody配置格式支持{ from: to }', (done) ->
        coffee(
            './fixtures/bin/replacebody_basic_opts.coffee'
            cwd: __dirname
            (err, stdout, stderr) ->
                assert.ok ~stdout.indexOf('replace_from -> replace_to')
                done()
        )

    it 'replaceBody配置格式支持[[from1, to1], [from2, to2]]', (done) ->
        coffee(
            './fixtures/bin/replacebody_arr_opts.coffee'
            cwd: __dirname
            (err, stdout, stderr) ->
                assert.ok(
                    /^\s*replace_from1 -> replace_to1\s*$/m.test(stdout) and
                    /^\s*replace_from2 -> replace_to2\s*$/m.test(stdout)
                )
                done()
        )

    it 'replaceBody配置格式支持组合式 [{ from1: to1 }, [from2, to2]]', (done) ->
        coffee(
            './fixtures/bin/replacebody_combine_opts.coffee'
            cwd: __dirname
            (err, stdout, stderr) ->
                assert.ok(
                    /^\s*replace_from1 -> replace_to1\s*$/m.test(stdout) and
                    /^\s*replace_from2 -> replace_to2\s*$/m.test(stdout)
                )
                done()
        )

    it 'body支持替换', (done) ->
        replaceBody = [
            {'old title': 'new title'}
            [/http:\/\/a\.com\/(.+)\.jpg(\W)/g,'/b.com/$1.png$2']
        ]
        conf = {
            url: originalServerUrl
            replaceBody
        }
        htmlTarget = htmlOriginal
        htmlTarget = htmlTarget.replace 'old title', 'new title'
        htmlTarget = htmlTarget.replace replaceBody[1][0], replaceBody[1][1]

        server = http.createServer(proxy(conf))
        request server
        .get '/'
        .expect htmlTarget
        .end done


    it 'replaceLimit配置可用性', (done) ->
        replaceBody = [
            {'old title': 'new title'}
            [/http:\/\/a\.com\/(.+)\.jpg(\W)/g,'/b.com/$1.png$2']
        ]
        conf = {
            url: originalServerUrl
            replaceBody
            replaceLimit: htmlLen - 1
        }
        server = http.createServer(proxy(conf))
        request server
        .get '/'
        .expect htmlOriginal
        .end done

    it 'options.pathMap 有效', (done) ->
        expectStr = 'ima'
        http.createServer (req, res) ->
            if req.url = '/a'
                res.end expectStr
            else
                res.end 'nonono'
        .listen 7002

        conf = {
            url: 'http://127.0.0.1:7002'
            pathMap: {'/': '/a'}
        }
        server = http.createServer(proxy(conf))
        request server
        .get '/'
        .expect expectStr
        .end done

    it 'options.ip 有效', (done) ->
        conf = {
            url: 'http://baidu.com:7000'
            ip: '127.0.0.1'
        }
        server = http.createServer(proxy(conf))
        request server
        .get '/'
        .expect htmlOriginal
        .end done

    it 'options.handleReqHeaders 有效', (done) ->
        expectStr = 'ok'
        headerValue = 'test'
        http.createServer (req, res) ->
            if req.headers.proxysite is headerValue
                res.end expectStr
            else
                res.end 'nonono'
        .listen 7004

        conf = {
            url: 'http://127.0.0.1:7004'
            handleReqHeaders: (headers) ->
                headers.proxysite = headerValue
                headers
        }
        server = http.createServer(proxy(conf))
        request server
        .get '/'
        .expect expectStr
        .end done

    it 'options.handleResHeaders 有效', (done) ->
        headerValue = 'test'
        headerServer = 'lighttpd'

        conf = {
            url: originalServerUrl
            handleResHeaders: (headers) ->
                headers.proxysite = headerValue
                headers.server = headerServer
                headers
        }
        server = http.createServer(proxy(conf))
        request server
        .get '/'
        .expect 'proxysite', headerValue
        .expect 'server', headerServer
        .end done
