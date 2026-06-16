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

Le scroll (`²`) et le mute (`)`) visent toujours la **vraie** fenêtre TikTok ;
le PiP affiche la même vidéo en flottant.

## 📁 Structure du projet

```
extensionpj/
├── brainrot.ahk          # Script principal AutoHotkey v2 (toute la logique)
├── README.md             # Guide d'install + dépannage pour les amis
├── RECAP.md              # Ce fichier
├── .gitignore
└── tiktok-clean/         # (ancienne extension Chrome — plus utilisée,
                          #  conservée pour historique)
```

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

### ⏳ À tester par l'utilisateur (Windows)

1. **Installer l'extension Google Picture-in-Picture** (lien dans le README).
2. Vérifier que **Alt+P** détache bien la vidéo quand on est manuellement sur
   l'onglet TikTok (sanity check de l'extension).
3. `git pull`, recharger le script ([Reload]).
4. `à` pour ouvrir TikTok, puis `=` → la vidéo doit se détacher en mini-fenêtre
   flottante. Re-`=` pour la refermer.

## 💡 Pistes / idées non encore faites

- Si le bref focus gêne : tester `pipAllowFocusFallback := false` (PiP en
  arrière-plan via ControlSend — à voir si ça marche selon le navigateur).
- Raccourci pour **déplacer / redimensionner** la fenêtre PiP (limité : c'est
  le navigateur qui la contrôle).
- Binds **like** (`L`) ou **play/pause** sur TikTok.
- Mode **auto-scroll** (une vidéo toutes les X secondes, mains libres).
