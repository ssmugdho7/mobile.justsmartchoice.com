// Refresh only the two public marketing pages, never authenticated CRM content.
const fs = require('node:fs/promises');
const path = require('node:path');
const crypto = require('node:crypto');
const { JSDOM } = require('jsdom');
async function main() {
  const directory = path.resolve(__dirname, '../preview_site');
  await fs.mkdir(directory, { recursive: true });
  const resources = path.join(directory, 'resources');
  await fs.mkdir(resources, { recursive: true });
  const cache = new Map();
  async function rewriteUrls(text, base, prefix) {
    const matches = [...text.matchAll(/url\(\s*['"]?([^'"\)]+)['"]?\s*\)/g)];
    for (const match of matches) {
      const file = await asset(match[1], base);
      if (file) text = text.replace(match[0], `url('${prefix}${file}')`);
    }
    return text;
  }
  async function asset(value, base) {
    if (!value || /^(data:|blob:|#)/.test(value)) return null;
    const url = new URL(value, base);
    if (!['justsmartchoice.com', 'www.justsmartchoice.com'].includes(url.hostname)) return null;
    const extension = path.extname(url.pathname) || '.bin';
    const name = crypto.createHash('sha256').update(url.href).digest('hex').slice(0, 20) + extension;
    if (!cache.has(url.href)) {
      cache.set(url.href, (async () => {
        const response = await fetch(url, { signal: AbortSignal.timeout(30000) });
        if (!response.ok) throw new Error(`Public asset unavailable: ${url.pathname}`);
        let bytes = Buffer.from(await response.arrayBuffer());
        if (bytes.length > 20 * 1024 * 1024) throw new Error('Public asset exceeds preview size limit');
        if (extension === '.css') bytes = Buffer.from(await rewriteUrls(bytes.toString(), url, ''));
        await fs.writeFile(path.join(resources, name), bytes);
        return name;
      })());
    }
    return cache.get(url.href);
  }
  for (const [name, route] of [['home', '/'], ['about', '/about.php']]) {
    const url = new URL(route, 'https://justsmartchoice.com');
    const response = await fetch(url, { signal: AbortSignal.timeout(30000) });
    if (!response.ok || new URL(response.url).hostname !== url.hostname) throw new Error('Public page unavailable');
    const dom = new JSDOM(await response.text());
    const document = dom.window.document;
    document.querySelectorAll('base, meta[http-equiv], iframe').forEach(node => node.remove());
    const base = document.createElement('base');
    base.href = './';
    document.head.prepend(base);
    document.querySelectorAll('script').forEach(script => {
      const source = script.getAttribute('src');
      if (source && new URL(source, url).hostname !== url.hostname) script.remove();
      if (!source && /gtag|dataLayer|ahrefs|crm\.justsmartchoice|pusher/i.test(script.textContent)) script.remove();
    });
    // Bundle public assets because the website's CORP rules block cross-site loads.
    const elements = [...document.querySelectorAll('img[src], script[src], link[rel="stylesheet"][href], link[rel="icon"][href]')];
    for (let start = 0; start < elements.length; start += 6) {
      await Promise.all(elements.slice(start, start + 6).map(async element => {
        const attribute = element.hasAttribute('src') ? 'src' : 'href';
        const file = await asset(element.getAttribute(attribute), url);
        if (file) element.setAttribute(attribute, `resources/${file}`);
        else element.setAttribute(attribute, new URL(element.getAttribute(attribute), url).href);
      }));
    }
    for (const element of document.querySelectorAll('[srcset]')) {
      const values = [];
      for (const entry of element.getAttribute('srcset').split(',')) {
        const [value, size] = entry.trim().split(/\s+/);
        const file = await asset(value, url);
        values.push(`${file ? 'resources/' + file : value}${size ? ' ' + size : ''}`);
      }
      element.setAttribute('srcset', values.join(', '));
    }
    for (const element of document.querySelectorAll('[style]')) {
      element.setAttribute('style', await rewriteUrls(element.getAttribute('style'), url, 'resources/'));
    }
    for (const element of document.querySelectorAll('[data-slide-bg], [data-parallax-img]')) {
      for (const attribute of ['data-slide-bg', 'data-parallax-img']) {
        if (!element.hasAttribute(attribute)) continue;
        const file = await asset(element.getAttribute(attribute), url);
        if (file) element.setAttribute(attribute, `resources/${file}`);
      }
    }
    for (const style of document.querySelectorAll('style')) style.textContent = await rewriteUrls(style.textContent, url, 'resources/');
    document.querySelectorAll('a[href]').forEach(link => {
      const href = link.getAttribute('href');
      if (!href.startsWith('#')) { link.href = new URL(href, url).href; link.target = '_blank'; link.rel = 'noopener noreferrer'; }
    });
    // This is a design preview. Never submit production forms from a copied page.
    document.querySelectorAll('form').forEach(form => {
      form.removeAttribute('action');
      form.querySelectorAll('input, select, textarea, button').forEach(control => control.disabled = true);
    });
    const guard = document.createElement('script');
    guard.textContent = "window.gtag=function(){};window.dataLayer=[];document.addEventListener('submit',function(e){e.preventDefault();},true);";
    document.head.append(guard);
    const shellStyle = document.createElement('style');
    shellStyle.textContent = '.page-header,.page > .section-banner:first-child{display:none!important}';
    document.head.append(shellStyle);
    document.querySelectorAll('[aria-label="Open Smart Choice Assistant"]').forEach(node => node.remove());
    await fs.writeFile(path.join(directory, `${name}.html`), dom.serialize().replace(/[ \t]+\r?$/gm, ''));
    console.log(`Refreshed public ${name} preview`);
  }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
