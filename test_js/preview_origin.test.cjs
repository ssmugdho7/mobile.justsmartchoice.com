const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const html = fs.readFileSync('web/index.html', 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
function destination(url) {
  const parsed = new URL(url);
  let result = null;
  vm.runInNewContext(script, { location: {
    hostname: parsed.hostname, pathname: parsed.pathname, search: parsed.search, hash: parsed.hash,
    replace(value) { result = value; }
  } });
  return result;
}
test('GitHub preview uses same-site mobile host in the current tab', () => {
  assert.equal(destination('https://ssmugdho7.github.io/mobile.justsmartchoice.com/?v=test#home'),
    'https://mobile.justsmartchoice.com/preview/?v=test#home');
});
test('canonical preview, local development and unrelated GitHub projects do not redirect', () => {
  for (const url of ['https://mobile.justsmartchoice.com/preview/', 'http://localhost:8767/',
    'https://ssmugdho7.github.io/another-project/']) {
    assert.equal(destination(url), null);
  }
});
