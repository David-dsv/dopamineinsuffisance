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
| Mode mono-écran | **Miroir live** du 2e écran via l'API Windows **Magnification** |

> Note : le développement se fait sur **Mac**, mais le script ne tourne que sur
> **Windows** (AutoHotkey + Magnification.dll = Windows uniquement). Donc non
> testable depuis la machine de dev.

## ⌨️ Touches (clavier AZERTY FR, mappées par scancode)

| Touche | Scancode | Effet |
|--------|----------|-------|
| `à`        | SC00B | Ouvre / focus TikTok sur le **2e écran** |
| `²` (carré)| SC029 | **Vidéo suivante** (scroll bas) |
| `Maj` + `²`| +SC029| Vidéo précédente (scroll haut) |
| `)`        | SC00C | **Mute / unmute** la vidéo (envoie `m`) |
| `=`        | SC00D | **Miroir live** du 2e écran, en haut à gauche de l'écran principal (toggle) |

## 🪞 Le mode miroir (touche `=`) — approche actuelle

Au lieu d'ouvrir une 2e fenêtre TikTok (l'ancienne approche Chrome `--app` +
extension, qui posait trop de problèmes : barre de titre persistante, UI TikTok
visible, handoff Chrome), on **recopie en direct une zone du 2e écran** dans une
petite fenêtre flottante always-on-top sur l'écran principal.

- API utilisée : **Magnification.dll** (contrôle de classe `Magnifier`).
- La fenêtre hôte est nue (`-Caption`, `+ToolWindow`, `+E0x80000` = LAYERED).
- Un timer ré-appelle `MagSetWindowSource` à ~30 fps → image live.
- On mirrore **tout le 2e écran** (`monitorIndex`), donc TikTok doit y être
  maximisé (ce que fait déjà la touche `à`).
- Pas de récursion (source = écran 2, miroir = écran 1).

Le scroll (`²`) et le mute (`)`) visent toujours la **vraie** fenêtre TikTok du
2e écran ; le miroir affiche le résultat en direct.

## 📁 Structure du projet

```
extensionpj/
├── brainrot.ahk          # Script principal AutoHotkey v2 (toute la logique)
├── README.md             # Guide d'install + dépannage pour les amis
├── RECAP.md              # Ce fichier
├── .gitignore
└── tiktok-clean/         # (ancienne extension Chrome — plus utilisée par le
                          #  mode miroir, conservée pour historique)
```

## 🐛 Historique des approches du mode mono-écran

1. **PiP via Chrome `--app` + extension CSS** (commits `429c6cb`, `066f094`) :
   ouvrait une 2e fenêtre TikTok nue. Problèmes : barre de titre Chrome qui
   revenait, UI TikTok pas masquée, **handoff Chrome** (Chrome déjà ouvert →
   `--app`/extension/profil ignorés). Tentative de fix (extension "cacher tout
   sauf la vidéo" + témoin vert) **n'a pas marché non plus** → **revert**.
2. **Miroir live du 2e écran via Magnification API** (approche ACTUELLE) :
   beaucoup plus simple et fiable, aucune dépendance navigateur.

## 🔗 GitHub

Repo : **https://github.com/David-dsv/dopamineinsuffisance** (branche `main`)
Commits faits sous le compte `David-dsv`.

## ✅ État actuel

- [x] Scroll en arrière-plan fonctionnel (**confirmé : "marche grave bien"**)
- [x] Mute en arrière-plan (`)`)
- [x] Mode 2e écran (`à`)
- [x] Mode miroir (`=`) réécrit via Magnification API

### ⏳ À tester par l'utilisateur (Windows)

1. `git pull`, recharger le script ([Reload]).
2. `à` pour ouvrir TikTok sur le 2e écran (maximisé).
3. `=` → une petite fenêtre en haut à gauche doit **refléter en direct** le 2e
   écran. Scroller avec `²` doit se voir bouger dans le miroir.
4. Si message *"Magnification.dll indisponible"* : à investiguer (rare).

## 💡 Pistes / idées non encore faites

- Recadrer le miroir sur une **zone verticale** (ratio TikTok) au lieu de tout
  l'écran, pour éviter le noir sur les côtés (`MagSetWindowSource` avec un RECT
  plus étroit centré).
- Raccourci pour **déplacer / redimensionner** le miroir à la volée.
- Miroir **semi-transparent** quand on ne le regarde pas (`WinSetTransparent`).
- Binds **like** (`L`) ou **play/pause** sur TikTok.
- Mode **auto-scroll** (une vidéo toutes les X secondes, mains libres).
