(function () {
  'use strict';

  function qs(sel) { return document.querySelector(sel); }
  function qsa(sel) { return Array.prototype.slice.call(document.querySelectorAll(sel)); }

  function closeMenus() {
    qsa('.rd-navbar-nav.active, .rd-navbar-info.active, .rd-navbar-toggle.active, .rd-navbar-info-toggle.active').forEach(function (el) {
      el.classList.remove('active');
      if (el.hasAttribute('aria-expanded')) { el.setAttribute('aria-expanded', 'false'); }
    });
    document.documentElement.classList.remove('jsc-mobile-menu-open');
    document.body.classList.remove('jsc-mobile-menu-open');
  }

  function togglePanel(button, selector, oppositeSelector, event) {
    if (window.innerWidth > 991) { return; }
    if (event) {
      event.preventDefault();
      event.stopPropagation();
      if (event.stopImmediatePropagation) { event.stopImmediatePropagation(); }
    }

    var panel = qs(selector);
    var opposite = oppositeSelector ? qs(oppositeSelector) : null;
    var oppositeButton = selector === '.rd-navbar-nav' ? qs('.rd-navbar-info-toggle') : qs('.rd-navbar-toggle');
    if (!panel) { return; }

    var isOpen = panel.classList.contains('active');

    if (opposite) { opposite.classList.remove('active'); }
    if (oppositeButton) {
      oppositeButton.classList.remove('active');
      oppositeButton.setAttribute('aria-expanded', 'false');
    }

    if (isOpen) {
      panel.classList.remove('active');
      button.classList.remove('active');
      button.setAttribute('aria-expanded', 'false');
      document.documentElement.classList.remove('jsc-mobile-menu-open');
      document.body.classList.remove('jsc-mobile-menu-open');
    } else {
      panel.classList.add('active');
      button.classList.add('active');
      button.setAttribute('aria-expanded', 'true');
      document.documentElement.classList.add('jsc-mobile-menu-open');
      document.body.classList.add('jsc-mobile-menu-open');
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    var navToggle = qs('.rd-navbar-toggle');
    var infoToggle = qs('.rd-navbar-info-toggle');

    if (navToggle) {
      navToggle.setAttribute('aria-expanded', 'false');
      navToggle.addEventListener('click', function (e) {
        togglePanel(navToggle, '.rd-navbar-nav', '.rd-navbar-info', e);
      }, true);
    }

    if (infoToggle) {
      infoToggle.setAttribute('aria-expanded', 'false');
      infoToggle.addEventListener('click', function (e) {
        togglePanel(infoToggle, '.rd-navbar-info', '.rd-navbar-nav', e);
      }, true);
    }

    qsa('.rd-navbar-nav a, .rd-navbar-info a').forEach(function (link) {
      link.addEventListener('click', function () {
        if (window.innerWidth <= 991) { closeMenus(); }
      });
    });

    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') { closeMenus(); }
    });

    document.addEventListener('click', function (e) {
      if (window.innerWidth > 991) { return; }
      if (!document.body.classList.contains('jsc-mobile-menu-open')) { return; }
      if (e.target.closest('.rd-navbar-panel') || e.target.closest('.rd-navbar-nav') || e.target.closest('.rd-navbar-info')) { return; }
      closeMenus();
    });

    window.addEventListener('resize', function () {
      if (window.innerWidth > 991) { closeMenus(); }
    });
  });
})();
