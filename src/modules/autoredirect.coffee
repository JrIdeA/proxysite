url = require 'url'

module.exports = {
    name: 'autoRedirect'
    opts: {
        autoRedirect: false
    }
    afterProxy: (proxyRes, requestParam) ->
        statusCode = proxyRes.statusCode
        headers = proxyRes.headers
        if 300 <= statusCode < 400 and headers.location
            location = headers.location
            locObj = url.parse location
            # 绝对地址判断是否是同域
            if locObj.host
                targetHost = "#{locObj.protocol}//#{locObj.hostname}:#{locObj.port or 80}"
                sourceHost = "http://#{requestParam.host}:#{requestParam.port}"            
                if targetHost isnt sourceHost
                    return
                location = locObj.pathname

        headers.location = location
}
