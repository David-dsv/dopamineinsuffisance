// ===========================================================================
//  TikTok Clean — révèle UNIQUEMENT la vidéo, cache tout le reste.
//
//  Le CSS (clean.css) masque tout (body > *) SAUF les éléments marqués
//  data-brk="1". Ce script trouve la <video> et marque toute sa chaîne de
//  parents jusqu'à <body> avec data-brk="1" -> seule la vidéo reste visible,
//  quel que soit le nom des classes TikTok (robuste aux refontes du site).
// ===========================================================================

(() => {
  "use strict";

  // Marque la <video> et tous ses ancêtres (jusqu'à body) comme "à garder".
  function revealVideoChain() {
    const videos = document.querySelectorAll("video");
    if (!videos.length) return false;

    // On efface les anciennes marques (la vidéo active change quand on scrolle).
    for (const el of document.querySelectorAll('[data-brk="1"]')) {
      el.removeAttribute("data-brk");
    }

    // On garde la première vidéo réellement affichée (TikTok en précharge plusieurs).
    let target = videos[0];
    for (const v of videos) {
      const r = v.getBoundingClientRect();
      if (r.width > 0 && r.height > 0) { target = v; break; }
    }

    // On remonte la chaîne de parents et on marque chacun.
    let node = target;
    while (node && node !== document.body && node !== document.documentElement) {
      node.setAttribute("data-brk", "1");
      node = node.parentElement;
    }
    target.setAttribute("data-brk", "1");

    // Petit témoin visuel pour vérifier que l'extension tourne bien :
    // le fond du body passe au noir dès que la vidéo est trouvée.
    document.documentElement.setAttribute("data-brk-active", "1");
    return true;
  }

  // Masque les pop-ups de connexion qui bloquent la vidéo, s'il y en a.
  function dismissBlockers() {
    for (const sel of ['[role="dialog"]', '[class*="DivLoginContainer"]', '[class*="CookieBanner"]']) {
      for (const el of document.querySelectorAll(sel)) {
        el.style.setProperty("display", "none", "important");
      }
    }
  }

  function tick() {
    dismissBlockers();
    revealVideoChain();
  }

  // Premier passage dès que possible.
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", tick, { once: true });
  } else {
    tick();
  }

  // La vidéo apparaît tard (chargement async) : on retente quelques secondes.
  let tries = 0;
  const poll = setInterval(() => {
    tick();
    if (++tries > 40) clearInterval(poll);   // ~8 s puis on s'arrête
  }, 200);

  // Et on re-marque à chaque mutation du DOM (scroll = nouvelle vidéo active).
  let scheduled = false;
  const observer = new MutationObserver(() => {
    if (scheduled) return;
    scheduled = true;
    requestAnimationFrame(() => {
      scheduled = false;
      tick();
    });
  });
  observer.observe(document.documentElement, { childList: true, subtree: true });
})();
