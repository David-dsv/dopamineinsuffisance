# 🧠💀 Brainrot Companion — version macOS

Version Mac du projet (l'original `brainrot.ahk` est Windows-only car AutoHotkey
n'existe pas sur Mac). Réécrit pour **Hammerspoon** (Lua).

> ⚠️ **À savoir d'emblée** : League of Legends tourne mal/peu sur Mac, et macOS
> est techniquement plus restrictif que Windows pour piloter une autre app.
> Cette version marche, mais avec **deux compromis** (voir « Différences avec
> Windows » plus bas). Si tes amis sont sur PC, garde la version Windows.

## Touches

| Touche      | Effet                                   |
|-------------|-----------------------------------------|
| `à`         | Ouvre / focus TikTok sur le 2e écran    |
| `@`         | Vidéo suivante (scroll bas)             |
| `Maj` + `@` | Vidéo précédente (scroll haut)          |
| `)`         | Mute / unmute la vidéo                  |
| `=`         | Picture-in-Picture (mini-fenêtre)       |

> `@` remplace le `²` de la version Windows (le `²` n'existe pas sur Mac).

## Installation

1. **Installe Hammerspoon** : https://www.hammerspoon.org (gratuit, open source).
2. Lance Hammerspoon une fois. Clique sur son icône dans la barre de menu →
   **Open Config** : ça ouvre `~/.hammerspoon/init.lua`.
3. **Copie le contenu de `brainrot.lua` dans `~/.hammerspoon/init.lua`**
   (ou copie le fichier et `dofile`-le depuis ton init).
4. **Donne les droits Accessibilité** à Hammerspoon :
   *Réglages Système → Confidentialité et sécurité → Accessibilité* → coche
   Hammerspoon. (Indispensable : sans ça, impossible de capter les touches ni
   de poster le scroll/clavier.)
5. Dans le menu Hammerspoon → **Reload Config**. Un message
   « 🧠💀 Brainrot Companion chargé » confirme que ça tourne.

### Pour le mode PiP (`=`)

Installe l'extension Google **Picture-in-Picture** sur Chrome (raccourci ⌥P) :
➡️ https://chromewebstore.google.com/detail/picture-in-picture-extension/hkgfoiooedgoejojocmhlaklaeopbecg

## Configuration

Tout est en haut de `brainrot.lua` dans la table `CONFIG` :

- `browserApp` : nom de l'app navigateur (`"Google Chrome"`, `"Microsoft Edge"`,
  `"Brave Browser"`, `"Arc"`…).
- `monitorIndex` : sur quel écran afficher TikTok (`2` par défaut).
- `wheelClicks` : « force » du scroll par appui (baisse si ça scrolle trop).
- `wheelLines` : amplitude d'un cran.
- `windowMatch` : mot-clé cherché dans le titre de la fenêtre (`TikTok`).
- `pipShortcut` : raccourci de l'extension PiP (par défaut ⌥P).
- `pipAllowFocusFallback` : `true` = bref focus sur TikTok pour déclencher le
  PiP (fiable), puis retour à League. `false` = jamais de focus volé (le PiP
  peut alors échouer).

### Si une touche ne réagit pas

Les claviers AZERTY/ISO Mac varient. Si `à`, `@`, `)` ou `=` ne déclenche rien :

1. Charge **`keycode-finder.lua`** dans Hammerspoon (remplace temporairement
   ton init.lua par ce fichier, recharge).
2. Appuie sur la touche voulue → son **keycode** s'affiche.
3. Dans `brainrot.lua`, mets `USE_KEYCODES = true` et reporte les 4 valeurs
   dans la table `KEYCODE`.
4. Remets `brainrot.lua` comme init et recharge.

## Différences avec la version Windows (compromis macOS)

macOS ne permet **pas** d'envoyer un scroll à une fenêtre en arrière-plan aussi
proprement que le `PostMessage(WM_MOUSEWHEEL)` de Windows. D'où deux compromis :

1. **Scroll (`@`)** : le script déplace le curseur sur la fenêtre TikTok (2e
   écran) le temps de poster le scroll, puis le **remet exactement où il
   était**. Le **focus clavier ne bouge pas** → League continue de recevoir tes
   touches. Mais le curseur « saute » visuellement un court instant. C'est le
   prix à payer sur macOS.

2. **Mute (`)`)** : l'envoi de la touche `m` à l'app navigateur sans la focus
   n'est pas garanti à 100 % sur macOS (selon le navigateur et la version). Si
   le mute ne marche pas en arrière-plan, dis-le-moi : on basculera sur la même
   stratégie « bref focus » que le PiP.

3. **Pas de click-through ni de largeur-max sur la PiP** : ces réglages fins de
   la version Windows reposent sur des styles de fenêtre Win32 sans équivalent
   simple sur macOS. La PiP macOS est celle, native, gérée par le navigateur.

## Dépannage

- **Rien ne se passe quand j'appuie sur une touche** → vérifie les droits
  Accessibilité (étape 4), puis Reload Config.
- **« TikTok pas ouvert »** → appuie d'abord sur `à`.
- **Le scroll ne change pas la vidéo** → augmente `wheelClicks` (ex: 5).
- **Une touche ne répond pas** → voir « Si une touche ne réagit pas » ci-dessus.
- **Le curseur saute trop loin / mauvais écran** → vérifie `monitorIndex`.
