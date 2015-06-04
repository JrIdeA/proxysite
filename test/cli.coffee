assert = require 'assert'
{exec} = require 'child_process'
nokit = require 'nokit'
cli = require '../src/cli_intro'

sh = '../bin/siteproxy.js'

describe 'cli', ->
    it '读取.coffee配置文件并生效', ->
        exec(
            sh + ' ./config.coffee'
            {
                timeout: 2000
            }
            (err, stdout, stderr) ->
                assert.ok ~~stdout.indexOf('jrist.me')
        )

    it '读取.js配置文件并生效', ->
        exec(
            sh + ' ./config.js'
            {
                timeout: 2000
            }
            (err, stdout, stderr) ->
                assert.ok ~~stdout.indexOf('jrist.me')
        )

    it '读取cli配置并生效', ->
        exec(
            sh + ' -u "jrist.me"'
            {
                timeout: 2000
            }
            (err, stdout, stderr) ->
                assert.ok ~~stdout.indexOf('jrist.me')
        )
    it '优先使用配置文件的配置', ->
        exec(
            sh + ' -u "use-cli.me" proxy.coffee'
            {
                timeout: 2000
            }
            (err, stdout, stderr) ->
                assert.ok ~~stdout.indexOf('jrist.me')
        )
    it 'cli选项可以任意位置', ->
        exec(
            sh + ' proxy.coffee -u "use-cli.me"'
            {
                timeout: 2000
            }
            (err, stdout, stderr) ->
                assert.ok ~~stdout.indexOf('jrist.me')
        )
