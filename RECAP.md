# 📋 Récap projet — Brainrot Companion

> Résumé de la conversation et de l'état d'avancement.
> Dernière mise à jour : 2026-06-16.

## 🎯 Le concept

App pour les potes **geeks brainrot** qui manquent de dopamine pendant leurs
games de **League of Legends**. Principe : pendant la game, TikTok défile sur un
2e écran (ou en mini-fenêtre), et on peut **scroller / mute SANS jamais quitter
League** — aucun focus volé, aucun input perdu en teamfight.

Pensé pour un **setup 2 écrans** au départ, avec un mode mono-écran ajouté
ensuite (mini-fenêtre par-dessus le jeu).

## 🧱 Choix techniques (validés ensemble)

| Sujet | Choix |
|-------|-------|
| OS cible | **Windows** (les amis jouent sur PC) |
| Outil | **AutoHotkey v2** (hotkeys globales + contrôle de fenêtre, rien à compiler) |
| Méthode scroll | **Scroll en arrière-plan** : on envoie `WM_MOUSEWHEEL` directement à la fenêtre du navigateur → League garde le focus à 100% (pas d'alt-tab) |
| Affichage TikTok | **Navigateur web** (tiktok.com) |
| Mode LoL requis | **Sans bordure (Borderless)** pour le mode PiP |

> Note : le développement se fait sur **Mac**, mais le script ne tourne que sur
> **Windows** (AutoHotkey n'existe pas sur macOS). Donc non testable depuis la
> machine de dev.

## ⌨️ Touches (clavier AZERTY FR, mappées par scancode)

| Touche | Scancode | Effet |
|--------|----------|-------|
| `à`        | SC00B | Ouvre / focus TikTok sur le **2e écran** |
| `²` (carré)| SC029 | **Vidéo suivante** (scroll bas) |
| `Maj` + `²`| +SC029| Vidéo précédente (scroll haut) |
| `)`        | SC00C | **Mute / unmute** la vidéo (envoie `m`) |
| `=`        | SC00D | **Mini-fenêtre PiP** vidéo seule, écran principal (toggle on/off) |

## 🖼️ Les deux modes d'affichage

1. **2e écran** (`à`) — TikTok en grand sur l'écran secondaire.
2. **Mini-fenêtre PiP** (`=`) — **uniquement la vidéo** flottante en haut à
   gauche de l'écran principal, par-dessus League. Toggle pour l'ouvrir/fermer.

Le scroll (`²`) et le mute (`)`) marchent sur les deux ; ils **priorisent la PiP**
quand elle est ouverte.

## 🎬 Comment le mode PiP n'affiche QUE la vidéo (2 couches retirées)

1. **Fenêtre Windows** : lancement Chrome en `--app`, puis suppression de tout
   le cadre (barre de titre + boutons réduire/agrandir/fermer) via l'API Win32
   (`StripWindowChrome`, ré-appliquée après 350 ms car Chrome redessine son
   cadre).
2. **UI du site TikTok** : une **extension Chrome locale** (`tiktok-clean/`)
   masque toute l'interface par CSS pour ne laisser que la `<video>`. Chargée
   via `--load-extension` dans un **profil Chrome dédié** (`.pip-profile/`,
   auto-créé) → le Chrome perso n'est jamais touché.

## 📁 Structure du projet

```
extensionpj/
├── brainrot.ahk          # Script principal AutoHotkey v2 (toute la logique)
├── README.md             # Guide d'install + dépannage pour les amis
├── RECAP.md              # Ce fichier
├── .gitignore            # Ignore .exe, logs, .pip-profile/, etc.
└── tiktok-clean/         # Extension Chrome "vidéo seule"
    ├── manifest.json     # Manifest v3
    ├── clean.css         # Masque l'UI TikTok, étire la vidéo plein cadre
    └── clean.js          # MutationObserver : re-masque l'UI réinjectée
```

> ⚠️ `brainrot.ahk` et `tiktok-clean/` doivent **rester côte à côte** (le mode
> PiP charge l'extension depuis ce chemin relatif).

## 🐛 Bugs trouvés & corrigés en cours de route

- **`ControlFromPoint` n'existe pas en AHK v2** → remplacé par l'API Win32
  `WindowFromPoint` via `DllCall` (`ControlUnderPoint`).
- **Scancode du mute mal mappé** : `)` était sur `SC00D` (= la touche `=`).
  Corrigé : `)` = `SC00C`, `=` = `SC00D`.
- **PiP affichait encore toute l'UI TikTok + barre de titre** (capture user) :
  Chrome **redirigeait** vers la fenêtre Chrome déjà ouverte → `--app` et
  l'extension ignorés. Corrigés ensemble :
  1. **Extension réécrite en "cacher tout sauf la `<video>`"** (au lieu
     d'énumérer les classes TikTok, qui changent sans arrêt). `clean.js` marque
     la vidéo + ses parents `data-brk="1"`, `clean.css` ne montre que ça.
  2. **Témoin visuel** : liseré vert au bord de la fenêtre = extension active.
     Pas de liseré = handoff Chrome (→ fermer tout Chrome une fois).
  3. **Détection fenêtre** : on saisit la vraie fenêtre `--app` (titre sans
     " - Google Chrome"), `--new-window` ajouté, garde si dossier ext manquant.

## 🔗 GitHub

Repo : **https://github.com/David-dsv/dopamineinsuffisance** (branche `main`)
Tout est poussé et à jour. Commits faits sous le compte `David-dsv`.

## ✅ État actuel

- [x] Scroll en arrière-plan fonctionnel (**confirmé : "marche grave bien"**)
- [x] Mute en arrière-plan (`)`)
- [x] Mode 2e écran (`à`)
- [x] Mode PiP mini-fenêtre (`=`) avec vidéo seule (cadre nu + extension CSS)
- [x] Tout poussé sur GitHub

### ⏳ À tester par l'utilisateur (Windows) — après le fix UI

1. `git pull` pour récupérer la nouvelle extension + script.
2. **Fermer TOUTES les fenêtres Chrome** (sinon handoff → l'ancien bug revient).
3. Recharger le script ([Reload]) puis `=`.
4. Vérifier le **liseré vert** au bord de la fenêtre → extension active.
   - Liseré vert + que la vidéo = ✅ réglé.
   - Pas de liseré = Chrome a encore redirigé → re-fermer tout Chrome.
5. 1er lancement PiP : profil dédié → possible **reconnexion TikTok** (normal).

## 💡 Pistes / idées non encore faites

- Raccourci pour **déplacer / redimensionner** la PiP à la volée.
- PiP **semi-transparente** quand on ne la regarde pas.
- Binds **like** (`L`) ou **play/pause** sur TikTok.
- Mode **auto-scroll** (une vidéo toutes les X secondes, mains libres).
- Si l'UI TikTok réapparaît un jour (changement de classes côté site) :
  ajouter les sélecteurs manquants dans `tiktok-clean/clean.css`.
