assert = require 'assert'
{exec} = require 'child_process'
{ _ } = require 'nokit'
proxy = require '../dist/proxy'

sh = '../bin/proxysite.js'
describe 'cli', ->
    it '读取.coffee配置文件并生效', (done) ->
        exec(
            sh + ' ./fixtures/config.coffee'
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
            sh + ' ./fixtures/config.js'
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
            sh + ' -u "jrist.me"'
            {
                timeout: 1500
                cwd: __dirname
            }
            (err, stdout, stderr) ->
                console.log stdout
                console.log stderr
                assert.ok ~stdout.indexOf('jrist.me')
                done()
        )
    it '优先使用配置文件的配置', (done) ->
        exec(
            sh + ' -u "use-cli.me" ./fixtures/config.coffee'
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
            sh + ' ./fixtures/config.coffee -u "use-cli.me"'
            {
                timeout: 1500
                cwd: __dirname
            }
            (err, stdout, stderr) ->
                assert.ok ~stdout.indexOf('jrist.me')
                done()
        )
