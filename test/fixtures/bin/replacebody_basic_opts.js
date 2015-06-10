var config, proxy;

proxy = require('../../../dist/proxy');

config = {
  url: 'jrist.me',
  replaceBody: {"replace_from": "replace_to"}
};

proxy(config);
