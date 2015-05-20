代理网站，具有文本内容替换和地址重定向功能

## 用例
```
proxysite config.coffee
```

## 配置文件
配置文件支持 .coffee 与 .js 后缀，配置需要用 module.exports 导出
以下是一个配置文件的实例，
也是所有的选项和默认值
```coffee
module.exports =
    # 需要代理的网站
    # String or Url Object
    url: ''

    # 本机端口
    port: 8234

    # 访问的url做替换
    urlMap: {}

    # 替换内容，只针对文本的 content-type 做替换,
    # 支持正则，若需要使用正则，key使用 '/reg/' 这样的形式
    contentMap: {}

    # 自定义修改request的headers
    reqHeaders: (headers) -> headers

    # 自定义修改respond的headers
    resHeaders: (headers) -> headers
```

## TODO
- [] 基本实现
- [] 可编程接口
- [] https的支持
