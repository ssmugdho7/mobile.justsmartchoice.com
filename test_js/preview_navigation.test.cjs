const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {JSDOM} = require('jsdom');
test('copied public links send navigation to the mobile parent instead of opening tabs', () => {
  const dom = new JSDOM('<a href="https://justsmartchoice.com/toolbox.php" target="_blank">Toolbox</a>', {
    url:'https://ssmugdho7.github.io/mobile.justsmartchoice.com/public-pages/home.html',
    referrer:'https://mobile.justsmartchoice.com/preview/',runScripts:'outside-only',
  });
  const messages=[];
  dom.window.parent.postMessage = (message,origin) => messages.push({message,origin});
  dom.window.eval(fs.readFileSync('preview_site/navigation.js','utf8'));
  const event = new dom.window.MouseEvent('click',{bubbles:true,cancelable:true});
  dom.window.document.querySelector('a').dispatchEvent(event);
  assert.equal(event.defaultPrevented,true);
  assert.equal(messages.length,1);
  assert.equal(messages[0].message.url,'https://justsmartchoice.com/toolbox.php');
  assert.equal(messages[0].origin,'https://mobile.justsmartchoice.com');
  dom.window.close();
});
