// Generated by CoffeeScript 1.9.1
var _, assert, exec, proxy;

assert = require('assert');

exec = require('child_process').exec;

_ = require('nokit')._;

proxy = require('../dist/proxy');

describe('cli', function() {
  it('读取.coffee配置文件并生效', function(done) {
    return exec('../bin/siteproxy.js ./fixtures/config.coffee', {
      timeout: 1500,
      cwd: __dirname
    }, function(err, stdout, stderr) {
      assert.ok(~stdout.indexOf('jrist.me'));
      return done();
    });
  });
  return it('读取.js配置文件并生效', function(done) {
    return exec('../bin/siteproxy.js ./fixtures/config.js', {
      timeout: 1500,
      cwd: __dirname
    }, function(err, stdout, stderr) {
      assert.ok(~stdout.indexOf('jrist.me'));
      return done();
    });
  });
});

describe('proxy', function() {
  return it('proxy返回函数', function() {
    return assert.ok(_.isFunction(proxy({
      url: 'jrist.me'
    })));
  });
});
