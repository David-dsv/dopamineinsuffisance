# 🧠💀 Brainrot Companion

Pour les vrais : scrolle TikTok sur ton 2e écran **pendant ta game de League**,
sans jamais quitter la partie. Plus jamais de manque de dopamine en farmant.

> 🪟 **Windows** : ce README (script `brainrot.ahk`, AutoHotkey).
> 🍎 **macOS** : voir le dossier [`mac/`](mac/) (script Hammerspoon, touche `@`
> pour scroller au lieu de `²`). Compromis macOS expliqués dans `mac/README.md`.

## Comment ça marche

Le scroll est envoyé **directement à la fenêtre du navigateur en arrière-plan**.
League ne perd **jamais** le focus — pas d'alt-tab, pas d'input perdu en
teamfight. Tu restes en game à 100%, ton pouce scrolle des vidéos.

## Touches

| Touche        | Effet                                                |
|---------------|------------------------------------------------------|
| `à`           | Ouvre TikTok sur le 2e écran (ou le focus)           |
| `²` (carré)   | Vidéo suivante (scroll bas)                          |
| `Maj` + `²`   | Vidéo précédente (scroll haut)                       |
| `)`           | Mute / unmute la vidéo                               |
| `=`           | Picture-in-Picture : détache la vidéo en mini-fenêtre|

### Deux modes, au choix

- **2e écran** (`à`) : TikTok en grand sur ton écran secondaire.
- **Picture-in-Picture** (`=`) : détache la vidéo TikTok dans une **mini-fenêtre
  flottante** que le navigateur épingle par-dessus tout (donc par-dessus
  League). Réappuie sur `=` pour la refermer. Pratique en mono-écran.
  La fenêtre est **incliquable** (les clics passent vers League) et sa **largeur
  est plafonnée** pour qu'une vidéo paysage ne bloque pas toute ta vue.

Le scroll (`²`) et le mute (`)`) visent toujours la vraie fenêtre TikTok — et tu
vois le changement en direct dans la mini-fenêtre PiP.

#### ⭐ Prérequis du PiP (à faire une fois)

Le mode `=` utilise le **Picture-in-Picture natif de Chrome**, déclenché par le
raccourci **Alt+P** de l'extension officielle Google. Installe-la (gratuit,
1 clic) :

➡️ **[Picture-in-Picture Extension (by Google)](https://chromewebstore.google.com/detail/picture-in-picture-extension/hkgfoiooedgoejojocmhlaklaeopbecg)**

Une fois installée, le raccourci `Alt+P` détache/rattache la vidéo. Le script
n'a plus qu'à l'envoyer pour toi quand tu appuies sur `=`.

Chrome ouvre la fenêtre PiP près de l'onglet TikTok (souvent sur le 2e écran) :
le script la **replace automatiquement en haut à gauche de ton écran
principal**, par-dessus League. Tu peux régler ça dans la config (`pipX`,
`pipY`, `pipMonitorIndex`), ou le désactiver avec `pipMoveToMain := false`.

> Si tu as changé le raccourci de l'extension, reporte-le dans `brainrot.ahk`
> (`Config.pipShortcut`, ex: `"^."` pour Ctrl+. ).
> Par défaut le script donne un **bref focus** à TikTok le temps de déclencher
> le PiP, puis rend le focus à League. Pour ne jamais voler le focus, mets
> `Config.pipAllowFocusFallback := false` (mais le PiP peut alors échouer).

> `à` et `²` sont reconnues par leur position physique (scancode), donc ça
> marche en AZERTY. Tu peux changer les touches dans `brainrot.ahk` (section
> HOTKEYS).

## Installation (Windows)

1. **Installe AutoHotkey v2** : https://www.autohotkey.com/ (bouton
   « Download » → v2). C'est gratuit, ~5 Mo.
2. Double-clique sur **`brainrot.ahk`**. Une icône verte « H » apparaît dans
   la barre des tâches → le script tourne.
3. (Pour le mode `=`) Installe l'extension Google Picture-in-Picture — voir le
   lien dans la section « Prérequis du PiP » plus haut.
4. Branche ton 2e écran, lance League, et appuie sur `à` pour ouvrir TikTok.
   (Puis `=` pour détacher la vidéo en mini-fenêtre flottante.)
5. Scrolle avec `²`. Profite. 💀

Pour l'arrêter : clic droit sur l'icône verte → *Exit*.

## Configuration

Tout est en haut de `brainrot.ahk` dans la classe `Config` :

- `monitorIndex` : sur quel écran ouvrir TikTok (`2` par défaut).
- `browserPath` : chemin de Chrome/Edge si tu ne veux pas le navigateur par
  défaut (laisse `""` sinon).
- `wheelClicks` : « force » du scroll par appui (3 = un bon coup, change la
  vidéo à coup sûr). Baisse à 1 si ça scrolle trop.
- `windowMatch` : mot-clé cherché dans le titre de la fenêtre (`TikTok`).
- `pipShortcut` : raccourci du PiP (par défaut `"!p"` = Alt+P, celui de
  l'extension Google). Change-le si tu as personnalisé l'extension.
- `pipAllowFocusFallback` : `true` = bref focus sur TikTok pour déclencher le
  PiP (fiable). `false` = jamais de focus volé, mais le PiP peut échouer.
- `pipMoveToMain` : `true` = déplace la fenêtre PiP sur l'écran principal après
  ouverture. `false` = laisse Chrome la placer où il veut.
- `pipMonitorIndex` : écran de destination de la PiP (`1` = principal).
- `pipX` / `pipY` : position de la PiP depuis le coin haut-gauche (20,20).
- `pipMaxWidth` : largeur max de la fenêtre PiP (380). Les vidéos paysage qui
  bloquaient toute la vue sont réduites (à ratio gardé). `0` = pas de limite.
- `pipClickThrough` : `true` = fenêtre PiP **incliquable**, les clics traversent
  vers League (tu joues "à travers" la PiP). `false` = fenêtre cliquable.

## Lancer au démarrage de Windows (optionnel)

`Win + R` → tape `shell:startup` → glisse un raccourci de `brainrot.ahk`
dedans. Le scroller sera prêt à chaque démarrage.

## Dépannage

- **« TikTok pas ouvert »** quand j'appuie sur `²` → appuie d'abord sur `à`.
- **Le scroll ne change pas la vidéo** → augmente `wheelClicks` (ex: 5).
  Certains navigateurs/sites veulent un scroll plus franc.
- **Ça ouvre sur le mauvais écran** → change `monitorIndex` (1, 2, 3...).
- **Le PiP (`=`) ne se déclenche pas** → vérifie que l'extension Google
  Picture-in-Picture est bien installée, et qu'Alt+P marche quand tu es
  manuellement sur l'onglet TikTok. Vérifie aussi le raccourci dans
  `chrome://extensions/shortcuts` (doit être Alt+P, sinon adapte `pipShortcut`).
- **Le PiP s'ouvre puis se referme tout seul** → ton raccourci est peut-être
  envoyé deux fois ; garde `pipAllowFocusFallback := true` (le script n'envoie
  alors le raccourci qu'une seule fois).
- **Le PiP s'ouvre mais reste sur le mauvais écran** → le script repère la
  fenêtre PiP par son titre ("Picture-in-Picture" / "Image dans l'image"). Si
  ton Chrome est dans une autre langue, le titre diffère : dis-le-moi pour
  l'ajouter, ou ajuste la liste dans `FindPipWindow()` (dans `brainrot.ahk`).
- **Les touches `à`/`²` font autre chose dans League** → rebind dans la section
  HOTKEYS du script (ex: `Numpad0`, `XButton1` souris, etc.).

## ⚠️ Note fair-play

C'est un outil de **scroll passif sur une autre appli** : il n'automatise rien
dans League (pas de macro de jeu, pas d'avantage en partie), donc rien à voir
avec un cheat. Mais regarder TikTok en ranked, c'est toi qui vois pour ton LP. 😅
