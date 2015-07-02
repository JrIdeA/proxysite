assert = require 'assert'
{ _ } = require 'nokit'
proxy = require '../src/proxy'
{exec} = require './helper'

sh = '../bin/proxysite.js'
describe 'cli', ->
    it '读取.coffee配置文件并生效', (done) ->
        exec(
            ' ./fixtures/config.coffee'
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
            ' ./fixtures/config.js'
            {
                timeout: 1500
                cwd: __dirname
            }
            (err, stdout, stderr) ->
                assert.ok ~stdout.indexOf('jrist.me')
                done()
        )

    it '读取cli配置并生效', (done) ->
        exec(
            ' -u "jrist.me"'
            {
                timeout: 1500
                cwd: __dirname
            }
            (err, stdout, stderr) ->
                assert.ok ~stdout.indexOf('jrist.me')
                done()
        )
    it '优先使用配置文件的配置', (done) ->
        exec(
            ' -u "use-cli.me" ./fixtures/config.coffee'
            {
                timeout: 1500
                cwd: __dirname
            }
            (err, stdout, stderr) ->
                assert.ok ~stdout.indexOf('jrist.me')
                done()
        )
    it 'cli选项可以任意位置', (done) ->
        exec(
            ' ./fixtures/config.coffee -u "use-cli.me"'
            {
                timeout: 1500
                cwd: __dirname
            }
            (err, stdout, stderr) ->
                assert.ok ~stdout.indexOf('jrist.me')
                done()
        )
