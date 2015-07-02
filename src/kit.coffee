colors = require 'colors'
toString = Object.prototype.toString

kit =
    log: () ->
        console.log.apply console, arguments

    err: (msg) ->
        console.error msg

    extend: (target) ->
        to = Object target

        i = 0
        l = arguments.length
        while ++i < l
            from = arguments[i]
            continue unless from?
            keys = Object.keys Object from

            j = keys.length
            while j--
                v = from[keys[j]]
                continue unless v?
                to[keys[j]] = v

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

    ###*
     * 将稀疏数组转换为密集数组
    ###
    compact: (arr) ->
        r = []
        i = arr?.length
        while i--
            r.unshift arr[i] if arr[i] isnt undefined
        r

    ###*
     * 只返回具有该类型的数据项的集合
     * @param {String} `type` 类型
    ###
    filterArrType: (arr, type) ->
        r = []
        i = arr?.length
        type = type.toLowerCase()
        while i--
            r.unshift arr[i] if type is kit.type(arr[i])
        r

    type: (mixin) ->
        tmp = toString.call(mixin).substr(8)
        tmp.toLowerCase().substr 0, tmp.length-1

    open: (args) ->
        switch process.platform
            when 'darwin' then cmd = 'open '
            when 'win32' then cmd = 'start'
        require 'child_process'
            .exec cmd + args

module.exports = kit
