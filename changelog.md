### v0.3.0
- add: 添加`opts.keepPathname`选项用来保留`opts.url`中的 pathname
- upd: 将传递给代理的 headers 直接传递给 server

### v0.2.0
- add: 添加自动代理同域301、302的跳转，通过设置参数`autoRedirect: true`开启，只针对cli运行有效
- upd: 升级依赖`replacestream`至4.0

### v0.1.2
- fix: `afterProxy` 参数无效的情况

### v0.1.1
- 添加开启代理则自动打开网页选项 `-o`
