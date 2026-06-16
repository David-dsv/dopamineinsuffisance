#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode("Input")

; ----------------------------------------------------------------------------
;  ÉTAT GLOBAL
; ----------------------------------------------------------------------------
; hwnd de la mini-fenêtre PiP (overlay) quand elle est ouverte, sinon 0.
global gPipHwnd := 0

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
;     =   -> mini-fenêtre PiP nue en haut à gauche de l'écran principal (on/off)
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

    ; --- Mini-fenêtre PiP (overlay sur l'écran principal) ---
    ; Taille de la petite fenêtre TikTok flottante, en pixels.
    static pipWidth := 380
    static pipHeight := 680
    ; Position depuis le coin haut-gauche de l'écran principal, en pixels.
    static pipX := 20
    static pipY := 20
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
SC00D::TogglePip()           ; touche "="  -> mini-fenêtre PiP overlay on/off


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
;  MINI-FENÊTRE PiP (overlay sur l'écran principal)  —  touche "="
; ----------------------------------------------------------------------------
;  Toggle : 1er appui -> ouvre une petite fenêtre TikTok NUE (sans aucune
;  bordure ni barre d'URL) en haut à gauche, épinglée par-dessus League.
;  2e appui -> la ferme. Indépendant de la version 2e écran (touche "à").
;
;  On garde le hwnd de l'overlay dans une globale pour le fermer précisément,
;  même si une autre fenêtre TikTok (2e écran) est ouverte en parallèle.
;  (La globale gPipHwnd est déclarée en haut du fichier, section ÉTAT GLOBAL.)
; ----------------------------------------------------------------------------
TogglePip() {
    global gPipHwnd

    ; Déjà ouverte et toujours valide -> on la ferme.
    if (gPipHwnd && WinExist("ahk_id " gPipHwnd)) {
        WinClose("ahk_id " gPipHwnd)
        gPipHwnd := 0
        return
    }
    gPipHwnd := 0

    ; On mémorise les fenêtres TikTok déjà présentes pour repérer la NOUVELLE.
    SetTitleMatchMode(2)
    before := Map()
    for id in WinGetList(Config.windowMatch)
        before[id] := true

    ; Lancement en mode "--app" : fenêtre épurée, sans onglets ni barre d'URL.
    ; (Chrome ET Edge supportent --app, donc on l'utilise même par défaut.)
    exe := Config.browserPath != "" ? Config.browserPath : DefaultChromiumExe()
    if (!exe) {
        ToolTip("Mode PiP : Chrome ou Edge requis. Renseigne browserPath.")
        SetTimer(() => ToolTip(), -2500)
        return
    }
    Run('"' exe '" --app="' Config.url '"'
        . ' --window-size=' Config.pipWidth ',' Config.pipHeight
        . ' --window-position=' Config.pipX ',' Config.pipY)

    ; On attend l'apparition de la fenêtre qui n'était PAS là avant.
    pip := WaitForNewTikTokWindow(before, 8000)
    if (!pip) {
        ToolTip("Mode PiP : la fenêtre n'est pas apparue.")
        SetTimer(() => ToolTip(), -2500)
        return
    }

    gPipHwnd := pip
    StripWindowChrome(pip)                 ; enlève la barre de titre Windows
    WinMove(Config.pipX, Config.pipY, Config.pipWidth, Config.pipHeight, pip)
    WinSetAlwaysOnTop(1, pip)              ; reste visible par-dessus League
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
; Si la mini-fenêtre PiP (overlay) est ouverte, on la priorise : c'est celle
; que l'utilisateur regarde en mode overlay. Sinon, 1re fenêtre TikTok trouvée.
FindTikTokWindow() {
    global gPipHwnd
    if (gPipHwnd && WinExist("ahk_id " gPipHwnd))
        return gPipHwnd

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

; Attend qu'une fenêtre TikTok ABSENTE de `before` apparaisse. Renvoie hwnd ou 0.
; Sert à isoler la mini-fenêtre PiP qu'on vient juste de lancer.
WaitForNewTikTokWindow(before, timeout) {
    SetTitleMatchMode(2)
    endTime := A_TickCount + timeout
    while (A_TickCount < endTime) {
        for id in WinGetList(Config.windowMatch) {
            if (!before.Has(id) && WinGetTitle(id) != "")
                return id
        }
        Sleep(120)
    }
    return 0
}

; Retire la barre de titre / le cadre Windows d'une fenêtre -> rendu "nu".
; On enlève les styles WS_CAPTION et WS_THICKFRAME puis on force le rafraîchi.
StripWindowChrome(hwnd) {
    static WS_CAPTION := 0x00C00000
    static WS_THICKFRAME := 0x00040000
    style := WinGetStyle(hwnd)
    WinSetStyle(style & ~WS_CAPTION & ~WS_THICKFRAME, hwnd)
    ; SWP_FRAMECHANGED|SWP_NOMOVE|SWP_NOSIZE|SWP_NOZORDER = 0x27 -> applique le
    ; changement de cadre sans bouger/redimensionner.
    DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0
        , "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x27)
}

; Tente de localiser l'exécutable Chrome puis Edge dans les emplacements
; standards. Renvoie le chemin trouvé ou "" si aucun.
DefaultChromiumExe() {
    candidates := [
        EnvGet("ProgramFiles") "\Google\Chrome\Application\chrome.exe",
        EnvGet("ProgramFiles(x86)") "\Google\Chrome\Application\chrome.exe",
        EnvGet("LocalAppData") "\Google\Chrome\Application\chrome.exe",
        EnvGet("ProgramFiles") "\Microsoft\Edge\Application\msedge.exe",
        EnvGet("ProgramFiles(x86)") "\Microsoft\Edge\Application\msedge.exe",
    ]
    for path in candidates {
        if FileExist(path)
            return path
    }
    return ""
}
