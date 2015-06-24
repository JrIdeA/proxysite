module.exports = {
  url: '',
  ip: null,
  port: 8234,
  pathMap: {},
  replaceBody: [],
  autoRedirect: false,
  replaceLimit: 1048576,
  handleReqHeaders: function(headers) {
    return headers;
  },
  handleResHeaders: function(headers) {
    return headers;
  },
  beforeProxy: null,
  afterProxy: null
};
