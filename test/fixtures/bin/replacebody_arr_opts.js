var config, proxy;

proxy = require('../../../dist/proxy');

config = {
  url: 'jrist.me',  
  replaceBody: [
    ["replace_from1", "replace_to1"],
    ["replace_from2", "replace_to2"]
  ]
};

proxy(config);
