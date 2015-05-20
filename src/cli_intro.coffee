cmd = require 'commander'
path = require 'path'
cs = require 'colors/safe'
kit = require './kit'
{ version } = require '../package.json'
defaultConf = require './default_config'

cmd
    .version version
    .usage  '\n\n    siteproxy config.coffee'
    .parse process.argv

# configFile = cmd.args[0] or cmd.args[1]
# console.log cmd
confFile = cmd.args[1]

try
    if path.extname is '.coffee'
        require 'coffee-script/register'
    conf = require path.resolve(confFile)
catch err
    if cmd.args.length > 0
        kit.err err.stack
        process.exit 1
    else
        kit.err cs.red 'No config specified!'

conf = kit.assign defaultConf, conf
kit.log conf
