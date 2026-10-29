const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {JSDOM} = require('jsdom');
const script = fs.readFileSync('assets/staff_portal_mobile.js','utf8');
function fixture(url = 'https://crm.justsmartchoice.com/admin', width = 390) {
  const dom = new JSDOM(`<!doctype html><html lang="en"><head></head><body class="admin"><div id="wrapper"><div class="announcement"><a href="/admin/misc/dismiss_announcement/4">Close</a><h4>Announcement</h4><h4>Important <em>team</em> update</h4><div><p>Full notice text</p><a href="/media/training.mp4">Training video</a></div></div><div id="widget-top_stats">Primary metrics</div><div id="widget-user_data"><button>My tasks</button></div><div id="widget-calendar"><div class="widget-dragger"></div><div id="calendar"><button>Next</button></div></div><div id="widget-commission"><h4>Commission</h4><canvas></canvas></div><form><input type="hidden" name="csrf" value="original"><input name="subject" value="draft"></form></div></body></html>`,{url,runScripts:'outside-only'});
  let change;
  const media = {matches:width<768,addEventListener:(_,callback)=>{change=callback;}};
  dom.window.matchMedia = () => media;
  const advance = () => new Promise(resolve=>setImmediate(resolve));
  return {dom,advance,resize:(width)=>{media.matches=width<768;if(change)change();}};
}
test('staff notices collapse without dismissing or altering content/actions/form state', async () => {
  const {dom,advance} = fixture(); const w=dom.window,d=w.document;
  const close=d.querySelector('.announcement a'), video=d.querySelector('.announcement div a');
  let clicks=0;video.addEventListener('click',e=>{e.preventDefault();clicks++;});
  const originalForm=d.querySelector('form').outerHTML;
  w.eval(script);d.dispatchEvent(new w.Event('DOMContentLoaded'));await advance();
  const notice=d.querySelector('.sc-staff-notice details');
  assert.ok(notice);assert.equal(notice.open,false);
  assert.match(notice.querySelector('summary').textContent,/Important team update/);
  assert.strictEqual(d.querySelector('.sc-staff-notice-content > a'),close);
  assert.strictEqual(d.querySelector('.sc-staff-notice-content div a'),video);
  video.click();assert.equal(clicks,1);
  assert.equal(d.querySelector('form').outerHTML,originalForm);
  notice.open=true;await advance();assert.match(notice.textContent,/Full notice text/);
  assert.equal(d.querySelector('#widget-user_data button').textContent,'My tasks');
  assert.equal(d.querySelector('#widget-calendar details').open,false);
  assert.ok(d.querySelector('#widget-calendar > .widget-dragger'));
  w.eval(script);await advance();assert.equal(d.querySelectorAll('#sc-staff-mobile-style').length,1);
  assert.equal(d.querySelectorAll('.sc-staff-notice details').length,1);
  w.close();
});
test('late notices are enhanced once and desktop starts expanded', async () => {
  const {dom,advance}=fixture(undefined,1024);const w=dom.window,d=w.document;
  w.eval(script);d.dispatchEvent(new w.Event('DOMContentLoaded'));await advance();
  assert.equal(d.querySelector('.sc-staff-notice details').open,true);
  assert.equal(d.querySelector('#widget-calendar details').open,true);
  const notice=d.createElement('div');notice.className='announcement';notice.innerHTML='<h4>Late notice</h4><p>Keep all details</p>';
  d.querySelector('#wrapper').appendChild(notice);await advance();
  assert.equal(notice.querySelectorAll('details').length,1);assert.match(notice.textContent,/Keep all details/);
  w.close();
});
test('rotation exposes all content and returning to phone restores compact sections', async () => {
  const {dom,advance,resize}=fixture();const w=dom.window,d=w.document;
  w.eval(script);d.dispatchEvent(new w.Event('DOMContentLoaded'));await advance();
  assert.equal(d.querySelector('.sc-staff-details').open,false);
  resize(1024);assert.ok(Array.from(d.querySelectorAll('.sc-staff-details')).every(e=>e.open));
  resize(390);assert.ok(Array.from(d.querySelectorAll('.sc-staff-details')).every(e=>!e.open));
  assert.equal(d.querySelectorAll('#widget-calendar #calendar button').length,1);
  w.close();
});
for (const url of ['https://crm.justsmartchoice.com/clients/','https://crm.justsmartchoice.com/admin/authentication','https://dev.justsmartchoice.com/admin','https://other.example/admin']) {
  test('does not modify '+url, async()=>{const {dom,advance}=fixture(url);const html=dom.window.document.documentElement.outerHTML;dom.window.eval(script);await advance();assert.equal(dom.window.document.documentElement.outerHTML,html);dom.window.close();});
}
