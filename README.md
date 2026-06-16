# 🧠💀 Brainrot Companion

Pour les vrais : scrolle TikTok sur ton 2e écran **pendant ta game de League**,
sans jamais quitter la partie. Plus jamais de manque de dopamine en farmant.

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
| `=`           | Miroir live du 2e écran en haut à gauche (on/off)    |

### Deux modes, au choix

- **2e écran** (`à`) : TikTok en grand sur ton écran secondaire.
- **Miroir live** (`=`) : une petite fenêtre flottante en haut à gauche de ton
  écran principal qui **recopie en direct ton 2e écran**, par-dessus League.
  Tu vois donc TikTok (ce qui tourne sur l'écran 2) sans quitter ta game.
  Réappuie sur `=` pour le fermer. Pratique quand tu regardes l'écran principal.

Le scroll (`²`) et le mute (`)`) visent toujours la vraie fenêtre TikTok du 2e
écran — et tu vois le changement en direct dans le miroir.

> ⚠️ **League doit être en "Sans bordure" (Borderless)**, pas en plein écran
> exclusif — sinon Windows masque la fenêtre miroir.
> Dans LoL : *Options → Vidéo → Mode d'affichage → Sans bordure*.

#### Comment marche le miroir

On utilise l'**API Magnification de Windows** (intégrée à Windows, rien à
installer) : elle sait afficher en temps réel le contenu d'une zone de l'écran.
On crée une petite fenêtre nue always-on-top, et un timer y recopie ton 2e écran
~30 fois par seconde. Aucun navigateur en plus, aucun focus volé : c'est juste
une "loupe" live de l'écran 2.

> Le miroir recopie **tout le 2e écran**, donc garde TikTok maximisé là-bas
> (la touche `à` le fait). Tu peux régler la taille/position du miroir dans
> `brainrot.ahk` (section `Config`, variables `mirror...`).

> `à` et `²` sont reconnues par leur position physique (scancode), donc ça
> marche en AZERTY. Tu peux changer les touches dans `brainrot.ahk` (section
> HOTKEYS).

## Installation (Windows)

1. **Installe AutoHotkey v2** : https://www.autohotkey.com/ (bouton
   « Download » → v2). C'est gratuit, ~5 Mo.
2. Double-clique sur **`brainrot.ahk`**. Une icône verte « H » apparaît dans
   la barre des tâches → le script tourne.
3. Branche ton 2e écran, lance League, et appuie sur `à` pour ouvrir TikTok.
   (Puis `=` pour afficher le miroir du 2e écran sur ton écran principal.)
4. Scrolle avec `²`. Profite. 💀

Pour l'arrêter : clic droit sur l'icône verte → *Exit*.

## Configuration

Tout est en haut de `brainrot.ahk` dans la classe `Config` :

- `monitorIndex` : sur quel écran ouvrir TikTok (`2` par défaut).
- `browserPath` : chemin de Chrome/Edge si tu ne veux pas le navigateur par
  défaut (laisse `""` sinon).
- `wheelClicks` : « force » du scroll par appui (3 = un bon coup, change la
  vidéo à coup sûr). Baisse à 1 si ça scrolle trop.
- `windowMatch` : mot-clé cherché dans le titre de la fenêtre (`TikTok`).
- `mirrorWidth` / `mirrorHeight` : taille de la fenêtre miroir (380×680).
- `mirrorX` / `mirrorY` : position du miroir sur l'écran principal (20,20).
- `mirrorFps` : fluidité du miroir (30 par défaut ; 60 = plus fluide, plus de CPU).
- `mirrorSourceMonitor` : écran recopié (`0` = suit `monitorIndex`).

## Lancer au démarrage de Windows (optionnel)

`Win + R` → tape `shell:startup` → glisse un raccourci de `brainrot.ahk`
dedans. Le scroller sera prêt à chaque démarrage.

## Dépannage

- **« TikTok pas ouvert »** quand j'appuie sur `²` → appuie d'abord sur `à`.
- **Le scroll ne change pas la vidéo** → augmente `wheelClicks` (ex: 5).
  Certains navigateurs/sites veulent un scroll plus franc.
- **Ça ouvre sur le mauvais écran** → change `monitorIndex` (1, 2, 3...).
- **Le miroir (`=`) montre le mauvais écran** → règle `mirrorSourceMonitor`.
- **Le miroir est noir / vide** → vérifie que quelque chose s'affiche bien sur
  le 2e écran (lance TikTok avec `à`), et que League est en *Sans bordure*.
- **Les touches `à`/`²` font autre chose dans League** → rebind dans la section
  HOTKEYS du script (ex: `Numpad0`, `XButton1` souris, etc.).

## ⚠️ Note fair-play

C'est un outil de **scroll passif sur une autre appli** : il n'automatise rien
dans League (pas de macro de jeu, pas d'avantage en partie), donc rien à voir
avec un cheat. Mais regarder TikTok en ranked, c'est toi qui vois pour ton LP. 😅
