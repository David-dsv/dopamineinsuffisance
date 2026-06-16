#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode("Input")

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
}


; ----------------------------------------------------------------------------
;  HOTKEYS
; ----------------------------------------------------------------------------
; Note : "à" et "²" sont des touches d'un clavier AZERTY (FR).
;   - "²" correspond au scancode SC029 (la touche au-dessus de Tab).
;   - "à" correspond à la touche du "0" / "à" : SC00B.
; On utilise les scancodes pour rester fiable quelle que soit la disposition.

SC00B::OpenTikTok()          ; touche "à"  -> ouvrir / focus TikTok
SC029::ScrollTikTok(-1)      ; touche "²"  -> vidéo suivante (scroll bas)
+SC029::ScrollTikTok(+1)     ; Maj + "²"   -> vidéo précédente (scroll haut)
SC00D::ToggleMuteTikTok()    ; touche ")"  -> mute / unmute TikTok


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

; Renvoie le hwnd de la 1re fenêtre dont le titre contient le mot-clé TikTok.
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
