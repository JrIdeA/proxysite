require 'colors'
cmd = require 'commander'
path = require 'path'
http = require 'http'
kit = require './kit'
proxy = require './proxy'
{ version } = require '../package.json'
defaultOpts = require './default.config'

cmd
    .version version
    .usage  '\n\n    siteproxy config.coffee'
    .option '-u, --url', 'proxy url'
    .option '-i, --ip', 'force remote ip'
    .option '-p, --port', 'local server port'
    .parse process.argv

confFile = cmd.args[0]

try
    if '.coffee' is path.extname confFile
        require 'coffee-script/register'
    opts = require path.resolve(process.cwd(), confFile)
catch err
    if cmd.args.length > 0
        kit.err err.stack
    else
        kit.err 'No config specified!'.red
    process.exit 1

opts = kit.assign defaultOpts, opts

ip = kit.getIp()[0] or '127.0.0.1'
port = opts.port
try
    proxyHandler = proxy(opts)
catch e
    kit.err e.message.red
    process.exit 1

http.createServer (req, res) ->
    promise = proxyHandler(req, res)
    promise.catch (err) ->
        kit.err '>> proxy err!'.red
        kit.err err
.listen port

kit.log '\nProxy Site: '.cyan + opts.url
kit.log 'Server start at '.cyan + "#{ip}:#{port}"
