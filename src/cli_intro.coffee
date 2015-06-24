require 'colors'
cmd = require 'commander'
path = require 'path'
http = require 'http'
kit = require './kit'
proxy = require './proxy'
fs = require 'fs'
{ version } = require '../package.json'
defaultOpts = require './default.config'

cmd
    .version version
    .usage  '\n\n   $ siteproxy config.js\n   $ siteproxy -u jrist.me'
    .option '-u, --url [url]', "proxy site's url"
    .option '-i, --ip [ip]', "force proxy site's ip"
    .option '-p, --port <port>', 'local server port'
    .option '-o, --openpage', 'open proxy page when proxy starting'
    .parse process.argv

confFile = cmd.args[0]
cmdOpts = {
    url: cmd.url
    ip: cmd.ip
    port: cmd.port
}

try
    if '.coffee' is path.extname confFile
        require 'coffee-script/register'
    opts = require path.resolve(process.cwd(), confFile)
catch err
    if cmd.args.length > 0
        kit.err err.stack
        process.exit 1
    else
        kit.log 'No config file specified!'.yellow

opts = kit.extend defaultOpts, cmdOpts, opts

ip = kit.getIp()[0] or '127.0.0.1'
port = opts.port
try
    # load plugins
    pluginsDir = __dirname + '/plugins/'
    pluginsFiles = fs.readdirSync(pluginsDir).map (n) ->  pluginsDir + path.basename(n, '.js')
    if pluginsFiles.length
        kit.log '>> Loading plugins:'.cyan
        beforeProxyArr = [opts.beforeProxy]
        afterProxyArr = [opts.afterProxy]
        pluginsFiles.map (n) ->
            plugin = require n
            opts = kit.extend opts, plugin.opts
            beforeProxyArr.unshift plugin.beforeProxy
            afterProxyArr.unshift plugin.afterProxy
            kit.log '    ' + plugin.name + ' [loaded]'.green
        beforeProxyArr = kit.filterArrType beforeProxyArr, 'function'
        afterProxyArr = kit.filterArrType afterProxyArr, 'function'
        opts.beforeProxy = ->
            n.apply(@, arguments) for n in beforeProxyArr
        opts.afterProxy = ->
            n.apply(@, arguments) for n in afterProxyArr

    # initialize proxy!
    proxyHandler = proxy(opts)
catch e
    kit.err e.message.red
    kit.err e.stack
    process.exit 1

http.createServer (req, res) ->
    promise = proxyHandler(req, res)
    promise.catch (err) ->
        kit.err '>> proxy err!'.red
        kit.err err
.listen port

localServer = "#{ip}:#{port}"
kit.log '\nProxy Site: '.cyan + opts.url
kit.log 'Server start at '.cyan + localServer

if cmd.openpage
    kit.open "http://#{localServer}"
