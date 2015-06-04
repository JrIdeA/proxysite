var colors, kit, toString;

colors = require('colors');

toString = Object.prototype.toString;

kit = {
  log: function() {
    return console.log.apply(console, arguments);
  },
  err: function(msg) {
    return console.error(msg);
  },
  assign: Object.assign || function(target) {
    var from, i, j, keys, l, to;
    if (target == null) {
      throw new TypeError('Object.assign cannot be called with null or undefined');
    }
    to = Object(target);
    i = 1;
    l = arguments.length;
    while (i < l) {
      from = arguments[i];
      keys = Object.keys(Object(from));
      j = keys.length;
      while (j--) {
        to[keys[j]] = from[keys[j]];
      }
      i++;
    }
    return to;
  },

  /**
   * 获得本地的ip地址数组
   * @return {Array}
   */
  getIp: function() {
    var k, netObj, o, os, output, v;
    os = require('os');
    netObj = os.networkInterfaces();
    output = [];
    for (k in netObj) {
      v = netObj[k];
      if (Array.isArray(v)) {
        o = v.reduce(function(p, c, i) {
          if (c.family === 'IPv4' && !c.internal) {
            p.push(c.address);
          }
          return p;
        }, []);
      }
      output = output.concat(o);
    }
    return output;
  },
  isObject: function(obj) {
    return !!obj && '[object Object]' === toString.call(obj);
  },
  isEmptyOrNotObject: function(obj) {
    var name;
    if (!kit.isObject(obj)) {
      return true;
    }
    for (name in obj) {
      return false;
    }
    return true;
  },
  isArray: Array.isArray,
  isString: function(value) {
    return typeof value === 'string';
  },
  isFullString: function(value) {
    return typeof value === 'string' && value.length;
  },
  compact: function(arr) {
    var i, r;
    r = [];
    i = arr != null ? arr.length : void 0;
    while (i--) {
      if (arr[i] !== void 0) {
        r.unshift(arr[i]);
      }
    }
    return r;
  }
};

module.exports = kit;
