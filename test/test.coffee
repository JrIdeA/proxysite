assert = require 'assert'
{exec} = require 'child_process'
{ _ } = require 'nokit'
proxy = require '../dist/proxy'

describe 'cli', ->
    it '读取.coffee配置文件并生效', (done) ->
        exec(
            '../bin/siteproxy.js ./fixtures/config.coffee'
            {
                timeout: 1500
                cwd: __dirname
            }
            (err, stdout, stderr) ->
                assert.ok ~stdout.indexOf('jrist.me')
                done()
        )

    it '读取.js配置文件并生效', (done) ->
        exec(
            '../bin/siteproxy.js ./fixtures/config.js'
            {
                timeout: 1500
                cwd: __dirname
            }
            (err, stdout, stderr) ->
                assert.ok ~stdout.indexOf('jrist.me')
                done()
        )

describe 'proxy', ->
    it 'proxy返回函数', ->
        assert.ok _.isFunction proxy {
            url: 'jrist.me'
        }
    # it 'proxy没有指定url需抛出错误'
    # it '配置replaceBody支持 {key:value}'
