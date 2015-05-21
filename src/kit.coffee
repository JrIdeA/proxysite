colors = require 'colors'

module.exports =
    log: () ->
        console.log.apply console, arguments
    err: (msg) ->
        console.error msg

    # ES6 Object.assign shim
    assign: Object.assign or (target, source) ->
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
     * Get a list of local ip address
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

    isObject: (value) ->
        !!value and typeof value is 'object'

    isEmptyOrNotObject: (value) ->
        return false if !this.isObject(value)
        for name of obj
            return false
        true

    isArray: Array.isArray

    isFullString: (value) ->
        typeof value is 'string' and value.length
