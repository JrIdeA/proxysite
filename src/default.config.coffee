module.exports =
    url: ''
    ip: null
    port: 8234
    keepPathname: false
    pathMap: {}
    replaceBody: []
    autoRedirect: false
    replaceLimit: 1048576 # 1024 * 1024
    handleReqHeaders: (headers) -> headers
    handleResHeaders: (headers) -> headers
    beforeProxy: null
    afterProxy: null
