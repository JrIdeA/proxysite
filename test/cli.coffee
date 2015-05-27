assert = require 'assert'
{exec} = require 'child_process'
nokit = require 'nokit'
cli = require '../src/cli_intro'

describe 'cli', ->
    it '读取.coffee配置文件并生效', ->
        exec(
        '../../../bin/siteproxy.js ./config.coffee'
        {
            timeout: 2000
        }
        (err, stdout, stderr) ->
            assert.ok ~~stdout.indexOf('jrist.me')
        )

    it '读取.js配置文件并生效', ->
        exec(
        '../../../bin/siteproxy.js ./config.coffee'
        {
            timeout: 2000
        }
        (err, stdout, stderr) ->
            assert.ok ~~stdout.indexOf('jrist.me')
        )
        
