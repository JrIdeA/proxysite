{exec, spawn} = require 'child_process'
module.exports = h = {}

h.coffee = (arg, opts, callback) ->
    sh = "../node_modules/coffee-script/bin/coffee #{arg}"
    exec sh, opts, callback

h.exec = (arg, opts, callback) ->
    h.coffee "../src/cli_intro.coffee #{arg}", opts, callback

h.spawn = (arg, opts) ->
    command = '../node_modules/coffee-script/bin/coffee'
    args = ['../src/cli_intro.coffee'].concat arg.split(/\s+/)
    spawn command, args, opts

###*
 * 所有正常完成才会触发 done，然后有一个失败就直接返回失败，类似 Promise.all
###
h.allDone = (done) ->
    curFlag = 0
    ider = 0
    results = []
    end = false
    ->
        id = ider++
        (err, r) ->
            return if end
            if err
                end = true
                return done(err, r)
            else
                results[id] = r
                curFlag = curFlag | Math.pow(2, id)
                if curFlag is Math.pow(2, ider) - 1
                    end = true
                    return done(null, results)
