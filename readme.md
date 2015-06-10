# PROXYSITE
这是一个能够代理某个站点的工具，
具有文本内容替换和地址重定向等功能

## 用例
proxysite可以使用两种方式启动

### 使用CLI

直接运行命令
```
$ proxysite -u jrist.me -i 127.0.0.1 -p 8888
```
使用浏览器访问 `127.0.0.1:8888`


支持的参数为
```
-u, --url [url]    proxy site's url
-i, --ip [ip]      force proxy site's ip
-p, --port <port>  local server port
```

### 使用配置文件

使用配置文件可以提供更多高级功能。

编辑配置文件，比如 config.coffee
```coffee
module.exports =
    url: 'jrist.me'
    port: 8888
```

本机启动代理服务器
```
$ proxysite config.coffee
```
使用浏览器访问 `127.0.0.1:8888`

## 安装
```
$ npm install -g proxysite
```

## 配置文件
配置文件支持 .coffee 与 .js 后缀，配置需要用 module.exports 导出，
以下是一个配置文件的示例，
也是所有的选项和默认值
```coffee
module.exports =
    # 需要代理的网站
    # 类型为 String 或 Url 对象
    url: ''
    # 实际代理请求的ip地址，这个是可选的
    # 指定了则相当于设置了 hosts 文件
    ip: null

    # 本机开的server端口
    port: 8234

    # 访问的url做替换，完全匹配
    # '/abc' => '/bcd'
    pathMap: {}

    ###*
     * 替换内容，只针对文本的 content-type 做替换，支持正则表达式
     * 例如：
     * 1. 简单替换 replaceBody: {'a': 'b'}
     * 2. 正则替换 replaceBody: [/(\w+)\.ooo\.com/g, '$1.xxx.com']
     * 3. 多条匹配规则
     * replaceBody: [
     *     {'a': 'b'}
     *     [/(\w+)\.ooo\.com/g, '$1.xxx.com']
     * ]
    ###
    replaceBody: []

    # 内容替换默认处理小于 1MB 的文件，设置null则不限制大小
    replaceLimit: 1024 * 1024

    ###*
     * 自定义修改 request 的 headers，所有 headers 的 key为小写
     * 注意：referer 会在该回调之后替换代理hostname为目标地址的hostname，若有影响请使用beforeProxy进行处理
     * @param {Object} `headers` 发送给远端的 headers
     * @param {String} `urlPath` 当前请求的 url 的 path
    ###
    handleReqHeaders: (headers, urlPath) -> headers

    ###*
     * 自定义修改 respond 的 headers
     * 所有 headers 的 key 为小写
     * @param {Object} `headers` 目标地址返回的 headers
     * @param {String} `urlPath` 当前请求的 url 的 path
    ###
    handleResHeaders: (headers, urlPath) -> headers

    ###*
     * 在代理发送请求前执行该回调, 供高级定制
     * 注意：配置`opts.ip`的时候首先使用`requestParam.hostname`
     * @param {Object} `requestParam` 传递给代理请求 http.request 的参数
    ###
    beforeProxy: (requestParam) ->

    ###*
     * 在代理发送请求后执行该回调, 供高级定制
     * 注意：内容是直接 pipe 的，不提供修改
     * @param {Object} `proxyRes` 代理请求 http.request 返回的 response 对象
    ###
    afterProxy: (proxyRes) ->
```

## 可编程接口
将配置参数直接传递给 proxy，
返回函数接收两个参数:(req, res)，
该函数返回`Promise`。

例如：
```coffee
proxy = require 'proxysite'
http = require 'http'
handle = proxy opts
http.createServer (req, res) ->
    handle(req, res)
.listen 80
```

## TODO
- [ ] https的支持
- [ ] 301/302 自动跳转支持
