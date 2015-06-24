module.exports = {
  name: 'autoRedirect',
  opts: {
    autoRedirect: false
  },
  beforeProxy: function(requestParam) {
    return console.log('plugin before proxy');
  },
  afterProxy: function(proxyRes) {
    return console.log('plugin after proxy');
  }
};
