#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode("Input")

; (Le mode PiP utilise le Picture-in-Picture natif du navigateur — aucun état
;  global à maintenir : c'est Chrome qui gère la mini-fenêtre flottante.)

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
;     =   -> Picture-in-Picture : détache la vidéo TikTok en mini-fenêtre
;            flottante (PiP natif du navigateur). Voir prérequis ci-dessous.
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

    ; --- Picture-in-Picture (touche "=") ---
    ; PRÉREQUIS : installe l'extension Google "Picture-in-Picture" (gratuite,
    ;   1 clic) sur ton Chrome. Elle ajoute le raccourci Alt+P qui détache la
    ;   vidéo en cours dans une mini-fenêtre flottante :
    ;   https://chromewebstore.google.com/detail/picture-in-picture-extension/hkgfoiooedgoejojocmhlaklaeopbecg
    ;
    ; Raccourci que l'extension écoute pour (dé)clencher le PiP.
    ; Format AHK : "!p" = Alt+P. Si tu changes le raccourci de l'extension,
    ; mets-le ici dans la même syntaxe (ex: "^." = Ctrl+. ).
    static pipShortcut := "!p"

    ; Si le raccourci envoyé en arrière-plan ne marche pas, on autorise un bref
    ; passage de focus sur TikTok (puis retour à League) pour le déclencher.
    ; Mets false si tu ne veux JAMAIS de focus volé (mais le PiP peut échouer).
    static pipAllowFocusFallback := true

    ; Chrome ouvre la fenêtre PiP près de l'onglet source (souvent le 2e écran).
    ; On la REPLACE ensuite sur l'écran principal, dans le coin haut-gauche.
    ; Mets pipMoveToMain := false pour laisser Chrome décider (pas de déplacement).
    static pipMoveToMain := true
    ; Écran de destination de la fenêtre PiP (1 = principal).
    static pipMonitorIndex := 1
    ; Position depuis le coin haut-gauche de cet écran, en pixels.
    static pipX := 20
    static pipY := 20

    ; Largeur MAX de la fenêtre PiP (px). Les vidéos paysage rendent une fenêtre
    ; large qui bloque la vue : on la plafonne ici. La vidéo paysage sera alors
    ; petite, mais ne mangera plus tout l'écran. 0 = pas de limite.
    static pipMaxWidth := 380

    ; Fenêtre PiP INCLIQUABLE (click-through) : les clics traversent la fenêtre
    ; vers League -> tu continues à cliquer dans ton jeu même "à travers" la PiP.
    ; (Le scroll/mute passent par les touches, pas par la souris, donc OK.)
    static pipClickThrough := true

    ; Titre de la fenêtre PiP, pour la repérer. Chrome FR = "Image dans l'image",
    ; EN = "Picture-in-Picture". On matche les deux par mots-clés (voir code).
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
SC00D::TogglePictureInPicture() ; touche "="  -> PiP : détache la vidéo TikTok


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
;  PICTURE-IN-PICTURE (mini-fenêtre vidéo flottante)  —  touche "="
; ----------------------------------------------------------------------------
;  On utilise le PiP NATIF du navigateur : Chrome détache la vidéo en cours
;  dans une petite fenêtre flottante, always-on-top, gérée par le navigateur
;  lui-même (pas de capture, pas de DLL, pas de 2e fenêtre TikTok).
;
;  Déclenchement : l'extension Google "Picture-in-Picture" écoute Alt+P. On
;  envoie ce raccourci à la fenêtre TikTok. Réappuyer referme le PiP (le même
;  raccourci fait toggle). PRÉREQUIS : extension installée (voir Config).
;
;  Stratégie focus (pipAllowFocusFallback dans Config) :
;    - true  (défaut) : bref focus sur TikTok -> Alt+P -> retour focus à League.
;                       Le plus fiable (les combos Alt passent mal sans focus).
;    - false          : envoi en arrière-plan (ControlSend), zéro focus volé,
;                       mais le PiP peut ne pas se déclencher selon le navigateur.
;  On envoie le raccourci UNE seule fois (il fait toggle ouvrir/fermer).
; ----------------------------------------------------------------------------
TogglePictureInPicture() {
    hwnd := FindTikTokWindow()
    if (!hwnd) {
        ToolTip("TikTok pas ouvert — appuie sur 'à' pour le lancer.")
        SetTimer(() => ToolTip(), -1500)
        return
    }

    ; Une fenêtre PiP est-elle DÉJÀ ouverte ? Si oui, cet appui va la FERMER
    ; (toggle) -> inutile de chercher à déplacer quoi que ce soit ensuite.
    pipBefore := FindPipWindow()

    ; IMPORTANT : on n'envoie le raccourci QU'UNE fois (sinon le PiP s'ouvre
    ; puis se referme, car le même raccourci fait toggle).
    if (Config.pipAllowFocusFallback) {
        ; Méthode bref-focus (la plus fiable pour un combo Alt+touche) :
        ; on active TikTok le temps d'envoyer Alt+P, puis on rend le focus.
        prevActive := WinActive("A")          ; fenêtre active avant (League)
        WinActivate(hwnd)
        if (WinWaitActive("ahk_id " hwnd, , 0.4)) {
            Send(Config.pipShortcut)
            Sleep(120)                        ; laisse l'extension réagir
        }
        ; On rend le focus à ce qui était actif avant (League), si possible.
        if (prevActive && WinExist("ahk_id " prevActive))
            WinActivate("ahk_id " prevActive)
    } else {
        ; Mode "zéro focus volé" : on tente en arrière-plan (peut échouer selon
        ; le navigateur, car les combos Alt passent mal sans focus réel).
        try ControlSend(Config.pipShortcut, , hwnd)
    }

    ; Si c'était une OUVERTURE (aucun PiP avant) et qu'on veut la replacer,
    ; on attend que Chrome crée sa fenêtre PiP puis on la pousse sur l'écran 1.
    if (Config.pipMoveToMain && !pipBefore) {
        if (pip := WaitForPipWindow(2500))
            MovePipToMain(pip)
    }
}

; Repère la fenêtre Picture-in-Picture du navigateur, ou 0 si aucune.
; Chrome nomme cette fenêtre "Picture-in-Picture" (EN) ou "Image dans l'image"
; (FR). On matche sur ces titres (mode "contient", insensible aux variantes).
FindPipWindow() {
    SetTitleMatchMode(2)
    for title in ["Picture-in-Picture", "Picture in picture", "Image dans l'image"] {
        if (id := WinExist(title))
            return id
    }
    return 0
}

; Attend l'apparition d'une fenêtre PiP (timeout en ms). Renvoie hwnd ou 0.
WaitForPipWindow(timeout) {
    endTime := A_TickCount + timeout
    while (A_TickCount < endTime) {
        if (id := FindPipWindow())
            return id
        Sleep(80)
    }
    return 0
}

; Place la fenêtre PiP en haut-gauche de l'écran principal, plafonne sa largeur
; (pour que les vidéos paysage ne bloquent pas la vue) et la rend incliquable.
MovePipToMain(pip) {
    idx := Config.pipMonitorIndex
    count := MonitorGetCount()
    if (idx > count)
        idx := count
    ; MonitorGetWorkArea = zone hors barre des tâches -> coin propre.
    MonitorGetWorkArea(idx, &left, &top, &right, &bottom)

    x := left + Config.pipX
    y := top + Config.pipY

    ; Taille actuelle (Chrome la fixe selon le ratio de la vidéo).
    WinGetPos(, , &w, &h, pip)

    ; Plafond de largeur : si trop large (vidéo paysage), on réduit largeur ET
    ; hauteur dans le MÊME ratio -> la vidéo reste correcte, juste plus petite.
    if (Config.pipMaxWidth > 0 && w > Config.pipMaxWidth) {
        scale := Config.pipMaxWidth / w
        w := Config.pipMaxWidth
        h := Round(h * scale)
    }

    WinMove(x, y, w, h, pip)
    WinSetAlwaysOnTop(1, pip)          ; reste par-dessus League (déjà le cas)

    ; Click-through : les clics traversent la PiP vers League.
    if (Config.pipClickThrough)
        MakeWindowClickThrough(pip)
}

; Rend une fenêtre incliquable : la souris la traverse (clics -> fenêtre du
; dessous, ex: League). On ajoute les styles étendus WS_EX_LAYERED + TRANSPARENT
; (TRANSPARENT seul exige LAYERED pour que le click-through fonctionne).
MakeWindowClickThrough(hwnd) {
    static WS_EX_LAYERED     := 0x80000
    static WS_EX_TRANSPARENT := 0x20
    static LWA_ALPHA         := 0x2

    ex := WinGetExStyle(hwnd)
    WinSetExStyle(ex | WS_EX_LAYERED | WS_EX_TRANSPARENT, hwnd)

    ; LAYERED rend la fenêtre invisible tant qu'on n'a pas fixé son opacité :
    ; on force 255 (totalement opaque) pour que la PiP reste bien visible.
    DllCall("SetLayeredWindowAttributes"
        , "Ptr", hwnd, "UInt", 0, "UChar", 255, "UInt", LWA_ALPHA)
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
