var cmd, confFile, defaultOpts, e, err, http, ip, kit, opts, path, port, proxy, proxyHandler, version;

require('colors');

cmd = require('commander');

path = require('path');

http = require('http');

kit = require('./kit');

proxy = require('./proxy');

version = require('../package.json').version;

defaultOpts = require('./default.config');

cmd.version(version).usage('\n\n    siteproxy config.coffee').parse(process.argv);

confFile = cmd.args[0] || cmd.args[1];

try {
  if ('.coffee' === path.extname(confFile)) {
    require('coffee-script/register');
  }
  opts = require(path.resolve(process.cwd(), confFile));
} catch (_error) {
  err = _error;
  if (cmd.args.length > 0) {
    kit.err(err.stack);
  } else {
    kit.err('No config specified!'.red);
  }
  process.exit(1);
}

opts = kit.assign(defaultOpts, opts);

ip = kit.getIp()[0] || '127.0.0.1';

port = opts.port;

try {
  proxyHandler = proxy(opts);
} catch (_error) {
  e = _error;
  kit.err(e.message.red);
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

kit.log('\nProxy Site: '.cyan + opts.url);

kit.log('Server start at '.cyan + (ip + ":" + port));
