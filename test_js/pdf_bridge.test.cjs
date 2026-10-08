const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {JSDOM} = require('jsdom');
const script = fs.readFileSync('assets/pdf_download_bridge.js', 'utf8')
  .replace('"__SC_NONCE__"', '"fixture-nonce"')
  .replace('"__SC_ORIGIN__"', '"https://crm.justsmartchoice.com"');

async function scenario({html, origin = 'https://crm.justsmartchoice.com/invoice/1/hash',
    mime = 'application/pdf', status = true, size, actionName, chunks} = {}) {
  const dom = new JSDOM(html || '<form method="post"><input name="csrf" value="fixture-token"><button name="invoicepdf" value="invoicepdf">PDF</button></form>',
    {url: origin, runScripts: 'outside-only'});
  const {window} = dom;
  const calls = [], exports = [];
  const pdf = Uint8Array.from(Buffer.from('%PDF-1.7\nfixture'));
  window.fetch = async (url, options) => {
    calls.push({url, options});
    let index = 0;
    return {ok: status, headers: {get: key => ({'content-type': mime, 'content-length': size,
      'content-disposition': 'attachment; filename="Invoice.pdf"'})[key] || null},
      body: {getReader: () => ({read: async () => {
        const values = chunks || [pdf];
        return index < values.length ? {done: false, value: values[index++]} : {done: true};
      }, cancel: async () => {}})}};
  };
  window.flutter_inappwebview = {callHandler: async (...args) => {exports.push(args); return true;}};
  window.eval(script);
  const form = window.document.querySelector('form');
  const button = window.document.querySelector('button');
  // Chromium exposes named form controls ahead of built-in properties.
  // CI's hidden action field must not replace the form destination URL.
  if (form.querySelector('[name=action]')) Object.defineProperty(form, 'action', {value: form.querySelector('[name=action]')});
  if (actionName) form.querySelector('[name=action]').value = actionName;
  const event = new window.SubmitEvent('submit', {bubbles: true, cancelable: true, submitter: button});
  form.dispatchEvent(event);
  await new Promise(setImmediate);
  return {dom, calls, exports, event, button};
}
test('PDF POST retains clicked button, CSRF and same-origin credentials', async () => {
  const r = await scenario();
  assert.equal(r.event.defaultPrevented, true);
  assert.equal(r.calls.length, 1);
  const request = r.calls[0];
  assert.equal(request.options.method, 'POST');
  assert.equal(request.options.credentials, 'same-origin');
  assert.equal(request.options.redirect, 'error');
  assert.equal(request.options.body.get('csrf'), 'fixture-token');
  assert.equal(request.options.body.get('invoicepdf'), 'invoicepdf');
  assert.equal(r.exports[0][0], 'scExportPdf');
  assert.equal(r.exports[0][1], 'fixture-nonce');
  assert.equal(r.exports[0][2], 'save');
  assert.equal(r.exports[0][3], 'Invoice.pdf');
  assert.equal(Buffer.from(r.exports[0][4], 'base64').toString(), '%PDF-1.7\nfixture');
  assert.equal(r.button.disabled, false);
  r.dom.window.close();
});
test('Estimate and payment buttons preserve their own PDF field values', async () => {
  for (const name of ['estimatepdf', 'paymentpdf']) {
    const r = await scenario({html: `<form method="post"><input name="csrf" value="token"><button name="${name}" value="31">PDF</button></form>`});
    assert.equal(r.calls[0].options.body.get(name), '31');
    r.dom.window.close();
  }
});
test('Contract and proposal PDF forms retain their hidden action', async () => {
  for (const name of ['proposal_pdf', 'contract_pdf']) {
    const r = await scenario({html: `<form method="post"><input name="action" value="${name}"><input name="csrf" value="token"><button>PDF</button></form>`});
    assert.equal(r.calls[0].options.body.get('action'), name);
    assert.equal(r.calls[0].url, 'https://crm.justsmartchoice.com/invoice/1/hash');
    r.dom.window.close();
  }
});
test('Payment, approval, signature and upload submissions are left untouched', async () => {
  for (const name of ['pay_invoice', 'accept_proposal', 'sign_contract', 'upload']) {
    const r = await scenario({html: `<form method="post"><input name="action" value="${name}"><button>Submit</button></form>`});
    assert.equal(r.event.defaultPrevented, false);
    assert.equal(r.calls.length, 0);
    assert.equal(r.exports.length, 0);
    r.dom.window.close();
  }
});
test('Cross-origin forms and third-party frames cannot invoke PDF capture', async () => {
  const cases = [
    {html: '<form method="post" action="https://other.example/pdf"><button name="invoicepdf">PDF</button></form>'},
    {origin: 'https://meet.jit.si/room'},
    {origin: 'https://crm.justsmartchoice.com.evil.test/'},
  ];
  for (const data of cases) {
    const r = await scenario(data);
    assert.equal(r.event.defaultPrevented, false);
    assert.equal(r.calls.length, 0);
    assert.equal(r.exports.length, 0);
    r.dom.window.close();
  }
});
test('Login HTML, server errors and large PDFs show failure without exporting', async () => {
  for (const options of [{mime: 'text/html'}, {status: false}, {size: String(11 * 1024 * 1024)},
    {chunks: [new Uint8Array(10 * 1024 * 1024 + 1)]}]) {
    const r = await scenario(options);
    assert.equal(r.exports.length, 1);
    assert.equal(r.exports[0][2], 'error');
    assert.equal(r.button.disabled, false);
    r.dom.window.close();
  }
});
