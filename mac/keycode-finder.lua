-- ===========================================================================
--  KEYCODE FINDER  —  outil d'aide pour Brainrot Companion (macOS)
-- ---------------------------------------------------------------------------
--  À utiliser si une touche ne réagit pas dans brainrot.lua (les claviers
--  AZERTY/ISO Mac varient). Ce script affiche le KEYCODE de chaque touche que
--  tu presses : appuie sur la touche voulue (à / @ / ) / =), note son numéro,
--  puis reporte-le dans brainrot.lua (table KEYCODE) avec USE_KEYCODES = true.
--
--  UTILISATION :
--    1) Ouvre la console Hammerspoon (clic sur l'icône > Console), OU
--       remplace temporairement ton init.lua par ce fichier et recharge.
--    2) Appuie sur les touches : leur keycode s'affiche en alerte + console.
--    3) Quand tu as les 4 valeurs, remets brainrot.lua et reporte-les.
--    4) Ferme/recharge pour arrêter l'écoute (ce listener capte TOUTES les
--       touches le temps qu'il tourne — ne le laisse pas actif en jeu).
-- ===========================================================================

local finder = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
  local code = e:getKeyCode()
  local char = e:getCharacters(true) or "?"
  local msg = string.format("keycode = 0x%02X (%d)   touche: %s", code, code, char)
  print("[keycode-finder] " .. msg)   -- visible dans la console Hammerspoon
  hs.alert.closeAll()
  hs.alert.show(msg, 1.5)
  -- false = on ne bloque pas la touche (elle agit normalement aussi).
  return false
end)

finder:start()
hs.alert.show("🔎 Keycode Finder actif — appuie sur une touche", 3)

-- Astuce : pour l'arrêter sans recharger, exécute  finder:stop()  dans la
-- console Hammerspoon.
