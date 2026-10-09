// Keep copied public-page navigation inside the shared mobile interface.
(function () {
  const parentOrigin = (() => {
    try { return new URL(document.referrer).origin; } catch (_) { return null; }
  })();
  if (!parentOrigin) return;
  document.addEventListener('click', function (event) {
    const link = event.target.closest && event.target.closest('a[href]');
    if (!link) return;
    const href = link.getAttribute('href');
    if (!href || href.startsWith('#')) return;
    let url;
    try { url = new URL(href, location.href); } catch (_) { return; }
    const deviceAction = ['tel:', 'mailto:'].includes(url.protocol) && url.pathname;
    if ((!deviceAction && url.protocol !== 'https:') || url.username || url.password || url.port) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    window.parent.postMessage({type: 'sc-mobile-navigate', url: url.href}, parentOrigin);
  }, true);
})();
