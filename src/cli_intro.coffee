cmd = require 'commander'
path = require 'path'
http = require 'http'
cs = require 'colors/safe'
kit = require './kit'
proxy = require './proxy'
{ version } = require '../package.json'
defaultOpts = require './default.config'

cmd
    .version version
    .usage  '\n\n    siteproxy config.coffee'
    .parse process.argv

confFile = cmd.args[0] or cmd.args[1]

try
    if '.coffee' is path.extname confFile
        require 'coffee-script/register'
    opts = require path.resolve(process.cwd(), confFile)
catch err
    if cmd.args.length > 0
        kit.err err.stack
        process.exit 1
    else
        kit.err cs.red 'No config specified!'

opts = kit.assign defaultOpts, opts
kit.log opts

ip = kit.getIp()[0] or '127.0.0.1'
port = opts.port
proxyHandler = proxy(opts)
http.createServer (req, res) ->
    promise = proxyHandler(req, res)
    promise.catch (err) ->
        kit.err '>> proxy err!'.red
        kit.log err

.listen port
kit.log '\nServer start at '.cyan + "#{ip}:#{port}"
