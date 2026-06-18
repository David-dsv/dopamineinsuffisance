-- ===========================================================================
--  BRAINROT COMPANION (macOS)  —  TikTok scroller pour gamers League of Legends
-- ---------------------------------------------------------------------------
--  Version Mac du projet Windows (brainrot.ahk), réécrite pour Hammerspoon.
--
--  Concept : pendant ta game, ton 2e écran affiche TikTok. Tu scrolles les
--  vidéos SANS quitter League : le scroll est posté à l'emplacement de la
--  fenêtre TikTok sur le 2e écran, sans déplacer durablement le curseur ni
--  voler le focus clavier à League.
--
--  Touches (clavier AZERTY Mac, captées par position physique = keycode) :
--     à        -> ouvre / met au premier plan TikTok sur le 2e écran
--     @        -> vidéo suivante (scroll bas)
--     Maj + @  -> vidéo précédente (scroll haut)
--     )        -> mute / unmute la vidéo
--     =        -> Picture-in-Picture (PiP natif du navigateur)
--
--  PRÉREQUIS :
--   1) Installer Hammerspoon : https://www.hammerspoon.org (gratuit).
--   2) Copier ce fichier en ~/.hammerspoon/init.lua  (ou le charger depuis là).
--   3) Donner à Hammerspoon les droits Accessibilité :
--        Réglages Système > Confidentialité et sécurité > Accessibilité.
--      (Indispensable pour capter les touches et poster scroll/clavier.)
--   4) Pour le PiP : installer l'extension Google "Picture-in-Picture" sur
--      Chrome (raccourci ⌥P / Alt+P). Voir CONFIG.pipShortcut.
-- ===========================================================================


-- ---------------------------------------------------------------------------
--  CONFIGURATION
-- ---------------------------------------------------------------------------
local CONFIG = {
  -- URL ouverte au lancement.
  url = "https://www.tiktok.com",

  -- Application navigateur à utiliser pour ouvrir / cibler TikTok.
  -- Doit correspondre au nom de l'app macOS ("Google Chrome", "Microsoft Edge",
  -- "Brave Browser", "Arc"...).
  browserApp = "Google Chrome",

  -- Sur quel écran afficher TikTok. 1 = écran principal, 2 = secondaire, etc.
  monitorIndex = 2,

  -- Nombre de "crans" de molette envoyés par appui. TikTok change de vidéo avec
  -- un scroll franc -> on en envoie plusieurs. Baisse si ça scrolle trop.
  wheelClicks = 3,
  -- Amplitude d'un cran (en lignes). 10 ≈ un bon cran de molette sur macOS.
  wheelLines = 10,

  -- Mot-clé cherché dans le TITRE de la fenêtre pour reconnaître l'onglet TikTok.
  windowMatch = "TikTok",

  -- --- Picture-in-Picture (touche "=") ---
  -- Raccourci de l'extension Google PiP. Sur Mac, Alt = ⌥ (option).
  -- Format Hammerspoon : { mods = {...}, key = "p" }.
  pipShortcut = { mods = { "alt" }, key = "p" },

  -- Réafficher TikTok au premier plan le temps d'envoyer le raccourci PiP
  -- (les combos ⌥ passent mal sans focus), puis rendre le focus à League.
  pipAllowFocusFallback = true,
}


-- ---------------------------------------------------------------------------
--  TOUCHES
-- ---------------------------------------------------------------------------
-- On lie les hotkeys par CARACTÈRE (le plus simple et lisible) : Hammerspoon
-- résout le caractère vers la bonne touche selon ta disposition active.
--
-- ⚠️ Si une touche ne réagit pas sur TON clavier (AZERTY/ISO varient), passe
-- en mode keycode : mets USE_KEYCODES = true ci-dessous et renseigne les 4
-- valeurs. Pour trouver le keycode d'une touche : charge "keycode-finder.lua"
-- (fourni à côté), appuie sur la touche, son numéro s'affiche.
local USE_KEYCODES = false

-- Caractères (mode par défaut).
local KEYS = {
  openTikTok = "à",   -- ouvrir / focus TikTok
  scroll     = "@",   -- vidéo suivante (+ Maj pour précédente)
  mute       = ")",   -- mute / unmute
  pip        = "=",   -- Picture-in-Picture
}

-- Keycodes physiques (utilisés seulement si USE_KEYCODES = true).
-- Valeurs de DÉPART à ajuster avec keycode-finder.lua si besoin.
local KEYCODE = {
  openTikTok = 0x1D,  -- "à"  (touche du 0)
  scroll     = 0x0A,  -- "@"
  mute       = 0x1B,  -- ")"
  pip        = 0x18,  -- "="
}

-- Renvoie l'identifiant de touche à lier (caractère ou keycode selon le mode).
local function keyFor(name)
  if USE_KEYCODES then return KEYCODE[name] else return KEYS[name] end
end


-- ---------------------------------------------------------------------------
--  HELPERS — repérage de la fenêtre TikTok
-- ---------------------------------------------------------------------------

-- Renvoie la fenêtre (hs.window) du navigateur dont le titre contient le
-- mot-clé TikTok, ou nil si aucune.
local function findTikTokWindow()
  local app = hs.application.get(CONFIG.browserApp)
  if not app then return nil end
  for _, win in ipairs(app:allWindows()) do
    local title = win:title() or ""
    if title:find(CONFIG.windowMatch, 1, true) then
      return win
    end
  end
  return nil
end

-- Petit message à l'écran (équivalent du ToolTip Windows).
local function notify(msg)
  hs.alert.closeAll()
  hs.alert.show(msg, 1.2)
end

-- Renvoie l'écran (hs.screen) correspondant à monitorIndex (1-based), ou le
-- principal si l'index dépasse le nombre d'écrans.
local function screenForIndex(idx)
  local screens = hs.screen.allScreens()
  if idx < 1 or idx > #screens then
    return hs.screen.primaryScreen()
  end
  return screens[idx]
end


-- ---------------------------------------------------------------------------
--  OUVERTURE / FOCUS DE TIKTOK SUR LE 2e ÉCRAN  —  touche "à"
-- ---------------------------------------------------------------------------
local function openTikTok()
  local win = findTikTokWindow()
  if win then
    -- Déjà ouvert : on le replace sur le bon écran (plein cadre).
    local screen = screenForIndex(CONFIG.monitorIndex)
    win:moveToScreen(screen)
    win:maximize()
    return
  end

  -- Pas encore ouvert : on lance l'URL dans le navigateur choisi.
  hs.execute(string.format('open -a "%s" "%s"', CONFIG.browserApp, CONFIG.url))

  -- On attend l'apparition de la fenêtre puis on la place sur le 2e écran.
  hs.timer.waitUntil(
    function() return findTikTokWindow() ~= nil end,
    function()
      local w = findTikTokWindow()
      if w then
        w:moveToScreen(screenForIndex(CONFIG.monitorIndex))
        w:maximize()
      end
    end,
    0.3  -- vérifie toutes les 300 ms (s'arrête dès que trouvé)
  )
end


-- ---------------------------------------------------------------------------
--  SCROLL EN ARRIÈRE-PLAN  —  touche "@"  (le coeur du projet)
-- ---------------------------------------------------------------------------
--  macOS n'a pas d'équivalent au PostMessage(WM_MOUSEWHEEL) de Windows : un
--  événement de scroll va à la fenêtre située SOUS LE CURSEUR. Astuce pour ne
--  PAS voler le focus à League : on déplace le curseur sur la fenêtre TikTok
--  (2e écran) le temps de poster le scroll, puis on le remet exactement où il
--  était. Le FOCUS CLAVIER, lui, ne bouge pas -> League continue de recevoir
--  tes touches/clics.
--
--  direction : -1 = vers le bas (vidéo suivante), +1 = vers le haut.
-- ---------------------------------------------------------------------------
local function scrollTikTok(direction)
  local win = findTikTokWindow()
  if not win then
    notify("TikTok pas ouvert — appuie sur 'à' pour le lancer.")
    return
  end

  -- Centre de la fenêtre TikTok (coordonnées écran global).
  local f = win:frame()
  local target = hs.geometry.point(f.x + f.w / 2, f.y + f.h / 2)

  -- On mémorise la position réelle du curseur pour la restaurer après.
  local origin = hs.mouse.absolutePosition()

  -- On place le curseur sur TikTok SANS cliquer ni activer la fenêtre.
  hs.mouse.absolutePosition(target)

  -- Lignes de scroll : signe négatif = vers le bas dans le repère macOS.
  local lines = -direction * CONFIG.wheelLines

  for _ = 1, CONFIG.wheelClicks do
    -- newScrollEvent({horiz, vert}, modifiers, unit). unit "line" = crans.
    hs.eventtap.event.newScrollEvent({ 0, lines }, {}, "line"):post()
    hs.timer.usleep(8000)  -- 8 ms entre les crans
  end

  -- On remet le curseur exactement où il était.
  hs.mouse.absolutePosition(origin)
end


-- ---------------------------------------------------------------------------
--  MUTE / UNMUTE  —  touche ")"
-- ---------------------------------------------------------------------------
--  Sur TikTok web, la touche "m" coupe / remet le son. On l'envoie à
--  l'application du navigateur SANS l'activer (keyStroke ciblé sur l'app).
-- ---------------------------------------------------------------------------
local function toggleMuteTikTok()
  local win = findTikTokWindow()
  if not win then
    notify("TikTok pas ouvert — appuie sur 'à' pour le lancer.")
    return
  end
  local app = win:application()
  if app then
    -- Envoi de "m" à l'app navigateur sans changer le focus clavier global.
    hs.eventtap.keyStroke({}, "m", 0, app)
  end
end


-- ---------------------------------------------------------------------------
--  PICTURE-IN-PICTURE  —  touche "="
-- ---------------------------------------------------------------------------
--  PiP natif du navigateur via l'extension Google (raccourci ⌥P). Comme sur
--  Windows, les combos avec ⌥/Alt passent mal sans focus réel : par défaut on
--  donne un bref focus à TikTok, on envoie le raccourci, puis on rend le focus
--  à League (la fenêtre qui était active avant).
-- ---------------------------------------------------------------------------
local function togglePictureInPicture()
  local win = findTikTokWindow()
  if not win then
    notify("TikTok pas ouvert — appuie sur 'à' pour le lancer.")
    return
  end

  if CONFIG.pipAllowFocusFallback then
    -- Fenêtre active avant (typiquement League) pour lui rendre le focus après.
    local prev = hs.window.focusedWindow()
    win:focus()
    hs.timer.doAfter(0.12, function()
      hs.eventtap.keyStroke(CONFIG.pipShortcut.mods, CONFIG.pipShortcut.key)
      -- On rend le focus à ce qui était actif avant (League), si possible.
      hs.timer.doAfter(0.12, function()
        if prev then prev:focus() end
      end)
    end)
  else
    -- Mode "zéro focus volé" : envoi direct à l'app navigateur (moins fiable
    -- pour les combos ⌥ selon le navigateur).
    local app = win:application()
    if app then
      hs.eventtap.keyStroke(CONFIG.pipShortcut.mods, CONFIG.pipShortcut.key, 0, app)
    end
  end
end


-- ---------------------------------------------------------------------------
--  LIAISON DES TOUCHES (hotkeys globales)
-- ---------------------------------------------------------------------------
-- La forme { } comme modificateur = touche seule, aucun modificateur requis.

-- à -> ouvrir / focus TikTok
hs.hotkey.bind({}, keyFor("openTikTok"), openTikTok)

-- @ -> vidéo suivante (scroll bas) ; Maj+@ -> vidéo précédente (scroll haut)
hs.hotkey.bind({}, keyFor("scroll"), function() scrollTikTok(-1) end)
hs.hotkey.bind({ "shift" }, keyFor("scroll"), function() scrollTikTok(1) end)

-- ) -> mute / unmute
hs.hotkey.bind({}, keyFor("mute"), toggleMuteTikTok)

-- = -> Picture-in-Picture
hs.hotkey.bind({}, keyFor("pip"), togglePictureInPicture)


-- Petit signal au chargement pour confirmer que le script tourne.
hs.alert.show("🧠💀 Brainrot Companion chargé — à / @ / ) / =", 2)
