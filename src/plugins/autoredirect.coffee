module.exports = {
    name: 'autoRedirect'
    opts: {
        autoRedirect: false
        # handleReqLog: ->

    }
    beforeProxy: (requestParam) ->
        console.log 'plugin before proxy'

    afterProxy: (proxyRes) ->
        console.log 'plugin after proxy'
}
