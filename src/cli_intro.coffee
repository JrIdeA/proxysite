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

loadModules = (opts) ->
    modulesDir = __dirname + '/modules/'
    modulesFiles = fs.readdirSync(modulesDir).map (n) ->  modulesDir + path.basename(n, '.js')
    if modulesFiles.length
        kit.log 'Loading modules'.cyan
        beforeProxyArr = [opts.beforeProxy]
        afterProxyArr = [opts.afterProxy]
        modulesFiles.map (n) ->
            module = require n
            if kit.isFunction module
                module = module(opts)

            return if not kit.isObject module
            opts = kit.extend opts, module.opts
            beforeProxyArr.unshift module.beforeProxy
            afterProxyArr.unshift module.afterProxy
            kit.log '    ' + module.name + ' [loaded]'.green
        beforeProxyArr = kit.filterArrType beforeProxyArr, 'function'
        afterProxyArr = kit.filterArrType afterProxyArr, 'function'
        opts.beforeProxy = ->
            n.apply(@, arguments) for n in beforeProxyArr
        opts.afterProxy = ->
            n.apply(@, arguments) for n in afterProxyArr
    opts

try
    opts = loadModules(opts)
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
