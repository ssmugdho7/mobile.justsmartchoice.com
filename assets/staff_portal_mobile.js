// App-only staff presentation. Never changes permissions, records or notification state.
(function () {
  'use strict';
  if (location.origin !== 'https://crm.justsmartchoice.com' ||
      !/^\/admin(?:\/|$)/.test(location.pathname) ||
      /^\/admin\/authentication(?:\/|$)/.test(location.pathname)) return;
  if (document.getElementById('sc-staff-mobile-style')) return;
  const style = document.createElement('style');
  style.id = 'sc-staff-mobile-style';
  style.textContent = `
@media (max-width:767px) {
  body.app.admin #header #smart-choice-links-left-live,
  body.app.admin #header #smart-choice-links-right-live { transform:translateX(4px)!important; }
  body.admin #wrapper > .content { padding:12px 12px 88px!important; }
  body.admin.sc-staff-dashboard #wrapper > .content > .row { margin-inline:0!important; }
  body.admin.sc-staff-dashboard #wrapper > .content > .row > [class*="col-"] { padding-inline:0!important; }
  body.admin #wrapper .panel_s { margin-bottom:12px!important; border-radius:12px!important; }
  body.admin #wrapper .panel_s > .panel-body { padding:12px!important; }
  body.admin #wrapper .panel-footer { padding:10px 12px!important; }
  body.admin #wrapper h4 { font-size:15px; line-height:1.4; }
  body.admin #wrapper .widget { margin-bottom:12px!important; }
  body.admin #wrapper .sc-staff-notice { padding:0!important; max-height:none!important; overflow:visible!important; visibility:visible!important; }
  body.admin .sc-staff-details > summary {
    display:flex; align-items:center; justify-content:space-between; gap:12px;
    min-height:48px; padding:12px; font-size:14px; line-height:1.4;
    font-weight:600; cursor:pointer; list-style:none; overflow-wrap:anywhere;
  }
  body.admin .sc-staff-details > summary::-webkit-details-marker { display:none; }
  body.admin .sc-staff-details > summary::after { content:'+'; flex:none; font-size:20px; font-weight:400; }
  body.admin .sc-staff-details[open] > summary::after { content:'−'; }
  body.admin .sc-staff-details > summary:focus-visible { outline:2px solid #047857; outline-offset:-3px; }
  body.admin .sc-staff-notice-label { display:block; color:#075985; font-size:11px; font-weight:700; }
  body.admin .sc-staff-notice .sc-staff-details > summary { justify-content:space-between; }
  body.admin .sc-staff-notice-content { padding:0 12px 12px; overflow-wrap:anywhere; }
  body.admin .sc-staff-notice-content :is(img,video,iframe) { max-width:100%!important; }
  body.admin .sc-staff-notice-content h3 { font-size:17px!important; }
  body.admin #widget-top_stats > .row {
    display:grid!important; grid-template-columns:repeat(2,minmax(0,1fr)); gap:8px; margin:0!important;
  }
  body.admin #widget-top_stats > .row::before, body.admin #widget-top_stats > .row::after { display:none!important; }
  body.admin #widget-top_stats > .row > [class*="quick-stats-"] { width:auto!important; min-width:0; padding:0!important; margin:0!important; }
  body.admin #widget-top_stats .top_stats_wrapper { min-height:88px!important; height:100%!important; padding:12px!important; margin:0!important; }
  body.admin #widget-top_stats .top_stats_wrapper > div:first-child { flex-wrap:wrap; gap:6px; margin-top:0!important; }
  body.admin #widget-top_stats .tw-truncate { overflow:visible!important; white-space:normal!important; text-overflow:clip!important; font-size:12px; }
  body.admin #widget-top_stats svg { width:18px!important; height:18px!important; margin-inline-end:6px!important; flex:none; }
  body.admin #widget-top_stats .progress { height:4px!important; margin-top:10px!important; }
  body.admin #widget-user_data .nav-tabs { display:flex!important; flex-wrap:nowrap!important; overflow-x:auto!important; }
  body.admin #widget-user_data .nav-tabs > li { flex:none!important; float:none!important; }
  body.admin #widget-user_data .nav-tabs > li > a { min-height:44px; padding:12px 10px!important; white-space:nowrap; font-size:12px; }
  body.admin #widget-user_data .home-activity { height:auto!important; min-height:0!important; }
  body.admin #widget-user_data .dataTables_wrapper > .row:has(.dataTables_length) { display:flex; flex-wrap:wrap; align-items:center; gap:8px; margin:0!important; }
  body.admin #widget-user_data .dataTables_wrapper > .row:has(.dataTables_length) > [class*="col-"] { flex:1 1 120px; width:auto!important; padding:0!important; }
  body.admin #widget-user_data .dataTables_wrapper > .row:empty { display:none!important; }
  body.admin #widget-user_data .dataTables_length, body.admin #widget-user_data .dt-buttons { float:none!important; display:inline-flex!important; vertical-align:middle; margin:0 4px 0 0!important; }
  body.admin #widget-user_data .dataTables_filter, body.admin #widget-user_data .dataTables_filter label { width:100%!important; float:none!important; margin:0!important; text-align:start!important; }
  body.admin #widget-user_data .dataTables_filter .input-group { display:flex; width:100%; }
  body.admin #widget-user_data .dataTables_filter input { width:100%!important; min-width:0; }
  body.admin #widget-user_data .dataTables_scrollBody { height:auto!important; max-height:50vh!important; }
  body.admin #wrapper .dataTables_length, body.admin #wrapper .dataTables_filter { margin-bottom:8px!important; }
  body.admin #wrapper .table-responsive { overflow-x:auto!important; -webkit-overflow-scrolling:touch; }
  body.admin #wrapper .sc-staff-secondary { border:1px solid #dce5e1; border-radius:12px; background:#fff; }
  body.admin .sc-staff-secondary-content { padding:0 10px 10px; }
  body.admin .sc-staff-secondary-content .panel_s { margin-bottom:0!important; border:0!important; box-shadow:none!important; }
  body.admin #toast-container { width:calc(100% - 24px)!important; max-width:420px!important; max-height:min(180px,24vh)!important; overflow-y:auto!important; inset-inline:12px!important; margin:auto!important; }
  body.admin #toast-container > .toast { width:100%!important; min-height:0!important; margin-bottom:6px!important; padding:10px 44px 10px 42px!important; font-size:13px!important; }
  body.admin #toast-container .toast-message { max-height:84px; overflow-y:auto; overflow-wrap:anywhere; }
  body.admin #toast-container .toast-close-button { position:absolute; top:0; right:0; width:44px; height:44px; }
  body.admin #header .notifications .dropdown-menu { width:min(360px,calc(100vw - 16px))!important; max-height:65vh!important; overflow:auto!important; }
}
/* Native details remain expanded on desktop/tablet; no lost content after rotation. */
@media (min-width:768px) {
  body.admin .sc-staff-details > summary { display:none; }
  body.admin .sc-staff-details:not([open]) > :not(summary) { display:block; }
}
`;
  (document.head || document.documentElement).appendChild(style);
  const mobile = window.matchMedia('(max-width:767px)');
  const dashboard = /^\/admin\/?$/.test(location.pathname) || /^\/admin\/dashboard\/?$/.test(location.pathname);
  function disclosure(label, className) {
    const details = document.createElement('details');
    details.className = 'sc-staff-details ' + className;
    details.open = !mobile.matches;
    const summary = document.createElement('summary');
    summary.textContent = label;
    details.appendChild(summary);
    details.addEventListener('toggle', function () {
      if (details.open) window.dispatchEvent(new Event('resize'));
    });
    return details;
  }
  function apply() {
    if (!document.body || !document.body.classList.contains('admin')) return;
    if (dashboard) document.body.classList.add('sc-staff-dashboard');
    document.querySelectorAll('#wrapper .announcement:not(.sc-staff-notice)').forEach(function (notice) {
      const headings = notice.querySelectorAll('h4');
      const title = headings.length > 1 ? headings[1] : headings[0];
      const details = disclosure('', '');
      const summary = details.querySelector('summary');
      const text = document.createElement('span');
      const label = document.createElement('span');
      label.className = 'sc-staff-notice-label';
      label.textContent = document.documentElement.lang.startsWith('es') ? 'Anuncio · Toca para leer' : 'Announcement · Tap to read';
      text.appendChild(label);
      text.appendChild(document.createTextNode(title ? title.textContent.trim() : 'Announcement'));
      summary.appendChild(text);
      const content = document.createElement('div');
      content.className = 'sc-staff-notice-content';
      while (notice.firstChild) content.appendChild(notice.firstChild);
      details.appendChild(content);
      notice.classList.add('sc-staff-notice');
      notice.appendChild(details);
    });
    if (!dashboard) return;
    // Secondary widgets are still one tap away; primary work tabs and KPIs stay visible.
    const secondaryLabels = document.documentElement.lang.startsWith('es')
      ? {calendar:'Calendario',commission:'Comisiones',leads_chart:'Resumen de clientes potenciales',projects_chart:'Estado de proyectos',tickets_chart:'Estado de tickets'}
      : {calendar:'Calendar',commission:'Commission',leads_chart:'Leads overview',projects_chart:'Project status',tickets_chart:'Ticket status'};
    Object.keys(secondaryLabels).forEach(function (name) {
      const widget = document.getElementById('widget-' + name);
      if (!widget || widget.dataset.scStaffDisclosure || widget.classList.contains('hide')) return;
      const heading = widget.querySelector('h4,h3,.panel-title');
      const title = widget.getAttribute('data-name') || (heading && heading.textContent.trim()) || secondaryLabels[name];
      if (!title) return;
      const details = disclosure(title, 'sc-staff-secondary');
      const content = document.createElement('div');
      content.className = 'sc-staff-secondary-content';
      Array.from(widget.childNodes).forEach(function (child) {
        if (child.nodeType === 1 && child.classList.contains('widget-dragger')) return;
        content.appendChild(child);
      });
      details.appendChild(content);
      widget.dataset.scStaffDisclosure = 'true';
      widget.appendChild(details);
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', apply, {once:true});
  else apply();
  // Modules may add notices/widgets after their first AJAX response.
  const observer = new MutationObserver(function (records) {
    if (records.some(function (record) { return record.addedNodes.length > 0; })) apply();
  });
  observer.observe(document.documentElement, {childList:true,subtree:true});
  mobile.addEventListener('change', function () {
    document.querySelectorAll('.sc-staff-details').forEach(function (details) { details.open = !mobile.matches; });
  });
})();
