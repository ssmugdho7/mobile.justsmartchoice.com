{{flutter_js}}
{{flutter_build_config}}

// Keep browser history on the hosting document's origin. Code/assets may be
// served by GitHub Pages, independently of the mobile host's URL and cookies.
const appAssetBase = new URL('.', document.currentScript.src).href;
_flutter.loader.load({
  config: {
    entrypointBaseUrl: appAssetBase,
    assetBase: appAssetBase,
    canvasKitBaseUrl: new URL('canvaskit/', appAssetBase).href,
  },
});
