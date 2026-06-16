#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode("Input")

; À la fermeture du script, on libère l'API Magnification si elle a été init.
OnExit(CleanupMirror)

; ----------------------------------------------------------------------------
;  ÉTAT GLOBAL
; ----------------------------------------------------------------------------
; Objet GUI de la fenêtre miroir quand elle est ouverte, sinon 0.
global gMirrorGui := 0
; hwnd du contrôle "Magnifier" à l'intérieur de la fenêtre miroir.
global gMagHwnd := 0
; true si Magnification.dll a bien été initialisée (MagInitialize).
global gMagReady := false

; ============================================================================
;  BRAINROT COMPANION  —  TikTok scroller pour gamers League of Legends
; ----------------------------------------------------------------------------
;  Concept : pendant ta game, ton 2e écran affiche TikTok. Tu scrolles les
;  vidéos SANS jamais quitter League : le scroll est envoyé directement à la
;  fenêtre du navigateur en arrière-plan. Aucun alt-tab, aucun focus volé.
;
;  Touches :
;     à   -> ouvre (ou met au premier plan) TikTok sur le 2e écran
;     ²   -> scrolle d'une vidéo (vers le bas)
;     Maj + ²  -> scrolle vers le haut (vidéo précédente)
;     )   -> mute / unmute la vidéo
;     =   -> MIROIR live du 2e écran en haut à gauche de l'écran principal (on/off)
;
;  Config tout en bas du fichier (chemin du navigateur, écran, touches...).
; ============================================================================


; ----------------------------------------------------------------------------
;  CONFIGURATION
; ----------------------------------------------------------------------------
class Config {
    ; URL ouverte au lancement
    static url := "https://www.tiktok.com"

    ; Chemin du navigateur. Laisse "" pour utiliser le navigateur par défaut.
    ; Exemples :
    ;   "C:\Program Files\Google\Chrome\Application\chrome.exe"
    ;   "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    static browserPath := ""

    ; Sur quel écran ouvrir TikTok. 1 = écran principal, 2 = secondaire, etc.
    ; (Sert à placer la fenêtre ET à savoir où envoyer le scroll.)
    static monitorIndex := 2

    ; Fraction d'une "encoche" de molette par appui. 120 = un cran complet de
    ; molette classique. TikTok web change de vidéo avec un scroll franc, donc
    ; on envoie plusieurs crans d'un coup pour bien déclencher le changement.
    static wheelClicks := 3        ; nombre de crans envoyés par appui
    static wheelDelta := 120       ; valeur Windows standard d'un cran

    ; Mot(s)-clé recherché(s) dans le titre de la fenêtre du navigateur pour
    ; reconnaître l'onglet TikTok.
    static windowMatch := "TikTok"

    ; --- Miroir live du 2e écran (overlay sur l'écran principal) — touche "=" ---
    ; Le miroir recopie en direct une ZONE du 2e écran (là où TikTok est
    ; maximisé) dans une petite fenêtre flottante, par-dessus League.
    ;
    ; Taille de la fenêtre miroir, en pixels (ratio vertical type TikTok 9:16).
    static mirrorWidth := 380
    static mirrorHeight := 680
    ; Position depuis le coin haut-gauche de l'écran principal, en pixels.
    static mirrorX := 20
    static mirrorY := 20
    ; Rafraîchissements par seconde du miroir. 30 = fluide et léger ; monte à 60
    ; pour plus de fluidité (un peu plus de CPU/GPU).
    static mirrorFps := 30
    ; Quel écran on recopie. Par défaut le même que TikTok (monitorIndex).
    ; Laisse 0 pour suivre automatiquement monitorIndex.
    static mirrorSourceMonitor := 0
}


; ----------------------------------------------------------------------------
;  HOTKEYS
; ----------------------------------------------------------------------------
; Note : "à" et "²" sont des touches d'un clavier AZERTY (FR).
;   - "²" correspond au scancode SC029 (la touche au-dessus de Tab).
;   - "à" correspond à la touche du "0" / "à" : SC00B.
; On utilise les scancodes pour rester fiable quelle que soit la disposition.

SC00B::OpenTikTok()          ; touche "à"  -> ouvrir / focus TikTok (2e écran)
SC029::ScrollTikTok(-1)      ; touche "²"  -> vidéo suivante (scroll bas)
+SC029::ScrollTikTok(+1)     ; Maj + "²"   -> vidéo précédente (scroll haut)
SC00C::ToggleMuteTikTok()    ; touche ")"  -> mute / unmute TikTok
SC00D::ToggleMirror()        ; touche "="  -> miroir live du 2e écran on/off


; ----------------------------------------------------------------------------
;  OUVERTURE / MISE AU PREMIER PLAN DE TIKTOK
; ----------------------------------------------------------------------------
OpenTikTok() {
    hwnd := FindTikTokWindow()
    if (hwnd) {
        ; Déjà ouvert : on le replace sur le bon écran, sans voler le focus
        ; à League plus que nécessaire (juste le temps de le positionner).
        PlaceWindowOnMonitor(hwnd, Config.monitorIndex)
        return
    }

    ; Pas encore ouvert : on lance le navigateur sur l'URL TikTok.
    if (Config.browserPath != "") {
        Run('"' Config.browserPath '" --new-window "' Config.url '"')
    } else {
        Run(Config.url)   ; navigateur par défaut
    }

    ; On attend que la fenêtre apparaisse puis on la place sur le 2e écran.
    if (newHwnd := WaitForTikTokWindow(8000)) {
        PlaceWindowOnMonitor(newHwnd, Config.monitorIndex)
    }
}


; ----------------------------------------------------------------------------
;  MIROIR LIVE DU 2e ÉCRAN (overlay sur l'écran principal)  —  touche "="
; ----------------------------------------------------------------------------
;  Au lieu d'ouvrir une 2e fenêtre TikTok (galère : Chrome, extension, etc.),
;  on RECOPIE EN DIRECT une zone du 2e écran — là où TikTok est déjà maximisé —
;  dans une petite fenêtre flottante par-dessus League. Aucun navigateur en
;  plus, aucun focus volé : c'est juste une "loupe" temps réel de l'écran 2.
;
;  Techniquement : on utilise l'API Windows "Magnification" (Magnification.dll).
;  Elle fournit un contrôle (classe "Magnifier") qui sait afficher en live le
;  contenu d'un rectangle de l'écran. On le met dans une fenêtre GUI nue,
;  always-on-top, et un timer rafraîchit la source N fois par seconde.
;
;  Toggle : 1er appui -> ouvre le miroir. 2e appui -> le ferme.
; ----------------------------------------------------------------------------
ToggleMirror() {
    global gMirrorGui

    ; Déjà ouvert -> on ferme.
    if (gMirrorGui) {
        CloseMirror()
        return
    }
    OpenMirror()
}

OpenMirror() {
    global gMirrorGui, gMagHwnd, gMagReady

    ; Init de l'API Magnification (une seule fois par exécution du script).
    if (!gMagReady) {
        if (!DllCall("Magnification\MagInitialize", "Int")) {
            ToolTip("Miroir : Magnification.dll indisponible sur ce Windows.")
            SetTimer(() => ToolTip(), -3000)
            return
        }
        gMagReady := true
    }

    ; --- Fenêtre hôte : nue, sans bordure, always-on-top, par-dessus League ---
    ; +E0x80000 = WS_EX_LAYERED, requis par l'API Magnification pour l'hôte.
    g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x80000")
    g.BackColor := "000000"
    g.Show("x" Config.mirrorX " y" Config.mirrorY
         . " w" Config.mirrorWidth " h" Config.mirrorHeight " NoActivate")

    ; --- Contrôle "Magnifier" enfant, qui remplit toute la fenêtre hôte -------
    ; WS_CHILD(0x40000000)|WS_VISIBLE(0x10000000) ; classe "Magnifier".
    mag := DllCall("CreateWindowEx"
        , "UInt", 0
        , "Str", "Magnifier"
        , "Str", "MagnifierControl"
        , "UInt", 0x40000000 | 0x10000000
        , "Int", 0, "Int", 0
        , "Int", Config.mirrorWidth, "Int", Config.mirrorHeight
        , "Ptr", g.Hwnd
        , "Ptr", 0
        , "Ptr", 0
        , "Ptr", 0
        , "Ptr")

    if (!mag) {
        g.Destroy()
        ToolTip("Miroir : impossible de créer le contrôle Magnifier.")
        SetTimer(() => ToolTip(), -3000)
        return
    }

    gMirrorGui := g
    gMagHwnd := mag

    ; Premier cadrage de la source + démarrage du rafraîchissement live.
    ; Timer RÉPÉTITIF (période positive en ms) : re-capture l'écran 2 N fps.
    UpdateMirrorSource()
    fps := Config.mirrorFps > 0 ? Config.mirrorFps : 30
    SetTimer(UpdateMirrorSource, Round(1000 / fps))

    ; On force la fenêtre tout en haut sans lui donner le focus (League garde la main).
    WinSetAlwaysOnTop(1, g.Hwnd)
}

CloseMirror() {
    global gMirrorGui, gMagHwnd
    SetTimer(UpdateMirrorSource, 0)     ; stoppe le rafraîchissement
    if (gMirrorGui) {
        try gMirrorGui.Destroy()
    }
    gMirrorGui := 0
    gMagHwnd := 0
}

; Indique au contrôle Magnifier QUELLE zone de l'écran recopier (le 2e écran),
; et l'ÉTIRE pour remplir la petite fenêtre. Appelé en boucle par le timer :
; c'est ce qui rend l'image "live" (le contrôle re-capture à chaque appel).
UpdateMirrorSource() {
    global gMirrorGui, gMagHwnd
    if (!gMirrorGui || !gMagHwnd)
        return

    ; Écran source : celui de TikTok, sauf override explicite dans la config.
    idx := Config.mirrorSourceMonitor > 0
         ? Config.mirrorSourceMonitor : Config.monitorIndex
    count := MonitorGetCount()
    if (idx > count)
        idx := count
    MonitorGet(idx, &left, &top, &right, &bottom)

    ; RECT source = tout l'écran à recopier. On le passe par un buffer (4x Int32).
    rect := Buffer(16, 0)
    NumPut("Int", left,   rect, 0)
    NumPut("Int", top,    rect, 4)
    NumPut("Int", right,  rect, 8)
    NumPut("Int", bottom, rect, 12)

    ; MagSetWindowSource(hwndMag, RECT) : définit la zone capturée. Le contrôle
    ; étire automatiquement cette zone pour remplir sa propre taille (notre
    ; petite fenêtre) -> le 2e écran apparaît réduit dans le miroir.
    DllCall("Magnification\MagSetWindowSource", "Ptr", gMagHwnd, "Ptr", rect, "Int")
}


; ----------------------------------------------------------------------------
;  SCROLL EN ARRIÈRE-PLAN (le coeur du projet)
; ----------------------------------------------------------------------------
;  direction : -1 = vers le bas (vidéo suivante), +1 = vers le haut.
;  On envoie WM_MOUSEWHEEL directement au contrôle de la fenêtre du navigateur.
;  Aucun changement de focus -> League continue de recevoir tes inputs.
; ----------------------------------------------------------------------------
ScrollTikTok(direction) {
    hwnd := FindTikTokWindow()
    if (!hwnd) {
        ToolTip("TikTok pas ouvert — appuie sur 'à' pour le lancer.")
        SetTimer(() => ToolTip(), -1500)
        return
    }

    ; Point cible au centre de la fenêtre TikTok (coordonnées écran).
    WinGetPos(&wx, &wy, &ww, &wh, hwnd)
    px := wx + ww // 2
    py := wy + wh // 2

    ; lParam = position du curseur (x dans les 16 bits bas, y dans les hauts).
    lParam := (py << 16) | (px & 0xFFFF)

    ; On vise le contrôle réel sous le point (le rendu de la page web), sinon
    ; le scroll est souvent ignoré si on l'envoie à la fenêtre racine.
    target := ControlUnderPoint(px, py)
    if (!target)
        target := hwnd

    Loop Config.wheelClicks {
        ; wParam : delta de molette dans les 16 bits hauts (signé).
        delta := direction * Config.wheelDelta
        wParam := (delta & 0xFFFF) << 16

        ; WM_MOUSEWHEEL = 0x020A. PostMessage = asynchrone, ne bloque pas.
        PostMessage(0x020A, wParam, lParam, , target)
        Sleep(8)
    }
}

; ----------------------------------------------------------------------------
;  MUTE / UNMUTE EN ARRIÈRE-PLAN
; ----------------------------------------------------------------------------
;  Sur TikTok web, la touche "m" coupe / remet le son de la vidéo. On l'envoie
;  directement à la fenêtre du navigateur via ControlSend -> pas de focus volé,
;  League continue de tourner pendant que tu coupes le son des brainrots.
; ----------------------------------------------------------------------------
ToggleMuteTikTok() {
    hwnd := FindTikTokWindow()
    if (!hwnd) {
        ToolTip("TikTok pas ouvert — appuie sur 'à' pour le lancer.")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    ; "m" est le raccourci natif mute/unmute du lecteur TikTok web.
    ControlSend("m", , hwnd)
}

; Renvoie le hwnd du contrôle situé sous un point écran (x, y).
; AHK v2 n'a pas de "ControlFromPoint" : on appelle l'API Win32 WindowFromPoint.
ControlUnderPoint(x, y) {
    ; POINT est packé : x et y en Int32 successifs -> un seul Int64.
    pt := (y << 32) | (x & 0xFFFFFFFF)
    return DllCall("WindowFromPoint", "Int64", pt, "Ptr")
}


; ----------------------------------------------------------------------------
;  HELPERS
; ----------------------------------------------------------------------------

; Renvoie le hwnd de la fenêtre TikTok à cibler pour scroll/mute.
; (Le miroir n'est qu'un reflet du 2e écran : le scroll/mute vise toujours la
;  vraie fenêtre TikTok, et le miroir affiche le résultat en direct.)
FindTikTokWindow() {
    ; Match partiel sur le titre, peu importe le navigateur.
    SetTitleMatchMode(2)
    ids := WinGetList(Config.windowMatch)
    for id in ids {
        ; On ignore les fenêtres sans titre / outils.
        if WinGetTitle(id) != ""
            return id
    }
    return 0
}

; Attend que la fenêtre TikTok apparaisse (timeout en ms). Renvoie hwnd ou 0.
WaitForTikTokWindow(timeout) {
    SetTitleMatchMode(2)
    endTime := A_TickCount + timeout
    while (A_TickCount < endTime) {
        if (hwnd := FindTikTokWindow())
            return hwnd
        Sleep(150)
    }
    return 0
}

; Place et maximise une fenêtre sur l'écran d'index donné (1-based).
PlaceWindowOnMonitor(hwnd, idx) {
    count := MonitorGetCount()
    if (idx > count)
        idx := count        ; pas de 2e écran ? on retombe sur le 1er.

    MonitorGet(idx, &left, &top, &right, &bottom)

    ; On dé-maximise d'abord pour pouvoir déplacer, puis on remaximise.
    WinRestore(hwnd)
    WinMove(left, top, right - left, bottom - top, hwnd)
    WinMaximize(hwnd)
}

; Libère proprement l'API Magnification quand le script se ferme.
CleanupMirror(*) {
    global gMagReady
    if (gMagReady) {
        try DllCall("Magnification\MagUninitialize", "Int")
        gMagReady := false
    }
}
