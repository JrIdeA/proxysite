var Promise, TEXT_MIME, colors, cookieReplace, createReplaceStream, formatHeaders, formatReplaceOpt, http, ip, isReplaceContent, kit, proxy, replace, resInnerError, urlKit, zlib,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

http = require('http');

urlKit = require('url');

colors = require('colors');

replace = require('replacestream');

zlib = require('zlib');

Promise = require('bluebird');

kit = require('./kit');

ip = kit.getIp()[0] || '127.0.0.1';

TEXT_MIME = ['application/json', 'application/javascript'];

formatHeaders = function(headers) {
  var k, newHeaders, nk, v;
  newHeaders = {};
  for (k in headers) {
    v = headers[k];
    nk = k.replace(/(\w)(\w*)/g, function(m, p1, p2) {
      return p1.toUpperCase() + p2;
    });
    newHeaders[nk] = v;
  }
  return newHeaders;
};


/**
 * 格式化 replaceBody 的配置
 * @return {Array|null} [ [replaceKey, replaceValue], ... ] 这样的格式
 */

formatReplaceOpt = function(opt, sub) {
  var i, j, k, len, n, optLen, r, v;
  r = [];
  if (kit.isObject(opt)) {
    for (k in opt) {
      v = opt[k];
      r.push([k, String(v)]);
    }
  } else if (kit.isArray(opt)) {
    optLen = opt.length;
    if (sub) {
      if (opt.length >= 2) {
        r.push([opt[0], String(opt[1])]);
      }
    } else {
      if (opt.length >= 2 && !kit.isArray(opt[0]) && kit.isString(opt[1])) {
        r = r.concat(formatReplaceOpt(opt, true));
      } else {
        for (i = j = 0, len = opt.length; j < len; i = ++j) {
          n = opt[i];
          r = r.concat(formatReplaceOpt(n, true));
        }
      }
    }
  }
  if (r.length > 0 || sub) {
    return r;
  } else {
    return null;
  }
};

createReplaceStream = function(formatOpt) {
  var i, j, len, n, r;
  r = [];
  for (i = j = 0, len = formatOpt.length; j < len; i = ++j) {
    n = formatOpt[i];
    r.push(replace(n[0], n[1]));
  }
  return r;
};

isReplaceContent = function(opts, resHeaders) {
  var contentType;
  if (!resHeaders['content-type']) {
    return false;
  }
  contentType = resHeaders['content-type'].split(';')[0];
  if (opts.replaceBody && (contentType.substr(0, 5) === 'text/' || indexOf.call(TEXT_MIME, contentType) >= 0) && (!('content-length' in resHeaders) || !+opts.replaceLimit || resHeaders['content-length'] < opts.replaceLimit)) {
    return true;
  }
  return false;
};

cookieReplace = function(cookieArr, fromHostname, toHostname) {
  var REG, matchedCookie;
  matchedCookie = '.' + toHostname;
  REG = /;\s*domain=([^;]+)\s*(;|$)/;
  cookieArr = cookieArr.map(function(cookie) {
    var index, matched, matchedArr, r;
    if (matchedArr = REG.exec(cookie)) {
      matched = matchedArr[1];
      index = matchedCookie.lastIndexOf(matched);
      if (~index && index === matchedCookie.length - matched.length) {
        r = cookie.replace(REG, function(str, p1, p2, offset) {
          return "; domain=" + fromHostname + p2;
        });
        return r;
      }
    }
    return void 0;
  });
  return kit.compact(cookieArr);
};

resInnerError = function(res) {
  res.statusCode = 500;
  res._headers = null;
  return res.end();
};

proxy = function(opts) {
  var j, len, n, ref, to;
  if (!(opts && opts.url)) {
    throw new Error('No proxy url specified!');
  }
  opts.replaceBody = formatReplaceOpt(opts.replaceBody);
  if (opts.replaceBody) {
    kit.log('\n>> replace body:'.cyan);
    ref = opts.replaceBody;
    for (j = 0, len = ref.length; j < len; j++) {
      n = ref[j];
      kit.log('  '.cyan + n[0] + ' -> '.green + n[1]);
    }
  }
  to = opts.url;
  if (kit.isObject(to)) {
    if (to.protocol == null) {
      to.protocol = 'http:';
    }
  } else {
    if (to.indexOf('http') !== 0) {
      to = 'http://' + to;
    }
    to = urlKit.parse(to);
    if (to.protocol == null) {
      to.protocol = 'http:';
    }
    delete to.host;
  }
  return function(req, res) {
    return new Promise(function(resolve, reject) {
      var from, path, pathname, proxyErrorHandle, proxyHeaderHandle, proxyReq, proxyResHandle, ref1, reqHeaders, requestParam, resPipeError, search, toHost;
      resPipeError = function(err) {
        res.end();
        return reject(err);
      };
      proxyResHandle = function(proxyRes) {
        var allStream, resHeaders, unzip, upStream, zip;
        resHeaders = proxyRes.headers;
        if (!isReplaceContent(opts, resHeaders)) {
          return proxyRes.pipe(res);
        } else {
          allStream = createReplaceStream(opts.replaceBody);
          upStream = proxyRes;
          switch (resHeaders['content-encoding']) {
            case 'gzip':
              unzip = zlib.createGunzip();
              zip = zlib.createGzip();
              break;
            case 'deflate':
              unzip = zlib.createInflate();
              zip = zlib.createDeflate();
              break;
            default:
              unzip = null;
          }
          if (unzip) {
            unzip.on('error', resPipeError);
            allStream.unshift(unzip);
            allStream.push(zip);
          }
          allStream.push(res);
          allStream.forEach(function(stream) {
            return upStream = upStream.pipe(stream);
          });
          proxyRes.on('error', resPipeError);
          res.on('error', resPipeError);
          return res.on('finish', function() {
            kit.log((" done << (" + res.statusCode + ") ").green + toHost);
            return resolve(res);
          });
        }
      };
      proxyHeaderHandle = function(proxyRes) {
        var resHeaders;
        opts.afterProxy && opts.afterProxy(proxyRes, requestParam, req, res);
        if (opts.handleResHeaders) {
          resHeaders = opts.handleResHeaders(proxyRes.headers, path);
        } else {
          resHeaders = proxyRes.headers;
        }
        if (!kit.isEmptyOrNotObject(resHeaders)) {
          if (resHeaders['set-cookie']) {
            resHeaders['set-cookie'] = cookieReplace(resHeaders['set-cookie'], from.hostname, to.hostname);
          }
        }
        if (opts.replaceBody) {
          delete resHeaders['content-length'];
        }
        resHeaders = formatHeaders(resHeaders);
        return res.writeHead(proxyRes.statusCode, resHeaders);
      };
      proxyErrorHandle = function(e) {
        var ref1;
        if (e && ((ref1 = e.code) === 'ECONNREFUSED' || ref1 === 'ENOTFOUND')) {
          kit.log(' fail << '.red + toHost + " (unreachable)".red);
          res.statusCode = 503;
          res.end();
          return resolve(res);
        } else {
          return resPipeError(e);
        }
      };
      ref1 = urlKit.parse(req.url), pathname = ref1.pathname, search = ref1.search;
      if (!kit.isEmptyOrNotObject(opts.pathMap)) {
        pathname = opts.pathMap[pathname] || pathname;
      }
      search = search ? search : '';
      path = pathname + search;
      from = urlKit.parse('http://' + req.headers.host);
      if (opts.handleReqHeaders) {
        reqHeaders = opts.handleReqHeaders(req.headers, path) || {};
      }
      reqHeaders = formatHeaders(reqHeaders);
      reqHeaders.Host = to.hostname;
      if (reqHeaders.Referer) {
        reqHeaders.Referer = reqHeaders.Referer.replace("http://" + from.host + "/", "http://" + to.hostname + "/");
      }
      requestParam = {
        host: to.hostname,
        port: to.port || 80,
        method: req.method,
        path: path,
        headers: reqHeaders
      };
      if (opts.ip) {
        requestParam.hostname = opts.ip;
      }
      opts.beforeProxy && opts.beforeProxy(requestParam, req, res);
      toHost = 'http://' + requestParam.host + ':' + requestParam.port + requestParam.path;
      if (requestParam.hostname) {
        toHost += (" (" + requestParam.hostname + ")").cyan;
      }
      kit.log('proxy >> '.yellow + toHost);
      proxyReq = http.request(requestParam, proxyResHandle);
      proxyReq.on('response', proxyHeaderHandle);
      proxyReq.on('error', proxyErrorHandle);
      req.on('error', resPipeError);
      return req.pipe(proxyReq);
    });
  };
};

module.exports = proxy;
