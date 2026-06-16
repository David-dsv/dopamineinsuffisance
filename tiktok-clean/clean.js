// ===========================================================================
//  TikTok Clean — filet de sécurité JS.
//  Le gros du masquage est fait par clean.css. Mais TikTok injecte de l'UI
//  dynamiquement après le chargement (pop-ups de connexion, bannières...).
//  On observe le DOM et on re-masque ce qui réapparaît.
// ===========================================================================

(() => {
  "use strict";

  // Sélecteurs des blocs d'UI à neutraliser dès qu'ils apparaissent.
  const HIDE = [
    '[data-e2e="nav-bar"]',
    '[data-e2e="top-nav"]',
    '[data-e2e="search-box"]',
    'header',
    'nav',
    '[class*="DivHeaderContainer"]',
    '[class*="DivSideNavContainer"]',
    '[class*="DivActionItemContainer"]',
    '[class*="DivBottomContainer"]',
    '[class*="CookieBanner"]',
    '[class*="DivLoginContainer"]',
    '[class*="DivBannerContainer"]',
  ];

  function clean() {
    for (const sel of HIDE) {
      for (const el of document.querySelectorAll(sel)) {
        el.style.setProperty("display", "none", "important");
      }
    }
  }

  // Premier passage dès que le DOM est prêt.
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", clean, { once: true });
  } else {
    clean();
  }

  // Puis on re-nettoie à chaque mutation du DOM (débattu pour ne pas spammer).
  let scheduled = false;
  const observer = new MutationObserver(() => {
    if (scheduled) return;
    scheduled = true;
    requestAnimationFrame(() => {
      scheduled = false;
      clean();
    });
  });

  observer.observe(document.documentElement, {
    childList: true,
    subtree: true,
  });
})();
