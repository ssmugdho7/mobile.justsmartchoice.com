const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {JSDOM} = require('jsdom');
function calculator(name) {
  const dom = new JSDOM(fs.readFileSync(`preview_site/${name}.html`, 'utf8'), {runScripts: 'outside-only', url: 'https://mobile.justsmartchoice.com/preview/public-pages/'});
  for (const script of dom.window.document.querySelectorAll('script:not([src])')) dom.window.eval(script.textContent);
  return dom;
}
const cases = [
  ['calculator', {display:'2+3'}, 'calculate', /5/, 'display'],
  ['concretecalc', {width:10,length:10,depth:0.5,quantity:1}, 'calculateConcrete', /50\.00/, 'results'],
  ['feet-inches-calculator', {feet1:1,inches1:0,feet2:2,inches2:0,operation:'+'}, 'calculateFeetInches', /3 ft 0 in/, 'results'],
  ['flooring-calculator', {area:100,plankLength:4,plankWidth:1,waste:5}, 'calculateFlooring', /27 planks/, 'results'],
  ['paint-calculator', {wallLength:10,wallHeight:10,numWalls:1}, 'calculatePaint', /1 gallon/, 'results'],
  ['vinyl-fence-calculator', {linealFeet:80,insideCorners:0,outsideCorners:0,numGates:0}, 'calculateFence', /Total Posts Needed: 10/, 'results'],
];
for (const [name, values, fn, expected, output] of cases) {
  test(`${name} snapshot calculates without a server submission`, () => {
    const dom = calculator(name);
    for (const [id, value] of Object.entries(values)) {
      const input = dom.window.document.getElementById(id);
      assert.ok(input, id);
      input.value = value;
    }
    dom.window[fn]();
    const result = dom.window.document.getElementById(output);
    assert.match(result.value || result.textContent.replace(/\s+/g, ' '), expected);
    for (const form of dom.window.document.querySelectorAll('form')) assert.equal(form.hasAttribute('action'), false);
    dom.window.close();
  });
}
test('Public Forms and Contracts are bundled; commencement anchor is preserved', () => {
  for (const page of ['forms','contracts']) {
    const doc = new JSDOM(fs.readFileSync(`preview_site/${page}.html`, 'utf8')).window.document;
    assert.equal(doc.querySelectorAll('iframe').length, 0);
    if (page === 'forms') assert.ok(doc.getElementById('notice-of-commencement'));
    for (const form of doc.querySelectorAll('form')) assert.equal(form.hasAttribute('action'), false);
  }
});
test('Native Toolbox cards use current WebView; provider DOM is not modified', () => {
  const html='<a class="smart-toolbox-box" href="https://www.progressivecommercial.com/" target="_blank">Provider</a>';
  for (const [url, expected] of [['https://justsmartchoice.com/toolbox.php','_self'],['https://www.progressivecommercial.com/','_blank']]) {
    const dom = new JSDOM(html,{url,runScripts:'outside-only'});
    dom.window.eval(fs.readFileSync('assets/public_site_shell.js','utf8'));
    dom.window.document.dispatchEvent(new dom.window.Event('DOMContentLoaded'));
    assert.equal(dom.window.document.querySelector('a').target,expected);
    dom.window.close();
  }
});
