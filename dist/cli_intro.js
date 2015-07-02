var cmd, cmdOpts, confFile, defaultOpts, e, err, fs, http, ip, kit, loadModules, localServer, opts, path, port, proxy, proxyHandler, version;

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

loadModules = function(opts) {
  var afterProxyArr, beforeProxyArr, modulesDir, modulesFiles;
  modulesDir = __dirname + '/modules/';
  modulesFiles = fs.readdirSync(modulesDir).map(function(n) {
    return modulesDir + path.basename(n, '.js');
  });
  if (modulesFiles.length) {
    kit.log('>> Loading modules:'.cyan);
    beforeProxyArr = [opts.beforeProxy];
    afterProxyArr = [opts.afterProxy];
    modulesFiles.map(function(n) {
      var module;
      module = require(n);
      if (kit.isFunction(module)) {
        module = module(opts);
      } else if (!kit.isObject(module)) {
        return;
      }
      opts = kit.extend(opts, module.opts);
      beforeProxyArr.unshift(module.beforeProxy);
      afterProxyArr.unshift(module.afterProxy);
      return kit.log('    ' + module.name + ' [loaded]'.green);
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
  return opts;
};

try {
  opts = loadModules(opts);
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
