var afterProxyArr, beforeProxyArr, cmd, cmdOpts, confFile, defaultOpts, e, err, fs, http, ip, kit, localServer, opts, path, pluginsDir, pluginsFiles, port, proxy, proxyHandler, version;

require('colors');

cmd = require('commander');

path = require('path');

http = require('http');

kit = require('./kit');

proxy = require('./proxy');

fs = require('fs');

version = require('../package.json').version;

defaultOpts = require('./default.config');

cmd.version(version).usage('\n\n   $ siteproxy config.js\n   $ siteproxy -u jrist.me').option('-u, --url [url]', "proxy site's url").option('-i, --ip [ip]', "force proxy site's ip").option('-p, --port <port>', 'local server port').option('-o, --openpage', 'open proxy page when proxy starting').parse(process.argv);

confFile = cmd.args[0];

cmdOpts = {
  url: cmd.url,
  ip: cmd.ip,
  port: cmd.port
};

try {
  if ('.coffee' === path.extname(confFile)) {
    require('coffee-script/register');
  }
  opts = require(path.resolve(process.cwd(), confFile));
} catch (_error) {
  err = _error;
  if (cmd.args.length > 0) {
    kit.err(err.stack);
    process.exit(1);
  } else {
    kit.log('No config file specified!'.yellow);
  }
}

opts = kit.extend(defaultOpts, cmdOpts, opts);

ip = kit.getIp()[0] || '127.0.0.1';

port = opts.port;

try {
  pluginsDir = __dirname + '/plugins/';
  pluginsFiles = fs.readdirSync(pluginsDir).map(function(n) {
    return pluginsDir + path.basename(n, '.js');
  });
  if (pluginsFiles.length) {
    kit.log('>> Loading plugins:'.cyan);
    beforeProxyArr = [opts.beforeProxy];
    afterProxyArr = [opts.afterProxy];
    pluginsFiles.map(function(n) {
      var plugin;
      plugin = require(n);
      opts = kit.extend(opts, plugin.opts);
      beforeProxyArr.unshift(plugin.beforeProxy);
      afterProxyArr.unshift(plugin.afterProxy);
      return kit.log('    ' + plugin.name + ' [loaded]'.green);
    });
    beforeProxyArr = kit.filterArrType(beforeProxyArr, 'function');
    afterProxyArr = kit.filterArrType(afterProxyArr, 'function');
    opts.beforeProxy = function() {
      var i, len, n, results;
      results = [];
      for (i = 0, len = beforeProxyArr.length; i < len; i++) {
        n = beforeProxyArr[i];
        results.push(n.apply(this, arguments));
      }
      return results;
    };
    opts.afterProxy = function() {
      var i, len, n, results;
      results = [];
      for (i = 0, len = afterProxyArr.length; i < len; i++) {
        n = afterProxyArr[i];
        results.push(n.apply(this, arguments));
      }
      return results;
    };
  }
  proxyHandler = proxy(opts);
} catch (_error) {
  e = _error;
  kit.err(e.message.red);
  kit.err(e.stack);
  process.exit(1);
}

http.createServer(function(req, res) {
  var promise;
  promise = proxyHandler(req, res);
  return promise["catch"](function(err) {
    kit.err('>> proxy err!'.red);
    return kit.err(err);
  });
}).listen(port);

localServer = ip + ":" + port;

kit.log('\nProxy Site: '.cyan + opts.url);

kit.log('Server start at '.cyan + localServer);

if (cmd.openpage) {
  kit.open("http://" + localServer);
}
