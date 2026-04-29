#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

EnsureSingleInstance()
EnsureAdmin()

; =========================================================
; ATools NextGen | 02
; Modern AHK v2 UI
; Focus: reports, punishments, monitoring, settings
; =========================================================

appVersion := "1.2.7"
appTitle := "ATools NextGen | 02"
previewIconPath := A_ScriptDir "\preview.ico"
if FileExist(previewIconPath)
    try TraySetIcon(previewIconPath)
iniPath := A_ScriptDir "\config.ini"
roadPath := A_ScriptDir "\road.ini"
adminHelpUrl := "https://sites.google.com/view/admteamulrainegta?usp=sharing"
UGTA_BG_URL := "https://ukraine-gta.com.ua/images/pages/main/big-img.webp"
UGTA_LOGO_URL := "https://forum.ukraine-gta.com.ua/attachments/1680529092318-png.53613/"

Ranks := ["Ігровий помічник", "Модератор", "Старший модератор", "Адміністратор", "Ст.Адміністратор", "Заступник ГА", "Головний адміністратор"]

Theme := Map(
    "bg", "101010",
    "sidebar", "4B168F",
    "panel", "070707",
    "panel2", "3C136E",
    "field", "461875",
    "line", "151515",
    "text", "FFFFFF",
    "muted", "E9DDFB",
    "accent", "8A22D6",
    "accent2", "6D21D5",
    "danger", "E03636",
    "success", "00620E"
)
HoverCtrls := Map()
NavButtons := Map()
ActiveNavPage := ""
LastHoverHwnd := 0
BaseThemeColor := Theme["accent"]
ClickSoundFile := A_ScriptDir "\sounds\ui_click.wav"
StartupSoundFile := A_ScriptDir "\sounds\atools_start.wav"
NewReportSoundFile := A_ScriptDir "\sounds\new_report.wav"
NewFormSoundFile := A_ScriptDir "\sounds\new_form.wav"
UnansweredReportSoundFile := A_ScriptDir "\sounds\unanswered_report.wav"
SoundsEnabled := true
LastFormSoundKey := ""
LastReportSoundKey := ""
LastUnansweredSoundKey := ""

ReportPanelGui := ""
ReportPanelActiveKey := ""
ReportPanelItems := Map()
ReportPanelOrder := []
ReportPanelSeenKeys := Map()
ReportPanelMutedKeys := Map()
ReportPanelMaxAliveMs := 60000
ReportPanelAnsweredAliveMs := 30000
ReportPanelPlayerText := ""
ReportPanelStatusText := ""
ReportPanelTimerText := ""
ReportPanelHintText := ""
ReportPanelAccentBar := ""
ReportPanelLastBeepKey := ""
ReportPanelTitleText := ""
ReportPanelCloseText := ""
ReportPanelPosX := 20
ReportPanelPosY := 250
ReportPanelW := 340
ReportPanelH := 118

ConsoleLivePath := ""
ConsoleLiveOffset := 0
ConsoleLiveBuffer := ""
ConsoleLiveLines := []
ConsoleLiveReady := false
LastReportPanelLineIndex := 0
LastSoundLineIndex := 0
LastReportSoundTick := 0
CustomBgPath := ""
WindowTransparency := 255
ChatsActiveTab := "Віп-чат"
ChatsLastText := ""
F2PosX := 20
F2PosY := 20
BindHintsPosX := 20
BindHintsPosY := 360
RadialCommands := []
InitRadialCommands()

PlayUiClickSound() {
    PlayAtoolsSound("click")
}

PlayAtoolsSound(type := "click") {
    global ClickSoundFile, StartupSoundFile, NewReportSoundFile, NewFormSoundFile, UnansweredReportSoundFile, SoundsEnabled

    if (!SoundsEnabled)
        return

    soundFile := ClickSoundFile
    switch type {
        case "startup":
            soundFile := StartupSoundFile
        case "new_report":
            soundFile := NewReportSoundFile
        case "new_form":
            soundFile := NewFormSoundFile
        case "unanswered_report":
            soundFile := UnansweredReportSoundFile
        default:
            soundFile := ClickSoundFile
    }

    if FileExist(soundFile) {
        try SoundPlay(soundFile)
    }
}

WithClickSound(callback) {
    return (*) => (PlayUiClickSound(), callback())
}

IconPath(name) {
    png := A_ScriptDir "\\assets\\icons\\" name ".png"
    ico := A_ScriptDir "\\assets\\icons\\" name ".ico"
    return FileExist(png) ? png : ico
}

SafeAddPicture(guiObj, opts, path) {
    if !FileExist(path)
        return ""
    try {
        return guiObj.AddPicture(opts, path)
    } catch {
        return ""
    }
}

AddIconPicture(guiObj, x, y, w, h, name, page := "") {
    path := IconPath(name)
    if !FileExist(path)
        return ""
    try {
        ctrl := guiObj.AddPicture("x" x " y" y " w" w " h" h " BackgroundTrans", path)
        if (page != "")
            AddPageCtrl(page, ctrl)
        return ctrl
    }
    return ""
}

EnsureUGTAOfficialAssets() {
    global UGTA_BG_URL, UGTA_LOGO_URL
    try DirCreate(A_ScriptDir "\assets\bg")
    try DirCreate(A_ScriptDir "\assets\icons")
    bgFile := A_ScriptDir "\assets\bg\big-img.webp"
    logoFile := A_ScriptDir "\assets\icons\ugta_logo_official.png"
    if !FileExist(bgFile)
        try Download(UGTA_BG_URL, bgFile)
    if !FileExist(logoFile)
        try Download(UGTA_LOGO_URL, logoFile)
}

GetUGTABackgroundPath() {
    global CustomBgPath
    ; 1) Фон, який вибрав адміністратор у налаштуваннях.
    if (CustomBgPath != "" && FileExist(CustomBgPath))
        return CustomBgPath

    ; 2) Вбудований затемнений фон UGTA. PNG перший, щоб точно було видно фон, який ти скинув.
    customPng := A_ScriptDir "\assets\bg\custom_bg.png"
    png := A_ScriptDir "\assets\bg\ugta_bg_dark.png"
    bmp := A_ScriptDir "\assets\bg\ugta_bg_dark.bmp"
    if FileExist(customPng)
        return customPng
    if FileExist(png)
        return png
    if FileExist(bmp)
        return bmp
    return ""
}

GetUGTALogoPath() {
    official02 := A_ScriptDir "\assets\icons\server02_logo.png"
    return official02
}


Name := ""
Rank := Ranks[1]
nRank := 1
AppointmentDate := ""

Commands := []
CommandKeys := []
CommandKeys2 := []
Reports := []
ReportKeys := []
Loop 30 {
    Commands.Push("")
    CommandKeys.Push("")
    CommandKeys2.Push("")
}
; базові команди, які можна міняти у розділі Команди
Commands[1] := "sp"
Commands[2] := "pm"
Commands[3] := "resp"
Commands[4] := "jail"
Commands[5] := "mute"
Commands[6] := "kick"
Commands[7] := "unget"
Commands[8] := "admins"
Commands[9] := "a"
Commands[10] := "ahouse"
Loop 46 {
    Reports.Push("")
    ReportKeys.Push("")
}
Reports[1] := "Вітаю, на зв'язку {Rank} {Name}. Працюю по Вашій заявці."

EnableF2 := false
EnableF3 := false
EnableExtraCommands := false
EnableReportFollow := false
LastReportFollowAlertTick := 0
LastReportFollowAlertCount := 0
ReportFollowNotifyGui := ""
EnableAdminChatMonitor := false
EnableBindHints := false
LastPmId := ""
AcceptedFormKeys := Map()
FormSeenTicks := Map()
OverlayClickThrough := true
PunishmentQueueGui := ""
PunishmentProgress := ""
PunishmentStatus := ""
RadialGui := ""
RadialSelected := ""
RadialCenterX := 0
RadialCenterY := 0
RadialRadius := 150
RadialItems := []
RadialHwnd := 0
RadialPic := ""
RadialCursor := ""
RadialSelectedLabel := ""
RadialSelectedCmd := ""
RadialOptionCtrls := []
RadialActive := false
LastRadialWheel := 0
RadialWheelDelay := 160
EnableRadialMenu := true
RadialExtraCommands := ["", "", ""]
RadialExtraCtrls := []

InitRadialCommands() {
    global RadialCommands
    defaults := ["resp", "sp", "pm", "jail", "mute", "kick", "ahouse", "", "", ""]
    if !IsObject(RadialCommands)
        RadialCommands := []
    while (RadialCommands.Length < 10) {
        nextIndex := RadialCommands.Length + 1
        RadialCommands.Push(defaults[nextIndex])
    }
    Loop 10 {
        if (Trim(RadialCommands[A_Index]) = "")
            RadialCommands[A_Index] := defaults[A_Index]
    }
    RadialCommands[7] := "ahouse"
}

SafeArrayGet(arr, index, default := "") {
    try {
        if IsObject(arr) && arr.Length >= index
            return arr[index]
    }
    return default
}
AdminActivityPath := A_ScriptDir "\admin_activity.csv"

Pages := Map()
CurrentPage := ""
Controls := Map()
ThemeEditCtrls := Map()
CommandEditCtrls := []
CommandKeyCtrls := []
ReportEditCtrls := []
ReportKeyCtrls := []
ReportVisibleCount := 26
ReportMaxCount := 46
PunishmentBox := ""

F2Gui := ""
F2ListView := ""
F3Gui := ""
ReportGui := ""
AdminChatGui := ""
VipChatLastText := ""
BindHintsGui := ""
AdminHelpGui := ""
DashboardSetupNoteCtrls := []

ReadSettings()
EnsureUGTAOfficialAssets()
BuildTray()
ShowStartupLoader()
BuildGui()
StartSoundMonitor()
RegisterCommandHotkeys()
RegisterReportHotkeys()

F2::AcceptLastAdminForm()
F1::ReportPanelF1Action()
F3::AutoPmLastReport()
F4::RepeatLastPmId()
#HotIf WinActive("ahk_class AutoHotkeyGUI")
!r::SendEvent("{Alt up}r{Alt down}")
#HotIf
$!r::StartPunishmentQueue()
^F9::ToggleOverlayClickThrough()
^F10::AdminActivityTracker.GenerateBonusReport()
$CapsLock::HandleCapsLockDown()
$CapsLock Up::HandleCapsLockUp()

#HotIf RadialActive
1::RadialSelect(1)
2::RadialSelect(2)
3::RadialSelect(3)
4::RadialSelect(4)
5::RadialSelect(5)
6::RadialSelect(6)
7::RadialSelect(7)
8::RadialSelect(8)
9::RadialSelect(9)
0::RadialSelect(10)
Left::RadialCycle(-1)
Right::RadialCycle(1)
Up::RadialCycle(-1)
Down::RadialCycle(1)
WheelUp::RadialWheel(-1)
WheelDown::RadialWheel(1)
#HotIf


; =========================================================
; Admin rights
; =========================================================


EnsureSingleInstance() {
    ; AHK #SingleInstance Force сам прибирає стару копію.
    ; Старий mutex блокував Reload і давав помилку "два тулса".
    return
}

ShowStartupLoader() {
    global Theme, appVersion

    PlayAtoolsSound("startup")

    steps := [
        Map("p", 8,  "t", "Перевірка прав адміністратора"),
        Map("p", 18, "t", "Завантаження профілю адміністратора"),
        Map("p", 31, "t", "Підготовка конфігурації"),
        Map("p", 44, "t", "Підключення модулів репортів"),
        Map("p", 57, "t", "Ініціалізація моніторингу console.log"),
        Map("p", 70, "t", "Підготовка GDI+ radial menu"),
        Map("p", 84, "t", "Реєстрація гарячих клавіш"),
        Map("p", 96, "t", "Фінальна перевірка інтерфейсу"),
        Map("p", 100,"t", "Готово")
    ]

    loader := Gui("-Caption +AlwaysOnTop +ToolWindow", "Atools Loading")
    loader.BackColor := Theme["bg"]
    loader.SetFont("s10 c" Theme["text"], "Arial")

    loader.AddText("x0 y0 w520 h220 Background" Theme["bg"], "")
    loader.AddText("x0 y0 w520 h4 Background" Theme["accent"], "")
    loader.SetFont("s20 bold c" Theme["text"], "Arial")
    loader.AddText("x32 y30 w360 h36 BackgroundTrans", "ATools NextGen | 02")

    loader.SetFont("s9 c" Theme["muted"], "Arial")
    loader.AddText("x34 y68 w320 h22 BackgroundTrans", "Адмін тулс Західної України")
    loader.AddText("x420 y36 w70 h20 Right BackgroundTrans", "v" appVersion)

    status := loader.AddText("x34 y112 w450 h24 BackgroundTrans", "Запуск...")
    percent := loader.AddText("x430 y145 w55 h22 Right BackgroundTrans", "0%")
    barBack := loader.AddText("x34 y170 w450 h10 Background" Theme["line"], "")
    barFill := loader.AddText("x34 y170 w1 h10 Background" Theme["accent"], "")

    loader.Show("w520 h220 Center NoActivate")

    lastP := 0
    for _, step in steps {
        target := step["p"]
        status.Text := step["t"]
        while (lastP < target) {
            lastP += 2
            if (lastP > target)
                lastP := target
            barFill.Move(34, 170, Round(450 * lastP / 100), 10)
            percent.Text := lastP "%"
            Sleep(16)
        }
        Sleep(95)
    }

    Sleep(120)
    try loader.Destroy()
}

EnsureAdmin() {
    if A_IsAdmin
        return

    result := MsgBox("ATools NextGen | 02 потрібно запускати від імені адміністратора, інакше MTA може не приймати клавіші.`n`nПерезапустити з правами адміністратора?", "Потрібні права адміністратора", "YesNo Icon!")
    if (result = "Yes") {
        try {
            Run("*RunAs " A_ScriptFullPath)
            ExitApp()
        } catch {
            MsgBox("Не вдалося перезапустити з правами адміністратора. Запусти файл вручну через ПКМ → Запуск від імені адміністратора.", "ATools NextGen | 02", "Icon!")
        }
    }
}

; =========================================================
; UI
; =========================================================

SetGuiIcon(hwnd, iconPath) {
    if (!hwnd || !WinExist("ahk_id " hwnd) || !FileExist(iconPath))
        return

    hIconSmall := DllCall("LoadImage", "Ptr", 0, "Str", iconPath, "UInt", 1, "Int", 16, "Int", 16, "UInt", 0x10, "Ptr")
    hIconBig := DllCall("LoadImage", "Ptr", 0, "Str", iconPath, "UInt", 1, "Int", 32, "Int", 32, "UInt", 0x10, "Ptr")

    try {
        if hIconSmall
            SendMessage(0x80, 0, hIconSmall, , "ahk_id " hwnd)
        if hIconBig
            SendMessage(0x80, 1, hIconBig, , "ahk_id " hwnd)
    }
}

DragMainWindow() {
    global Main
    try PostMessage(0xA1, 2,,, "ahk_id " Main.Hwnd)
}

MinimizeAtools() {
    global Main
    try WinMinimize("ahk_id " Main.Hwnd)
}

AtoolsHardExit() {
    ; Закриття без MsgBox і без блокувань від таймерів/оверлеїв.
    ExitApp()
}

AtoolsTitleButtonHitTest(wParam, lParam, msg, hwnd) {
    global Main
    try {
        if (!WinExist("ahk_id " Main.Hwnd))
            return
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mx, &my)
        WinGetPos(&gx, &gy, &gw, &gh, "ahk_id " Main.Hwnd)
        x := mx - gx
        y := my - gy

        ; Робимо зону трохи більшою, бо у -Caption +Border координати можуть гуляти на 1-3 px.
        if (y >= -3 && y <= 34) {
            if (x >= gw - 70 && x <= gw - 38) {
                if (msg = 0x202)
                    MinimizeAtools()
                return 0
            }
            if (x >= gw - 38 && x <= gw + 2) {
                if (msg = 0x202)
                    AtoolsHardExit()
                return 0
            }
        }
    }
}

BuildGui() {
    global Main, Theme, appTitle, appVersion, Pages, Controls, previewIconPath

    Main := Gui("-Caption +Border +MinSize1180x720", appTitle)
    Main.BackColor := Theme["bg"]
    Main.SetFont("s10 c" Theme["text"], "Arial")
    Main.MarginX := 0
    Main.MarginY := 0
    Main.OnEvent("Close", (*) => ExitApp())

    winW := 1180
    winH := 720
    sidebarW := 235

    Main.AddText("x0 y0 w" sidebarW " h" winH " Background" Theme["sidebar"], "")

    ; Офіційний фон Ukraine GTA: big-img.webp, локальний fallback вже затемнений.
    ugtaBgPath := GetUGTABackgroundPath()
    if FileExist(ugtaBgPath) {
        SafeAddPicture(Main, "x" sidebarW " y26 w" (winW - sidebarW) " h" (winH - 26), ugtaBgPath)
        overlayPath := A_ScriptDir "\\assets\\bg\\dark_overlay.png"
        if FileExist(overlayPath)
            SafeAddPicture(Main, "x" sidebarW " y26 w" (winW - sidebarW) " h" (winH - 26), overlayPath)
        vignettePath := A_ScriptDir "\\assets\\bg\\vignette_bottom.png"
        if FileExist(vignettePath)
            SafeAddPicture(Main, "x" sidebarW " y26 w" (winW - sidebarW) " h" (winH - 26), vignettePath)
    }

    titleBar := Main.AddText("x" sidebarW " y0 w" (winW - sidebarW) " h26 Background" Theme["accent"], "")
    titleBar.OnEvent("Click", (*) => DragMainWindow())
    Main.SetFont("s9 bold c" Theme["text"], "Arial")
    titleText := Main.AddText("x" sidebarW " y5 w" (winW - sidebarW) " h18 Center BackgroundTrans", "ATools NextGen | Ukraine GTA 02")
    titleText.OnEvent("Click", (*) => DragMainWindow())
    ; Кнопки в правому кутку. +0x100 = SS_NOTIFY, без нього Static/Text не завжди віддає Click.
    minBtn := Main.AddText("x1118 y2 w28 h22 Center +0x100 Background" Theme["accent2"], "—")
    closeBtn := Main.AddText("x1150 y2 w28 h22 Center +0x100 Background" Theme["danger"], "×")
    minBtn.SetFont("s12 bold c" Theme["text"], "Arial")
    closeBtn.SetFont("s12 bold c" Theme["text"], "Arial")
    minBtn.OnEvent("Click", (*) => (PlayUiClickSound(), MinimizeAtools()))
    closeBtn.OnEvent("Click", (*) => (PlayUiClickSound(), AtoolsHardExit()))
    ; Дублюємо кліки через hit-test по натисканню і відпусканню, щоб спрацьовувало навіть якщо клік ловить дочірній control.
    OnMessage(0x201, AtoolsTitleButtonHitTest)
    OnMessage(0x202, AtoolsTitleButtonHitTest)
    RegisterHover(minBtn, Theme["accent2"], Theme["accent"])
    RegisterHover(closeBtn, Theme["danger"], "FF4B4B")
    Main.AddText("x235 y0 w1 h" winH " Background" Theme["line"], "")

    ; Логотип Ukraine GTA. Старі картинки більше не використовуються, щоб не було багу з іконками-літерами.
    ugtaLogoPath := GetUGTALogoPath()
    ugtaMarkPath := IconPath("ugta_mark")

    if FileExist(ugtaLogoPath)
        SafeAddPicture(Main, "x78 y10 w78 h78 BackgroundTrans", ugtaLogoPath)
    else {
        Main.SetFont("s16 bold c" Theme["text"], "Arial")
        Main.AddText("x24 y20 w160 h26 BackgroundTrans", "ATools")
        Main.SetFont("s8 c" Theme["muted"], "Arial")
        Main.AddText("x26 y50 w140 h18 BackgroundTrans", "NextGen | 02")
    }
    Main.AddText("x24 y88 w182 h1 Background" Theme["line"], "")

    AddNavButton("Головна", 24, 112, (*) => ShowPage("Dashboard"), "home", "Dashboard")
    AddNavButton("Репорти", 24, 157, (*) => ShowPage("Reports"), "reports", "Reports")
    AddNavButton("Покарання", 24, 202, (*) => ShowPage("Punishments"), "punishments", "Punishments")
    AddNavButton("Команди", 24, 247, (*) => ShowPage("Commands"), "hotkey", "Commands")
    AddNavButton("Моніторинг", 24, 292, (*) => ShowPage("Monitoring"), "monitoring", "Monitoring")
    AddNavButton("Налаштування", 24, 337, (*) => ShowPage("Settings"), "settings", "Settings")

    ; Bottom-left brand mark.
    if FileExist(ugtaMarkPath)
        SafeAddPicture(Main, "x26 y592 w44 h44 BackgroundTrans", ugtaMarkPath)

    Main.SetFont("s8 c" Theme["muted"], "Arial")
    Main.AddText("x78 y594 w130 h18 BackgroundTrans", "v" appVersion)
    Main.SetFont("s10 c" Theme["text"], "Arial")
    Main.AddText("x78 y616 w130 h22 BackgroundTrans", "UGTA Tools")

    Main.SetFont("s17 bold c" Theme["text"], "Arial")
    Controls["PageTitle"] := Main.AddText("x265 y24 w520 h34 BackgroundTrans", "Головна")
    Main.SetFont("s9 c" Theme["muted"], "Arial")
    Controls["PageSubtitle"] := Main.AddText("x265 y58 w580 h24 BackgroundTrans", "ATools NextGen | 02")
    Main.SetFont("s9 c" Theme["muted"], "Arial")
    Main.AddText("x1010 y28 w120 h24 BackgroundTrans", "v" appVersion)

    Pages["Dashboard"] := []
    Pages["Reports"] := []
    Pages["Punishments"] := []
    Pages["Commands"] := []
    Pages["Monitoring"] := []
    Pages["Settings"] := []

    BuildDashboardPage()
    BuildReportsPage()
    BuildPunishmentsPage()
    BuildCommandsPage()
    BuildMonitoringPage()
    BuildSettingsPage()

    ShowPage("Dashboard")
    Main.Show("w" winW " h" winH)
    OnMessage(0x200, WM_MOUSEMOVE_ATOOLS)
    FadeInMainWindow()
    ; GDI+ shell disabled: основне вікно лишається стабільним AHK GUI. GDI+ — radial/overlay.
    SetGuiIcon(Main.Hwnd, previewIconPath)
}

AddNavButton(title, x, y, callback, iconName := "", pageName := "") {
    global Main, Theme, NavButtons
    bg := Main.AddText("x0 y" y " w235 h34 Background" Theme["accent2"], "")
    marker := Main.AddText("x0 y" y " w5 h34 Background" Theme["text"], "")
    marker.Opt("Hidden")

    if (iconName != "") {
        icon := AddIconPicture(Main, 24, y + 6, 20, 20, iconName)
        if IsObject(icon)
            icon.OnEvent("Click", WithClickSound(callback))
    }

    txt := Main.AddText("x54 y" (y + 8) " w158 h18 BackgroundTrans", title)
    cb := WithClickSound(callback)
    bg.OnEvent("Click", cb)
    marker.OnEvent("Click", cb)
    txt.OnEvent("Click", cb)
    RegisterHover(bg, Theme["accent2"], ShadeHex(Theme["accent"], 22))
    RegisterHover(txt, Theme["accent2"], ShadeHex(Theme["accent"], 22))
    txt.SetFont("s9 bold c" Theme["text"], "Arial")
    if (pageName != "")
        NavButtons[pageName] := [bg, marker]
}

AddPageCtrl(page, ctrl) {
    global Pages
    Pages[page].Push(ctrl)
    return ctrl
}

AddHero(page, x, y, w, h, title, subtitle) {
    global Main, Theme
    AddPageCtrl(page, Main.AddText("x" x " y" y " w" w " h18 Background" Theme["accent"], ""))
    AddPageCtrl(page, Main.AddText("x" x " y" (y+18) " w" w " h" (h-18) " " PanelBgOpt(), ""))
    AddPageCtrl(page, Main.AddText("x" x " y" y " w" w " h1 Background" Theme["line"], ""))
    AddPageCtrl(page, Main.AddText("x" x " y" (y + h - 1) " w" w " h1 Background" Theme["line"], ""))

    iconName := page
    switch page {
        case "Dashboard": iconName := "home"
        case "Reports": iconName := "reports"
        case "Punishments": iconName := "punishments"
        case "Monitoring": iconName := "monitoring"
        case "Settings": iconName := "settings"
    }
    AddIconPicture(Main, x + 18, y + 30, 30, 30, iconName, page)

    Main.SetFont("s10 bold c" Theme["text"], "Arial")
    AddPageCtrl(page, Main.AddText("x" x " y" (y + 2) " w" w " h16 Center BackgroundTrans", title))
    Main.SetFont("s9 c" Theme["muted"], "Arial")
    AddPageCtrl(page, Main.AddText("x" (x + 60) " y" (y + 38) " w" (w - 90) " h22 BackgroundTrans", subtitle))
}

AddCard(page, x, y, w, h, title) {
    global Main, Theme
    AddPageCtrl(page, Main.AddText("x" x " y" y " w" w " h" h " " PanelBgOpt(), ""))
    AddPageCtrl(page, Main.AddText("x" x " y" y " w" w " h23 Background" Theme["accent2"], ""))
    AddPageCtrl(page, Main.AddText("x" x " y" y " w" w " h1 Background" Theme["line"], ""))
    AddPageCtrl(page, Main.AddText("x" x " y" (y + h - 1) " w" w " h1 Background" Theme["line"], ""))
    Main.SetFont("s10 c" Theme["text"], "Arial")
    AddPageCtrl(page, Main.AddText("x" x " y" (y + 4) " w" w " h16 Center BackgroundTrans", title))
}

AddSmallStat(page, x, y, title, value, accentColor := "", w := 185, valueSize := 15) {
    global Main, Theme
    AddPageCtrl(page, Main.AddText("x" x " y" y " w" w " h78 " PanelBgOpt(), ""))
    AddPageCtrl(page, Main.AddText("x" x " y" y " w" w " h1 Background" Theme["line"], ""))
    AddPageCtrl(page, Main.AddText("x" x " y" (y + 77) " w" w " h1 Background" Theme["line"], ""))
    AddPageCtrl(page, Main.AddText("x" x " y" y " w3 h78 Background" Theme["accent"], ""))
    Main.SetFont("s8 c" Theme["muted"], "Arial")
    AddPageCtrl(page, Main.AddText("x" (x + 16) " y" (y + 12) " w" (w - 32) " h18 BackgroundTrans", title))
    Main.SetFont("s" valueSize " c" Theme["text"], "Arial")
    AddPageCtrl(page, Main.AddText("x" (x + 16) " y" (y + 35) " w" (w - 32) " h30 BackgroundTrans", value))
}

ShowPage(pageName) {
    global Pages, Controls, CurrentPage, Main, Theme

    if (CurrentPage = pageName)
        return

    title := Map(
        "Dashboard", "Головна",
        "Reports", "Репорти",
        "Punishments", "Покарання",
        "Commands", "Команди",
        "Monitoring", "Моніторинг",
        "Settings", "Налаштування"
    )

    ; Стара анімація рухала кожен елемент і через це текст міг обрізатись.
    ; Тепер сторінки не зсуваються, а ефект перемикання робиться окремою верхньою лінією.
    for name, list in Pages {
        for ctrl in list
            ctrl.Opt(name = pageName ? "-Hidden" : "Hidden")
    }

    Controls["PageTitle"].Text := title[pageName]
    CurrentPage := pageName
    UpdateNavActive(pageName)

    PageSwitchPulse()
}

UpdateNavActive(pageName) {
    global NavButtons, Theme, ActiveNavPage
    ActiveNavPage := pageName
    for pg, data in NavButtons {
        try data[1].Opt("Background" (pg = pageName ? Theme["accent"] : Theme["accent2"]))
        try data[2].Opt(pg = pageName ? "-Hidden" : "Hidden")
    }
}

PageSwitchPulse() {
    return
}

BuildDashboardPage() {
    global Main, Theme, Name, Rank, AppointmentDate

    AddHero("Dashboard", 265, 98, 850, 78, "ATools NextGen | 02", "Офіційна панель для репортів, покарань, форм та моніторингу")

    ; Ширші картки, щоб довгі ранги не обрізались.
    AddSmallStat("Dashboard", 265, 205, "Профіль", Name != "" ? Name : "Не вказано", Theme["accent"], 300, 14)
    AddSmallStat("Dashboard", 585, 205, "Ранг", Rank, Theme["accent2"], 530, 14)

    promoText := GetPromotionLeftText(Rank, AppointmentDate)
    if (promoText != "") {
        AddSmallStat("Dashboard", 265, 315, "До підвищення", promoText, Theme["text"], 850, 14)
        systemY := 425
        noteY := 610
    } else {
        systemY := 315
        noteY := 525
    }

    AddCard("Dashboard", 265, systemY, 850, 160, "Що нового?")
    Main.SetFont("s9 c" Theme["muted"], "Arial")
    AddPageCtrl("Dashboard", Main.AddText("x290 y" (systemY + 45) " w760 h22 BackgroundTrans", "• Додано розділ Команди."))
    AddPageCtrl("Dashboard", Main.AddText("x290 y" (systemY + 75) " w760 h22 BackgroundTrans", "• Вікно форм F2 стало компактним і саме росте під кількість форм."))
    AddPageCtrl("Dashboard", Main.AddText("x290 y" (systemY + 105) " w760 h22 BackgroundTrans", "• CapsLock працює звичайно, якщо radial-меню вимкнено."))

    AddDashboardSetupNote(noteY)
}

AddDashboardSetupNote(noteY) {
    global Main, Theme, DashboardSetupNoteCtrls
    DashboardSetupNoteCtrls := []
    if IsAtoolsSetupComplete()
        return

    DashboardSetupNoteCtrls.Push(AddPageCtrl("Dashboard", Main.AddText("x265 y" noteY " w850 h92 " PanelBgOpt(), "")))
    DashboardSetupNoteCtrls.Push(AddPageCtrl("Dashboard", Main.AddText("x265 y" noteY " w850 h23 Background" Theme["accent2"], "")))
    DashboardSetupNoteCtrls.Push(AddPageCtrl("Dashboard", Main.AddText("x265 y" noteY " w850 h1 Background" Theme["line"], "")))
    DashboardSetupNoteCtrls.Push(AddPageCtrl("Dashboard", Main.AddText("x265 y" (noteY + 91) " w850 h1 Background" Theme["line"], "")))
    Main.SetFont("s10 c" Theme["text"], "Arial")
    DashboardSetupNoteCtrls.Push(AddPageCtrl("Dashboard", Main.AddText("x265 y" (noteY + 4) " w850 h16 Center BackgroundTrans", "Примітка")))
    Main.SetFont("s9 c" Theme["muted"], "Arial")
    DashboardSetupNoteCtrls.Push(AddPageCtrl("Dashboard", Main.AddText("x290 y" (noteY + 42) " w790 h22 BackgroundTrans", "Для коректної роботи вкажи нікнейм, дату призначення та папку Ukraine GTA у налаштуваннях.")))
    DashboardSetupNoteCtrls.Push(AddPageCtrl("Dashboard", Main.AddText("x290 y" (noteY + 66) " w790 h20 BackgroundTrans", "Папка потрібна для читання console.log, AutoID PM, F2-форм і службових overlay-вікон.")))
}

IsAtoolsSetupComplete() {
    global Name, AppointmentDate
    return (Trim(Name) != "" && Trim(AppointmentDate) != "" && GetUGTAPath() != "")
}

UpdateDashboardSetupNoteVisibility() {
    global DashboardSetupNoteCtrls
    if !IsAtoolsSetupComplete()
        return
    for _, ctrl in DashboardSetupNoteCtrls {
        try ctrl.Opt("Hidden")
    }
}

GetPromotionRequiredDays(rank) {
    switch rank {
        case "Ігровий помічник":
            return 15
        case "Модератор":
            return 31
        case "Старший модератор":
            return 62
        case "Адміністратор":
            return 121
        default:
            return 0
    }
}

GetPromotionLeftText(rank, appointmentDate) {
    daysNeed := GetPromotionRequiredDays(rank)
    if (daysNeed <= 0)
        return ""

    startStamp := NormalizeDateStamp(appointmentDate)
    if (startStamp = "")
        return "вкажи дату"

    promoteAt := DateAdd(startStamp, daysNeed, "Days")
    hoursLeft := DateDiff(promoteAt, A_Now, "Hours")

    if (hoursLeft <= 0)
        return "можна"

    return FormatCompactDuration(hoursLeft)
}

NormalizeDateStamp(value) {
    value := Trim(value)
    if (value = "")
        return ""

    if RegExMatch(value, "^(\d{2})\.(\d{2})\.(\d{4})$", &m)
        return m[3] m[2] m[1] "000000"

    if RegExMatch(value, "^(\d{4})-(\d{2})-(\d{2})$", &m)
        return m[1] m[2] m[3] "000000"

    if RegExMatch(value, "^(\d{8})$", &m)
        return m[1] "000000"

    return ""
}

FormatCompactDuration(hoursLeft) {
    totalDays := Floor(hoursLeft / 24)
    hours := Mod(hoursLeft, 24)
    months := Floor(totalDays / 30)
    days := Mod(totalDays, 30)

    if (months > 0)
        return months " міс. " days " дн. " hours " год"
    if (days > 0)
        return days " дн. " hours " год"
    return hours " год"
}

AddActionButton(page, title, x, y, callback) {
    global Main, Theme
    bg := Main.AddText("x" x " y" y " w95 h38 Background" Theme["panel2"], "")
    label := Main.AddText("x" x " y" (y + 9) " w95 h20 Center BackgroundTrans", title)
    label.SetFont("s10 bold c" Theme["text"], "Arial")
    cb := WithClickSound(callback)
    bg.OnEvent("Click", cb)
    label.OnEvent("Click", cb)
    RegisterHover(bg, Theme["accent"], Theme["accent2"])
    RegisterHover(label, Theme["accent"], Theme["accent2"])
    AddPageCtrl(page, bg)
    AddPageCtrl(page, label)
}

BuildCommandsPage() {
    global Main, Theme, Commands, CommandKeys, CommandEditCtrls, CommandKeyCtrls, CommandKey2Ctrls
    AddHero("Commands", 265, 98, 850, 78, "Команди", "Шаблони службових команд: команда + одна кнопка або кнопка виконання")
    AddCard("Commands", 265, 200, 850, 430, "Шаблони команд")
    AddIconPicture(Main, 285, 202, 18, 18, "hotkey", "Commands")
    Main.SetFont("s9 c" Theme["muted"], "Arial")
    AddPageCtrl("Commands", Main.AddText("x290 y240 w760 h30 BackgroundTrans", "Вписуй команду без /. Можна забіндити одну клавішу. Кнопка ВИКОНАТИ відправляє команду в чат."))

    CommandEditCtrls := []
    CommandKeyCtrls := []
    CommandKey2Ctrls := []

    Main.SetFont("s9 bold c" Theme["text"], "Arial")
    AddPageCtrl("Commands", Main.AddText("x290 y278 w420 h20 BackgroundTrans", "Команда"))
    AddPageCtrl("Commands", Main.AddText("x725 y278 w120 h20 Center BackgroundTrans", "Кнопка"))

    yStart := 305
    Loop 12 {
        i := A_Index
        y := yStart + ((i - 1) * 24)
        edit := Main.AddEdit("x290 y" y " w420 h22 Background" Theme["field"] " c" Theme["text"], SafeArrayGet(Commands, i, ""))
        hot1 := Main.AddHotkey("x725 y" y " w120 h22 c" Theme["text"], SafeArrayGet(CommandKeys, i, ""))
        CommandEditCtrls.Push(AddPageCtrl("Commands", edit))
        CommandKeyCtrls.Push(AddPageCtrl("Commands", hot1))
        CommandKey2Ctrls.Push("")
        idx := i
        AddTextButton("Commands", 870, y - 1, 200, 23, "ВИКОНАТИ", (*) => RunCommandButton(idx))
    }

    Main.SetFont("s8 c" Theme["muted"], "Arial")
    AddPageCtrl("Commands", Main.AddText("x290 y600 w520 h20 BackgroundTrans", "Приклади: sp, pm, resp, jail, mute, kick, unget. / ставити не треба."))
    AddTextButton("Commands", 850, 595, 230, 34, "ЗБЕРЕГТИ КОМАНДИ", (*) => SaveCommands())
}

RunCommandButton(index) {
    global CommandEditCtrls, CommandKeyCtrls, CommandKey2Ctrls, Commands, CommandKeys, CommandKeys2
    if (CommandEditCtrls.Length >= index)
        Commands[index] := CommandEditCtrls[index].Text
    if (CommandKeyCtrls.Length >= index)
        CommandKeys[index] := CommandKeyCtrls[index].Value
    CommandKeys2[index] := ""
    cmd := Trim(SafeArrayGet(Commands, index, ""))
    if (cmd = "")
        return
    SendCommandTextEx(cmd, true)
}
BuildReportsPage() {
    global Main, Theme, Reports, ReportKeys, ReportEditCtrls, ReportKeyCtrls, ReportVisibleCount, ReportMaxCount

    AddHero("Reports", 265, 98, 850, 78, "Репорти", "Шаблони відповідей, бінди та автопідстановка рангу/ніка")
    AddCard("Reports", 265, 200, 850, 430, "Шаблони репортів")
    AddIconPicture(Main, 285, 202, 18, 18, "report_new", "Reports")
    Main.SetFont("s9 c" Theme["muted"], "Arial")
    AddPageCtrl("Reports", Main.AddText("x290 y240 w760 h22 BackgroundTrans", "Можна використовувати {Rank} і {Name}. Натисни +2, щоб додати ще шаблони. Максимум +20."))

    visible := Max(1, Min(ReportVisibleCount, ReportMaxCount))
    cols := 3
    colX := [290, 565, 840]
    yStart := 282
    rowH := 24
    rows := Ceil(visible / cols)

    idx := 1
    Loop cols {
        col := A_Index
        Main.SetFont("s9 bold c" Theme["text"], "Arial")
        AddPageCtrl("Reports", Main.AddText("x" colX[col] " y262 w190 h20 BackgroundTrans", "Повідомлення"))
        AddPageCtrl("Reports", Main.AddText("x" (colX[col] + 195) " y262 w60 h20 Center BackgroundTrans", "Кнопка"))

        Loop rows {
            if (idx > visible)
                break
            y := yStart + ((A_Index - 1) * rowH)
            edit := Main.AddEdit("x" colX[col] " y" y " w190 h22 Background" Theme["field"] " c" Theme["text"], SafeArrayGet(Reports, idx, ""))
            hot := Main.AddHotkey("x" (colX[col] + 195) " y" y " w60 h22 c" Theme["text"], SafeArrayGet(ReportKeys, idx, ""))
            ReportEditCtrls.Push(AddPageCtrl("Reports", edit))
            ReportKeyCtrls.Push(AddPageCtrl("Reports", hot))
            idx++
        }
    }

    Main.SetFont("s9 c" Theme["muted"], "Arial")
    AddPageCtrl("Reports", Main.AddText("x290 y595 w300 h22 BackgroundTrans", "Показано: " visible " / " ReportMaxCount))
    AddTextButton("Reports", 610, 592, 120, 34, "+2 ШАБЛОНИ", (*) => AddReportTemplates())
    AddTextButton("Reports", 850, 592, 230, 34, "ЗБЕРЕГТИ РЕПОРТИ", (*) => SaveReports())
}

AddReportTemplates(*) {
    global ReportVisibleCount, ReportMaxCount, iniPath
    ReportVisibleCount := Min(ReportMaxCount, ReportVisibleCount + 2)
    IniWrite(ReportVisibleCount, iniPath, "Reports", "VisibleCount")
    SaveReports()
    Reload()
}


BuildPunishmentsPage() {
    global Main, Theme, PunishmentBox

    AddHero("Punishments", 265, 98, 850, 78, "Покарання", "Стара система відправки форм через ALT + R")
    AddCard("Punishments", 265, 200, 850, 430, "Форма видачі")
    AddIconPicture(Main, 285, 202, 18, 18, "punishments", "Punishments")
    Main.SetFont("s9 c" Theme["muted"], "Arial")
    AddPageCtrl("Punishments", Main.AddText("x290 y240 w760 h22 BackgroundTrans", "Одна форма — один рядок. Для відправки в гру натисни ALT + R."))

    PunishmentBox := Main.AddEdit("x290 y280 w790 h260 Multi WantTab Background" Theme["field"] " c" Theme["text"], "")
    AddPageCtrl("Punishments", PunishmentBox)

    AddTextButton("Punishments", 850, 570, 230, 34, "ВІДПРАВИТИ ALT+R", (*) => StartPunishmentQueue())
}

BuildMonitoringPage() {
    global Main, Theme

    AddHero("Monitoring", 265, 98, 850, 78, "◉ Моніторинг", "F2, F3, чати, підказки та overlay-вікна")
    AddCard("Monitoring", 265, 200, 850, 430, "Активні модулі")
    AddIconPicture(Main, 285, 202, 18, 18, "monitoring", "Monitoring")
    Main.SetFont("s9 c" Theme["muted"], "Arial")
    AddPageCtrl("Monitoring", Main.AddText("x290 y240 w760 h38 BackgroundTrans", "Для F2/F3 потрібен шлях до папки UKRAINE GTA у налаштуваннях."))

    AddIconPicture(Main, 292, 300, 22, 22, "forms", "Monitoring")
    AddCheck("Monitoring", "Прийняття адм. форм на F2", 322, 300, (*) => ToggleFeature("F2"))
    AddIconPicture(Main, 292, 335, 22, 22, "pm", "Monitoring")
    AddCheck("Monitoring", "AutoID PM на F3 / F4", 322, 335, (*) => ToggleFeature("F3"))
    AddIconPicture(Main, 292, 370, 22, 22, "report_new", "Monitoring")
    AddCheck("Monitoring", "Слідкування за репортами", 322, 370, (*) => ToggleFeature("ReportFollow"))
    AddIconPicture(Main, 292, 405, 22, 22, "vip", "Monitoring")
    AddCheck("Monitoring", "Чати", 322, 405, (*) => ToggleFeature("AdminChat"))
    AddIconPicture(Main, 292, 440, 22, 22, "bind", "Monitoring")
    AddCheck("Monitoring", "Підказки біндів", 322, 440, (*) => ToggleFeature("BindHints"))

    AddTextButton("Monitoring", 720, 300, 260, 34, "АДМ. КОМАНДИ", (*) => ToggleAdminCommandsHelp())
}

AddTextButton(page, x, y, w, h, title, callback) {
    global Main, Theme
    bg := Main.AddText("x" x " y" y " w" w " h" h " Background" Theme["accent"], "")
    label := Main.AddText("x" x " y" (y + 8) " w" w " h20 Center BackgroundTrans", title)
    label.SetFont("s9 bold c" Theme["text"], "Arial")
    cb := WithClickSound(callback)
    bg.OnEvent("Click", cb)
    label.OnEvent("Click", cb)
    RegisterHover(bg, Theme["accent"], Theme["accent2"])
    RegisterHover(label, Theme["accent"], Theme["accent2"])
    AddPageCtrl(page, bg)
    AddPageCtrl(page, label)
}

AddCheck(page, text, x, y, callback) {
    global Main, Theme
    cb := Main.AddCheckbox("x" x " y" y " w340 h24", text)
    cb.SetFont("s9 c" Theme["text"], "Arial")
    cb.OnEvent("Click", WithClickSound(callback))
    AddPageCtrl(page, cb)
    return cb
}

RegisterHover(ctrl, normalColor, hoverColor) {
    global HoverCtrls
    try HoverCtrls[ctrl.Hwnd] := [ctrl, normalColor, hoverColor]
}

WM_MOUSEMOVE_ATOOLS(wParam, lParam, msg, hwnd) {
    global HoverCtrls, LastHoverHwnd
    try MouseGetPos(,,, &ctrlHwnd, 2)
    catch
        return
    if (ctrlHwnd = LastHoverHwnd)
        return
    if (LastHoverHwnd && HoverCtrls.Has(LastHoverHwnd)) {
        data := HoverCtrls[LastHoverHwnd]
        try data[1].Opt("Background" data[2])
    }
    LastHoverHwnd := ctrlHwnd
    if (ctrlHwnd && HoverCtrls.Has(ctrlHwnd)) {
        data := HoverCtrls[ctrlHwnd]
        try data[1].Opt("Background" data[3])
    }
}

FadeInMainWindow() {
    ; Без прозорості всього вікна: текст, кнопки та чекбокси завжди лишаються чіткими.
    return
}

ApplyWindowTransparency() {
    ; Не робимо WinSetTransparent на все вікно, бо тоді тьмяніє текст.
    ; Прозорість імітується кольором фон-плашок: текст/кнопки лишаються чіткими.
    return
}

UseSoftPanels() {
    global WindowTransparency
    return (Integer(WindowTransparency) < 255)
}

PanelColor() {
    global WindowTransparency, Theme
    t := Max(150, Min(255, Integer(WindowTransparency)))
    if (t >= 250)
        return Theme["panel"]
    ratio := (255 - t) / 105.0
    return MixHex(Theme["panel"], "242424", ratio)
}

PanelBgOpt() {
    return "Background" PanelColor()
}

SaveWindowTransparency(*) {
    global Controls, WindowTransparency, iniPath
    try WindowTransparency := Controls["TransparencySlider"].Value
    WindowTransparency := Max(150, Min(255, Integer(WindowTransparency)))
    IniWrite(WindowTransparency, iniPath, "Theme", "WindowTransparency")
    ShowAtoolsNotice("Прозорість фону/плашок збережено. Перезапускаю ATools.")
    Sleep(420)
    Reload()
}


BuildSettingsPage() {
    global Main, Theme, Name, nRank, Ranks, Controls, RadialExtraCommands, RadialExtraCtrls, RadialCommands, RadialCtrls, AppointmentDate, EnableRadialMenu, ThemeEditCtrls, BaseThemeColor, WindowTransparency
    InitRadialCommands()

    AddHero("Settings", 265, 98, 850, 60, "Налаштування", "Профіль, шлях до гри, radial-меню та оформлення інтерфейсу")
    AddCard("Settings", 265, 180, 410, 245, "Профіль адміністратора")
    AddCard("Settings", 705, 180, 410, 315, "Radial / кнопки")
    AddCard("Settings", 265, 515, 850, 150, "Колір і фон інтерфейсу")
    AddIconPicture(Main, 286, 183, 18, 18, "profile", "Settings")
    AddIconPicture(Main, 726, 183, 18, 18, "radial", "Settings")
    AddIconPicture(Main, 286, 518, 18, 18, "palette", "Settings")

    Main.SetFont("s9 c" Theme["muted"], "Arial")
    AddPageCtrl("Settings", Main.AddText("x290 y225 w200 h20 BackgroundTrans", "NickName"))
    AddPageCtrl("Settings", Main.AddText("x290 y280 w200 h20 BackgroundTrans", "Рівень адміністратора"))
    AddPageCtrl("Settings", Main.AddText("x290 y335 w260 h20 BackgroundTrans", "Дата призначення"))
    AddPageCtrl("Settings", Main.AddText("x730 y225 w330 h20 BackgroundTrans", "Стан radial-меню"))
    AddPageCtrl("Settings", Main.AddText("x730 y295 w330 h34 BackgroundTrans", "Можна змінити 1-6 та 8-0. Кнопка 7 заблокована: ahouse."))

    Controls["NameEdit"] := AddPageCtrl("Settings", Main.AddEdit("x290 y248 w300 h25 Background" Theme["field"] " c" Theme["text"], Name))
    Controls["RankDDL"] := AddPageCtrl("Settings", Main.AddDropDownList("x290 y303 w300 Background" Theme["field"] " c" Theme["text"], Ranks))
    Controls["AppointmentDateEdit"] := AddPageCtrl("Settings", Main.AddEdit("x290 y358 w300 h25 Background" Theme["field"] " c" Theme["text"], AppointmentDate))
    Controls["RankDDL"].Choose(nRank)

    Controls["RadialEnabledCB"] := AddPageCtrl("Settings", Main.AddCheckbox("x730 y248 w320 h24 c" Theme["text"], "Увімкнути radial-меню CapsLock"))
    Controls["RadialEnabledCB"].Value := EnableRadialMenu ? 1 : 0
    Controls["RadialEnabledCB"].OnEvent("Click", (*) => (PlayUiClickSound(), SaveRadialToggleOnly()))

    RadialCtrls := []
    yR := 335
    Loop 10 {
        i := A_Index
        row := yR + Floor((i-1)/2)*28
        col := Mod(i-1, 2)
        xBase := 730 + col*150
        keyName := i = 10 ? "0" : String(i)
        AddPageCtrl("Settings", Main.AddText("x" xBase " y" row " w24 h22 Center Background" Theme["accent2"], keyName))
        if (i = 7)
            ed := Main.AddEdit("x" (xBase+30) " y" row " w110 h22 ReadOnly Background" Theme["field"] " c" Theme["muted"], "ahouse")
        else
            ed := Main.AddEdit("x" (xBase+30) " y" row " w110 h22 Background" Theme["field"] " c" Theme["text"], SafeArrayGet(RadialCommands, i, ""))
        RadialCtrls.Push(AddPageCtrl("Settings", ed))
    }

    Main.SetFont("s9 c" Theme["muted"], "Arial")
    AddPageCtrl("Settings", Main.AddText("x290 y548 w760 h22 BackgroundTrans", "Вибираєш один основний колір, а ATools сам підганяє меню, кнопки, поля, рамки та акценти під нього."))

    ThemeEditCtrls := Map()
    AddThemePresetButton("8A22D6", 290, 572)
    AddThemePresetButton("2D7DFF", 340, 572)
    AddThemePresetButton("10B9C8", 390, 572)
    AddThemePresetButton("36A81E", 440, 572)
    AddThemePresetButton("F28C18", 490, 572)
    AddThemePresetButton("E21835", 540, 572)
    AddThemePresetButton("D9268F", 590, 572)
    AddThemePresetButton("A9A9A9", 640, 572)
    AddThemePresetButton("000000", 690, 572)

    Main.SetFont("s9 c" Theme["text"], "Arial")
    AddPageCtrl("Settings", Main.AddText("x290 y625 w160 h20 BackgroundTrans", "Свій HEX колір:"))
    ThemeEditCtrls["base"] := AddPageCtrl("Settings", Main.AddEdit("x455 y610 w105 h25 Background" Theme["field"] " c" Theme["text"], BaseThemeColor))
    AddTextButton("Settings", 575, 607, 150, 30, "ЗАСТОСУВАТИ", (*) => SaveThemeSettings())
    AddTextButton("Settings", 745, 607, 170, 30, "ФОН ТУЛСУ", (*) => SelectBackgroundFile())
    AddPageCtrl("Settings", Main.AddText("x930 y548 w170 h20 BackgroundTrans", "Прозорість фону:"))
    Controls["TransparencySlider"] := AddPageCtrl("Settings", Main.AddSlider("x930 y575 w155 h28 Range150-255 ToolTip", WindowTransparency))
    Controls["TransparencySlider"].OnEvent("Change", SaveWindowTransparency)

    AddTextButton("Settings", 290, 390, 145, 28, "ЗБЕРЕГТИ", (*) => SaveProfile())
    AddTextButton("Settings", 445, 390, 145, 28, "ПАПКА UGTA", (*) => SelectUGTAFolder())
    AddTextButton("Settings", 730, 468, 285, 24, "ЗБЕРЕГТИ RADIAL", (*) => SaveRadialSettings())
}

AddThemePresetButton(hex, x, y) {
    global Main, Theme, BaseThemeColor
    isActive := (NormalizeHexColor(hex) = NormalizeHexColor(BaseThemeColor))
    label := isActive ? "✓" : ""
    b := AddPageCtrl("Settings", Main.AddText("x" x " y" y " w38 h24 Center Background" hex, label))
    b.SetFont("s10 bold cFFFFFF", "Arial")
    b.OnEvent("Click", (*) => (PlayUiClickSound(), SaveThemeBaseColor(hex)))
    RegisterHover(b, hex, ShadeHex(hex, 18))
}

ShowAtoolsNotice(text, timeout := 1100) {
    global Theme, Main
    n := Gui("-Caption +AlwaysOnTop +ToolWindow", "ATools notice")
    n.BackColor := Theme["panel"]
    n.SetFont("s9 c" Theme["text"], "Arial")
    n.AddText("x0 y0 w360 h4 Background" Theme["accent"], "")
    n.AddText("x0 y4 w360 h64 Background" Theme["panel"], "")
    n.AddText("x18 y20 w324 h28 Center BackgroundTrans", text)
    try {
        Main.GetPos(&mx, &my, &mw, &mh)
        n.Show("x" (mx + mw//2 - 180) " y" (my + 70) " w360 h68")
    } catch {
        n.Show("w360 h68")
    }
    SetTimer(() => (IsObject(n) ? n.Destroy() : 0), -timeout)
}

; =========================================================
; Settings / INI
; =========================================================

ReadSettings() {
    global iniPath, Name, Rank, nRank, AppointmentDate, Commands, CommandKeys, CommandKeys2, Reports, ReportKeys, ReportVisibleCount, ReportMaxCount, RadialExtraCommands, RadialCommands, Ranks, EnableRadialMenu, Theme, BaseThemeColor, ReportPanelPosX, ReportPanelPosY, CustomBgPath, F2PosX, F2PosY, BindHintsPosX, BindHintsPosY, WindowTransparency
    if !FileExist(iniPath)
        return

    BaseThemeColor := IniRead(iniPath, "Theme", "Base", IniRead(iniPath, "Theme", "accent", BaseThemeColor))
    ApplyThemeFromBase(BaseThemeColor)

    Name := IniRead(iniPath, "Admin", "Name", Name)
    Rank := IniRead(iniPath, "Admin", "Rank", Rank)
    nRank := Integer(IniRead(iniPath, "Admin", "nRank", nRank))
    if (nRank >= 1 && nRank <= Ranks.Length)
        Rank := Ranks[nRank]
    AppointmentDate := IniRead(iniPath, "Admin", "AppointmentDate", AppointmentDate)

    Loop 30 {
        i := A_Index
        Commands[i] := IniRead(iniPath, "Command", "Com" (i - 1), SafeArrayGet(Commands, i, ""))
        CommandKeys[i] := IniRead(iniPath, "Command", "keys" (i - 1), SafeArrayGet(CommandKeys, i, ""))
        CommandKeys2[i] := IniRead(iniPath, "Command", "keys2" (i - 1), SafeArrayGet(CommandKeys2, i, ""))
    }

    Loop 46 {
        i := A_Index
        Reports[i] := IniRead(iniPath, "Rep", "rep" (i - 1), SafeArrayGet(Reports, i, ""))
        ReportKeys[i] := IniRead(iniPath, "Reports", "keys" (i + 29), SafeArrayGet(ReportKeys, i, ""))
    }
    ReportVisibleCount := Max(26, Min(ReportMaxCount, Integer(IniRead(iniPath, "Reports", "VisibleCount", ReportVisibleCount))))

    EnableRadialMenu := Integer(IniRead(iniPath, "Radial", "Enabled", EnableRadialMenu ? 1 : 0)) = 1
    RadialExtraCommands[1] := IniRead(iniPath, "Radial", "Cmd8", RadialExtraCommands[1])
    RadialExtraCommands[2] := IniRead(iniPath, "Radial", "Cmd9", RadialExtraCommands[2])
    RadialExtraCommands[3] := IniRead(iniPath, "Radial", "Cmd0", RadialExtraCommands[3])

    ReportPanelPosX := Integer(IniRead(iniPath, "ReportPanel", "X", ReportPanelPosX))
    ReportPanelPosY := Integer(IniRead(iniPath, "ReportPanel", "Y", ReportPanelPosY))
    CustomBgPath := IniRead(iniPath, "Theme", "Background", CustomBgPath)
    WindowTransparency := Integer(IniRead(iniPath, "Theme", "WindowTransparency", WindowTransparency))
    F2PosX := Integer(IniRead(iniPath, "F2Panel", "X", F2PosX))
    F2PosY := Integer(IniRead(iniPath, "F2Panel", "Y", F2PosY))
    BindHintsPosX := Integer(IniRead(iniPath, "BindHints", "X", BindHintsPosX))
    BindHintsPosY := Integer(IniRead(iniPath, "BindHints", "Y", BindHintsPosY))
    InitRadialCommands()
    Loop 10 {
        oldCmd := SafeArrayGet(RadialCommands, A_Index, "")
        RadialCommands[A_Index] := IniRead(iniPath, "Radial", "Cmd" A_Index, oldCmd)
    }
    RadialCommands[7] := "ahouse"
}


SaveProfile() {
    global iniPath, Controls, Name, Rank, nRank, AppointmentDate, Ranks
    Name := Controls["NameEdit"].Text
    nRank := Controls["RankDDL"].Value
    Rank := Ranks[nRank]
    AppointmentDate := Controls["AppointmentDateEdit"].Text

    IniWrite(Rank, iniPath, "Admin", "Rank")
    IniWrite(nRank, iniPath, "Admin", "nRank")
    IniWrite(Name, iniPath, "Admin", "Name")
    IniWrite(AppointmentDate, iniPath, "Admin", "AppointmentDate")
    ShowAtoolsNotice("Профіль збережено.")
    UpdateDashboardSetupNoteVisibility()
}


SaveCommands() {
    global iniPath, Commands, CommandKeys, CommandKeys2, CommandEditCtrls, CommandKeyCtrls, CommandKey2Ctrls
    Loop CommandEditCtrls.Length {
        i := A_Index
        Commands[i] := CommandEditCtrls[i].Text
        CommandKeys[i] := (CommandKeyCtrls.Length >= i) ? CommandKeyCtrls[i].Value : ""
        CommandKeys2[i] := ""
        IniWrite(Commands[i], iniPath, "Command", "Com" (i - 1))
        IniWrite(CommandKeys[i], iniPath, "Command", "keys" (i - 1))
        IniWrite("", iniPath, "Command", "keys2" (i - 1))
    }
    RegisterCommandHotkeys()
    ShowAtoolsNotice("Команди збережено.")
}
SaveReports() {
    global iniPath, Reports, ReportKeys, ReportEditCtrls, ReportKeyCtrls, ReportVisibleCount
    Loop ReportEditCtrls.Length {
        i := A_Index
        Reports[i] := ReportEditCtrls[i].Text
        ReportKeys[i] := ReportKeyCtrls[i].Value
        IniWrite(Reports[i], iniPath, "Rep", "rep" (i - 1))
        IniWrite(ReportKeys[i], iniPath, "Reports", "keys" (i + 29))
    }
    IniWrite(ReportVisibleCount, iniPath, "Reports", "VisibleCount")
    RegisterReportHotkeys()
    ShowAtoolsNotice("Репорти збережено.")
}


SaveRadialToggleOnly() {
    global iniPath, Controls, EnableRadialMenu, RadialGui, RadialActive

    EnableRadialMenu := Controls.Has("RadialEnabledCB") ? (Controls["RadialEnabledCB"].Value = 1) : EnableRadialMenu
    IniWrite(EnableRadialMenu ? 1 : 0, iniPath, "Radial", "Enabled")

    if (!EnableRadialMenu && IsObject(RadialGui)) {
        try RadialGui.Destroy()
        RadialGui := ""
        RadialActive := false
    }
}

SaveRadialSettings() {
    global iniPath, RadialCommands, RadialCtrls, EnableRadialMenu, Controls
    InitRadialCommands()
    Loop 10 {
        if (A_Index = 7)
            RadialCommands[A_Index] := "ahouse"
        else if (RadialCtrls.Length >= A_Index)
            RadialCommands[A_Index] := RadialCtrls[A_Index].Text
        IniWrite(RadialCommands[A_Index], iniPath, "Radial", "Cmd" A_Index)
    }
    EnableRadialMenu := Controls.Has("RadialEnabledCB") ? (Controls["RadialEnabledCB"].Value = 1) : EnableRadialMenu
    IniWrite(EnableRadialMenu ? 1 : 0, iniPath, "Radial", "Enabled")
    ShowAtoolsNotice("Radial збережено.")
}

SaveThemeSettings() {
    global ThemeEditCtrls
    base := ThemeEditCtrls.Has("base") ? ThemeEditCtrls["base"].Text : "8A22D6"
    SaveThemeBaseColor(base)
}

SaveThemeBaseColor(base) {
    global iniPath, Theme, BaseThemeColor
    base := NormalizeHexColor(base, BaseThemeColor)
    BaseThemeColor := base
    ApplyThemeFromBase(base)
    IniWrite(base, iniPath, "Theme", "Base")
    for key, val in Theme
        IniWrite(val, iniPath, "Theme", key)
    ShowAtoolsNotice("Колір збережено. Перезапускаю ATools.")
    Sleep(420)
    Reload()
}

MixHex(hex1, hex2, ratio) {
    hex1 := RegExReplace(hex1, "[^0-9A-Fa-f]")
    hex2 := RegExReplace(hex2, "[^0-9A-Fa-f]")
    if (StrLen(hex1) < 6)
        hex1 := "070707"
    if (StrLen(hex2) < 6)
        hex2 := "242424"
    ratio := Max(0, Min(1, ratio))
    r1 := Integer("0x" SubStr(hex1, 1, 2)), g1 := Integer("0x" SubStr(hex1, 3, 2)), b1 := Integer("0x" SubStr(hex1, 5, 2))
    r2 := Integer("0x" SubStr(hex2, 1, 2)), g2 := Integer("0x" SubStr(hex2, 3, 2)), b2 := Integer("0x" SubStr(hex2, 5, 2))
    r := Round(r1 + (r2-r1)*ratio), g := Round(g1 + (g2-g1)*ratio), b := Round(b1 + (b2-b1)*ratio)
    return Format("{:02X}{:02X}{:02X}", r, g, b)
}

ApplyThemeFromBase(base) {
    global Theme, BaseThemeColor
    base := NormalizeHexColor(base, "8A22D6")
    BaseThemeColor := base
    if (base = "000000") {
        Theme["accent"] := "000000"
        Theme["accent2"] := "111111"
        Theme["sidebar"] := "050505"
        Theme["panel2"] := "0A0A0A"
        Theme["field"] := "101010"
        Theme["line"] := "202020"
        Theme["muted"] := "D8D8D8"
    } else {
        Theme["accent"] := base
        Theme["accent2"] := ShadeHex(base, -18)
        Theme["sidebar"] := ShadeHex(base, -45)
        Theme["panel2"] := ShadeHex(base, -32)
        Theme["field"] := ShadeHex(base, -58)
        Theme["line"] := ShadeHex(base, -72)
        Theme["muted"] := ShadeHex(base, 72)
    }
    Theme["bg"] := "101010"
    Theme["panel"] := "070707"
    Theme["text"] := "FFFFFF"
    Theme["danger"] := "E03636"
    Theme["success"] := "19D84A"
}

NormalizeHexColor(value, fallback := "8A22D6") {
    value := StrUpper(RegExReplace(value, "[^0-9A-Fa-f]"))
    if (StrLen(value) = 3) {
        value := SubStr(value,1,1) SubStr(value,1,1) SubStr(value,2,1) SubStr(value,2,1) SubStr(value,3,1) SubStr(value,3,1)
    }
    if (StrLen(value) != 6)
        return fallback
    return value
}

ShadeHex(hex, percent) {
    hex := NormalizeHexColor(hex)
    r := Integer("0x" SubStr(hex, 1, 2))
    g := Integer("0x" SubStr(hex, 3, 2))
    b := Integer("0x" SubStr(hex, 5, 2))
    if (percent >= 0) {
        r := Round(r + (255 - r) * percent / 100)
        g := Round(g + (255 - g) * percent / 100)
        b := Round(b + (255 - b) * percent / 100)
    } else {
        k := (100 + percent) / 100
        r := Round(r * k)
        g := Round(g * k)
        b := Round(b * k)
    }
    return Format("{:02X}{:02X}{:02X}", Max(0, Min(255, r)), Max(0, Min(255, g)), Max(0, Min(255, b)))
}


SelectBackgroundFile() {
    global iniPath, CustomBgPath
    selected := FileSelect(1, A_ScriptDir, "Вибери фон ATools", "Images (*.png; *.jpg; *.jpeg; *.webp)")
    if (selected = "")
        return
    CustomBgPath := selected
    IniWrite(CustomBgPath, iniPath, "Theme", "Background")
    ShowAtoolsNotice("Фон збережено. Перезапускаю ATools.")
    Sleep(450)
    Reload()
}

SelectUGTAFolder() {
    global roadPath
    selected := DirSelect("*" A_ScriptDir, 3, "Виберіть папку UKRAINE GTA")
    if (selected = "")
        return
    try FileDelete(roadPath)
    FileAppend(selected "`n", roadPath, "UTF-8")
    ShowAtoolsNotice("Папку UGTA збережено.")
    UpdateDashboardSetupNoteVisibility()
    InitConsoleLiveTail()
}

; =========================================================
; Hotkeys / actions
; =========================================================

RegisterCommandHotkeys() {
    global CommandKeys
    static oldKeys := []

    for _, key in oldKeys {
        if (key != "") {
            try Hotkey(key, "Off")
        }
    }
    oldKeys := []

    Loop 30 {
        i := A_Index
        key1 := SafeArrayGet(CommandKeys, i, "")
        if (key1 != "") {
            idx := i
            try {
                Hotkey(key1, (*) => RunCommand(idx), "On")
                oldKeys.Push(key1)
            }
        }
    }
}

RunCommand(index) {
    global Commands
    cmd := SafeArrayGet(Commands, index, "")
    if (Trim(cmd) = "")
        return
    SendCommandTextEx(cmd, true)
}

RegisterReportHotkeys() {
    global ReportKeys
    static oldKeys := []

    for _, key in oldKeys {
        if (key != "") {
            try Hotkey(key, "Off")
        }
    }
    oldKeys := []

    Loop 40 {
        i := A_Index
        key := SafeArrayGet(ReportKeys, i, "")
        if (key != "") {
            idx := i
            try {
                Hotkey(key, (*) => RunReport(idx), "On")
                oldKeys.Push(key)
            }
        }
    }
}

RunReport(index) {
    global Reports, Name, Rank
    text := Reports[index]
    if (text = "")
        return
    text := StrReplace(text, "{Rank}", Rank)
    text := StrReplace(text, "{Name}", Name)
    SendInput(text)
}

SendCommandText(cmd) {
    SendCommandTextEx(cmd, false)
}

SendCommandTextEx(cmd, autoEnter := false) {
    cmd := RegExReplace(cmd, "^/+")
    SendInput("{sc014}")
    Sleep(100)
    Send("^a")
    Sleep(100)
    if autoEnter
        SendInput("/" cmd "{Enter}")
    else
        SendInput("/" cmd " ")
}

StartPunishmentQueue() {
    global PunishmentBox, PunishmentQueueGui, PunishmentProgress, PunishmentStatus, Theme

    if !IsObject(PunishmentBox)
        return

    text := PunishmentBox.Text
    if (Trim(text) = "")
        return

    queue := []
    for line in StrSplit(text, "`n", "`r") {
        line := Trim(line)
        if (line != "")
            queue.Push(line)
    }

    if (queue.Length = 0)
        return

    ; Важливо для MTA: без WinActivate і без звичайного Center-вікна.
    ; Overlay показується NoActivate + click-through, тому не альтабає з гри.
    PunishmentQueueGui := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20", "Відправка покарань")
    PunishmentQueueGui.BackColor := Theme["panel"]
    PunishmentQueueGui.SetFont("s9 c" Theme["text"], "Arial")
    PunishmentQueueGui.AddText("x12 y8 w420 h20 BackgroundTrans", "Відправка покарань у гру")
    PunishmentProgress := PunishmentQueueGui.AddProgress("x12 y32 w420 h14 Range0-" queue.Length, 0)
    PunishmentStatus := PunishmentQueueGui.AddText("x12 y52 w420 h24 BackgroundTrans", "Підготовка...")

    x := Round((A_ScreenWidth - 444) / 2)
    y := 70
    PunishmentQueueGui.Show("x" x " y" y " w444 h84 NoActivate")
    try WinSetExStyle("+0x20", "ahk_id " PunishmentQueueGui.Hwnd)

    SendPunishmentQueue(queue)

    Sleep(250)
    try PunishmentQueueGui.Destroy()
}

SendPunishmentQueue(queue) {
    global PunishmentProgress, PunishmentStatus

    total := queue.Length

    for i, line in queue {
        if IsObject(PunishmentStatus)
            PunishmentStatus.Text := "Рядок " i " / " total
        if IsObject(PunishmentProgress)
            PunishmentProgress.Value := i - 1

        ; Старий робочий метод: T → текст → Enter.
        ; Без WinActivate, тому фокус лишається в MTA.
        Sleep(60)
        Send("{t}")
        Sleep(70)
        SendInput(line "{Enter}")
        Sleep(55)

        if IsObject(PunishmentProgress)
            PunishmentProgress.Value := i
    }
}

SendPunishmentLines() {
    global PunishmentBox

    if !IsObject(PunishmentBox)
        return

    text := PunishmentBox.Text
    if (Trim(text) = "")
        return

    for line in StrSplit(text, "`n", "`r") {
        line := Trim(line)
        if (line = "")
            continue

        Sleep(60)
        Send("{t}")
        Sleep(70)
        SendInput(line "{Enter}")
        Sleep(55)
    }
}

StartSoundMonitor() {
    InitConsoleLiveTail()
    SetTimer(CheckAtoolsSoundEvents, 200)
}

CheckAtoolsSoundEvents() {
    ; Репорт-звук грає тільки в ReportPanelScanLog(), коли приходить новий рядок репорту.
    ; Тут не читаємо старий log повністю, щоб не було спаму звуків.
    global LastFormSoundKey, LastSoundLineIndex, ConsoleLiveLines

    RefreshConsoleLiveTail()
    if (LastSoundLineIndex >= ConsoleLiveLines.Length)
        return

    startIndex := LastSoundLineIndex + 1
    LastSoundLineIndex := ConsoleLiveLines.Length

    Loop ConsoleLiveLines.Length - startIndex + 1 {
        line := ConsoleLiveLines[startIndex + A_Index - 1]
        if RegExMatch(line, "i)(Прийняття|форма|адм\.\s*форм|адміністративн).*?(F2|прийнято|заявк)", &m) {
            key := SubStr(line, 1, 160)
            if (key != LastFormSoundKey) {
                LastFormSoundKey := key
                PlayAtoolsSound("new_form")
            }
        }
    }
}

InitConsoleLiveTail() {
    global ConsoleLivePath, ConsoleLiveOffset, ConsoleLiveBuffer, ConsoleLiveLines, ConsoleLiveReady, LastReportPanelLineIndex, LastSoundLineIndex
    path := GetConsoleLogPath()
    ConsoleLivePath := path
    ConsoleLiveBuffer := ""
    ConsoleLiveLines := []
    LastReportPanelLineIndex := 0
    LastSoundLineIndex := 0

    if (path = "" || !FileExist(path)) {
        ConsoleLiveOffset := 0
        ConsoleLiveReady := false
        return
    }

    try {
        f := FileOpen(path, "r", "UTF-8")
        f.Seek(0, 2)
        ConsoleLiveOffset := f.Pos
        f.Close()
        ConsoleLiveReady := true
    } catch {
        ConsoleLiveOffset := 0
        ConsoleLiveReady := false
    }
}

RefreshConsoleLiveTail() {
    global ConsoleLivePath, ConsoleLiveOffset, ConsoleLiveBuffer, ConsoleLiveLines, ConsoleLiveReady
    global LastReportPanelLineIndex, LastSoundLineIndex

    path := GetConsoleLogPath()
    if (path = "" || !FileExist(path))
        return

    if (path != ConsoleLivePath || !ConsoleLiveReady) {
        InitConsoleLiveTail()
        return
    }

    try {
        f := FileOpen(path, "r", "UTF-8")
        f.Seek(0, 2)
        size := f.Pos
        if (size < ConsoleLiveOffset)
            ConsoleLiveOffset := 0
        if (size <= ConsoleLiveOffset) {
            f.Close()
            return
        }
        f.Seek(ConsoleLiveOffset, 0)
        chunk := f.Read()
        ConsoleLiveOffset := f.Pos
        f.Close()
    } catch {
        return
    }

    if (chunk = "")
        return

    chunk := ConsoleLiveBuffer chunk
    chunk := RegExReplace(chunk, "(\[\d{2}:\d{2}:\d{2}\])", "`n$1")
    rawLines := StrSplit(chunk, "`n", "`r")

    ConsoleLiveBuffer := ""
    if (rawLines.Length && !RegExMatch(rawLines[rawLines.Length], "^\[\d{2}:\d{2}:\d{2}\].+"))
        ConsoleLiveBuffer := rawLines.Pop()

    for _, raw in rawLines {
        line := NormalizeConsoleLine(Trim(raw))
        if (line != "")
            ConsoleLiveLines.Push(line)
    }

    if (ConsoleLiveLines.Length > 1500) {
        removeCount := ConsoleLiveLines.Length - 900
        Loop removeCount
            ConsoleLiveLines.RemoveAt(1)
        LastReportPanelLineIndex := Max(0, LastReportPanelLineIndex - removeCount)
        LastSoundLineIndex := Max(0, LastSoundLineIndex - removeCount)
    }
}

FindLastUnansweredReportInfo() {
    global ConsoleLiveLines
    RefreshConsoleLiveTail()
    last := ""
    start := Max(1, ConsoleLiveLines.Length - 120)
    Loop ConsoleLiveLines.Length - start + 1 {
        line := ConsoleLiveLines[start + A_Index - 1]
        info := ParseReportLine(line)
        if IsObject(info)
            last := Map("time", info["time"], "nick", info["nick"], "id", info["id"], "text", info["text"], "key", info["time"] "|" info["id"] "|" info["text"])
    }
    return last
}

GetUnansweredReportsSoundKey() {
    return ""
}

HandleCapsLockDown() {
    global EnableRadialMenu
    if (!EnableRadialMenu) {
        SetCapsLockState(!GetKeyState("CapsLock", "T"))
        return
    }
    ShowRadialMenu()
}

HandleCapsLockUp() {
    global EnableRadialMenu
    if (!EnableRadialMenu)
        return
    ExecuteRadialMenu()
}

; =========================================================
; Monitoring
; =========================================================

ToggleFeature(name) {
    global EnableF2, EnableF3, EnableExtraCommands, EnableReportFollow, EnableAdminChatMonitor, EnableBindHints
    switch name {
        case "F2":
            EnableF2 := !EnableF2
            ToggleLastFormWindow(EnableF2)
        case "F3":
            EnableF3 := !EnableF3
            ToggleAutoPmReportPanel(EnableF3)
        case "ReportFollow":
            EnableReportFollow := !EnableReportFollow
            ToggleReportFollow(EnableReportFollow)
        case "AdminChat":
            EnableAdminChatMonitor := !EnableAdminChatMonitor
            ToggleAdminChatWindow(EnableAdminChatMonitor)
        case "BindHints":
            EnableBindHints := !EnableBindHints
            ToggleBindHints(EnableBindHints)
    }
}

GetUGTAPath() {
    global roadPath
    if !FileExist(roadPath)
        return ""
    return Trim(FileRead(roadPath, "UTF-8"), " `t`r`n")
}

GetConsoleLogPath() {
    ugta := GetUGTAPath()
    if (ugta = "")
        return ""
    return ugta "\game\mta\logs\console.log"
}

ReadConsoleLog() {
    path := GetConsoleLogPath()
    if (path = "" || !FileExist(path))
        return ""
    try return FileRead(path, "UTF-8")
    catch
        return ""
}

GetConsoleLogLines(limit := 650) {
    content := ReadConsoleLog()
    linesOut := []
    if (content = "")
        return linesOut

    content := RegExReplace(content, "(\[\d{2}:\d{2}:\d{2}\])", "`n$1")
    rawLines := StrSplit(content, "`n", "`r")
    start := rawLines.Length - limit
    if (start < 1)
        start := 1

    Loop rawLines.Length - start + 1 {
        line := Trim(rawLines[start + A_Index - 1])
        if (line = "")
            continue
        line := NormalizeConsoleLine(line)
        if (line != "")
            linesOut.Push(line)
    }
    return linesOut
}

NormalizeConsoleLine(line) {
    line := RegExReplace(line, "^\[\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\]\s*\[[^\]]+\]\s*:\s*", "")
    line := RegExReplace(line, "\{[0-9A-Fa-f]{6}\}", "")
    line := RegExReplace(line, "#[0-9A-Fa-f]{6}", "")
    return Trim(line)
}

ParseReportLine(line) {
    ; М'який парсер під різні формати console.log:
    ; [15:09:04] Репорт від гравця Нік[ID]: текст
    ; [15:09:04] [БЕЗ ВІДПОВІДІ] Репорт від гравця Нік[ID]: текст
    if !InStr(line, "Репорт від гравця")
        return ""

    t := FormatTime(A_Now, "HH:mm:ss")
    if RegExMatch(line, "\[(\d{2}:\d{2}:\d{2})\]", &tm)
        t := tm[1]

    clean := RegExReplace(line, "\{[0-9A-Fa-f]{6}\}", "")
    clean := RegExReplace(clean, "#[0-9A-Fa-f]{6}", "")
    isUnanswered := RegExMatch(clean, "i)\[[^\]]*(БЕЗ|БЕЗ\s+ВІДПОВІДІ|БЕЗВІДПОВІДІ)[^\]]*ВІДПОВІДІ[^\]]*\]") ? true : false
    clean := RegExReplace(clean, "i)\[[^\]]*БЕЗ[^\]]*ВІДПОВІДІ[^\]]*\]", "")

    if RegExMatch(clean, "i)Репорт\s+від\s+гравця\s+(.+?)\s*\[(\d{4,10})\]\s*[:：]\s*(.*)", &m) {
        nick := Trim(m[1])
        nick := RegExReplace(nick, "^\[\d{2}:\d{2}:\d{2}\]\s*", "")
        text := Trim(m[3])
        if (text = "")
            text := "без тексту"
        return Map("time", t, "nick", nick, "id", m[2], "text", text, "key", m[2] ":" text, "unanswered", isUnanswered)
    }
    return ""
}

ParseAdminPmLine(line) {
    ; Дуже м'який парсер PM/дій адміністраторів.
    ; Ловить будь-яку роль: [Адміністратор / 4], [Ігровий помічник], [Заступник ГА] і т.д.
    ; Ловить ID як з пробілом перед дужками, так і без нього.
    clean := RegExReplace(line, "\{[0-9A-Fa-f]{6}\}", "")
    clean := RegExReplace(clean, "#[0-9A-Fa-f]{6}", "")
    clean := Trim(clean)

    t := FormatTime(A_Now, "HH:mm:ss")
    if RegExMatch(clean, "^\[(\d{2}:\d{2}:\d{2})\]", &tm)
        t := tm[1]

    ; 1) Основний формат:
    ; [15:38:50] [PM] [Адміністратор / 4] Віталік Яворський[6784077] -> Норт Фрей[6878726]: текст
    if InStr(clean, "[PM]") && InStr(clean, "->") {
        ; Беремо targetId після стрілки. Це головне для зняття статусу "без відповіді".
        if RegExMatch(clean, "->\s*(.*?)\s*\[(\d{4,10})\]\s*:", &target) {
            targetNick := Trim(target[1])
            targetId := target[2]

            adminName := "Адміністратор"
            adminId := ""

            ; Пробуємо витягнути адміна між роллю і його [ID].
            if RegExMatch(clean, "\[PM\]\s*\[[^\]]+\]\s*(.*?)\s*\[(\d{4,10})\]\s*->", &adm) {
                adminName := Trim(adm[1])
                adminId := adm[2]
            } else if RegExMatch(clean, "\[PM\].*?\]\s*(.*?)\s*\[(\d{4,10})\]\s*->", &adm2) {
                adminName := Trim(adm2[1])
                adminId := adm2[2]
            }

            return Map("time", t, "admin", adminName, "adminId", adminId, "targetNick", targetNick, "targetId", targetId)
        }
    }

    ; 2) Admin-chat лог дій: [A] Адмін[ID] -> /sp Гравець[ID] або /pm Гравець[ID]
    if RegExMatch(clean, "^\[(\d{2}:\d{2}:\d{2})\]\s*\[[AaАа]\]\s*(.+?)\s*\[(\d{4,10})\]\s*->\s*/(?:sp|pm)\s*(.+?)\s*\[(\d{4,10})\]", &m)
        return Map("time", m[1], "admin", Trim(m[2]), "adminId", m[3], "targetNick", Trim(m[4]), "targetId", m[5])

    ; 3) Fallback: будь-який рядок зі стрілкою на гравця з ID.
    ; Спеціально для випадків, коли console.log ріже/чистить частину префіксу.
    if InStr(clean, "->") && RegExMatch(clean, "->\s*(.*?)\s*\[(\d{4,10})\]", &fb) {
        ; Не чіпаємо системні рядки без ознак PM/admin.
        if InStr(clean, "[PM]") || RegExMatch(clean, "\[[AaАа]\]") || InStr(clean, "/sp") || InStr(clean, "/pm") {
            adminName := "Адміністратор"
            if RegExMatch(clean, "\]\s*([^\[\]]+?)\s*\[\d{4,10}\]\s*->", &an)
                adminName := Trim(an[1])
            return Map("time", t, "admin", adminName, "adminId", "", "targetNick", Trim(fb[1]), "targetId", fb[2])
        }
    }

    return ""
}

FindLastAdminForm() {
    info := FindLastAdminFormInfo()
    if !IsObject(info)
        return ""
    return info["cmd"]
}

GetPendingAdminForms(maxAgeSec := 60) {
    global AcceptedFormKeys, FormSeenTicks
    content := ReadConsoleLog()
    forms := []
    if (content = "")
        return forms

    words := "(offmute|jailoffline|pbanoffline|warn|pkick|pban|pmute|jail|unwarn|unmute|unjail|global|offwarn|pskin|weapongive|setnickname|tempnickname|gm|sethp|spawncar|fixveh|flip|slap|unban|mute|ban|kick)"

    for line in StrSplit(content, "`n", "`r") {
        line := Trim(line)
        if (line = "")
            continue
        if InStr(line, "[ATools]")
            continue

        logTime := ""
        nick := "Невідомо"
        cmd := ""
        id := ""

        ; Новий/ігровий формат: [03:31:15] [Головний Адміністратор] Нік [ID]: gm 123
        if RegExMatch(line, "^\[(\d{2}:\d{2}:\d{2})\]\s*\[[^\]]+\]\s*(.*?)\s*\[(\d+)\]\s*:\s*/?(" words "\b.*)$", &m) {
            logTime := m[1]
            nick := Trim(m[2])
            id := m[3]
            cmd := Trim(m[4])
        }
        ; Старий/Output формат із датою.
        else if RegExMatch(line, "^\[\d{4}-\d{2}-\d{2}\s(\d{2}:\d{2}:\d{2})\].*?:\s*/?(" words "\b.*)$", &m) {
            logTime := m[1]
            cmd := Trim(m[2])
            if RegExMatch(line, "\]\s*:\s*\[[^\]]+\]\s*(.*?)\s*\[(\d+)\]", &n) {
                nick := Trim(n[1])
                id := n[2]
            }
        }
        ; Fallback: будь-який рядок, де після двокрапки є команда.
        else if RegExMatch(line, "^\[(\d{2}:\d{2}:\d{2})\].*?:\s*/?(" words "\b.*)$", &m) {
            logTime := m[1]
            cmd := Trim(m[2])
        }

        if (cmd = "")
            continue

        key := logTime "|" nick "|" id "|" cmd
        if AcceptedFormKeys.Has(key)
            continue

        ; Якщо форму вже схвалив інший ATools, вона з overlay зникає.
        if HasRecentAToolsAccept(cmd, logTime, id, maxAgeSec) {
            AcceptedFormKeys[key] := true
            try FormSeenTicks.Delete(key)
            continue
        }

        if !FormSeenTicks.Has(key)
            FormSeenTicks[key] := A_TickCount

        age := SecondsSinceLogTime(logTime)
        if (age > maxAgeSec) {
            try FormSeenTicks.Delete(key)
            continue
        }

        seenTick := FormSeenTicks[key]
        forms.Push(Map("cmd", cmd, "nick", nick, "time", logTime, "id", id, "key", key, "age", age, "seenTick", seenTick))
    }

    return forms
}

FindLastAdminFormInfo() {
    forms := GetPendingAdminForms(60)
    if (forms.Length = 0)
        return ""
    return forms[forms.Length]
}

SecondsSinceLogTime(logTime) {
    if (logTime = "")
        return 0

    nowH := Integer(FormatTime(A_Now, "HH"))
    nowM := Integer(FormatTime(A_Now, "mm"))
    nowS := Integer(FormatTime(A_Now, "ss"))
    nowSec := nowH * 3600 + nowM * 60 + nowS

    parts := StrSplit(logTime, ":")
    if (parts.Length < 3)
        return 0

    logSec := Integer(parts[1]) * 3600 + Integer(parts[2]) * 60 + Integer(parts[3])
    diff := nowSec - logSec
    if (diff < 0)
        diff += 86400
    return diff
}
FindLastReportId() {
    last := ""
    for _, line in GetConsoleLogLines(900) {
        info := ParseReportLine(line)
        if IsObject(info)
            last := info["id"]
    }
    return last
}


FindLastReportLines(maxLines := 6) {
    matches := []
    for _, line in GetConsoleLogLines(900) {
        info := ParseReportLine(line)
        if IsObject(info) {
            matches.Push(line)
            if (matches.Length > maxLines)
                matches.RemoveAt(1)
        }
    }
    out := ""
    for _, line in matches
        out .= line "`n"
    return out
}


FindLastVipChatLines(maxLines := 12) {
    content := ReadConsoleLog()
    if (content = "")
        return ""

    matches := []

    ; Іноді console.log віддає кілька VIP-повідомлень одним шматком.
    ; Розбиваємо їх примусово перед кожним [HH:MM:SS] [VIP].
    content := RegExReplace(content, "(\[\d{2}:\d{2}:\d{2}\]\s*\[VIP\])", "`n$1")
    content := RegExReplace(content, "(\[\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\]\s*\[Output\]\s*:\s*\[VIP\])", "`n$1")

    for line in StrSplit(content, "`n", "`r") {
        raw := Trim(line)
        if (raw = "")
            continue

        time := "--:--:--"
        clean := raw

        ; [2026-04-28 04:05:28] [Output] : [VIP] текст
        if RegExMatch(clean, "^\[(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})\]\s*\[Output\]\s*:\s*(\[VIP\].*)$", &m) {
            time := m[2]
            clean := Trim(m[3])
        }
        ; [04:05:28] [VIP] текст
        else if RegExMatch(clean, "^\[(\d{2}:\d{2}:\d{2})\]\s*(\[VIP\].*)$", &m) {
            time := m[1]
            clean := Trim(m[2])
        }
        ; [VIP] текст
        else if RegExMatch(clean, "^(\[VIP\].*)$", &m) {
            clean := Trim(m[1])
        } else {
            continue
        }

        ; Якщо після VIP-повідомлення прилип наступний час, обрізаємо хвіст.
        clean := RegExReplace(clean, "\s+\[\d{2}:\d{2}:\d{2}\].*$", "")

        matches.Push(time " | " clean)
        if (matches.Length > maxLines)
            matches.RemoveAt(1)
    }

    out := ""
    for _, msg in matches
        out .= msg "`r`n"
    return out
}

AcceptLastAdminForm() {
    global EnableF2, AcceptedFormKeys, FormSeenTicks
    if !EnableF2
        return

    info := FindLastAdminFormInfo()
    if !IsObject(info)
        return

    last := info["cmd"]
    elapsedSec := info.Has("seenTick") ? ((A_TickCount - info["seenTick"]) / 1000) : SecondsSinceLogTime(info["time"])

    ; Якщо інший ATools уже прийняв цю форму протягом останніх 6 секунд, не дублюємо команду.
    if HasRecentAToolsAccept(last, info["time"], info.Has("id") ? info["id"] : "") {
        AcceptedFormKeys[info["key"]] := true
        try FormSeenTicks.Delete(info["key"])
        UpdateLastFormWindow()
        ToolTip("Форма вже прийнята іншим ATools")
        SetTimer(() => ToolTip(), -1400)
        return
    }

    ; Позначаємо форму прийнятою до відправки, щоб overlay не показував її повторно.
    AcceptedFormKeys[info["key"]] := true
    try FormSeenTicks.Delete(info["key"])
    UpdateLastFormWindow()

    SendInput("{sc014}")
    Sleep(500)

    ; Контроль прямо перед відправкою, щоб не встиг продублювати, враховуємо тільки останні 6 секунд.
    if HasRecentAToolsAccept(last, info["time"], info.Has("id") ? info["id"] : "") {
        ToolTip("Скасовано: форму вже прийняли")
        SetTimer(() => ToolTip(), -1400)
        return
    }

    SendInput("/" last "{Enter}")

    Sleep(120)

    ; Якщо за цей час у чаті з'явилось чуже [ATools] по цій же формі, не пишемо другий success.
    ; Для toggle-команд типу gm/lgm повторюємо команду, щоб повернути стан назад.
    if HasRecentAToolsAccept(last, info["time"], info.Has("id") ? info["id"] : "") {
        if IsToggleAdminCommand(last) {
            Sleep(200)
            SendInput("{sc014}")
            Sleep(220)
            SendInput("/" last "{Enter}")
            Sleep(300)
            SendAdminConflictNotice(last)
        }
        return
    }

    SendAdminAcceptNotice(last, elapsedSec, info.Has("time") ? info["time"] : "", info.Has("id") ? info["id"] : "")
}

NormalizeCommandForCompare(commandText) {
    cmd := StrLower(Trim(commandText))
    cmd := RegExReplace(cmd, "^/+")
    cmd := RegExReplace(cmd, "\s+", " ")
    return cmd
}

HasRecentAToolsAccept(commandText, formTime := "", formId := "", maxAgeSec := 6) {
    content := ReadConsoleLog()
    if (content = "")
        return false

    target := NormalizeCommandForCompare(commandText)
    formSec := TimeToSeconds(formTime)

    for line in StrSplit(content, "`n", "`r") {
        low := StrLower(line)
        if !InStr(low, "[atools]")
            continue
        if !InStr(low, "accepted command")
            continue

        ; Важливо: беремо час самого лог-рядка, тобто перші [HH:mm:ss] на початку рядка.
        ; Якщо часу немає — такий рядок не блокує форму.
        if !RegExMatch(line, "^\[(\d{2}:\d{2}:\d{2})\]", &tm)
            continue

        logTime := tm[1]
        acceptAge := SecondsSinceLogTime(logTime)
        if (acceptAge > maxAgeSec)
            continue

        ; Щоб стара ідентична команда вище не блокувала нову форму,
        ; приймаємо тільки повідомлення з form:<час подачі> або fid:<id>.
        hasFormMark := RegExMatch(line, "i)\bform:\s*(\d{2}:\d{2}:\d{2})", &fm)
        hasIdMark := RegExMatch(line, "i)\bfid:\s*(\d+)", &im)

        if (formTime != "") {
            if hasFormMark {
                if (fm[1] != formTime)
                    continue
            } else {
                ; Нові версії ATools завжди пишуть form:<час>.
                ; Старі [ATools] без form більше не блокують, бо через них були фальш-відмови.
                continue
            }
        }

        if (formId != "" && hasIdMark) {
            if (im[1] != formId)
                continue
        }

        ; Додатково страхуємося: accepted має бути не раніше форми і в межах maxAgeSec.
        if (formSec >= 0) {
            acceptSec := TimeToSeconds(logTime)
            deltaFromForm := acceptSec - formSec
            if (deltaFromForm < 0)
                deltaFromForm += 86400
            if (deltaFromForm > maxAgeSec)
                continue
        }

        if RegExMatch(line, "i)accepted command:\s*/?([^|]+)", &m) {
            accepted := NormalizeCommandForCompare(m[1])
            if (accepted = target)
                return true
        }
    }
    return false
}

TimeToSeconds(timeText) {
    if (timeText = "")
        return -1
    parts := StrSplit(timeText, ":")
    if (parts.Length < 3)
        return -1
    return Integer(parts[1]) * 3600 + Integer(parts[2]) * 60 + Integer(parts[3])
}

IsToggleAdminCommand(commandText) {
    cmd := NormalizeCommandForCompare(commandText)
    first := StrSplit(cmd, " ")[1]
    return first = "gm" || first = "lgm"
}

SendAdminAcceptNotice(commandText, elapsedSec, formTime := "", formId := "") {
    elapsed := Format("{:.2f}", elapsedSec)
    stamp := FormatTime(A_Now, "HH:mm:ss")

    ; Початок повідомлення залишився як ти просив.
    ; form/fid потрібні для захисту від дублювання саме цієї форми, а не старої ідентичної команди.
    message := "[ATools] Accepted command: /" commandText " | " elapsed "s | " stamp
    if (formTime != "")
        message .= " | form: " formTime
    if (formId != "")
        message .= " | fid: " formId

    SendInput("{sc014}")
    Sleep(60)
    SendInput("/a " message "{Enter}")
}

SendAdminConflictNotice(commandText) {
    stamp := FormatTime(A_Now, "HH:mm:ss")
    message := "[ATools] Conflict detected. Reverted duplicate: /" commandText " | " stamp
    SendInput("{sc014}")
    Sleep(60)
    SendInput("/a " message "{Enter}")
}
AutoPmLastReport() {
    global EnableF3, LastPmId
    if !EnableF3
        return

    id := ReportPanelGetActiveId()
    if (id = "")
        id := FindLastReportId()
    if (id = "")
        return

    SendInput("{sc014}")
    Sleep(60)
    SendInput("/pm " id " ")
    LastPmId := id
    ReportPanelMarkAnsweredByMe(id)
}

RepeatLastPmId() {
    global EnableF3, LastPmId
    if !EnableF3
        return

    id := ReportPanelGetActiveId()
    if (id = "")
        id := LastPmId
    if (id = "")
        return

    LastPmId := id
    SendInput(id " ")
}

ReportPanelF1Action() {
    global EnableF3
    if (EnableF3 && ReportPanelCloseActive())
        return
    DeclineLastAdminForm()
}

F2StartDrag(*) {
    global F2Gui
    if !IsObject(F2Gui)
        return
    PostMessage(0xA1, 2,,, "ahk_id " F2Gui.Hwnd)
    SetTimer(F2SavePosition, -700)
}

F2SavePosition() {
    global F2Gui, F2PosX, F2PosY, iniPath
    if !IsObject(F2Gui)
        return
    try {
        F2Gui.GetPos(&x, &y)
        F2PosX := x, F2PosY := y
        IniWrite(x, iniPath, "F2Panel", "X")
        IniWrite(y, iniPath, "F2Panel", "Y")
    }
}

ToggleLastFormWindow(enable) {
    global F2Gui, F2ListView, Theme, F2PosX, F2PosY
    if enable {
        F2Gui := Gui("-Caption +AlwaysOnTop +ToolWindow", "ATools | Forms")
        F2Gui.BackColor := Theme["panel"]
        F2Gui.SetFont("s8 c" Theme["text"], "Arial")
        titleBar := F2Gui.AddText("x0 y0 w420 h20 Background" Theme["line"], "")
        titleBar.OnEvent("Click", F2StartDrag)
        titleText := F2Gui.AddText("x8 y3 w330 h16 BackgroundTrans", "ATools | F2 форми")
        titleText.OnEvent("Click", F2StartDrag)
        close := F2Gui.AddText("x395 y2 w18 h16 Center +0x100 Background" Theme["line"], "×")
        close.OnEvent("Click", (*) => ToggleFeature("F2"))
        F2Gui.AddText("x8 y26 w400 h16 BackgroundTrans", "F2 — прийняти | F1 — закрити | росте під нові форми")
        F2ListView := F2Gui.AddListView("x8 y48 w404 h44 Background" Theme["field"] " c" Theme["text"] " Grid -Multi -Hdr", ["Форма", "Нікнейм", "ID", "Залишилось"])
        F2ListView.ModifyCol(1, 135)
        F2ListView.ModifyCol(2, 145)
        F2ListView.ModifyCol(3, 58)
        F2ListView.ModifyCol(4, 66)
        F2Gui.Show("x" F2PosX " y" F2PosY " w420 h100 NoActivate")
        ForceTopMost(F2Gui)
        SetTimer(UpdateLastFormWindow, 300)
        UpdateLastFormWindow()
    } else {
        SetTimer(UpdateLastFormWindow, 0)
        try F2Gui.Destroy()
        F2ListView := ""
    }
}

UpdateLastFormWindow() {
    global F2Gui, F2ListView
    if !IsObject(F2Gui)
        return

    ; Коли пункт моніторингу вимикається, таймер може спрацювати ще раз.
    ; Тому ListView чиститься тільки через try, без падіння AHK.
    try F2ListView.Delete()
    catch {
        return
    }

    forms := GetPendingAdminForms(60)
    rowCount := forms.Length
    if (rowCount = 0) {
        try F2ListView.Add("", "Активних форм немає", "", "", "")
        rowCount := 1
    } else {
        for _, f in forms {
            left := Max(0, 60 - Round(f["age"]))
            try F2ListView.Add("", f["cmd"], f["nick"], f["id"], left "с")
        }
    }

    rowsVisible := Min(Max(rowCount, 1), 6)
    listH := 28 + rowsVisible * 22
    totalH := 58 + listH
    try F2ListView.Move(8, 48, 404, listH)
    try F2Gui.Show("w420 h" totalH " NoActivate")
    ForceTopMost(F2Gui)
}


DeclineLastAdminForm() {
    global EnableF2, AcceptedFormKeys, FormSeenTicks
    if !EnableF2
        return

    info := FindLastAdminFormInfo()
    if !IsObject(info)
        return

    AcceptedFormKeys[info["key"]] := true
    elapsedSec := info.Has("seenTick") ? ((A_TickCount - info["seenTick"]) / 1000) : SecondsSinceLogTime(info["time"])
    try FormSeenTicks.Delete(info["key"])
    UpdateLastFormWindow()
    SendAdminDeclineNotice(info["cmd"], elapsedSec)
}

SendAdminDeclineNotice(commandText, elapsedSec) {
    elapsed := Format("{:.2f}", elapsedSec)
    stamp := FormatTime(A_Now, "HH:mm:ss")
    message := "[ATools] Declined command: /" commandText " | " elapsed "s | " stamp

    SendInput("{sc014}")
    Sleep(60)
    SendInput("/a " message "{Enter}")
}


ToggleAutoPmReportPanel(enable) {
    if enable {
        ReportPanelCreate()
        SetTimer(ReportPanelUpdate, 150)
        ToolTip("AutoID PM + Report Panel увімкнено")
    } else {
        SetTimer(ReportPanelUpdate, 0)
        ReportPanelDestroy()
        ToolTip("AutoID PM вимкнено")
    }
    SetTimer(() => ToolTip(), -900)
}

ToggleReportFollow(enable) {
    if enable {
        SetTimer(CheckReportFollowAlert, 500)
        ToolTip("Слідкування за репортами увімкнено")
    } else {
        SetTimer(CheckReportFollowAlert, 0)
        ToolTip("Слідкування за репортами вимкнено")
    }
    SetTimer(() => ToolTip(), -900)
}

CheckReportFollowAlert() {
    global ReportPanelItems, LastReportFollowAlertTick
    ReportPanelScanLog()
    now := A_TickCount
    count := 0
    for _, item in ReportPanelItems {
        if (item["status"] = "open" && item.Has("unanswered") && item["unanswered"])
            count++
    }
    if (count >= 5 && (now - LastReportFollowAlertTick) > 15000) {
        LastReportFollowAlertTick := now
        ShowReportFollowAlert(count)
    }
}

ShowReportFollowAlert(count) {
    global ReportFollowNotifyGui, Theme
    try {
        if IsObject(ReportFollowNotifyGui)
            ReportFollowNotifyGui.Destroy()
    }
    ReportFollowNotifyGui := Gui("-Caption +AlwaysOnTop +ToolWindow", "ATools Report Alert")
    ReportFollowNotifyGui.BackColor := Theme["panel"]
    ReportFollowNotifyGui.SetFont("s12 bold c" Theme["text"], "Arial")
    ReportFollowNotifyGui.AddText("x0 y0 w520 h4 Background" Theme["danger"], "")
    ReportFollowNotifyGui.AddText("x0 y4 w520 h58 Background" Theme["panel"], "")
    ReportFollowNotifyGui.AddText("x18 y20 w484 h24 Center BackgroundTrans", count "+ репортів без відповіді, потрібна допомога")
    ReportFollowNotifyGui.Show("x" (A_ScreenWidth//2 - 260) " y40 w520 h62 NoActivate")
    ForceTopMost(ReportFollowNotifyGui)
    SetTimer(HideReportFollowAlert, -7000)
}

HideReportFollowAlert() {
    global ReportFollowNotifyGui
    try {
        if IsObject(ReportFollowNotifyGui)
            ReportFollowNotifyGui.Destroy()
    }
    ReportFollowNotifyGui := ""
}

ReportPanelCreate() {
    global ReportPanelGui, Theme, ReportPanelPlayerText, ReportPanelStatusText, ReportPanelTimerText, ReportPanelHintText, ReportPanelAccentBar
    global ReportPanelTitleText, ReportPanelCloseText, ReportPanelPosX, ReportPanelPosY, ReportPanelW, ReportPanelH

    try {
        if IsObject(ReportPanelGui)
            ReportPanelGui.Destroy()
    }

    ReportPanelGui := Gui("-Caption +AlwaysOnTop +ToolWindow", "ATools Report Panel")
    ReportPanelGui.BackColor := Theme["panel"]

    ReportPanelAccentBar := ReportPanelGui.AddText("x0 y0 w" ReportPanelW " h4 Background" Theme["accent"], "")
    ReportPanelGui.AddText("x0 y4 w" ReportPanelW " h22 Background" Theme["field"], "")

    ReportPanelGui.SetFont("s8 bold c" Theme["text"], "Arial")
    ReportPanelTitleText := ReportPanelGui.AddText("x10 y7 w245 h18 BackgroundTrans", "✉ ATools | AutoID PM")
    ReportPanelTitleText.OnEvent("Click", ReportPanelStartDrag)

    ReportPanelGui.SetFont("s9 bold c" Theme["muted"], "Arial")
    ReportPanelCloseText := ReportPanelGui.AddText("x313 y6 w20 h18 Center BackgroundTrans", "×")
    ReportPanelCloseText.OnEvent("Click", (*) => ToggleFeature("F3"))

    ReportPanelGui.SetFont("s13 bold c" Theme["text"], "Arial")
    ReportPanelPlayerText := ReportPanelGui.AddText("x12 y32 w245 h23 BackgroundTrans", "✦ Репортів немає")

    ReportPanelGui.SetFont("s16 bold c" Theme["text"], "Arial")
    ReportPanelTimerText := ReportPanelGui.AddText("x265 y31 w60 h26 Right BackgroundTrans", "--")

    ReportPanelGui.SetFont("s9 c" Theme["muted"], "Arial")
    ReportPanelStatusText := ReportPanelGui.AddText("x12 y58 w315 h31 BackgroundTrans", "Очікування нових репортів з console.log")

    ReportPanelGui.SetFont("s8 c" Theme["muted"], "Arial")
    ReportPanelHintText := ReportPanelGui.AddText("x12 y94 w315 h17 BackgroundTrans", "F3 — PM | F4 — ID | F1 — наступний")

    ; Якщо координати злетіли за межі екрану — повертаємо у видиму область.
    if (ReportPanelPosX < 0 || ReportPanelPosX > A_ScreenWidth - 80)
        ReportPanelPosX := 20
    if (ReportPanelPosY < 0 || ReportPanelPosY > A_ScreenHeight - 60)
        ReportPanelPosY := 250

    ReportPanelGui.Show("x" ReportPanelPosX " y" ReportPanelPosY " w" ReportPanelW " h" ReportPanelH " NoActivate")
    ForceTopMost(ReportPanelGui)
    ReportPanelUpdate()
}

ReportPanelStartDrag(*) {
    global ReportPanelGui
    if !IsObject(ReportPanelGui)
        return
    PostMessage(0xA1, 2,,, "ahk_id " ReportPanelGui.Hwnd)
    SetTimer(ReportPanelSavePosition, -700)
}

ReportPanelSavePosition() {
    global ReportPanelGui, ReportPanelPosX, ReportPanelPosY, iniPath
    if !IsObject(ReportPanelGui)
        return
    try {
        ReportPanelGui.GetPos(&x, &y)
        ReportPanelPosX := x
        ReportPanelPosY := y
        IniWrite(x, iniPath, "ReportPanel", "X")
        IniWrite(y, iniPath, "ReportPanel", "Y")
    }
}

ReportPanelDestroy() {
    global ReportPanelGui, ReportPanelItems, ReportPanelOrder, ReportPanelActiveKey, ReportPanelSeenKeys, ReportPanelMutedKeys, ReportPanelTitleText, ReportPanelCloseText
    try {
        if IsObject(ReportPanelGui)
            ReportPanelGui.Destroy()
    }
    ReportPanelGui := ""
    ReportPanelTitleText := ""
    ReportPanelCloseText := ""
    ReportPanelItems := Map()
    ReportPanelOrder := []
    ReportPanelActiveKey := ""
    ReportPanelSeenKeys := Map()
    ReportPanelMutedKeys := Map()
}

ReportPanelUpdate() {
    global ReportPanelGui, ReportPanelItems, ReportPanelOrder, ReportPanelActiveKey
    global ReportPanelPlayerText, ReportPanelStatusText, ReportPanelTimerText, ReportPanelHintText, ReportPanelAccentBar
    global Theme

    ReportPanelScanLog()
    ReportPanelCleanup()
    ReportPanelChooseActive()

    if !IsObject(ReportPanelGui)
        return

    if (ReportPanelActiveKey = "" || !ReportPanelItems.Has(ReportPanelActiveKey)) {
        try {
            ReportPanelPlayerText.Text := "Репортів немає"
            ReportPanelStatusText.Text := "Очікування console.log"
            ReportPanelTimerText.Text := "--"
            ReportPanelHintText.Text := "F3 — PM | F4 — ID | F1 — наступний"
            ReportPanelAccentBar.Opt("Background" Theme["accent"])
        }
        return
    }

    item := ReportPanelItems[ReportPanelActiveKey]
    left := Max(0, Ceil((item["expires"] - A_TickCount) / 1000))
    safeText := item["text"]
    if (StrLen(safeText) > 74)
        safeText := SubStr(safeText, 1, 74) "..."

    status := item["status"]
    if (status = "answered")
        statusLine := "Взяв: " item["admin"] " | " safeText
    else if (status = "me")
        statusLine := "Відповідаєш ти | " safeText
    else {
        prefix := (item.Has("unanswered") && item["unanswered"]) ? "[БЕЗ ВІДПОВІДІ] " : "Новий репорт | "
        statusLine := prefix safeText
    }

    try {
        ReportPanelPlayerText.Text := item["nick"] " [" item["id"] "]"
        ReportPanelStatusText.Text := statusLine
        ReportPanelTimerText.Text := left "с"
        ReportPanelHintText.Text := "F3 — PM | F4 — ID | F1 — наступний"
        if (status = "open")
            ReportPanelAccentBar.Opt("Background" Theme["danger"])
        else
            ReportPanelAccentBar.Opt("Background" Theme["success"])
    }
}

ReportPanelScanLog() {
    global ReportPanelItems, ReportPanelOrder, ReportPanelSeenKeys, ReportPanelMutedKeys
    global ReportPanelMaxAliveMs, ReportPanelAnsweredAliveMs, ReportPanelLastBeepKey
    global ConsoleLiveLines, LastReportPanelLineIndex, LastReportSoundTick

    RefreshConsoleLiveTail()
    if (LastReportPanelLineIndex >= ConsoleLiveLines.Length)
        return

    now := A_TickCount
    startIndex := LastReportPanelLineIndex + 1
    LastReportPanelLineIndex := ConsoleLiveLines.Length

    Loop ConsoleLiveLines.Length - startIndex + 1 {
        raw := ConsoleLiveLines[startIndex + A_Index - 1]
        info := ParseReportLine(raw)
        if IsObject(info) {
            key := info["id"] ":" info["text"]
            if ReportPanelMutedKeys.Has(key)
                continue

            createdTick := now
            if !ReportPanelItems.Has(key) {
                ReportPanelItems[key] := Map("id", info["id"], "nick", info["nick"], "text", info["text"], "time", info["time"], "created", createdTick, "expires", createdTick + ReportPanelMaxAliveMs, "status", "open", "admin", "", "unanswered", info.Has("unanswered") ? info["unanswered"] : false)
                ReportPanelOrder.Push(key)

                if !ReportPanelSeenKeys.Has(key) {
                    ReportPanelSeenKeys[key] := true
                    if (ReportPanelLastBeepKey != key && (now - LastReportSoundTick) > 450) {
                        PlayAtoolsSound("new_report")
                        ReportPanelLastBeepKey := key
                        LastReportSoundTick := now
                    }
                }
            } else {
                item := ReportPanelItems[key]
                item["expires"] := Max(item["expires"], now + ReportPanelMaxAliveMs)
                if (item["status"] = "open") {
                    item["text"] := info["text"]
                    if (info.Has("unanswered") && info["unanswered"])
                        item["unanswered"] := true
                }
                ReportPanelItems[key] := item
            }
            continue
        }

        pm := ParseAdminPmLine(raw)
        if IsObject(pm) {
            targetId := pm["targetId"]
            adminName := pm["admin"]
            for key, item in ReportPanelItems {
                if (item["id"] = targetId && item["status"] != "me") {
                    limitExpires := item["created"] + ReportPanelAnsweredAliveMs
                    if (limitExpires < item["expires"])
                        item["expires"] := limitExpires
                    item["status"] := "answered"
                    item["admin"] := adminName
                    item["unanswered"] := false
                    ReportPanelItems[key] := item
                }
            }
        }
    }
}


ReportPanelCleanup() {
    global ReportPanelItems, ReportPanelOrder, ReportPanelActiveKey
    now := A_TickCount
    newOrder := []
    for _, key in ReportPanelOrder {
        if ReportPanelItems.Has(key) {
            item := ReportPanelItems[key]
            if (item["expires"] > now) {
                newOrder.Push(key)
            } else {
                try ReportPanelItems.Delete(key)
                if (ReportPanelActiveKey = key)
                    ReportPanelActiveKey := ""
            }
        }
    }
    ReportPanelOrder := newOrder
}

ReportPanelChooseActive() {
    global ReportPanelItems, ReportPanelOrder, ReportPanelActiveKey
    if (ReportPanelActiveKey != "" && ReportPanelItems.Has(ReportPanelActiveKey))
        return

    ReportPanelActiveKey := ""
    for _, key in ReportPanelOrder {
        if ReportPanelItems.Has(key) {
            ReportPanelActiveKey := key
            return
        }
    }
}

ReportPanelGetActiveId() {
    global ReportPanelItems, ReportPanelActiveKey
    ReportPanelUpdate()
    if (ReportPanelActiveKey != "" && ReportPanelItems.Has(ReportPanelActiveKey))
        return ReportPanelItems[ReportPanelActiveKey]["id"]
    return ""
}

ReportPanelMarkAnsweredByMe(id) {
    global ReportPanelItems
    for key, item in ReportPanelItems {
        if (item["id"] = id) {
            item["status"] := "me"
            item["admin"] := "Ви"
            if ((item["created"] + 30000) < item["expires"])
                item["expires"] := item["created"] + 30000
            ReportPanelItems[key] := item
            return
        }
    }
}

ReportPanelCloseActive() {
    global ReportPanelItems, ReportPanelOrder, ReportPanelActiveKey, ReportPanelMutedKeys
    if (ReportPanelActiveKey = "" || !ReportPanelItems.Has(ReportPanelActiveKey))
        return false

    ReportPanelMutedKeys[ReportPanelActiveKey] := true
    try ReportPanelItems.Delete(ReportPanelActiveKey)
    newOrder := []
    for _, key in ReportPanelOrder {
        if (key != ReportPanelActiveKey)
            newOrder.Push(key)
    }
    ReportPanelOrder := newOrder
    ReportPanelActiveKey := ""
    ReportPanelUpdate()
    return true
}

ToggleLastReportIdWindow(enable) {
    global F3Gui, Theme
    if enable {
        F3Gui := Gui("+AlwaysOnTop +ToolWindow", "Останній репорт від")
        F3Gui.BackColor := Theme["panel"]
        F3Gui.SetFont("s8 c" Theme["text"], "Arial")
        F3Gui.AddText("w500 h22 vLastReportIdText", "Очікування...")
        F3Gui.Show("x20 y60 NoActivate")
        ForceTopMost(F3Gui)
        SetTimer(UpdateLastReportIdWindow, 500)
    } else {
        SetTimer(UpdateLastReportIdWindow, 0)
        try F3Gui.Destroy()
    }
}

UpdateLastReportIdWindow() {
    global F3Gui, LastPmId
    if IsObject(F3Gui) {
        id := FindLastReportId()
        try F3Gui["LastReportIdText"].Text := id " | Остання відповідь: " LastPmId
    }
}

ToggleReportWindow(enable) {
    global ReportGui, Theme
    if enable {
        ReportGui := GameOverlay.Create("Репорти від гравців", Theme)
        ReportGui.SetFont("s9 c" Theme["text"], "Arial")
        reportViewOpt := "x10 y10 w900 h90 ReadOnly +Wrap Background" Theme["field"] " c" Theme["text"] " vReportText"
        ReportGui.AddEdit(reportViewOpt)
        reportSendOpt := "x10 y110 w900 h24 Background" Theme["field"] " c" Theme["text"] " vReportSendText"
        ReportGui.AddEdit(reportSendOpt)
        ReportGui.Show("x20 y100 w920 h145 NoActivate")
        ForceTopMost(ReportGui)
        GameOverlay.Apply(ReportGui)
        SetTimer(UpdateReportWindow, 1000)
    } else {
        SetTimer(UpdateReportWindow, 0)
        try ReportGui.Destroy()
    }
}

UpdateReportWindow() {
    global ReportGui
    if IsObject(ReportGui)
        try ReportGui["ReportText"].Text := FindLastReportLines()
}

SendReportWindowText() {
    global ReportGui
    if IsObject(ReportGui)
        SendTextToGameConsole(ReportGui["ReportSendText"].Text)
}

ToggleAdminChatWindow(enable) {
    global AdminChatGui, Theme, ChatsActiveTab, ChatsLastText
    if enable {
        AdminChatGui := Gui("+AlwaysOnTop +ToolWindow", "Чати")
        AdminChatGui.BackColor := Theme["panel"]
        AdminChatGui.SetFont("s8 c" Theme["text"], "Arial")
        AdminChatGui.OnEvent("Close", (*) => ToggleFeature("AdminChat"))
        AdminChatGui.AddText("x10 y8 w760 h20", "Чати: кілл-ліст, VIP, адмін-чат, репорти, фракційне, адмін-команди")
        tabs := ["Кілл-ліст", "Віп-чат", "Адмін-чат", "Репорти", "Фракційне", "Адмін команди"]
        x := 10
        for _, tab in tabs {
            btn := AdminChatGui.AddButton("x" x " y32 w130 h24", tab)
            t := tab
            btn.OnEvent("Click", ChatTabClick.Bind(t))
            x += 138
        }
        AdminChatGui.AddEdit("x10 y64 w840 h250 Multi ReadOnly -Wrap +HScroll +VScroll Background" Theme["field"] " c" Theme["text"] " vChatsText")
        ChatsLastText := ""
        AdminChatGui.Show("x20 y260 w860 h325 NoActivate")
        ForceTopMost(AdminChatGui)
        UpdateAdminChatWindow(true)
        SetTimer(UpdateAdminChatWindow, 1000)
    } else {
        SetTimer(UpdateAdminChatWindow, 0)
        try AdminChatGui.Destroy()
    }
}

SetChatsTab(tab) {
    global ChatsActiveTab, ChatsLastText
    ChatsActiveTab := tab
    ChatsLastText := ""
    UpdateAdminChatWindow(true)
}

ChatTabClick(tab, *) {
    PlayUiClickSound()
    SetChatsTab(tab)
}

UpdateAdminChatWindow(force := false) {
    global AdminChatGui, ChatsLastText, ChatsActiveTab
    if !IsObject(AdminChatGui)
        return
    ForceTopMost(AdminChatGui)
    newText := FindLastChatLines(ChatsActiveTab)
    if (!force && newText = ChatsLastText)
        return
    ChatsLastText := newText
    try AdminChatGui["ChatsText"].Text := newText
}

FindLastChatLines(tab, maxLines := 40) {
    ; Чати беруться напряму з console.log. При перемиканні вкладок не чистимо історію,
    ; а просто фільтруємо останні рядки під потрібний розділ.
    lines := []
    for _, line in GetConsoleLogLines(2500) {
        txt := ""
        if (tab = "Кілл-ліст") {
            txt := ParseKillListLine(line)
        } else if (tab = "Віп-чат") {
            txt := ParseVipChatLine(line)
        } else if (tab = "Адмін-чат") {
            txt := ParseAdminChatOnlyLine(line)
        } else if (tab = "Репорти") {
            info := ParseReportLine(line)
            if IsObject(info) {
                status := info.Has("unanswered") && info["unanswered"] ? "[БЕЗ ВІДПОВІДІ] " : ""
                txt := status info["nick"] "[" info["id"] "]: " info["text"]
            }
        } else if (tab = "Фракційне") {
            txt := ParseFactionChatOnlyLine(line)
        } else if (tab = "Адмін команди") {
            txt := ParseAdminCommandOnlyLine(line)
        }

        if (txt != "") {
            lines.Push(txt)
            if (lines.Length > maxLines)
                lines.RemoveAt(1)
        }
    }

    if (lines.Length = 0)
        return "Немає повідомлень для цього розділу. Перевір шлях до папки UGTA та console.log."

    out := ""
    for _, msg in lines
        out .= msg "`r`n"
    return RTrim(out, "`r`n")
}

CleanChatLineForParse(line) {
    clean := Trim(line)
    clean := RegExReplace(clean, "^\[\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\]\s*\[Output\]\s*:\s*", "")
    clean := RegExReplace(clean, "^\[\d{2}:\d{2}:\d{2}\]\s*", "")
    return Trim(clean)
}

ParseVipChatLine(line) {
    clean := CleanChatLineForParse(line)
    if (InStr(clean, "[VIP]") || InStr(clean, "[ВІП]"))
        return clean
    return ""
}

ParseKillListLine(line) {
    clean := CleanChatLineForParse(line)
    if RegExMatch(clean, "i)([A-Za-zА-Яа-яІіЇїЄєҐґ_]+)\[(\d{4,10})\]\s+Вбив\s+([A-Za-zА-Яа-яІіЇїЄєҐґ_]+)\[(\d{4,10})\]\s*\(([^\)]+)\)", &m)
        return m[1] "[" m[2] "] Вбив " m[3] "[" m[4] "] (" m[5] ")"
    return ""
}

ParseAdminChatOnlyLine(line) {
    clean := CleanChatLineForParse(line)
    ; [Головний Адміністратор] Святогор Подільський [6876591]: 1
    if RegExMatch(clean, "i)^\[([^\]]*(Адміністратор|Модератор|Помічник|ГА|ЗГА|Ігровий помічник)[^\]]*)\]\s+(.+?)\s*\[(\d{4,10})\]:\s*(.*)", &m)
        return "[" m[1] "] " m[3] " [" m[4] "]: " m[5]
    return ""
}
ParseAdminCommandOnlyLine(line) {
    clean := CleanChatLineForParse(line)
    ; [A] Андріан Мельник [6811581] -> /sp Ігор Процик [6899888]
    if RegExMatch(clean, "i)^\[[AaАа]\]\s*(.+?)\s*\[(\d{4,10})\]\s*->\s*(.*)", &m)
        return "[A] " m[1] " [" m[2] "] -> " m[3]
    return ""
}
ParseFactionChatOnlyLine(line) {
    roles := "Водій|Охоронник|Начальник охорони|Секретар|Народний депутат|Міністр ВС та Оборони|Міністр ОЗ та НС|Перший заступник Голови Верховної Ради України|Радник Президента України|Голова Верховної Ради|Прем'єр-міністр України|Президент України|Курсант|Капрал|Сержант|Ст\\. сержант|Мол\\. лейтенант|Лейтенант|Ст\\. лейтенант|Капітан|Майор|Підполковник|Полковник|Генерал|Рядовий|Старший Сержант|Молодший Лейтенант|Старший Лейтенант|Рекрут|Солдат|Старший солдат|Старшина|Прапорщик|Сержант ДКВС|Старший сержант ДКВС|Старшина ДКВС|Прапорщик ДКВС|Ст\\. Прапорщик ДКВС|Лейтенант ДКВС|Ст\\.Лейтенант ДКВС|Капітан ДКВС|Майор ДКВС|Підполковник ДКВС|Полковник ДКВС|Генерал ДКВС|Медбрат|Фармацефт|Фельдшер|Травматолог|Офтальмолог|Лікар-Терапевт|Лікар-Хірург|Сімейний лікар|Лікар Психіатр|Головний відділення|Зам\\. Головного лікаря|Головний лікар|Стажер|Копірайтер|Монтажер|Оператор|Журналіст|Ведучий|Режисер|Редактор|Головий редактор|Керуючий каналу|Заст\\. Директора ЗМІ|Директор ЗМІ|Слюсар|Провідник|Помічник машиніста|Машиніст|Диспетчер|Начальник УЗ"
    clean := CleanChatLineForParse(line)
    if RegExMatch(clean, "^\[(" roles ")\]\s+(.+?)\s*\[(\d{4,10})\]:\s*(.*)", &m)
        return "[" m[1] "] " m[2] " [" m[3] "]: " m[4]
    return ""
}

ForceTopMost(guiObj) {
    try {
        hwnd := guiObj.Hwnd
        WinSetAlwaysOnTop(1, "ahk_id " hwnd)
        DllCall("SetWindowPos", "ptr", hwnd, "ptr", -1, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x0001|0x0002|0x0010|0x0040)
    }
}

SendTextToGameConsole(text) {
    if (Trim(text) = "")
        return
    hWnd := WinExist("UKRAINE GTA")
    if !hWnd {
        MsgBox("Вікно UKRAINE GTA не знайдено.", "ATools NextGen | 02", "Icon!")
        return
    }
    cmd := text
    if (SubStr(cmd, 1, 1) = "/")
        cmd := SubStr(cmd, 2)
    else
        cmd := "say " cmd

    try BlockInput(true)
    try {
        ControlSend("{f8}", , "ahk_id " hWnd)
        Sleep(220)
        ControlSend("{Text}" cmd, , "ahk_id " hWnd)
        ControlSend("{Enter}", , "ahk_id " hWnd)
        Sleep(120)
        ControlSend("{f8}", , "ahk_id " hWnd)
    } finally {
        try BlockInput(false)
    }
}

ToggleOverlayClickThrough() {
    global OverlayClickThrough, ReportGui, AdminChatGui
    OverlayClickThrough := !OverlayClickThrough
    if IsObject(ReportGui)
        GameOverlay.SetClickThrough(ReportGui, OverlayClickThrough)
    if IsObject(AdminChatGui)
        GameOverlay.SetClickThrough(AdminChatGui, OverlayClickThrough)
    ToolTip(OverlayClickThrough ? "Overlay: кліки проходять у гру" : "Overlay: можна клікати/виділяти")
    SetTimer(() => ToolTip(), -1200)
}

ToggleBindHints(enable) {
    global BindHintsGui, Theme, Reports, ReportKeys, ReportKeyCtrls, BindHintsPosX, BindHintsPosY
    if enable {
        BindHintsGui := Gui("-Caption +AlwaysOnTop +ToolWindow", "Підказки біндів")
        BindHintsGui.BackColor := Theme["panel"]
        BindHintsGui.SetFont("s7 c" Theme["text"], "Arial")
        bar := BindHintsGui.AddText("x0 y0 w460 h20 Background" Theme["line"], "")
        bar.OnEvent("Click", BindHintsStartDrag)
        title := BindHintsGui.AddText("x8 y3 w400 h15 BackgroundTrans", "ATools | Підказки біндів")
        title.OnEvent("Click", BindHintsStartDrag)
        y := 28
        Loop 10 {
            i := A_Index
            shownKey := ""
            if (ReportKeyCtrls.Length >= i) {
                try shownKey := ReportKeyCtrls[i].Text
            }
            if (shownKey = "")
                shownKey := HotkeyToText(ReportKeys[i])
            BindHintsGui.AddText("x8 y" y " w70 h15", shownKey != "" ? shownKey : "—")
            msg := Reports[i]
            if (StrLen(msg) > 56)
                msg := SubStr(msg, 1, 56) "..."
            BindHintsGui.AddText("x82 y" y " w360 h15", msg)
            y += 18
        }
        BindHintsGui.Show("x" BindHintsPosX " y" BindHintsPosY " w460 h215 NoActivate")
        ForceTopMost(BindHintsGui)
    } else {
        try BindHintsGui.Destroy()
    }
}

BindHintsStartDrag(*) {
    global BindHintsGui
    if !IsObject(BindHintsGui)
        return
    PostMessage(0xA1, 2,,, "ahk_id " BindHintsGui.Hwnd)
    SetTimer(BindHintsSavePosition, -700)
}

BindHintsSavePosition() {
    global BindHintsGui, BindHintsPosX, BindHintsPosY, iniPath
    if !IsObject(BindHintsGui)
        return
    try {
        BindHintsGui.GetPos(&x, &y)
        BindHintsPosX := x, BindHintsPosY := y
        IniWrite(x, iniPath, "BindHints", "X")
        IniWrite(y, iniPath, "BindHints", "Y")
    }
}

HotkeyToText(key) {
    key := Trim(key)
    if (key = "")
        return ""

    out := ""
    if InStr(key, "^")
        out .= "Ctrl+"
    if InStr(key, "!")
        out .= "Alt+"
    if InStr(key, "+")
        out .= "Shift+"
    if InStr(key, "#")
        out .= "Win+"

    key := StrReplace(key, "^", "")
    key := StrReplace(key, "!", "")
    key := StrReplace(key, "+", "")
    key := StrReplace(key, "#", "")
    key := StrReplace(key, "sc013", "R")

    return out . StrUpper(key)
}

ToggleAdminCommandsHelp() {
    global AdminHelpGui, Theme
    if IsObject(AdminHelpGui) {
        try AdminHelpGui.Destroy()
        AdminHelpGui := ""
        return
    }
    AdminHelpGui := Gui("+AlwaysOnTop +ToolWindow", "Адм. команди")
    AdminHelpGui.BackColor := Theme["panel"]
    AdminHelpGui.SetFont("s8 c" Theme["text"], "Arial")
    commandsText := ""
    commandsText .= "ГРАВЕЦЬ`n"
    commandsText .= "────────────────────────────────────────`n"
    commandsText .= "/report - написати звернення для адміністратора`n"
    commandsText .= "/vuninvite - звільнитись з фракції з PREMIUM`n"
    commandsText .= "/mytime - показує відіграний час від моменту реєстрації`n"
    commandsText .= "/reconnect - перепід'єднання до серверу`n"
    commandsText .= "/wartime - перелік запланованих битв за бізнеси (неоф. орг. / адмін)`n"
    commandsText .= "/capture - запуск битви за територію (неоф. орг., старший ранг+)`n"
    commandsText .= "/show_tag - прибирає нікнейми гравців`n"
    commandsText .= "/nohud - прибирає худ`n"
    commandsText .= "/shownetstat - показує статистику`n"
    commandsText .= "/serial - показує серійний номер`n"
    commandsText .= "/fpslimit - встановлює FPS ліміт`n"
    commandsText .= "/puninvite <UID> - звільнення гравця з будь-якої фракції (президент)`n"
    commandsText .= "/purs <UID> - переслідування гравця (НПУ / СБУ)`n"
    commandsText .= "/follow <UID> - приєднатись до переслідування гравця (НПУ / СБУ)`n"
    commandsText .= "/stoppurs - закінчити переслідування гравця (НПУ / СБУ)`n"
    commandsText .= "/giverank <UID> <RANGID> - видати ранг (заступник / лідер)`n"
    commandsText .= "/fskin <UID> <SKINID> - встановити скін (з 10 рангу фракції)`n"
    commandsText .= "/invite <UID> - запросити у фракцію (заступник / лідер)`n"
    commandsText .= "/uninvite <UID> <REASON> - звільнити з фракції (заступник / лідер)`n"
    commandsText .= "Примітка: причину вказувати через нижнє підкреслення`n"
    commandsText .= "Приклад: /uninvite 6489415 За_власним_бажанням`n"
    commandsText .= "/realease <UID> - дістати гравця з КПЗ за 100 000 грн (мерія)`n"
    commandsText .= "/givemilitary <UID> - поновити військовий квиток (лідер/зам НПУ/СБУ/ЗСУ)`n"
    commandsText .= "/s <текст> - кричати`n"
    commandsText .= "/w <текст> - шепотіти`n"
    commandsText .= "`n"
    commandsText .= "[1] ІГРОВИЙ ПОМІЧНИК`n"
    commandsText .= "────────────────────────────────────────`n"
    commandsText .= "/pm <UID> - надати відповідь на репорт`n"
    commandsText .= "/a - адмін чат`n"
    commandsText .= "/inv - стати невидимим`n"
    commandsText .= "/admins - список адміністрації онлайн`n"
    commandsText .= "/pwarp <UID> - телепорт до гравця`n"
    commandsText .= "/resp <UID> - телепорт гравця на респавн`n"
    commandsText .= "/astats - статистика за день`n"
    commandsText .= "/adminmode - інформація для адміністрації`n"
    commandsText .= "/flip <VID> - перевернути авто`n"
    commandsText .= "/vget - телепортувати авто до себе`n"
    commandsText .= "/sp <UID> - слідкувати за гравцем`n"
    commandsText .= "/get <UID> - телепортувати гравця до себе`n"
    commandsText .= "/unget <UID> - телепортувати гравця на попереднє місце`n"
    commandsText .= "/killchat - вкл/викл список вбивств`n"
    commandsText .= "/atracer - увімкнути/вимкнути трасування куль`n"
    commandsText .= "/wartime - переглянути список битв за бізнес`n"
    commandsText .= "/ahouse - переміщує в інтер'єр для адміністрації`n"
    commandsText .= "`n"
    commandsText .= "[2] МОДЕРАТОР`n"
    commandsText .= "────────────────────────────────────────`n"
    commandsText .= "/rpadmin - вкл/викл надпис над головою`n"
    commandsText .= "/commands - список доступних команд`n"
    commandsText .= "/pmute <UID> <причина> - дати мут гравцю`n"
    commandsText .= "/punmute <UID> <причина> - зняти мут гравцю`n"
    commandsText .= "/fixveh <VID> - полагодити машину`n"
    commandsText .= "/jail <UID> <час> <причина> - посадити гравця у деморган`n"
    commandsText .= "/unjail <UID> - витягти гравця з деморгану`n"
    commandsText .= "/sethp <UID> <число> - встановити HP гравцю`n"
    commandsText .= "/vgoto <VID> - телепортуватися до автомобіля`n"
    commandsText .= "/rpjail <UID> - витягнути людину з ІТТ`n"
    commandsText .= "/gm <UID> - встановити безсмертя`n"
    commandsText .= "`n"
    commandsText .= "[3] СТАРШИЙ МОДЕРАТОР`n"
    commandsText .= "────────────────────────────────────────`n"
    commandsText .= "/reviving <UID> - відродити гравця`n"
    commandsText .= "/pfreeze <UID> - заморозити гравця`n"
    commandsText .= "/punfreeze <UID> - розморозити гравця`n"
    commandsText .= "/pban <UID> <час> <причина> - заблокувати гравця`n"
    commandsText .= "/punban <UID> - зняти блокування гравцю`n"
    commandsText .= "/vehspawn <VID> - задеспавнити автомобіль (не тимчасовий)`n"
    commandsText .= "/warn <UID> <причина> - видати варн гравцю`n"
    commandsText .= "/unwarn <UID> <причина> - зняти варн гравцю`n"
    commandsText .= "/pkick <UID> <причина> - від'єднати гравця`n"
    commandsText .= "`n"
    commandsText .= "[4] АДМІНІСТРАТОР`n"
    commandsText .= "────────────────────────────────────────`n"
    commandsText .= "/global <текст> - глобальне повідомлення у чат`n"
    commandsText .= "/alarm <текст> - надіслати повідомлення у телефон всім гравцям`n"
    commandsText .= "/tempnickname <UID> <ім'я> <прізвище> - тимчасове ім'я гравцю`n"
    commandsText .= "/setnickname <UID> <ім'я> <прізвище> - змінити нік гравцю`n"
    commandsText .= "/weapongive <UID> <ID зброї> <патрони> - видати зброю`n"
    commandsText .= "/weapontake <UID> <ID зброї> <патрони> - відібрати зброю`n"
    commandsText .= "/takeallweapons <UID> - відібрати всю зброю`n"
    commandsText .= "/vdelete <VID> - видалити тимчасову машину`n"
    commandsText .= "/ahistory <id> - подивитись історію покарань гравця`n"
    commandsText .= "/cc - очистити ігровий чат`n"
    commandsText .= "/offwarn <UID> <причина> - видати варн офлайн`n"
    commandsText .= "/offunwarn <UID> <причина> - зняти варн офлайн`n"
    commandsText .= "/offmute <UID> <причина> - видати мут в офлайні`n"
    commandsText .= "/offunmute <UID> - зняти мут в офлайні`n"
    commandsText .= "/jailoffline <UID> <час> <причина> - посадити гравця у деморган офлайн`n"
    commandsText .= "/offunjail <UID> - випустити з деморгану в офлайні`n"
    commandsText .= "/pbanoffline <UID> <час> <причина> - забанити гравця офлайн`n"
    commandsText .= "`n"
    commandsText .= "[5] СТАРШИЙ АДМІНІСТРАТОР`n"
    commandsText .= "────────────────────────────────────────`n"
    commandsText .= "/setfaction <UID> <фракція> - встановити гравця у фракцію + дати військовик`n"
    commandsText .= "/setfactionlevel <UID> <ранг> - встановити ранг у фракції`n"
    commandsText .= "/offsetfaction <UID> <фракція> - встановити гравця у фракцію офлайн`n"
    commandsText .= "/offsetfactionlevel <UID> <ранг> - встановити ранг у фракції офлайн`n"
    commandsText .= "/setrating <UID> <кількість> <причина> - змінити соціальний рейтинг гравця`n"
    commandsText .= "/create_war <id клану> <id клану> <id бізнесу> - створити битву за бізнес`n"
    commandsText .= "/vehpanel - створити тимчасовий автомобіль`n"
    helpOpt := "w820 h620 ReadOnly +Wrap Background" Theme["field"] " c" Theme["text"]
    AdminHelpGui.AddEdit(helpOpt, commandsText)
    AdminHelpGui.Show("x820 y20 NoActivate")
}

ChooseCustomBackground() {
    global iniPath, CustomBgPath
    try selected := FileSelect(1, A_ScriptDir, "Вибери фон для ATools", "Images (*.png; *.jpg; *.jpeg; *.bmp)")
    catch
        selected := ""
    if (selected = "")
        return
    try DirCreate(A_ScriptDir "\assets\bg")
    ext := RegExMatch(selected, "i)\.jpe?g$") ? ".jpg" : RegExMatch(selected, "i)\.bmp$") ? ".bmp" : ".png"
    dest := A_ScriptDir "\assets\bg\custom_bg" ext
    try FileCopy(selected, dest, true)
    CustomBgPath := dest
    IniWrite(CustomBgPath, iniPath, "Theme", "Background")
    ShowAtoolsNotice("Фон збережено. Перезапусти ATools, щоб застосувати.")
}

BuildTray() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Перемкнути overlay Ctrl+F9", (*) => ToggleOverlayClickThrough())
    A_TrayMenu.Add("Звіт бонусів Ctrl+F10", (*) => AdminActivityTracker.GenerateBonusReport())
    A_TrayMenu.Add()
    A_TrayMenu.Add("Перезапуск", (*) => Reload())
    A_TrayMenu.Add("Вихід", (*) => ExitApp())
}

; =========================================================
; Radial / Ring Menu — GDI+ HUD
; =========================================================

FirstToken(textValue, fallback := "CMD") {
    textValue := Trim(String(textValue))
    textValue := RegExReplace(textValue, "^/+")
    if (textValue = "")
        return fallback
    parts := StrSplit(textValue, " ")
    try token := parts[1]
    catch
        token := textValue
    token := Trim(token)
    if (token = "")
        token := fallback
    return token
}

BuildRadialItems() {
    global RadialCommands, RadialCtrls
    InitRadialCommands()
    defaults := ["resp", "sp", "pm", "jail", "mute", "kick", "ahouse", "", "", ""]
    items := []
    Loop 10 {
        i := A_Index
        cmd := ""
        if IsObject(RadialCtrls) && RadialCtrls.Length >= i {
            try cmd := Trim(RadialCtrls[i].Text)
        }
        if (cmd = "")
            cmd := Trim(SafeArrayGet(RadialCommands, i, SafeArrayGet(defaults, i, "")))
        if (cmd = "")
            cmd := SafeArrayGet(defaults, i, "")
        if (i = 7)
            cmd := "ahouse"
        clean := RegExReplace(String(cmd), "^/+")
        label := StrUpper(FirstToken(clean, "CMD"))
        if (StrLen(label) > 8)
            label := SubStr(label, 1, 8)
        items.Push(Map("label", label, "cmd", clean, "enter", i = 7))
    }
    return items
}
ShowRadialMenu() {
    global RadialGui, RadialSelected, RadialCenterX, RadialCenterY, RadialRadius, RadialItems, RadialHwnd, RadialActive, Theme, EnableRadialMenu

    if (!EnableRadialMenu) {
        RadialActive := false
        RadialSelected := ""
        return
    }

    if IsObject(RadialGui)
        return

    MouseGetPos(&mx, &my)
    RadialCenterX := mx
    RadialCenterY := my
    RadialSelected := 1
    RadialActive := true
    EnableRadialWheelHotkeys()
    RadialRadius := 170
    RadialItems := BuildRadialItems()

    RadialGui := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x80000 +E0x20", "Atools Radial")
    RadialGui.BackColor := "010101"
    RadialHwnd := RadialGui.Hwnd
    RadialGui.Show("x" (mx - RadialRadius) " y" (my - RadialRadius) " w" (RadialRadius * 2) " h" (RadialRadius * 2) " NoActivate")
    WinSetExStyle("+0x20", "ahk_id " RadialHwnd)
    RadialRender()
}

UpdateRadialHover() {
    ; MTA блокує мишу, тому radial керується цифрами/колесом/стрілками.
    return
}

RadialSelect(idx) {
    global RadialSelected, RadialItems
    if (idx < 1 || idx > RadialItems.Length)
        return
    RadialSelected := idx
    RadialRender()
}

RadialWheel(direction) {
    global RadialActive, LastRadialWheel, RadialWheelDelay

    if (!RadialActive)
        return

    ; Антиспам для колесика: тимчасово вимикає wheel-хоткеї після спрацювання.
    try DisableRadialWheelHotkeys()
    SetTimer(EnableRadialWheelHotkeys, -RadialWheelDelay)

    now := A_TickCount
    if (now - LastRadialWheel < RadialWheelDelay)
        return

    LastRadialWheel := now
    RadialCycle(direction)
}

EnableRadialWheelHotkeys() {
    global RadialActive
    if (!RadialActive)
        return
    try {
        HotIf('RadialActive')
        Hotkey('WheelUp', 'On')
        Hotkey('WheelDown', 'On')
        HotIf()
    }
}

DisableRadialWheelHotkeys() {
    try {
        HotIf('RadialActive')
        Hotkey('WheelUp', 'Off')
        Hotkey('WheelDown', 'Off')
        HotIf()
    }
}
RadialCycle(direction) {
    global RadialSelected, RadialItems
    if (RadialSelected = "" || RadialSelected < 1)
        RadialSelected := 1
    else
        RadialSelected += direction

    if (RadialSelected < 1)
        RadialSelected := RadialItems.Length
    if (RadialSelected > RadialItems.Length)
        RadialSelected := 1

    RadialSelect(RadialSelected)
}

RadialChoose(cmd) {
    ; залишено для сумісності
}

ExecuteRadialMenu() {
    global RadialGui, RadialSelected, RadialItems, RadialPic, RadialActive, RadialSelectedLabel, RadialOptionCtrls, EnableRadialMenu
    if (!EnableRadialMenu) {
        RadialActive := false
        return
    }
    if !IsObject(RadialGui)
        return
    RadialActive := false
    DisableRadialWheelHotkeys()

    idx := RadialSelected
    if IsObject(RadialGui) {
        try RadialGui.Destroy()
        RadialGui := ""
        RadialPic := ""
        RadialSelectedLabel := ""
        RadialOptionCtrls := []
    }

    if (idx is Integer && idx >= 1 && idx <= RadialItems.Length) {
        item := RadialItems[idx]
        autoEnter := item.Has("enter") ? item["enter"] : false
        SendCommandTextEx(item["cmd"], autoEnter)
    }
}

HexToARGB(hex, alpha := 255) {
    hex := NormalizeHexColor(hex)
    return (alpha << 24) | Integer("0x" hex)
}

RadialRender() {
    global RadialGui, RadialHwnd, RadialRadius, RadialItems, RadialSelected, Theme
    if !IsObject(RadialGui)
        return

    size := RadialRadius * 2
    pToken := GdiHud.Startup()
    if (!pToken) {
        ; Fallback без падіння, якщо GDI+ не стартував.
        return
    }

    hbm := GdiHud.CreateBitmap(size, size, &hdc, &obm)
    g := GdiHud.GraphicsFromHdc(hdc)
    GdiHud.Smoothing(g, 4)
    GdiHud.Clear(g, 0x00000000)

    cx := RadialRadius
    cy := RadialRadius
    outer := RadialRadius - 10
    inner := 58

    accent := HexToARGB(Theme["accent"], 235)
    accentSoft := HexToARGB(Theme["accent2"], 165)
    panelSoft := HexToARGB(Theme["panel2"], 210)
    lineColor := HexToARGB(Theme["accent"], 125)

    ; Тінь / база під стиль тулсу
    GdiHud.FillEllipse(g, 0xAA000000, 8, 8, size - 16, size - 16)
    GdiHud.FillEllipse(g, 0xF0080808, 16, 16, size - 32, size - 32)
    GdiHud.DrawEllipse(g, lineColor, 16, 16, size - 32, size - 32, 3)
    GdiHud.DrawEllipse(g, accentSoft, 32, 32, size - 64, size - 64, 1)

    count := RadialItems.Length
    sectorAngle := 360 / count

    Loop count {
        i := A_Index
        start := -90 + (i - 1) * sectorAngle - (sectorAngle / 2)
        sweep := sectorAngle - 3
        color := (i = RadialSelected) ? accent : panelSoft
        outline := (i = RadialSelected) ? 0xFFFFFFFF : lineColor
        GdiHud.FillPie(g, color, cx - outer, cy - outer, outer * 2, outer * 2, start, sweep)
        GdiHud.DrawPie(g, outline, cx - outer, cy - outer, outer * 2, outer * 2, start, sweep, 1)
    }

    ; Внутрішній круг перекриває середину секторів і дає чистий donut.
    GdiHud.FillEllipse(g, 0xF0050505, cx - inner, cy - inner, inner * 2, inner * 2)
    GdiHud.DrawEllipse(g, accent, cx - inner, cy - inner, inner * 2, inner * 2, 2)

    ; Підписи пунктів
    Loop count {
        i := A_Index
        angle := (-90 + (i - 1) * sectorAngle) * 3.1415926535 / 180
        tx := cx + Cos(angle) * 112
        ty := cy + Sin(angle) * 112
        keyName := i = 10 ? "0" : String(i)
        label := keyName "  " RadialItems[i]["label"]
        fontColor := (i = RadialSelected) ? 0xFFFFFFFF : 0xFFD4D4D4
        GdiHud.Text(g, label, tx - 52, ty - 12, 104, 24, 9, fontColor, 1, 1, true)
    }

    ; Центр
    selected := RadialItems[RadialSelected]
    keyName := RadialSelected = 10 ? "0" : String(RadialSelected)
    GdiHud.FillEllipse(g, 0xFF050505, cx - 43, cy - 43, 86, 86)
    GdiHud.DrawEllipse(g, accent, cx - 43, cy - 43, 86, 86, 2)
    GdiHud.Text(g, keyName, cx - 35, cy - 35, 70, 26, 17, 0xFFFFFFFF, 1, 1, true)
    GdiHud.Text(g, selected["label"], cx - 54, cy - 8, 108, 24, 11, 0xFFFFFFFF, 1, 1, true)
    GdiHud.Text(g, "/" RegExReplace(selected["cmd"], "^/+"), cx - 70, cy + 18, 140, 22, 8, 0xFFB8B8B8, 1, 1, false)

    ; Нижня підказка
    GdiHud.Text(g, "1-0  •  колесо  •  стрілки  •  CapsLock", cx - 130, size - 45, 260, 22, 8, 0xFFB8B8B8, 1, 1, false)

    GdiHud.UpdateLayeredWindow(RadialHwnd, hdc, RadialCenterX - RadialRadius, RadialCenterY - RadialRadius, size, size)
    GdiHud.DeleteGraphics(g)
    GdiHud.CleanupBitmap(hdc, hbm, obm)
}

; =========================================================
; =========================================================
; Main ATools GDI+ shell overlay
; Малює декоративну HUD-рамку поверх основного AHK GUI.
; Основні контроли лишаються стандартними, тому вікно швидке і надійне.
; =========================================================

class MainGdiShell {
    static GuiObj := ""
    static Hwnd := 0
    static MainHwnd := 0

    static Attach(mainGui, w, h) {
        this.MainHwnd := mainGui.Hwnd
        if IsObject(this.GuiObj) {
            try this.GuiObj.Destroy()
        }

        this.GuiObj := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20 +E0x80000", "Atools GDI Shell")
        this.GuiObj.BackColor := "010101"
        this.Hwnd := this.GuiObj.Hwnd

        WinGetPos(&x, &y, &mw, &mh, "ahk_id " this.MainHwnd)
        this.GuiObj.Show("x" x " y" y " w" w " h" h " NoActivate")
        this.Render(x, y, w, h)
        SetTimer(() => MainGdiShell.FollowMain(), 120)
    }

    static FollowMain() {
        if !this.MainHwnd || !WinExist("ahk_id " this.MainHwnd) {
            SetTimer(() => MainGdiShell.FollowMain(), 0)
            return
        }

        try {
            WinGetPos(&x, &y, &w, &h, "ahk_id " this.MainHwnd)
            if (w <= 0 || h <= 0)
                return
            WinMove(x, y, w, h, "ahk_id " this.Hwnd)
            this.Render(x, y, w, h)
        }
    }

    static Render(x, y, w, h) {
        if !this.Hwnd
            return

        GdiHud.Startup()
        hbm := GdiHud.CreateBitmap(w, h, &hdc, &obm)
        g := GdiHud.GraphicsFromHdc(hdc)
        GdiHud.Smoothing(g)
        GdiHud.Clear(g, 0x00000000)

        accent := 0x88FFFFFF
        softRed := 0x44333333
        line := 0x663A3A3A
        pale := 0x44E5E5E5
        darkGlass := 0x18000000

        GdiHud.FillRect(g, darkGlass, 0, 0, w, h)
        GdiHud.FillRect(g, 0x26000000, 0, 0, 235, h)
        GdiHud.DrawLine(g, softRed, 235, 0, 235, h, 2)
        GdiHud.DrawLine(g, line, 236, 0, 236, h, 1)

        GdiHud.DrawLine(g, accent, 0, 0, w, 0, 2)
        GdiHud.DrawLine(g, softRed, 0, 70, w, 70, 1)
        GdiHud.DrawLine(g, softRed, 0, h - 1, w, h - 1, 2)

        len := 44
        off := 10
        GdiHud.DrawLine(g, pale, off, off, off + len, off, 2)
        GdiHud.DrawLine(g, pale, off, off, off, off + len, 2)
        GdiHud.DrawLine(g, pale, w - off - len, off, w - off, off, 2)
        GdiHud.DrawLine(g, pale, w - off, off, w - off, off + len, 2)
        GdiHud.DrawLine(g, pale, off, h - off, off + len, h - off, 2)
        GdiHud.DrawLine(g, pale, off, h - off - len, off, h - off, 2)
        GdiHud.DrawLine(g, pale, w - off - len, h - off, w - off, h - off, 2)
        GdiHud.DrawLine(g, pale, w - off, h - off - len, w - off, h - off, 2)

        yy := 92
        while (yy < h - 30) {
            GdiHud.DrawLine(g, 0x0FE5E5E5, 250, yy, w - 25, yy, 1)
            yy += 38
        }

        GdiHud.UpdateLayeredWindow(this.Hwnd, hdc, x, y, w, h)
        GdiHud.DeleteGraphics(g)
        GdiHud.CleanupBitmap(hdc, hbm, obm)
    }
}

; Minimal GDI+ HUD renderer for AHK v2
; =========================================================

class GdiHud {
    static Token := 0

    static Startup() {
        if (this.Token)
            return this.Token
        si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
        NumPut("UInt", 1, si, 0)
        DllCall("gdiplus\GdiplusStartup", "Ptr*", &token := 0, "Ptr", si, "Ptr", 0)
        this.Token := token
        return token
    }

    static CreateBitmap(w, h, &hdc, &obm) {
        hdc := DllCall("gdi32\CreateCompatibleDC", "Ptr", 0, "Ptr")
        bi := Buffer(40, 0)
        NumPut("UInt", 40, bi, 0)
        NumPut("Int", w, bi, 4)
        NumPut("Int", -h, bi, 8)
        NumPut("UShort", 1, bi, 12)
        NumPut("UShort", 32, bi, 14)
        NumPut("UInt", 0, bi, 16)
        hbm := DllCall("gdi32\CreateDIBSection", "Ptr", 0, "Ptr", bi, "UInt", 0, "Ptr*", &ppvBits := 0, "Ptr", 0, "UInt", 0, "Ptr")
        obm := DllCall("gdi32\SelectObject", "Ptr", hdc, "Ptr", hbm, "Ptr")
        return hbm
    }

    static GraphicsFromHdc(hdc) {
        DllCall("gdiplus\GdipCreateFromHDC", "Ptr", hdc, "Ptr*", &g := 0)
        return g
    }

    static Smoothing(g, mode := 4) {
        DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", g, "Int", mode)
        DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", g, "Int", 4)
    }

    static Clear(g, argb) {
        DllCall("gdiplus\GdipGraphicsClear", "Ptr", g, "UInt", argb)
    }

    static Brush(argb) {
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", argb, "Ptr*", &brush := 0)
        return brush
    }

    static Pen(argb, width := 1) {
        DllCall("gdiplus\GdipCreatePen1", "UInt", argb, "Float", width, "Int", 2, "Ptr*", &pen := 0)
        return pen
    }

    static FillRect(g, argb, x, y, w, h) {
        b := this.Brush(argb)
        DllCall("gdiplus\GdipFillRectangle", "Ptr", g, "Ptr", b, "Float", x, "Float", y, "Float", w, "Float", h)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", b)
    }

    static DrawLine(g, argb, x1, y1, x2, y2, lineW := 1) {
        p := this.Pen(argb, lineW)
        DllCall("gdiplus\GdipDrawLine", "Ptr", g, "Ptr", p, "Float", x1, "Float", y1, "Float", x2, "Float", y2)
        DllCall("gdiplus\GdipDeletePen", "Ptr", p)
    }

    static FillEllipse(g, argb, x, y, w, h) {
        b := this.Brush(argb)
        DllCall("gdiplus\GdipFillEllipse", "Ptr", g, "Ptr", b, "Float", x, "Float", y, "Float", w, "Float", h)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", b)
    }

    static DrawEllipse(g, argb, x, y, w, h, lineW := 1) {
        p := this.Pen(argb, lineW)
        DllCall("gdiplus\GdipDrawEllipse", "Ptr", g, "Ptr", p, "Float", x, "Float", y, "Float", w, "Float", h)
        DllCall("gdiplus\GdipDeletePen", "Ptr", p)
    }

    static FillPie(g, argb, x, y, w, h, start, sweep) {
        b := this.Brush(argb)
        DllCall("gdiplus\GdipFillPie", "Ptr", g, "Ptr", b, "Float", x, "Float", y, "Float", w, "Float", h, "Float", start, "Float", sweep)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", b)
    }

    static DrawPie(g, argb, x, y, w, h, start, sweep, lineW := 1) {
        p := this.Pen(argb, lineW)
        DllCall("gdiplus\GdipDrawPie", "Ptr", g, "Ptr", p, "Float", x, "Float", y, "Float", w, "Float", h, "Float", start, "Float", sweep)
        DllCall("gdiplus\GdipDeletePen", "Ptr", p)
    }

    static Text(g, text, x, y, w, h, size, argb, align := 1, valign := 1, bold := false) {
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Arial", "Ptr", 0, "Ptr*", &family := 0)
        style := bold ? 1 : 0
        DllCall("gdiplus\GdipCreateFont", "Ptr", family, "Float", size, "Int", style, "Int", 3, "Ptr*", &font := 0)
        DllCall("gdiplus\GdipCreateStringFormat", "Int", 0, "Int", 0, "Ptr*", &format := 0)
        DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", format, "Int", align)
        DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", format, "Int", valign)
        rect := Buffer(16, 0)
        NumPut("Float", x, rect, 0)
        NumPut("Float", y, rect, 4)
        NumPut("Float", w, rect, 8)
        NumPut("Float", h, rect, 12)
        b := this.Brush(argb)
        DllCall("gdiplus\GdipDrawString", "Ptr", g, "WStr", text, "Int", -1, "Ptr", font, "Ptr", rect, "Ptr", format, "Ptr", b)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", b)
        DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", format)
        DllCall("gdiplus\GdipDeleteFont", "Ptr", font)
        DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", family)
    }

    static UpdateLayeredWindow(hwnd, hdc, x, y, w, h) {
        hdcScreen := DllCall("user32\GetDC", "Ptr", 0, "Ptr")
        ptDst := Buffer(8, 0), sz := Buffer(8, 0), ptSrc := Buffer(8, 0), blend := Buffer(4, 0)
        NumPut("Int", x, ptDst, 0), NumPut("Int", y, ptDst, 4)
        NumPut("Int", w, sz, 0), NumPut("Int", h, sz, 4)
        NumPut("Int", 0, ptSrc, 0), NumPut("Int", 0, ptSrc, 4)
        NumPut("UChar", 0, blend, 0)
        NumPut("UChar", 0, blend, 1)
        NumPut("UChar", 255, blend, 2)
        NumPut("UChar", 1, blend, 3)
        DllCall("user32\UpdateLayeredWindow", "Ptr", hwnd, "Ptr", hdcScreen, "Ptr", ptDst, "Ptr", sz, "Ptr", hdc, "Ptr", ptSrc, "UInt", 0, "Ptr", blend, "UInt", 2)
        DllCall("user32\ReleaseDC", "Ptr", 0, "Ptr", hdcScreen)
    }

    static DeleteGraphics(g) {
        DllCall("gdiplus\GdipDeleteGraphics", "Ptr", g)
    }

    static CleanupBitmap(hdc, hbm, obm) {
        DllCall("gdi32\SelectObject", "Ptr", hdc, "Ptr", obm)
        DllCall("gdi32\DeleteObject", "Ptr", hbm)
        DllCall("gdi32\DeleteDC", "Ptr", hdc)
    }
}

; =========================================================
; Class architecture foundation
; =========================================================

class AppConfig {
    static IniPath := A_ScriptDir "\config.ini"
    static RoadPath := A_ScriptDir "\road.ini"
    static JsonPath := A_ScriptDir "\config.json"

    static Read(section, key, default := "") {
        try return IniRead(this.IniPath, section, key, default)
        catch
            return default
    }

    static Write(section, key, value) {
        IniWrite(value, this.IniPath, section, key)
    }

    static GetGamePath() {
        if !FileExist(this.RoadPath)
            return ""
        return Trim(FileRead(this.RoadPath, "UTF-8"), " `t`r`n")
    }

    static SetGamePath(path) {
        try FileDelete(this.RoadPath)
        FileAppend(path "`n", this.RoadPath, "UTF-8")
    }

    static ExportJson(name, rank, server, reports, reportKeys, commands, commandKeys) {
        q := Chr(34)
        json := "{`n"
        json .= "  " q "profile" q ": {" q "name" q ": " q this.Escape(name) q ", " q "rank" q ": " q this.Escape(rank) q ", " q "server" q ": " q this.Escape(server) q "},`n"
        json .= "  " q "reports" q ": ["

        Loop reports.Length {
            i := A_Index
            if (i > 1)
                json .= ","
            json .= "{" q "text" q ":" q this.Escape(reports[i]) q "," q "key" q ":" q this.Escape(reportKeys[i]) q "}"
        }

        json .= "],`n  " q "commands" q ": ["

        Loop commands.Length {
            i := A_Index
            if (i > 1)
                json .= ","
            json .= "{" q "text" q ":" q this.Escape(commands[i]) q "," q "key" q ":" q this.Escape(commandKeys[i]) q "}"
        }

        json .= "]`n}"

        try FileDelete(this.JsonPath)
        FileAppend(json, this.JsonPath, "UTF-8")
    }

    static Escape(value) {
        value := StrReplace(value, "\", "\")
        value := StrReplace(value, Chr(34), "\" . Chr(34))
        value := StrReplace(value, "`r", "")
        value := StrReplace(value, "`n", "\n")
        return value
    }
}

class LogParser {
    static GetConsolePath() {
        path := AppConfig.GetGamePath()
        if (path = "")
            return ""
        return path "\game\mta\logs\console.log"
    }

    static ReadConsole() {
        path := this.GetConsolePath()
        if (path = "" || !FileExist(path))
            return ""
        try return FileRead(path, "UTF-8")
        catch
            return ""
    }

    static LastReportId() {
        content := this.ReadConsole()
        last := ""
        for line in StrSplit(content, "`n", "`r") {
            if RegExMatch(line, "від гравця.*?\s*\[(\d+)\]", &m)
                last := m[1]
        }
        return last
    }

    static TailByPattern(pattern, maxLines := 6) {
        content := this.ReadConsole()
        matches := []
        for line in StrSplit(content, "`n", "`r") {
            if RegExMatch(line, pattern) {
                matches.Push(line)
                if (matches.Length > maxLines)
                    matches.RemoveAt(1)
            }
        }
        out := ""
        for _, line in matches
            out .= line "`n"
        return out
    }
}

class GameOverlay {
    static TransparentColor := "010101"

    static Create(title, Theme) {
        guiObj := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x80000 +E0x20", title)
        guiObj.BackColor := this.TransparentColor
        return guiObj
    }

    static Apply(guiObj) {
        global OverlayClickThrough
        hwnd := guiObj.Hwnd
        WinSetTransColor(this.TransparentColor " 235", "ahk_id " hwnd)
        this.SetClickThrough(guiObj, OverlayClickThrough)
    }

    static SetClickThrough(guiObj, enabled := true) {
        hwnd := guiObj.Hwnd
        if enabled
            WinSetExStyle("+0x20", "ahk_id " hwnd)
        else
            WinSetExStyle("-0x20", "ahk_id " hwnd)
    }
}

class UIManager {
    static SetОфіційнийFont(guiObj, Theme, size := 10, bold := false) {
        weight := bold ? " bold" : ""
        guiObj.SetFont("s" size weight " c" Theme["text"], "Arial")
    }
}

class AdminActivityTracker {
    static DataPath := A_ScriptDir "\admin_activity.csv"

    static ScanAndAppend() {
        content := LogParser.ReadConsole()
        if (content = "")
            return

        if !FileExist(this.DataPath)
            FileAppend("time;type;name;details`n", this.DataPath, "UTF-8")

        for line in StrSplit(content, "`n", "`r") {
            if RegExMatch(line, "^\[(.*?)\].*\[Output\].*\[(.*?)\]\s([^\[]+)\[(\d+)\].*прийняв репорт", &m) {
                FileAppend(m[1] ";report;" Trim(m[3]) ";" m[4] "`n", this.DataPath, "UTF-8")
            }
            else if RegExMatch(line, "^\[(.*?)\].*\[Output\].*(адміністратор|Адміністратор).*?([^\[]+)\[(\d+)\].*(увійшов|зайшов|вийшов)", &m) {
                FileAppend(m[1] ";online;" Trim(m[3]) ";" m[5] "`n", this.DataPath, "UTF-8")
            }
        }
    }

    static GenerateBonusReport() {
        this.ScanAndAppend()

        if !FileExist(this.DataPath) {
            MsgBox("Дані активності ще не зібрані.", "GA Tools", "Icon!")
            return
        }

        raw := FileRead(this.DataPath, "UTF-8")
        reports := Map()

        for line in StrSplit(raw, "`n", "`r") {
            if (line = "" || InStr(line, "time;type;name;details"))
                continue
            parts := StrSplit(line, ";")
            if (parts.Length < 4)
                continue
            type := parts[2]
            name := parts[3]
            if (type = "report") {
                if !reports.Has(name)
                    reports[name] := 0
                reports[name] += 1
            }
        }

        out := "Звіт бонусів ATools NextGen | 02`n`n"
        out .= "Формула поки базова: 1 прийнятий репорт = 1 кб.`n`n"
        for name, count in reports {
            out .= name " — " count " репортів — " count " кб`n"
        }

        reportPath := A_ScriptDir "\bonus_report.txt"
        try FileDelete(reportPath)
        FileAppend(out, reportPath, "UTF-8")
        MsgBox("Звіт створено:`n" reportPath, "GA Tools", "Iconi")
    }
}
