(() => {
  'use strict';
  const nonce = "__SC_NONCE__";
  const crmOrigin = "__SC_ORIGIN__";
  if (location.origin !== crmOrigin) return;
  const maxBytes = 10 * 1024 * 1024;
  const names = new Set(['invoicepdf', 'estimatepdf', 'paymentpdf']);
  const actions = new Set(['proposal_pdf', 'contract_pdf']);
  const native = (...args) => window.flutter_inappwebview.callHandler('scExportPdf', nonce, ...args);
  document.addEventListener('submit', async event => {
    const form = event.target;
    if (!(form instanceof HTMLFormElement)) return;
    const button = event.submitter;
    const data = new FormData(form);
    if (!names.has(button?.name) && !actions.has(data.get('action'))) return;
    const method = (button?.getAttribute('formmethod') || form.getAttribute('method') || 'GET').toUpperCase();
    const url = new URL(button?.getAttribute('formaction') || form.getAttribute('action') || location.href, location.href);
    if (method !== 'POST' || url.origin !== crmOrigin) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    if (button?.disabled) return;
    if (button?.name) data.append(button.name, button.value);
    if (button) button.disabled = true;
    try {
      const response = await fetch(url.href, {method: 'POST', body: new URLSearchParams(data),
        credentials: 'same-origin', redirect: 'error'});
      if (!response.ok || !response.headers.get('content-type')?.toLowerCase().includes('application/pdf')) throw new Error('Unavailable');
      if (Number(response.headers.get('content-length')) > maxBytes) throw new Error('Too large');
      const reader = response.body.getReader();
      const chunks = [];
      let length = 0;
      while (true) {
        const {done, value} = await reader.read();
        if (done) break;
        length += value.length;
        if (length > maxBytes) { await reader.cancel(); throw new Error('Too large'); }
        chunks.push(value);
      }
      const bytes = new Uint8Array(length);
      let offset = 0;
      for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
      const pieces = [];
      for (let i = 0; i < bytes.length; i += 32768) pieces.push(String.fromCharCode(...bytes.subarray(i, i + 32768)));
      const disposition = response.headers.get('content-disposition') || '';
      const utfName = disposition.match(/filename\*=UTF-8''([^;]+)/i);
      const plainName = disposition.match(/filename="([^"]+)"|filename=([^;]+)/i);
      let name = plainName?.[1] || plainName?.[2] || 'CRM-document.pdf';
      if (utfName) { try { name = decodeURIComponent(utfName[1]); } catch (_) {} }
      const result = await native('save', name, btoa(pieces.join('')));
      if (result !== true) throw new Error('Cannot save');
    } catch (_) {
      try { await native('error'); }
      catch (_) { window.alert('Unable to download this PDF. Please try again after the page has loaded.'); }
    } finally {
      if (button) button.disabled = false;
    }
  }, true);
})();
