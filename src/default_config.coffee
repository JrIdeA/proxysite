module.exports =
    # 需要代理的网站
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
