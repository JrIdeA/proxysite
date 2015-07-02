require 'colors'
coffee = require 'coffee-script'
kit = require 'nokit'
{ glob, path, Promise, log, fs } = kit
join = path.join

srcPath = 'src'
distPath = 'dist'

buildFiles = (files) ->
    Promise.all files.map (path) ->
        sourceReg = new RegExp("^#{srcPath}")
        jsPath = "#{path.replace(sourceReg, distPath).replace(/(\.coffee)$/, '')}.js"
        kit.readFile(path, 'utf8').then (str) ->
            try
                return coffee.compile(str, {bare: true})
            catch e
                log ">> Error: #{path} \n#{e}".red
        .then (code) ->
            kit.outputFile(jsPath, code).then ->
                log '>> Compiled: '.cyan + path

task 'dev', 'In dev, Watch all file', ->
    fs.watchDir srcPath, {
        pattern: '*.coffee'
        handler: (type, path) ->
            buildFiles([path])
    }

task 'build', 'Build all source code.', ->
    fs.remove distPath
    .catch (e) ->
        console.error e
        process.exit 1
    .then ->
        glob join(srcPath, '**', '*.coffee')
        .then (files) ->
            buildFiles(files)
