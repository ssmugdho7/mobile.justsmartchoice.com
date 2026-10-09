// Match the original app's native navigation without duplicating the web header.
(function () {
  if (!['justsmartchoice.com', 'www.justsmartchoice.com'].includes(location.hostname)) return;
  function apply() {
    if (document.getElementById('sc-native-shell-style')) return;
    const style = document.createElement('style');
    style.id = 'sc-native-shell-style';
    style.textContent = '.page-header,.page > .section-banner:first-child{display:none!important}@media(max-width:400px){.swiper-slide .swiper-slide-caption .cta-box-heading{font-size:clamp(26px,8vw,32px)!important}}';
    (document.head || document.documentElement).appendChild(style);
  }
  apply();
  document.addEventListener('DOMContentLoaded', apply, {once: true});
})();
