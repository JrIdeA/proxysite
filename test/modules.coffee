assert = require 'assert'
request = require 'supertest'
http = require 'http'
{exec} = require './helper'

describe 'auto_redirect', ->
    EXPECT_STR = 'NEW_PAGE'
    EXPECT_PATH = '/new'
    LOC_SAME = 'http://127.0.0.1:7100'+ EXPECT_PATH
    LOC_DIFF_PORT = 'http://127.0.0.1:7101' + EXPECT_PATH
    LOC_DIFF_HOSTNAME = 'http://jrist.me/'

    redirectServer = http.createServer (req, res) ->
        switch req.url
            when '/oldrelative'
                res.writeHead 302, {
                    Location: EXPECT_PATH
                }
                res.end()
            when '/oldsame'
                res.writeHead 302, {
                    Location: LOC_SAME
                }
                res.end()
            when '/olddiffport'
                res.writeHead 302, {
                    Location: LOC_DIFF_PORT
                }
                res.end()
            when '/olddiffhostname'
                res.writeHead 302, {
                    Location: LOC_DIFF_HOSTNAME
                }
                res.end()
            when EXPECT_PATH
                res.end EXPECT_STR
            else
                res.end 'index'
    redirectServer.listen 7100

    server = '127.0.0.1:7102'

    before (done) ->
        # FIXME
        # 有没启动完成的callback，利用 setTimeout 肯定是不好的
        exec(
            './fixtures/conf/auto_redirect.coffee'
            {
                cwd: __dirname
            },
            (err, stdout, stderr) ->
                done(err)
                clearTimeout timer
        )
        timer = setTimeout ->
            done()
        , 1500

    # supertest 对于测试 redirect 的方法
    # http://stackoverflow.com/questions/12272228/testing-requests-that-redirect-with-mocha-supertest-in-node
    endHandler = (expectPath, done) -> (err, res) ->
        if res.headers.location isnt expectPath
            throw "expected: `#{expectPath}`, but location: `#{res.headers.location}`"
        done()

    it '相对地址跳转', (done) ->
        request server
        .get '/oldrelative'
        .end endHandler EXPECT_PATH, done

    it '绝对地址同域代理跳转', (done) ->
        request server
        .get '/oldsame'
        .end endHandler EXPECT_PATH, done

    it '绝对地址同域不同端口不代理跳转', (done) ->
        request server
        .get '/olddiffport'
        .end endHandler LOC_DIFF_PORT, done

    it '绝对地址不同域不代理跳转', (done) ->
        request server
        .get '/olddiffhostname'
        .end endHandler LOC_DIFF_HOSTNAME, done
