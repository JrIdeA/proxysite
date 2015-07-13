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
