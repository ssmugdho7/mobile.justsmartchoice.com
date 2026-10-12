// Public Toolbox audit only; never submits forms or requests authenticated CRM data.
const fs = require('node:fs/promises');
const { JSDOM } = require('jsdom');
async function main() {
  const doc = new JSDOM(await fs.readFile('preview_site/toolbox.html', 'utf8')).window.document;
  const cards = [...doc.querySelectorAll('a.smart-toolbox-box')].map(a => ({
    title: (a.querySelector('h3,h4,h5,h6,strong')?.textContent ?? a.textContent).trim().replace(/\s+/g, ' '),
    url: a.href,
  }));
  const results = [];
  const calculatorPaths = new Set(['calculator.php','concretecalc.php','feet-inches-calculator.php','flooring-calculator.php','paint-calculator.php','vinyl-fence-calculator.php']);
  for (let start = 0; start < cards.length; start += 5) {
    await Promise.all(cards.slice(start, start + 5).map(async card => {
      try {
        const resolved = new URL(card.url);
        if (resolved.hostname === 'justsmartchoice.com' && calculatorPaths.has(resolved.pathname.slice(1))) resolved.pathname = '/calculators' + resolved.pathname;
        const response = await fetch(resolved, {
          headers: { 'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36', 'Accept': 'text/html,application/pdf' },
          signal: AbortSignal.timeout(20000),
        });
        results.push({ ...card, resolvedUrl: resolved.href, status: response.status, finalUrl: response.url,
          frameOptions: response.headers.get('x-frame-options'),
          frameAncestors: response.headers.get('content-security-policy')?.match(/frame-ancestors[^;]*/)?.[0] ?? null,
          contentType: response.headers.get('content-type') });
        await response.body?.cancel();
      } catch (error) { results.push({ ...card, error: error.name }); }
    }));
  }
  results.sort((a, b) => cards.findIndex(c => c.url === a.url) - cards.findIndex(c => c.url === b.url));
  const report = JSON.stringify(results, null, 2);
  if (process.argv[2]) await fs.writeFile(process.argv[2], report);
  console.log(report);
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
