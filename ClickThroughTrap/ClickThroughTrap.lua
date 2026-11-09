local BIG = 10000

local defaults = {
    enabled  = true,
    alpha    = 0.25,
    target   = true,
    bars     = true,
    barAlpha = 0.35,
    extra    = {},
}

local exactUnit = {
    "FocusFrame",
    "ArenaEnemyFrames",
    "ArenaEnemyFrame1", "ArenaEnemyFrame2", "ArenaEnemyFrame3",
    "ArenaEnemyFrame4", "ArenaEnemyFrame5",
    "ArenaPrepFrames",
    "ArenaPrepFrame1", "ArenaPrepFrame2", "ArenaPrepFrame3",
    "ArenaPrepFrame4", "ArenaPrepFrame5",
}
local patternsUnit = {
    "^ArenaEnemyFrame", "^ArenaPrepFrame", "^FocusFrame",
    "^ElvUF_Focus", "^ElvUF_Arena",
    "^SUFUnitfocus", "^SUFUnitarena", "^SUFHeaderarena",
    "^GladiusButtonFrame", "^GladdyButtonFrame", "^sArenaEnemyFrame",
    "^PitBull4_Frames_Focus", "^PitBull4_Frames_Arena",
    "^XPerl_Focus", "^XPerl_Arena",
    "^Nidhaus",
}

local exactBars = {
    "MainMenuBar", "MainMenuBarArtFrame",
    "MultiBarBottomLeft", "MultiBarBottomRight",
    "MultiBarRight", "MultiBarLeft", "VerticalMultiBarsContainer",
    "ShapeshiftBarFrame", "PetActionBarFrame",
    "BonusActionBarFrame", "VehicleMenuBar",

    "NEB_BarLeft", "NEB_BarRight",
}
local patternsBars = {
    "^ActionButton%d", "^MultiBar%a+Button%d",
    "^NEB_Bar%a+Button%d",
    "^BT4Bar", "^BT4Button",
    "^DominosFrame", "^DominosActionButton",
}

local DB
local cache, groupOf, dirty = {}, {}, true
local saved      = {}
local alphaOf    = {}
local alphaGroup = {}
local touched    = {}
local active     = false
local forceUntil = 0

local pending    = {}

local IGNORE_SPELLS = { 6991 }

local function Print(msg) DEFAULT_CHAT_FRAME:AddMessage("|cffffffffClickThrough|r|cff00ff00Trap|r: " .. tostring(msg)) end

local L = {
    TEST       = "8 s test: move the sliders and click through the frames.",
    ON         = "enabled",
    OFF        = "disabled",
    INCLUDED   = "included",
    EXCLUDED   = "excluded",
    USAGE      = "usage: ",
    ALPHA_USE  = "0.25  (0 = invisible, 1 = opaque)",
    ADDED      = "added: ",
    NOT_YET    = "  (it does not exist yet, it will be looked for later)",
    ADD_USE    = "/ctt add FrameName",
    REMOVED    = "removed: ",
    ROOTS      = " root frames found:",
    NO_MOUSE   = "there is no frame under the mouse",
    ANON       = "<unnamed>",
    PROT       = "[protected]",
    UNDER      = "under the mouse: ",
    SCAN_HINT  = "use /ctt add <name> with the ROOT frame of that chain (the one before UIParent).",
    HELP       = "/ctt (opens the menu) | on|off | target on|off | bars on|off | alpha <0-1> | baralpha <0-1> | add | del | list | scan | test",
    SUB        = "While you aim a ground spell, the frames turn see-through and the mouse clicks through them.",
    CB_ON      = "Addon enabled",
    CB_TARGET  = "Include the target frame",
    CB_BARS    = "Include the action bars (keybinds keep working)",
    SL_FRAMES  = "Focus / arena / target opacity",
    SL_BARS    = "Action bar opacity",
    BTN_TEST   = "Try it for 8 seconds",
    HINT       = "0% = invisible, 100% = no opacity change. Clicks always go through while you aim.",
}
local LOCALE = GetLocale and GetLocale() or "enUS"
if LOCALE == "esES" or LOCALE == "esMX" then
    L.TEST      = "prueba de 8 s: mové los sliders y hacé clic a través de los marcos."
    L.ON        = "activado"
    L.OFF       = "desactivado"
    L.INCLUDED  = "incluido"
    L.EXCLUDED  = "excluido"
    L.USAGE     = "uso: "
    L.ALPHA_USE = "0.25  (0 = invisible, 1 = opaco)"
    L.ADDED     = "añadido: "
    L.NOT_YET   = "  (todavía no existe, se buscará más tarde)"
    L.ADD_USE   = "/ctt add NombreDelMarco"
    L.REMOVED   = "quitado: "
    L.ROOTS     = " marcos raíz encontrados:"
    L.NO_MOUSE  = "no hay ningún marco bajo el ratón"
    L.ANON      = "<anónimo>"
    L.PROT      = "[protegido]"
    L.UNDER     = "bajo el ratón: "
    L.SCAN_HINT = "usá /ctt add <nombre> con el marco RAÍZ de esa cadena (el de antes de UIParent)."
    L.HELP      = "/ctt (abre el menú) | on|off | target on|off | bars on|off | alpha <0-1> | baralpha <0-1> | add | del | list | scan | test"
    L.SUB       = "Mientras apuntás un hechizo de suelo, los marcos se vuelven transparentes y el ratón los atraviesa."
    L.CB_ON     = "Addon activado"
    L.CB_TARGET = "Incluir el marco del objetivo"
    L.CB_BARS   = "Incluir las barras de acción (las teclas siguen funcionando)"
    L.SL_FRAMES = "Opacidad de focus / arena / objetivo"
    L.SL_BARS   = "Opacidad de las barras de acción"
    L.BTN_TEST  = "Probar 8 segundos"
    L.HINT      = "0% = invisible, 100% = sin cambio de opacidad. El clic siempre atraviesa mientras apuntás."
end

local function matchAny(name, list)
    for _, p in ipairs(list) do
        if name:find(p) then return true end
    end
    return false
end

local function Resolve()
    wipe(cache); wipe(groupOf)
    local function add(f, g)
        if f and f.GetHitRectInsets and f.SetAlpha and not groupOf[f] then
            groupOf[f] = g
            cache[#cache + 1] = f
        end
    end
    local function isWantedUnit(u)
        if type(u) ~= "string" then return false end
        if DB.target and (u == "target" or u == "targettarget") then return true end
        return u == "focus" or u == "focustarget" or u:find("^arena%d") ~= nil
    end

    for _, n in ipairs(exactUnit) do add(_G[n], "alpha") end
    for _, n in ipairs(DB.extra)  do add(_G[n], "alpha") end
    if DB.target then add(_G["TargetFrame"], "alpha") end
    if DB.bars then
        for _, n in ipairs(exactBars) do add(_G[n], "barAlpha") end
    end

    local f = EnumerateFrames()
    while f do
        local n = f.GetName and f:GetName()
        local g
        if n then
            if matchAny(n, patternsUnit) then g = "alpha"
            elseif DB.target and n:find("^TargetFrame") then g = "alpha"
            elseif DB.bars and matchAny(n, patternsBars) then g = "barAlpha" end
        end
        if not g and f.GetAttribute then
            local ok, u = pcall(f.GetAttribute, f, "unit")
            if ok and isWantedUnit(u) then g = "alpha" end
        end
        if not g and isWantedUnit(rawget(f, "unit")) then g = "alpha" end
        if g then add(f, g) end
        f = EnumerateFrames(f)
    end
    dirty = false
end

local function Locked(f)
    return InCombatLockdown() and f.IsProtected and f:IsProtected()
end

local function SameInsets(f, r)
    local a, b, c, d = f:GetHitRectInsets()
    return math.abs((a or 0) - r[1]) < 0.5 and math.abs((b or 0) - r[2]) < 0.5
       and math.abs((c or 0) - r[3]) < 0.5 and math.abs((d or 0) - r[4]) < 0.5
end

local function RestoreInsets(f, r)
    if not Locked(f) then
        f:SetHitRectInsets(r[1], r[2], r[3], r[4])
        if SameInsets(f, r) then pending[f] = nil; return true end
    end
    pending[f] = r
    return false
end

local function FlushPending()
    for f, r in pairs(pending) do RestoreInsets(f, r) end
end

local function ApplyTree(f, group)
    if saved[f] ~= nil then return end
    touched[#touched + 1] = f
    if Locked(f) then
        saved[f] = false
    else
        local orig = pending[f] or { f:GetHitRectInsets() }
        pending[f] = nil
        saved[f] = orig
        f:SetHitRectInsets(BIG, BIG, BIG, BIG)
    end
    if group then
        alphaOf[f] = f:GetAlpha()
        alphaGroup[f] = group
        f:SetAlpha(DB[group])
    end
    local children = { f:GetChildren() }
    for i = 1, #children do ApplyTree(children[i], nil) end
end

local function Start()
    if active then return end
    active = true
    if dirty then Resolve() end
    local rootSet = {}
    for i = 1, #cache do rootSet[cache[i]] = true end
    local function hasRootAncestor(f)
        local p = f:GetParent()
        while p do
            if rootSet[p] then return true end
            p = p:GetParent()
        end
        return false
    end
    for i = 1, #cache do
        local f = cache[i]

        ApplyTree(f, (not hasRootAncestor(f)) and groupOf[f] or nil)
    end
end

local function Stop()
    if not active then return end
    active = false
    for i = 1, #touched do
        local f = touched[i]
        local r = saved[f]
        if r then RestoreInsets(f, r) end
        if alphaOf[f] then f:SetAlpha(alphaOf[f]) end
    end
    wipe(saved); wipe(alphaOf); wipe(alphaGroup); wipe(touched)
end

local function ReleaseProtected()
    for i = 1, #touched do
        local f = touched[i]
        local r = saved[f]
        if r and f.IsProtected and f:IsProtected() then
            f:SetHitRectInsets(r[1], r[2], r[3], r[4])
            if SameInsets(f, r) then saved[f] = false else pending[f] = r; saved[f] = false end
        end
    end
    FlushPending()
end

local function RefreshAlpha()
    for f, g in pairs(alphaGroup) do f:SetAlpha(DB[g]) end
end

local function TestNow()
    forceUntil = GetTime() + 8
    Print(L.TEST)
end

local ignoreNames
local function IgnoredSpellPending()
    if not ignoreNames then
        ignoreNames = {}
        for _, id in ipairs(IGNORE_SPELLS) do
            local n = GetSpellInfo(id)
            if n then ignoreNames[#ignoreNames + 1] = n end
        end
    end
    for _, n in ipairs(ignoreNames) do
        local ok, cur = pcall(IsCurrentSpell, n)
        if ok and cur then return true end

        local i = 1
        while true do
            local name = GetSpellName(i, BOOKTYPE_SPELL)
            if not name then break end
            if name == n then
                local ok2, cur2 = pcall(IsCurrentSpell, i, BOOKTYPE_SPELL)
                if ok2 and cur2 then return true end
                break
            end
            i = i + 1
        end
    end
    return false
end

local watcher = CreateFrame("Frame")
watcher:SetScript("OnUpdate", function()
    if not DB or not DB.enabled then
        if active then Stop() end
        return
    end
    local want = (SpellIsTargeting() and not IgnoredSpellPending()) or (GetTime() < forceUntil)
    if want and not active then Start()
    elseif not want and active then Stop() end
end)

local panel = CreateFrame("Frame", "ClickThroughTrapOptions", UIParent)
panel.name = "ClickThroughTrap"
local loading = false

local function MakeCheck(name, label, y, get, set)
    local cb = CreateFrame("CheckButton", name, panel, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 16, y)
    _G[name .. "Text"]:SetText(label)
    cb:SetScript("OnClick", function(self)
        set(self:GetChecked() and true or false)
    end)
    cb.refresh = function() cb:SetChecked(get()) end
    return cb
end

local function MakeSlider(name, label, y, key)
    local s = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", 20, y)
    s:SetWidth(260)
    s:SetMinMaxValues(0, 100)
    s:SetValueStep(5)
    _G[name .. "Low"]:SetText("0%")
    _G[name .. "High"]:SetText("100%")
    s.label = label
    s:SetScript("OnValueChanged", function(self, value)
        if loading then return end
        DB[key] = value / 100
        _G[name .. "Text"]:SetText(label .. ": " .. math.floor(value + 0.5) .. "%")
        if active then RefreshAlpha() end
    end)
    s.refresh = function()
        loading = true
        s:SetValue(DB[key] * 100)
        _G[name .. "Text"]:SetText(label .. ": " .. math.floor(DB[key] * 100 + 0.5) .. "%")
        loading = false
    end
    return s
end

local widgets = {}
local function BuildPanel()
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cffffffffClickThrough|r|cff00ff00Trap|r")

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetText(L.SUB)

    widgets[#widgets + 1] = MakeCheck("CTTCheckEnabled", L.CB_ON, -60,
        function() return DB.enabled end, function(v) DB.enabled = v end)
    widgets[#widgets + 1] = MakeCheck("CTTCheckTarget", L.CB_TARGET, -90,
        function() return DB.target end, function(v) DB.target = v; dirty = true end)
    widgets[#widgets + 1] = MakeCheck("CTTCheckBars", L.CB_BARS, -120,
        function() return DB.bars end, function(v) DB.bars = v; dirty = true end)

    widgets[#widgets + 1] = MakeSlider("CTTSliderFrames", L.SL_FRAMES, -175, "alpha")
    widgets[#widgets + 1] = MakeSlider("CTTSliderBars", L.SL_BARS, -230, "barAlpha")

    local btn = CreateFrame("Button", "CTTTestButton", panel, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", 20, -275)
    btn:SetWidth(200); btn:SetHeight(24)
    btn:SetText(L.BTN_TEST)
    btn:SetScript("OnClick", TestNow)

    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -10)
    hint:SetText(L.HINT)
end

panel:SetScript("OnShow", function()
    for _, w in ipairs(widgets) do w.refresh() end
end)

watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("PLAYER_FOCUS_CHANGED")
watcher:RegisterEvent("ARENA_OPPONENT_UPDATE")
watcher:RegisterEvent("PLAYER_LOGOUT")
watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "ClickThroughTrap" then
        ClickThroughTrapDB = ClickThroughTrapDB or {}
        DB = ClickThroughTrapDB
        for k, v in pairs(defaults) do
            if DB[k] == nil then
                DB[k] = (type(v) == "table") and {} or v
            end
        end
        BuildPanel()
        InterfaceOptions_AddCategory(panel)
    elseif event == "PLAYER_LOGOUT" then
        Stop()
    elseif event == "PLAYER_REGEN_DISABLED" then
        if active then ReleaseProtected() else FlushPending() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        FlushPending()
    else
        dirty = true
    end
end)

local function OpenPanel()
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)
end

SLASH_CLICKTHROUGHTRAP1 = "/ctt"
SlashCmdList["CLICKTHROUGHTRAP"] = function(msg)
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()

    if cmd == "" or cmd == "config" or cmd == "options" then
        OpenPanel()

    elseif cmd == "on" or cmd == "off" then
        DB.enabled = (cmd == "on")
        Print(DB.enabled and L.ON or L.OFF)

    elseif cmd == "target" or cmd == "bars" then
        rest = rest:lower()
        if rest == "on" or rest == "off" then
            DB[cmd] = (rest == "on"); dirty = true
            Print(cmd .. ": " .. (DB[cmd] and L.INCLUDED or L.EXCLUDED))
        else Print(L.USAGE .. "/ctt " .. cmd .. " on|off") end

    elseif cmd == "alpha" or cmd == "baralpha" then
        local a = tonumber(rest)
        local key = (cmd == "alpha") and "alpha" or "barAlpha"
        if a and a >= 0 and a <= 1 then DB[key] = a; Print(key .. " = " .. a)
        else Print(L.USAGE .. "/ctt " .. cmd .. " " .. L.ALPHA_USE) end

    elseif cmd == "add" then
        if rest ~= "" then
            tinsert(DB.extra, rest); dirty = true
            Print(L.ADDED .. rest .. (_G[rest] and "" or L.NOT_YET))
        else Print(L.USAGE .. L.ADD_USE) end

    elseif cmd == "del" then
        for i = #DB.extra, 1, -1 do
            if DB.extra[i] == rest then tremove(DB.extra, i) end
        end
        dirty = true; Print(L.REMOVED .. rest)

    elseif cmd == "list" then
        Resolve()
        Print(#cache .. L.ROOTS)
        for i = 1, #cache do
            Print("  [" .. groupOf[cache[i]] .. "] " .. (cache[i]:GetName() or tostring(cache[i])))
        end

    elseif cmd == "scan" then
        local f = GetMouseFocus()
        if not f then Print(L.NO_MOUSE) return end
        local chain = {}
        while f do
            chain[#chain + 1] = (f:GetName() or L.ANON) ..
                (f.IsProtected and f:IsProtected() and L.PROT or "")
            f = f:GetParent()
        end
        Print(L.UNDER .. table.concat(chain, " < "))
        Print(L.SCAN_HINT)

    elseif cmd == "test" then
        TestNow()

    else
        Print(L.HELP)
    end
end
