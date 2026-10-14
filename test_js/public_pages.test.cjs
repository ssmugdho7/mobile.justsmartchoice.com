const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {JSDOM} = require('jsdom');
for (const page of ['terms','privacy','cookie-policy','legal','sitemap','partners','investors','services','financing','blog','faqs','career','promo_flooring','charger','login']) {
  test(`${page} public snapshot bundles first-party assets and disables production forms`, () => {
    const dom = new JSDOM(fs.readFileSync(`preview_site/${page}.html`, 'utf8'));
    const document = dom.window.document;
    assert.equal(document.querySelectorAll('iframe').length, 0);
    assert.ok(document.querySelector('script[src="navigation.js"]'));
    for (const form of document.querySelectorAll('form')) {
      assert.equal(form.hasAttribute('action'), false);
      assert.ok([...form.querySelectorAll('input, select, textarea, button')].every(control => control.disabled));
    }
    for (const asset of document.querySelectorAll('script[src], link[rel="stylesheet"][href]')) {
      const source = asset.getAttribute('src') || asset.getAttribute('href');
      if (asset.tagName === 'LINK' && /^https:\/\/fonts\.googleapis\.com\/css/.test(source)) continue;
      assert.ok(source === 'navigation.js' || source.startsWith('resources/'), source);
      assert.ok(fs.existsSync(`preview_site/${source}`), source);
    }
    dom.window.close();
  });
}
