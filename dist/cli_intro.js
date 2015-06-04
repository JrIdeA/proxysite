var cmd, cmdOpts, confFile, defaultOpts, e, err, http, ip, kit, opts, path, port, proxy, proxyHandler, version;

require('colors');

cmd = require('commander');

path = require('path');

http = require('http');

kit = require('./kit');

proxy = require('./proxy');

version = require('../package.json').version;

defaultOpts = require('./default.config');

cmd.version(version).usage('\n\n   $ siteproxy config.js\n   $ siteproxy -u jrist.me').option('-u, --url [url]', 'proxy url').option('-i, --ip [ip]', 'force remote ip').option('-p, --port <port>', 'local server port').parse(process.argv);

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
