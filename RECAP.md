# 📋 Récap projet — Brainrot Companion

> Résumé de la conversation et de l'état d'avancement.
> Dernière mise à jour : 2026-06-16.

## 🎯 Le concept

App pour les potes **geeks brainrot** qui manquent de dopamine pendant leurs
games de **League of Legends**. Principe : pendant la game, TikTok défile sur un
2e écran, et on peut **scroller / mute SANS jamais quitter League** — aucun
focus volé, aucun input perdu en teamfight.

Pensé pour un **setup 2 écrans**, avec un mode mono-écran via **miroir live** du
2e écran ramené sur l'écran principal.

## 🧱 Choix techniques (validés ensemble)

| Sujet | Choix |
|-------|-------|
| OS cible | **Windows** (les amis jouent sur PC) |
| Outil | **AutoHotkey v2** (hotkeys globales + contrôle de fenêtre, rien à compiler) |
| Méthode scroll | **Scroll en arrière-plan** : on envoie `WM_MOUSEWHEEL` directement à la fenêtre du navigateur → League garde le focus à 100% |
| Affichage TikTok | **Navigateur web** (tiktok.com) sur le 2e écran |
| Mode mono-écran | **Picture-in-Picture natif** du navigateur (Chrome), déclenché par Alt+P |

> Note : le développement se fait sur **Mac**, mais le script ne tourne que sur
> **Windows** (AutoHotkey = Windows uniquement). Donc non testable depuis la
> machine de dev.

## ⌨️ Touches (clavier AZERTY FR, mappées par scancode)

| Touche | Scancode | Effet |
|--------|----------|-------|
| `à`        | SC00B | Ouvre / focus TikTok sur le **2e écran** |
| `²` (carré)| SC029 | **Vidéo suivante** (scroll bas) |
| `Maj` + `²`| +SC029| Vidéo précédente (scroll haut) |
| `)`        | SC00C | **Mute / unmute** la vidéo (envoie `m`) |
| `=`        | SC00D | **Picture-in-Picture** : détache la vidéo en mini-fenêtre flottante (toggle) |

## 🖼️ Le mode PiP (touche `=`) — approche actuelle

On utilise le **Picture-in-Picture NATIF du navigateur** : Chrome détache la
vidéo TikTok dans une mini-fenêtre flottante que le navigateur épingle
lui-même par-dessus tout (donc par-dessus League). Pas de capture, pas de DLL,
pas de 2e fenêtre TikTok.

- **Prérequis utilisateur** : installer l'extension officielle Google
  *Picture-in-Picture* (gratuite, 1 clic). Elle ajoute le raccourci **Alt+P**.
- Le script envoie ce raccourci à la fenêtre TikTok quand on presse `=`.
- **Déclenchement** (`TogglePictureInPicture`) : si `pipAllowFocusFallback` est
  `true` (défaut), bref focus sur TikTok → `Send(Alt+P)` → retour du focus à
  League. Sinon, tentative en arrière-plan via `ControlSend` (moins fiable pour
  les combos Alt). On n'envoie le raccourci **qu'une seule fois** (sinon le PiP
  toggle deux fois et se referme).
- **Placement** : Chrome ouvre la PiP près de l'onglet source (2e écran). Le
  script la **déplace ensuite sur l'écran principal** (haut-gauche par défaut).
  On repère la fenêtre PiP par son **titre** ("Picture-in-Picture" /
  "Image dans l'image") via `FindPipWindow`, on attend son apparition
  (`WaitForPipWindow`), puis `MovePipToMain`. Désactivable via
  `pipMoveToMain := false`. Config : `pipMonitorIndex`, `pipX`, `pipY`.
- **Largeur max** (`pipMaxWidth`, 380) : une vidéo paysage donne une fenêtre PiP
  large qui bloque la vue. `MovePipToMain` plafonne la largeur et réduit la
  hauteur dans le même ratio (la vidéo reste correcte, juste plus petite).
  ⚠️ Limite : le PiP natif ne permet PAS de **cropper** un paysage en portrait
  (c'est Chrome qui dessine) — on ne peut que plafonner la taille de la fenêtre.
- **Incliquable** (`pipClickThrough`, true) : `MakeWindowClickThrough` ajoute
  `WS_EX_LAYERED | WS_EX_TRANSPARENT` + `SetLayeredWindowAttributes(alpha=255)`
  (le LAYERED rendrait la fenêtre invisible sans alpha forcé). Les clics
  traversent la PiP vers League. Le scroll/mute passant par les touches (pas la
  souris), aucune interaction souris n'est nécessaire sur la PiP.

Le scroll (`²`) et le mute (`)`) visent toujours la **vraie** fenêtre TikTok ;
le PiP affiche la même vidéo en flottant.

## 📁 Structure du projet

```
extensionpj/
├── brainrot.ahk          # WINDOWS — script AutoHotkey v2 (toute la logique)
├── README.md             # Guide Windows + pointeur vers la version Mac
├── RECAP.md              # Ce fichier
├── .gitignore
├── mac/                  # macOS — version Hammerspoon (Lua)
│   ├── brainrot.lua      #   script principal (équivalent du .ahk)
│   ├── keycode-finder.lua#   outil pour trouver les keycodes du clavier
│   └── README.md         #   install Hammerspoon + compromis macOS
└── tiktok-clean/         # (ancienne extension Chrome — plus utilisée,
                          #  conservée pour historique)
```

## 🍎 Version macOS (Hammerspoon)

AutoHotkey étant Windows-only, la version Mac est réécrite en **Lua pour
Hammerspoon** (`mac/brainrot.lua`). Mêmes touches, sauf **`@` au lieu de `²`**
pour scroller (le `²` n'existe pas sur Mac).

Compromis macOS (documentés dans `mac/README.md`) :
- **Scroll** : macOS n'a pas de `PostMessage(WM_MOUSEWHEEL)`. On déplace le
  curseur sur la fenêtre TikTok (2e écran), on poste le scroll, puis on remet
  le curseur où il était. Le **focus clavier ne bouge pas** (League OK), mais le
  curseur saute visuellement un court instant.
- **Mute** : l'envoi de `m` en arrière-plan n'est pas garanti à 100% sur macOS
  (à confirmer en test ; fallback "bref focus" possible).
- **PiP** : natif navigateur (extension Google ⌥P), sans le click-through ni la
  largeur-max de la version Windows (styles Win32 sans équivalent simple).

Liaison des touches **par caractère** par défaut ; bascule possible en
**keycodes** (`USE_KEYCODES = true`) avec `keycode-finder.lua` si une touche ne
répond pas (claviers AZERTY/ISO Mac varient).

Syntaxe Lua des deux fichiers **validée** (`luac -p`). Comportement runtime
**non testé** (ni Hammerspoon ni 2e écran ni League sur la machine de dev).

## 🐛 Historique des approches du mode mono-écran

1. **PiP via Chrome `--app` + extension CSS** (commits `429c6cb`, `066f094`) :
   ouvrait une 2e fenêtre TikTok nue. Problèmes : barre de titre Chrome qui
   revenait, UI TikTok pas masquée, **handoff Chrome** (Chrome déjà ouvert →
   `--app`/extension/profil ignorés). Tentative de fix (extension "cacher tout
   sauf la vidéo" + témoin vert) **n'a pas marché non plus** → **revert**.
2. **Miroir live du 2e écran via Magnification API** : `CreateWindowEx` classe
   "Magnifier" échouait avec **err 1407** (CANNOT_FIND_WND_CLASS), même avec le
   bon hInstance. L'API Magnification ne coopère pas sur la machine cible →
   **abandonné**.
3. **Picture-in-Picture natif (Alt+P)** (approche ACTUELLE) : le plus simple et
   fiable. Une seule dépendance : l'extension Google PiP côté utilisateur.

## 🔗 GitHub

Repo : **https://github.com/David-dsv/dopamineinsuffisance** (branche `main`)
Commits faits sous le compte `David-dsv`.

## ✅ État actuel

- [x] Scroll en arrière-plan fonctionnel (**confirmé : "marche grave bien"**)
- [x] Mute en arrière-plan (`)`)
- [x] Mode 2e écran (`à`)
- [x] Mode PiP (`=`) réécrit via Picture-in-Picture natif (Alt+P)
- [x] PiP **se déclenche** (confirmé par l'utilisateur)
- [x] PiP **déplacée auto** sur l'écran principal (haut-gauche)
- [x] **Version macOS** (Hammerspoon) écrite, syntaxe Lua validée, `@` = scroll

### ⏳ À tester par l'utilisateur (Windows)

1. `git pull`, recharger le script ([Reload]).
2. `à` pour ouvrir TikTok, puis `=` → la vidéo doit se détacher ET **se replacer
   en haut à gauche de l'écran principal** (avant elle restait en bas à droite
   du 2e écran). Re-`=` pour la refermer.
3. Si elle ne bouge pas : ton Chrome est peut-être dans une autre langue → me
   donner le titre exact de la fenêtre PiP pour l'ajouter à `FindPipWindow`.

### ⏳ À tester par l'utilisateur (macOS)

1. Installer **Hammerspoon** + copier `mac/brainrot.lua` en `~/.hammerspoon/init.lua`.
2. Droits **Accessibilité** pour Hammerspoon, puis Reload Config.
3. Tester `à` / `@` / `Maj+@` / `)` / `=`. Si une touche ne répond pas →
   `mac/keycode-finder.lua` puis `USE_KEYCODES = true`.
4. Vérifier si le **mute (`)`)** marche en arrière-plan ; sinon me le dire pour
   passer en mode "bref focus".

## 💡 Pistes / idées non encore faites

- Si le bref focus gêne : tester `pipAllowFocusFallback := false` (PiP en
  arrière-plan via ControlSend — à voir si ça marche selon le navigateur).
- Raccourci pour **déplacer / redimensionner** la fenêtre PiP (limité : c'est
  le navigateur qui la contrôle).
- Binds **like** (`L`) ou **play/pause** sur TikTok.
- Mode **auto-scroll** (une vidéo toutes les X secondes, mains libres).
