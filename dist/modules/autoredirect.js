var url;

url = require('url');

module.exports = {
  name: 'autoRedirect',
  opts: {
    autoRedirect: false
  },
  afterProxy: function(proxyRes, requestParam) {
    var headers, locObj, location, sourceHost, statusCode, targetHost;
    statusCode = proxyRes.statusCode;
    headers = proxyRes.headers;
    if ((300 <= statusCode && statusCode < 400) && headers.location) {
      location = headers.location;
      locObj = url.parse(location);
      if (locObj.host) {
        targetHost = locObj.protocol + "//" + locObj.hostname + ":" + (locObj.port || 80);
        sourceHost = "http://" + requestParam.host + ":" + requestParam.port;
        if (targetHost !== sourceHost) {
          return;
        }
        location = locObj.pathname;
      }
    }
    return headers.location = location;
  }
};
