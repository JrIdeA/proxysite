colors = require 'colors'
toString = Object.prototype.toString

kit =
    log: () ->
        console.log.apply console, arguments

    err: (msg) ->
        console.error msg

    # ES6 Object.assign shim
    assign: Object.assign or (target) ->
        unless target?
            throw new TypeError('Object.assign cannot be called with null or undefined')
        to = Object target

        i = 1
        l = arguments.length
        while i < l
            from = arguments[i]
            keys = Object.keys Object from

            j = keys.length
            while j--
                to[keys[j]] = from[keys[j]]
            i++

        to

    ###*
     * 获得本地的ip地址数组
     * @return {Array}
    ###
    getIp: ->
        os = require 'os'
        netObj = os.networkInterfaces()
        output = []
        for k, v of netObj
            if Array.isArray(v)
                o = v.reduce( (p, c, i) ->
                    if c.family is 'IPv4' and !c.internal
                        p.push c.address
                    p
                [])
            output = output.concat o
        output

    isObject: (obj) ->
        !!obj and '[object Object]' is toString.call obj

    isEmptyOrNotObject: (obj) ->
        return true if !kit.isObject(obj)
        for name of obj
            return false
        true

    isArray: Array.isArray

    isString: (value) ->
        typeof value is 'string'

    isFullString: (value) ->
        typeof value is 'string' and value.length

    # 将稀疏数组转换为密集数组
    compact: (arr) ->
        r = []
        i = arr?.length
        while i--
            r.unshift arr[i] if arr[i] isnt undefined
        r

module.exports = kit
