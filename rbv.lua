local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local Workspace          = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService   = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local TweenService       = game:GetService("TweenService")
local Camera             = workspace.CurrentCamera
local lp = Players.LocalPlayer
if not lp then
	repeat task.wait(0.5) until Players.LocalPlayer
	lp = Players.LocalPlayer
end
local character = lp.Character or lp.CharacterAdded:Wait()
local _humanoid  = character:WaitForChild("Humanoid")
local _rootPart  = character:WaitForChild("HumanoidRootPart")
local _cam = Workspace.CurrentCamera

if game.PlaceId ~= 93978595733734 then
    Players.LocalPlayer:Kick("[ROLL HUB] This map is not supported.")
    error("[ROLL HUB] This map is not supported.")
end

local state = {
	running = true,
	cfg = {
		spear_enabled        = false,
		spear_key            = Enum.KeyCode.E,
		spear_isHolding      = false,
        spear_targetPart = "Head",

		sc_enabled  = false,
        sc_key      = 32,
        sc_lead     = 2,
        sc_offset   = 110,
        sc_instant_offset  = 110,
        sc_trap_offset     = 110,
        sc_trapgoal_offset = 105,
        sc_pressKey = true,

		ap_enabled       = false,
		ap_range         = 12,
		ap_mode          = "Normal",
		ap_faceTh        = 0.35,
		ap_safety        = false,

		ap_showCircle    = true,
		ap_circleColor   = Color3.fromRGB(0, 255, 200),
		ap_cdFromServer  = true,
		esp_enabled       = false,
		esp_showName      = true,
		esp_showDist      = true,
		esp_showHighlight = true,
		esp_showBox       = true,
		esp_maxDist       = 500,
		scp_esp_enabled      = false,
		scp_esp_showHighlight = true,
		scp_esp_showBox      = true,
		scp_esp_showName     = true,
		scp_esp_showDist     = true,
		scp_esp_maxDist      = 500,
		p_esp_enabled       = false,
		p_esp_showName      = true,
		p_esp_showDist      = true,
		p_esp_showHighlight = true,
		p_esp_showBox       = true,
		p_esp_showStatus    = false,
		p_esp_maxDist       = 500,
		noFlashBlind        = false,
		breakSpeed_enabled  = false,
		breakSpeed_value    = 1,
		selectMask          = "Alex",
        swiftspeed_enabled = false,
        swiftspeed_value   = 1.5,
		autoPumpkin_enabled  = false,
		autoPumpkin_delay    = 0.3,
		tof_enabled = false,
		tof_target = "Killer",
		tof_maxDist = 50,
		flashlightAim_maxDist = 30,
        meEsp_enabled = false,
        fastVault_enabled    = false,
        flowstate_enabled    = false,
        flowstate_cooldown   = 15,
	},
	ui = {},
	render = {
    lines = {},
    meHighlight = nil,
    meAnimT = 0,
    scInstantConn = nil,
},

	killer2DEspElements = {},
	player2DEspElements = {},
	scpEspElements = {},
	genEspElements = {},
	bearTrapEspElements = {},
	pumpkinEspElements = {},
	vaultEspElements = {},
	palletEspElements = {},

	genEspEnabled = false,
	bearTrapEspEnabled = false,
	pumpkinEspEnabled = false,
	vaultEspEnabled = false,
	palletEspEnabled = false,

	pallets = {},
	killerRoots = {},
	_cachedPlayers = {},
	_playerCacheTime = 0,
	droppedPallets = {},
	lastDrop = {},
	lastTeamName = "",

	scLast = { l=nil, g=nil, win=nil },
	scHits = 0,
	scFired = false,
	_instantLoopRunning = false,

	ap_monitoredKillers = {},
	ap_animConns = {},
	ap_lastParryTime = 0,
	ap_parryCD = false,
	ap_parryCDTok = 0,
	ap_parryCDThr = nil,

	playerParryState = {},
	monitoredPlayerAnimators = {},

	_lastCrouchTime = 0,

	_skillCDCache = false,
	_skillCDLastCheck = 0,

	_fullbrightEnabled = false,
	_nofogEnabled = false,
	originalLighting = {},
	savedAtmosphere = {},
	savedColorCorrection = {},

	_genScanCache = nil,
	_genScanTime  = 0,
	_genCounter   = 0,
	_genPrevProgress = {},
	_genIsBreaking = {},

	_bearTrapScanTime = 0,

	_pumpkinScanTime = 0,

	_scpScanTime = 0,
	_scpTick = 0,

	_mapEspConns = {},

	autoGenLegit_enabled   = false,
	autoGenLegit_mode      = "Normal",
	autoGenLegit_busy      = false,

	flashlightAimEnabled = false,
	flashlightAimConn = nil,
	_flashlightNotified = false,

	_hopServerBusy = false,

	_fvPatches          = {},
	_fvController       = nil,
	_fsCD               = 0,
	_fsOverrideEnd      = 0,
	_fsCDLock           = 0,
	_fvAnimConn         = nil,

	autoBreakGenAura_enabled = false,
	autoBreakGenAura_radius = 20,

	moonwalkEnabled = false,
	moonwalkKey     = Enum.KeyCode.G,
	moonwalkAdT     = 0,
	moonwalkAdDir   = 1,

	pfRunning     = false,
	pfThread      = nil,
	pfToggleElem  = nil,
	pfToggleState = false,
	pfStuckGen    = 0,
	pfStuckSignal = false,

	_saFiring = false,

	uiLabels = { status = nil, killerDist = nil, parryDaggerCD = nil },
	pStat = { elig=false, inZone=false, hp=true, nearD=nil, killD=nil, baiting=false },

	lblMapPrefix = nil,
	lblNamePrefix = nil,
	lblKillerPrefix = nil,
	lblKillerThe = nil,
	lblMapValue = nil,
	lblNameValue = nil,
	lblKillerValue = nil,
}

local UILib = getgenv().UILib_Dev
if not UILib then
    local okRead, src = pcall(readfile, "UILib.lua")
    if not okRead or type(src) ~= "string" then
        error("[ROLL HUB] UILib.lua tidak ditemukan di folder workspace executor.")
    end
    UILib = loadstring(src)()
end

local ICONS = {
    bookmark = "📌", user = "👤", zap = "⚡", swords = "⚔", crosshair = "🎯",
    eye = "👁", globe = "🌍", ghost = "👻",
}

local function wrapContainer(c, win)
    local w = {}
    function w:Toggle(o)
        local el = c:AddToggle({ Name = o.Title, Default = o.Default, Desc = o.Desc, Callback = o.Callback })
        local proxy = { raw = el }
        function proxy:SetValue(v) el:Set(v and true or false, true) end
        function proxy:Get() return el:Get() end
        return proxy
    end
    function w:Slider(o)
        local el = c:AddSlider({
            Name = o.Title, Min = o.Min, Max = o.Max, Default = o.Default,
            Increment = o.Step or 1, Suffix = o.Suffix, Desc = o.Desc, Callback = o.Callback,
        })
        local proxy = { raw = el }
        function proxy:SetValue(v) el:Set(v, true) end
        function proxy:Get() return el:Get() end
        return proxy
    end
    function w:Dropdown(o)
        local el = c:AddDropdown({
            Name = o.Title, Options = o.Values, Default = o.Default, Desc = o.Desc, Callback = o.Callback,
        })
        local proxy = { raw = el }
        function proxy:SetValue(v) el:Set(v, true) end
        function proxy:Get() return el:Get() end
        return proxy
    end
    function w:Button(o)
        local cb = o.Callback
        if o.Confirm then
            local real = cb
            cb = function()
                win:Dialog({
                    Title = o.Title, Content = o.Confirm,
                    Buttons = { { Name = "Batal" }, { Name = "Ya", Primary = true, Callback = real } },
                })
            end
        end
        return c:AddButton({ Name = o.Title, Desc = o.Desc, Callback = cb })
    end
    function w:Label(o)
        return c:AddLabel(type(o) == "table" and (o.Text or o.Title) or tostring(o))
    end
    return w
end

local function wrapTab(tab, win)
    local t = wrapContainer(tab, win)
    function t:Section(o)
        return wrapContainer(tab:AddSection(o.Title), win)
    end
    return t
end

OasisUI = {}
function OasisUI:Notify(o)
    UILib:Notify({ Title = o.Title, Content = o.Content, Duration = o.Duration or 4, Type = o.Type or "info" })
end
function OasisUI:Unload() UILib:Unload() end
function OasisUI:OnUnload(fn) UILib.OnUnload = fn end
function OasisUI:CreateWindow(o)
    local win = UILib:CreateWindow({
        Title = o.Title, Subtitle = o.Subtitle, ToggleKey = o.ToggleKey,
        Icon = ICONS[o.Icon] or "☰",
    })
    local ww = {}
    function ww:Tab(t) return wrapTab(win:AddTab(t.Title, ICONS[t.Icon] or "•"), win) end
    function ww:Raw() return win end
    return ww
end

state.ui.Window = OasisUI:CreateWindow({
    Title     = "ROLL HUB",
    Subtitle  = "v1.3",
    Icon      = "swords",
    ToggleKey = Enum.KeyCode.RightShift,
})

local AD_INTERVAL = 0.03

local PF_STUCK_TIMEOUT   = 2.0
local PF_STUCK_THRESHOLD = 0.5
local PF_ATTEMPT_ANGLES  = { 0, math.rad(45), math.rad(-45), math.rad(90), math.rad(-90) }
local SPEAR_SPEED_READY = 180
local SPEAR_SPEED_CD    = 170
local SPEAR_GRAV_READY = 98.1
local SPEAR_GRAV_CD    = 100.0
local AIM_HEIGHT_OFFSET = -0.5
local ABYSSWALKER_SKILL_ID = 100014992013740

local HIT_ANIM_IDS = {
    [127417297154354]=true, [83333467665074]=true,  [129626174716003]=true,
    [113691709436161]=true, [93902163029544]=true,  [75618342544502]=true,
    [79310600168078]=true,  [104540716539347]=true, [101636125032002]=true,
    [125430111937587]=true, [136820376940910]=true, [84926129581106]=true,
    [81963230963908]=true,
    [122812055447896]=true, [133963973694098]=true, [117042998468241]=true,
    [135002183282873]=true, [121216847022485]=true, [132817836308238]=true,
    [129784271201071]=true, [82666958311998]=true,  [78432063483146]=true,
    [118907603246885]=true, [139369275981139]=true, [110355011987939]=true,
    [111920872708571]=true, [105374834496520]=true, [138720291317243]=true,
    [106871536134254]=true, [130593238885843]=true, [115244153053858]=true,
    [74968262036854]=true,  [113255068724446]=true, [98163597193511]=true,
    [109402730355822]=true, [78935059863801]=true,  [117070354890871]=true,
[73681849513551]=true, [137795837089724]=true,
}
local AP_ABYSSAL_S1_ID = 80411309607666

local ITEM_ICONS = {
    ["Adrenaline Shot"] = "rbxassetid://135388781922226",
    ["Bandage"]         = "rbxassetid://97791520639443",
    ["Flashlight"]      = "rbxassetid://103299939715311",
    ["Gate"]            = "rbxassetid://131249244284700",
    ["Holy Water"]      = "rbxassetid://86130208614143",
    ["Monkey Paw"]      = "rbxassetid://78636637697235",
    ["Motion Tracker"]  = "rbxassetid://92303584765773",
    ["Parrying Dagger"] = "rbxassetid://76822757630703",
    ["Riot Shield"]     = "rbxassetid://95718705901699",
    ["Shadow Clone"]    = "rbxassetid://134088840518889",
    ["Twist of Fate"]   = "rbxassetid://98397448432071",
    ["WaxBound Candle"] = "rbxassetid://110413686590821",
}

local killerTeamKeywords = { "Killer", "killer" }
local spectatorKeywords  = { "Spectator", "Spectator" }

local Lighting = game:GetService("Lighting")

local espGui = Instance.new("ScreenGui")
espGui.Name           = "ROLL_HUB_2DESP_ScreenGui"
espGui.ResetOnSpawn   = false
espGui.DisplayOrder   = 999
espGui.IgnoreGuiInset = true
espGui.Parent         = game:GetService("CoreGui")

local palletCountGui = Instance.new("ScreenGui")
palletCountGui.Name           = "ROLL_HUB_PalletCount"
palletCountGui.ResetOnSpawn   = false
palletCountGui.DisplayOrder   = 1001
palletCountGui.IgnoreGuiInset = true
palletCountGui.Parent         = game:GetService("CoreGui")

local palletCountFrame = Instance.new("Frame")
palletCountFrame.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
palletCountFrame.BackgroundTransparency = 0.45
palletCountFrame.Size                   = UDim2.new(0, 220, 0, 46)
palletCountFrame.Position               = UDim2.new(0.5, -110, 0, 10)
palletCountFrame.BorderSizePixel        = 0
palletCountFrame.Visible                = false
palletCountFrame.Parent                 = palletCountGui
Instance.new("UICorner", palletCountFrame).CornerRadius = UDim.new(0, 8)

local uiList = Instance.new("UIListLayout")
uiList.Padding         = UDim.new(0, 2)
uiList.FillDirection   = Enum.FillDirection.Vertical
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiList.SortOrder       = Enum.SortOrder.LayoutOrder
uiList.Parent          = palletCountFrame

local function makeInfoLabel(layoutOrder)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size                   = UDim2.new(1, -10, 0, 16)
    lbl.TextColor3             = Color3.fromRGB(220, 220, 220)
    lbl.TextStrokeTransparency = 0.5
    lbl.Font                   = Enum.Font.Gotham
    lbl.TextSize               = 11
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Text                   = ""
    lbl.LayoutOrder            = layoutOrder
    lbl.Parent                 = palletCountFrame
    return lbl
end

local infoKillerLabel   = makeInfoLabel(1)
local infoMorphLabel    = makeInfoLabel(2)
local killerInfoVisible = false
infoKillerLabel.Visible = false
infoMorphLabel.Visible  = false

local uiPad = Instance.new("UIPadding")
uiPad.PaddingLeft  = UDim.new(0, 8)
uiPad.PaddingTop   = UDim.new(0, 5)
uiPad.Parent       = palletCountFrame

local pfDotFolder = workspace:FindFirstChild("_PF_Dots") or Instance.new("Folder")
pfDotFolder.Name   = "_PF_Dots"
pfDotFolder.Parent = workspace

local function isSpectator()
	local team = lp.Team
	if not team then return false end
	local tn = string.lower(tostring(team.Name or ""))
	for _, kw in ipairs(spectatorKeywords) do
		if tn:find(string.lower(kw)) then return true end
	end
	return false
end

local function hasKillerTeamName(plr)
	local tn = plr.Team and string.lower(tostring(plr.Team.Name or "")) or ""
	for _, kw in ipairs(killerTeamKeywords) do
		if tn:find(string.lower(kw)) then return true end
	end
	return false
end

local function isSurvivor()
	if isSpectator() then return false end
	if hasKillerTeamName(lp) then return false end
	return true
end

local function isKillerPlayer(plr)
	if plr == lp then return false end
	if hasKillerTeamName(plr) then return true end
	if not hasKillerTeamName(lp) then
		if lp.Team and plr.Team and plr.Team ~= lp.Team then
			local tn = plr.Team and string.lower(tostring(plr.Team.Name or "")) or ""
			for _, kw in ipairs(spectatorKeywords) do
				if tn:find(string.lower(kw)) then return false end
			end
			return true
		end
	end
	return false
end

local function myRoot()
	local ch = lp.Character
	return ch and ch:FindFirstChild("HumanoidRootPart")
end

local function healthOk()
	local ch = lp.Character
	local hum = ch and ch:FindFirstChild("Humanoid")
	if not hum then return true end
	local h = hum.Health
	return (type(h) ~= "number") or (h > 50)
end

local function busy()
	local ch = lp.Character
	local sc = ch and ch:FindFirstChild("CheckInterractable")
	if not sc then return false end
	local ok, v = pcall(function() return sc:GetAttribute("isDroppingPallet") end)
	return ok and (v == true)
end

local function pressKey(keyCodeEnum, keyCodeNum)
	task.spawn(function()
		pcall(function()
			VirtualInputManager:SendKeyEvent(true, keyCodeEnum or Enum.KeyCode.Space, false, game)
			task.wait(0.01)
			VirtualInputManager:SendKeyEvent(false, keyCodeEnum or Enum.KeyCode.Space, false, game)
		end)
	end)
end

local LUNGE_CONFIG = {
	Mode          = "Infinite",
	ScanInterval  = 2,
	LungeBoostVal = 999999,
}
local LUNGE_S = {
	Running   = false,
	Ctrl      = nil,
	CtrlOrig  = nil,
	LastScan  = 0,
	Scanning  = false,
	OrigBoost = nil,
	Char      = nil,
}
local function lungeIsKiller()
	return hasKillerTeamName(lp)
end
local function lungeApplyMaxHold()
	if type(LUNGE_S.Ctrl) ~= "table" then return end
	if LUNGE_S.CtrlOrig == nil then
		LUNGE_S.CtrlOrig = rawget(LUNGE_S.Ctrl, "_origMaxHold") or LUNGE_S.Ctrl.maxHold
		rawset(LUNGE_S.Ctrl, "_origMaxHold", LUNGE_S.CtrlOrig)
	end
	if LUNGE_S.Ctrl.maxHold ~= math.huge then
		pcall(function() LUNGE_S.Ctrl.maxHold = math.huge end)
	end
end
local function lungeRestoreMaxHold()
	if type(LUNGE_S.Ctrl) == "table" and LUNGE_S.CtrlOrig ~= nil then
		pcall(function() LUNGE_S.Ctrl.maxHold = LUNGE_S.CtrlOrig end)
	end
	LUNGE_S.Ctrl, LUNGE_S.CtrlOrig = nil, nil
end
local function lungeApplyBoost()
	local char = lp.Character
	if not char then return end
	if LUNGE_S.Char ~= char then
		LUNGE_S.Char = char
		LUNGE_S.OrigBoost = char:GetAttribute("lungeboost")
	end
	if char:GetAttribute("lungeboost") ~= LUNGE_CONFIG.LungeBoostVal then
		pcall(function() char:SetAttribute("lungeboost", LUNGE_CONFIG.LungeBoostVal) end)
	end
end
local function lungeRestoreBoost()
	local char = lp.Character
	if char and char:GetAttribute("lungeboost") == LUNGE_CONFIG.LungeBoostVal then
		pcall(function() char:SetAttribute("lungeboost", LUNGE_S.OrigBoost or 1) end)
	end
	LUNGE_S.Char, LUNGE_S.OrigBoost = nil, nil
end
local function lungeScan()
	if LUNGE_S.Scanning or not lp.Character or not lungeIsKiller() then return end
	if typeof(getgc) ~= "function" then return end
	LUNGE_S.Scanning = true
	local char = lp.Character
	pcall(function()
		local gc = getgc(true)
		if type(gc) ~= "table" then return end
		local start = os.clock()
		for i, obj in ipairs(gc) do
			if not state.running or lp.Character ~= char then return end
			if i % 128 == 0 and os.clock() - start >= 0.002 then
				RunService.Heartbeat:Wait(); start = os.clock()
			end
			if type(obj) == "table"
				and rawget(obj, "maxHold") ~= nil
				and rawget(obj, "lungeThreshold") ~= nil then
				LUNGE_S.Ctrl = obj
				LUNGE_S.CtrlOrig = rawget(obj, "_origMaxHold") or obj.maxHold
				rawset(obj, "_origMaxHold", LUNGE_S.CtrlOrig)
				break
			end
		end
	end)
	LUNGE_S.Scanning = false
end

local _lungeWasRunning = false

local _lungeHbConn = RunService.Heartbeat:Connect(function()
	if not state.running then return end
	if not LUNGE_S.Running then
		if _lungeWasRunning then
			_lungeWasRunning = false
			lungeRestoreBoost()
			lungeRestoreMaxHold()
		end
		return
	end
	_lungeWasRunning = true
	if not lp.Character then
		lungeRestoreMaxHold(); lungeRestoreBoost(); return
	end
	if lungeIsKiller() then
		lungeApplyBoost()
		if LUNGE_S.Ctrl then lungeApplyMaxHold() end
	else
		lungeRestoreBoost(); lungeRestoreMaxHold()
	end
	local now = tick()
	if lungeIsKiller() and (not LUNGE_S.Ctrl or not LUNGE_S.Ctrl.maxHold)
		and now - LUNGE_S.LastScan >= LUNGE_CONFIG.ScanInterval then
		LUNGE_S.LastScan = now
		task.spawn(lungeScan)
	end
end)

lp.CharacterAdded:Connect(function()
	LUNGE_S.Ctrl, LUNGE_S.CtrlOrig = nil, nil
	LUNGE_S.Char, LUNGE_S.OrigBoost = nil, nil
	task.wait(2); LUNGE_S.LastScan = 0; pcall(lungeScan)
end)

task.spawn(function() task.wait(2); pcall(lungeScan) end)

local function getAnimAssetId(track)
	local ok, animId = pcall(function()
		return track.Animation and track.Animation.AnimationId or ""
	end)
	if not ok then return nil end
	return tonumber(animId:match("(%d+)$"))
end

local function getTextWidth(text, size)
    return #text * (size * 0.55)
end

local function findAnimator(char)
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local a = hum:FindFirstChildOfClass("Animator")
        if a then return a end
    end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("Animator") then return v end
    end
    return nil
end

local function isPalletDropped(pal)
	if not pal or not pal.board or not pal.board.Parent then return true end
	if state.droppedPallets[pal.id] then return true end
	local b = pal.board
	local p = b.Parent
	if b:GetAttribute("isDropped") or b:GetAttribute("Dropped") or b:GetAttribute("isDown") then
		state.droppedPallets[pal.id] = true; return true
	end
	if p and (p:GetAttribute("isDropped") or p:GetAttribute("Dropped") or p:GetAttribute("isDown")) then
		state.droppedPallets[pal.id] = true; return true
	end
	return false
end

local function saveOriginalLighting()
    state.originalLighting.Brightness      = Lighting.Brightness
    state.originalLighting.ClockTime       = Lighting.ClockTime
    state.originalLighting.FogEnd          = Lighting.FogEnd
    state.originalLighting.FogStart        = Lighting.FogStart
    state.originalLighting.GlobalShadows   = Lighting.GlobalShadows
    state.originalLighting.Ambient         = Lighting.Ambient
    state.originalLighting.OutdoorAmbient  = Lighting.OutdoorAmbient
end
saveOriginalLighting()

local function applyFullBright()
    Lighting.Brightness     = 2
    Lighting.ClockTime      = 14
    Lighting.GlobalShadows  = false
    Lighting.Ambient        = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
end

local function restoreFullBright()
    Lighting.Brightness     = state.originalLighting.Brightness
    Lighting.ClockTime      = state.originalLighting.ClockTime
    Lighting.GlobalShadows  = state.originalLighting.GlobalShadows
    Lighting.Ambient        = state.originalLighting.Ambient
    Lighting.OutdoorAmbient = state.originalLighting.OutdoorAmbient
end

local function applyNoFog()
    Lighting.FogEnd   = 100000
    Lighting.FogStart = 100000
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Atmosphere") then
            state.savedAtmosphere[#state.savedAtmosphere + 1] = {
                obj = obj, Density = obj.Density, Offset = obj.Offset, Haze = obj.Haze,
            }
            obj.Density = 0; obj.Offset = 0; obj.Haze = 0
        end
        if obj:IsA("ColorCorrectionEffect") then
            state.savedColorCorrection[#state.savedColorCorrection + 1] = {
                obj = obj, Enabled = obj.Enabled,
                Brightness = obj.Brightness, Contrast = obj.Contrast, Saturation = obj.Saturation,
            }
            obj.Brightness = 0; obj.Contrast = 0; obj.Saturation = 0
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = string.lower(obj.Name or "")
        if name:find("fog") or name:find("mist") or name:find("haze") then
            if obj:IsA("BasePart") then
                obj.Transparency = 1; obj.CastShadow = false
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Smoke") then
                obj.Enabled = false
            end
        end
    end
end

local function restoreNoFog()
    Lighting.FogEnd   = state.originalLighting.FogEnd
    Lighting.FogStart = state.originalLighting.FogStart
    for _, s in ipairs(state.savedAtmosphere) do
        pcall(function() s.obj.Density = s.Density; s.obj.Offset = s.Offset; s.obj.Haze = s.Haze end)
    end
    state.savedAtmosphere = {}
    for _, s in ipairs(state.savedColorCorrection) do
        pcall(function()
            s.obj.Enabled = s.Enabled; s.obj.Brightness = s.Brightness
            s.obj.Contrast = s.Contrast; s.obj.Saturation = s.Saturation
        end)
    end
    state.savedColorCorrection = {}
end

Lighting.Changed:Connect(function(prop)
    if not (state._fullbrightEnabled or state._nofogEnabled) then return end
    if state._fullbrightEnabled and (prop == "Brightness" or prop == "ClockTime" or prop == "Ambient" or prop == "OutdoorAmbient") then
        if Lighting.Brightness < 1.5 then applyFullBright() end
    end
end)

Lighting.ChildAdded:Connect(function(child)
    if not state._nofogEnabled then return end
    task.wait(0.1)
    if child:IsA("Atmosphere") then
        child.Density = 0; child.Offset = 0; child.Haze = 0
    elseif child:IsA("ColorCorrectionEffect") then
        child.Brightness = 0; child.Contrast = 0; child.Saturation = 0
    end
end)

local FV_DISCOVER_COOLDOWN = 8
local _fvLastDiscover      = 0
local _fvFailCount         = 0

local function fvDiscover()
    local char = lp.Character
    if not char then return end

    if state._fvController then
        local ok, c = pcall(rawget, state._fvController, "character")
        if ok and c == char then return end
        state._fvController = nil
    end

    local now = tick()
    if (now - _fvLastDiscover) < FV_DISCOVER_COOLDOWN then return end
    _fvLastDiscover = now

    if _fvFailCount > 3 then
        task.wait(0)
    end

    local ok, gc = pcall(getgc, true)
    if not ok or type(gc) ~= "table" then return end

    for _, v in ipairs(gc) do
        if type(v) == "table" then
            local ok1, fn1 = pcall(rawget, v, "_onVaultAnimation")
            local ok2, fn2 = pcall(rawget, v, "_cancelVaultTraversal")
            if ok1 and ok2 and type(fn1) == "function" and type(fn2) == "function" then
                local cOk, cVal = pcall(rawget, v, "character")
                if not cOk or not cVal or cVal == char then
                    state._fvController = v
                    _fvFailCount = 0
                    return
                end
            end
        end
    end
    _fvFailCount += 1
end

local function fvPatch()
    if not state.cfg.fastVault_enabled then return end
    if not state._fvController then return end

    local ctrl = state._fvController

    for _, p in ipairs(state._fvPatches) do
        if p.Module == ctrl then
            local okCur, cur = pcall(rawget, ctrl, p.Key)
            if okCur and cur == p.Wrapped then
                return
            end
            p.Original = cur
            local wrapped = function(...)
                if state.cfg.fastVault_enabled then
                    return true, "ready", 5
                end
                return p.Original(...)
            end
            if pcall(rawset, ctrl, p.Key, wrapped) then
                p.Wrapped = wrapped
            end
            return
        end
    end

    local ok, orig = pcall(rawget, ctrl, "_validateFastVault")
    if not ok or type(orig) ~= "function" then return end

    local wrapped = function(...)
        if state.cfg.fastVault_enabled then
            return true, "ready", 5
        end
        return orig(...)
    end
    local setOk = pcall(rawset, ctrl, "_validateFastVault", wrapped)
    if not setOk then return end
    table.insert(state._fvPatches, {
        Module = ctrl, Key = "_validateFastVault",
        Original = orig, Wrapped = wrapped,
    })
end

local function fvUnpatch()
    for _, p in ipairs(state._fvPatches) do
        local ok, cur = pcall(rawget, p.Module, p.Key)
        if ok and cur == p.Wrapped then
            pcall(rawset, p.Module, p.Key, p.Original)
        end
    end
    table.clear(state._fvPatches)
    state._fvController = nil
    _fvLastDiscover = 0
    _fvFailCount = 0
end

local function fsClearAttr()
    pcall(function()
        local c = lp.Character
        if c then c:SetAttribute("Flowstate", false) end
        lp:SetAttribute("Flowstate", false)
        for _, fn in ipairs({"climb_obsessing","climb_collisoning","climb_collisioning","climb_colliding"}) do
            local f = workspace:FindFirstChild(fn)
            if f then
                local m = f:FindFirstChild(lp.Name)
                if m then m:SetAttribute("Flowstate", false) end
            end
        end
    end)
end

local function fsApplyAttr()
    if not state.cfg.flowstate_enabled then return end
    local c = lp.Character
    if not c then return end
    local now = tick()

    if state._fsCD == 0 and state._fsOverrideEnd == 0 then
        state._fsOverrideEnd = now + 0.5
        state._fsCD = now + 0.5 + (state.cfg.flowstate_cooldown or 15)
    end

    local inOvr = now < state._fsOverrideEnd
    local inCD  = now < state._fsCD
    local val   = inOvr or not inCD

    if lp:GetAttribute("Flowstate") ~= val then lp:SetAttribute("Flowstate", val) end
    if c:GetAttribute("Flowstate") ~= val then c:SetAttribute("Flowstate", val) end
    for _, fn in ipairs({"climb_obsessing","climb_collisoning","climb_collisioning","climb_colliding"}) do
        local f = workspace:FindFirstChild(fn)
        if f then
            local m = f:FindFirstChild(lp.Name)
            if m and m:GetAttribute("Flowstate") ~= val then m:SetAttribute("Flowstate", val) end
        end
    end
end

local function fvHookAnim(char)
    if state._fvAnimConn then
        pcall(function() state._fvAnimConn:Disconnect() end)
        state._fvAnimConn = nil
    end
    if not char then return end
    task.spawn(function()
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        local anim = hum:WaitForChild("Animator", 5)
        if not anim then return end
        state._fvAnimConn = anim.AnimationPlayed:Connect(function(track)
            if not state.cfg.flowstate_enabled then return end
            local name = string.lower(track.Name or "")
            local id = track.Animation and tostring(track.Animation.AnimationId):lower() or ""
            if name:find("walking") or id:find("126081405469607") then return end
            if name:find("running") or name:find("finesse") or name:find("fast")
                or id:find("83873880822918") or id:find("136962284480779") then
                local now = tick()
                if now < state._fsOverrideEnd then return end
                if now < state._fsCD then return end
                state._fsOverrideEnd = now + 0.5
                state._fsCD = now + 0.5 + (state.cfg.flowstate_cooldown or 15)
            end
        end)
    end)
end

local function get2DScreenBounds(char)
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local cam = workspace.CurrentCamera
	if not cam then return nil end
	local head = char:FindFirstChild("Head")
	local topY    = head and (head.Position.Y + 1.5) or (root.Position.Y + 3.8)
	local bottomY = root.Position.Y - 3.8
	local rootPos    = root.Position
	local topWorld    = Vector3.new(rootPos.X, topY, rootPos.Z)
	local bottomWorld = Vector3.new(rootPos.X, bottomY, rootPos.Z)
	local topScreen, _    = cam:WorldToViewportPoint(topWorld)
	local bottomScreen, _ = cam:WorldToViewportPoint(bottomWorld)
	if topScreen.Z < 0 then return nil end
	local height = math.abs(bottomScreen.Y - topScreen.Y)
	if height < 10 then height = 10 end
	local width = math.clamp(height * 0.55, 14, 500)
	local x = topScreen.X - (width / 2)
	local y = topScreen.Y
	local realDist = (cam.CFrame.Position - rootPos).Magnitude
	return x, y, width, height, realDist
end

local function updateEspElem(elem, char, x, y, width, height, dist)
	local c = state.cfg
	local cam = workspace.CurrentCamera
	if elem.highlight then elem.highlight.Enabled = c.p_esp_showHighlight end
	if x then
		local vp = cam.ViewportSize
		local labelX    = math.clamp(x + (width/2) - 80, 0, vp.X - 160)
		local labelTopY = math.clamp(y - 22, 0, vp.Y - 30)
		local labelBotY = math.clamp(y + height + 3, 0, vp.Y - 20)
		local dynamicFont = math.clamp(math.floor(height * 0.20), 10, 14)
		elem.container.Visible = true
		elem.nameLabel.Visible = c.p_esp_showName
		local knocked = char:GetAttribute("Knocked")
		local okBot, botId   = pcall(function() return char:GetAttribute("BotId") end)
		local okBot2, botNetId = pcall(function() return char:GetAttribute("BotNetId") end)
		local isBot = (okBot and botId ~= nil) or (okBot2 and botNetId ~= nil)
		local displayName = isBot and ("[Bot] " .. char.Name) or char.Name
		elem.nameLabel.Text = displayName .. (knocked and "  [KNOCKED]" or "")
		if knocked then
			elem.nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			if elem.highlight then elem.highlight.OutlineColor = Color3.fromRGB(255, 80, 80) end
		else
			elem.nameLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
			if elem.highlight then elem.highlight.OutlineColor = Color3.fromRGB(0, 180, 255) end
		end
		elem.nameLabel.Position = UDim2.new(0, labelX, 0, labelTopY)
		elem.nameLabel.TextSize = dynamicFont
		elem.distLabel.Visible  = true
		elem.distLabel.Position = UDim2.new(0, labelX, 0, labelBotY)
		elem.distLabel.TextSize = math.max(9, dynamicFont - 1)
		elem.distLabel.Text     = string.format("[%d studs]", math.floor(dist or 0))
		if elem.itemLabel then
			local icon = nil
			for _, child in ipairs(char:GetChildren()) do
				if child:IsA("Model") or child:IsA("Tool") then
					local foundIcon = ITEM_ICONS[child.Name]
					if foundIcon then icon = foundIcon; break end
				end
			end
			if not icon then
				local ok2, eq = pcall(function() return char:GetAttribute("EquippedItem") end)
				if ok2 and eq then icon = ITEM_ICONS[tostring(eq)] end
			end
			if icon then
				local iconSize = 35
				local iconX = math.clamp(x + (width/2) - iconSize/2, 0, vp.X - iconSize)
				local iconY = math.clamp(y + height + 18, 0, vp.Y - iconSize)
				elem.itemLabel.Image    = icon
				elem.itemLabel.Size     = UDim2.new(0, iconSize, 0, iconSize)
				elem.itemLabel.Position = UDim2.new(0, iconX, 0, iconY)
				elem.itemLabel.Visible  = true
			else
				elem.itemLabel.Visible = false
			end
		end
	else
		elem.container.Visible = false
	end
end

local removePlayer2DESP
local removeKiller2DESP
local createKiller2DESP

local function createPlayer2DESP(char)
    removePlayer2DESP(char)
    local highlight = Instance.new("Highlight")
    highlight.Name                = "ROLL_HUB_Player_Highlight"
    highlight.FillColor           = Color3.fromRGB(0, 40, 80)
    highlight.OutlineColor        = Color3.fromRGB(0, 180, 255)
    highlight.FillTransparency    = 0.7
    highlight.OutlineTransparency = 0
    highlight.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee             = char
    highlight.Parent              = char
    local container = Instance.new("Frame")
    container.Name                   = "Player2DContainer"
    container.BackgroundTransparency = 1
    container.Size                   = UDim2.new(1, 0, 1, 0)
    container.Parent                 = espGui
    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size                   = UDim2.new(0, 160, 0, 16)
    nameLabel.TextColor3             = Color3.fromRGB(0, 200, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font                   = Enum.Font.GothamBold
    nameLabel.TextSize               = 13
    nameLabel.TextXAlignment         = Enum.TextXAlignment.Center
    nameLabel.Text                   = char.Name
    nameLabel.Parent                 = container
    local distLabel = Instance.new("TextLabel")
    distLabel.BackgroundTransparency = 1
    distLabel.Size                   = UDim2.new(0, 160, 0, 14)
    distLabel.TextColor3             = Color3.fromRGB(100, 220, 255)
    distLabel.TextStrokeTransparency = 0
    distLabel.Font                   = Enum.Font.GothamBold
    distLabel.TextSize               = 11
    distLabel.TextXAlignment         = Enum.TextXAlignment.Center
    distLabel.Text                   = ""
    distLabel.Parent                 = container
    local itemLabel = Instance.new("ImageLabel")
    itemLabel.BackgroundTransparency = 1
    itemLabel.Size                   = UDim2.new(0, 24, 0, 24)
    itemLabel.ScaleType              = Enum.ScaleType.Fit
    itemLabel.Image                  = ""
    itemLabel.Visible                = false
    itemLabel.Parent                 = container
    state.player2DEspElements[char] = {
        container = container,
        highlight = highlight,
        nameLabel = nameLabel,
        distLabel = distLabel,
        itemLabel = itemLabel,
    }
end

removeKiller2DESP = function(char)
	if state.killer2DEspElements[char] then
		pcall(function() state.killer2DEspElements[char].container:Destroy() end)
		pcall(function() state.killer2DEspElements[char].highlight:Destroy() end)
		state.killer2DEspElements[char] = nil
	end
end

createKiller2DESP = function(char)
	removeKiller2DESP(char)
	local highlight = Instance.new("Highlight")
	highlight.Name                = "ROLL_HUB_Killer_Highlight"
	highlight.FillColor           = Color3.fromRGB(80, 0, 0)
	highlight.OutlineColor        = Color3.fromRGB(255, 50, 50)
    highlight.FillTransparency    = 0.7
    highlight.OutlineTransparency = 0
    highlight.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee             = char
	highlight.Parent              = char
	local container = Instance.new("Frame")
	container.Name                   = "Killer2DContainer"
	container.BackgroundTransparency = 1
	container.Size                   = UDim2.new(1, 0, 1, 0)
	container.Parent                 = espGui
	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size                   = UDim2.new(0, 160, 0, 16)
	nameLabel.TextColor3             = Color3.fromRGB(255, 50, 50)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font                   = Enum.Font.GothamBold
	nameLabel.TextSize               = 13
	nameLabel.TextXAlignment         = Enum.TextXAlignment.Center
	nameLabel.Text                   = "[Killer] " .. char.Name
	nameLabel.Parent                 = container
	local distLabel = Instance.new("TextLabel")
	distLabel.BackgroundTransparency = 1
	distLabel.Size                   = UDim2.new(0, 160, 0, 14)
	distLabel.TextColor3             = Color3.fromRGB(255, 150, 150)
	distLabel.TextStrokeTransparency = 0
	distLabel.Font                   = Enum.Font.GothamBold
	distLabel.TextSize               = 11
	distLabel.TextXAlignment         = Enum.TextXAlignment.Center
	distLabel.Text                   = ""
	distLabel.Parent                 = container
	state.killer2DEspElements[char] = {
		container = container,
		highlight = highlight,
		nameLabel = nameLabel,
		distLabel = distLabel,
	}
end

removePlayer2DESP = function(char)
	if state.player2DEspElements[char] then
		pcall(function() state.player2DEspElements[char].container:Destroy() end)
		pcall(function() state.player2DEspElements[char].highlight:Destroy() end)
		state.player2DEspElements[char] = nil
	end
end

local function removeSCPESP(model)
	local e = state.scpEspElements[model]
	if not e then return end
	pcall(function() e.highlight:Destroy() end)
	state.scpEspElements[model] = nil
end

local function createSCPESP(model)
	if state.scpEspElements[model] then return end
	local root = model.PrimaryPart
		or model:FindFirstChildOfClass("MeshPart")
		or model:FindFirstChildOfClass("BasePart")
	if not root then return end
	local hl = Instance.new("Highlight")
	hl.Name                = "ROLL_HUB_SCP_Highlight"
	hl.FillColor           = Color3.fromRGB(50, 0, 80)
	hl.OutlineColor        = Color3.fromRGB(180, 80, 255)
	hl.FillTransparency    = 0.5
	hl.OutlineTransparency = 0
	hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee             = model
	hl.Parent              = model
	state.scpEspElements[model] = { highlight = hl }
end

local function isValidSCP(name)
    local lower = string.lower(name)
    local num = lower:match("^scp[%-%s]?(%d+)$")
    if num then
        local n = tonumber(num)
        return n and n >= 1 and n <= 8
    end
    return false
end

local function scanSCPs()
    if os.clock() - state._scpScanTime < 2 then return end
    state._scpScanTime = os.clock()
    local found = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and isValidSCP(obj.Name) then
            found[obj] = true
            createSCPESP(obj)
        end
    end
    for model in pairs(state.scpEspElements) do
        if not found[model] then removeSCPESP(model) end
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    if not state.bearTrapEspEnabled then return end
    if not obj:IsA("Model") then return end
    local lower = string.lower(obj.Name)
    if lower == "beartrap" or lower == "bear_trap" then
        task.wait(0.1)
        createBearTrapESP(obj)
    end
end)

Workspace.DescendantRemoving:Connect(function(obj)
    if state.bearTrapEspElements[obj] then removeBearTrapESP(obj) end
end)

local function removeGenESP(model)
    local e = state.genEspElements[model]
    if not e then return end
    pcall(function() e.highlight:Destroy() end)
    pcall(function() e.nameText:Remove() end)
    pcall(function() e.infoText:Remove() end)
    pcall(function() e.barBg:Remove() end)
    pcall(function() e.barFill:Remove() end)
    state.genEspElements[model] = nil
end

local function createGenESP(model, index)
    if state.genEspElements[model] then return end
    local root = model:FindFirstChild("RootPart")
        or model.PrimaryPart
        or model:FindFirstChildOfClass("MeshPart")
        or model:FindFirstChildOfClass("BasePart")
    if not root then return end
    local nameText = Drawing.new("Text")
    nameText.Visible   = false; nameText.Text = model.Name; nameText.Size = 14
    nameText.Font      = Drawing.Fonts.Plex; nameText.Color = Color3.fromRGB(255, 255, 255)
    nameText.Outline   = true; nameText.Center = true
    local infoText = Drawing.new("Text")
    infoText.Visible   = false; infoText.Text = "0% | idle"; infoText.Size = 12
    infoText.Font      = Drawing.Fonts.Plex; infoText.Color = Color3.fromRGB(200, 200, 200)
    infoText.Outline   = true; infoText.Center = true
    local barBg = Drawing.new("Square")
    barBg.Visible = false; barBg.Filled = true; barBg.Color = Color3.fromRGB(40, 40, 40)
    barBg.Transparency = 0.4; barBg.Thickness = 1
    local barFill = Drawing.new("Square")
    barFill.Visible = false; barFill.Filled = true; barFill.Color = Color3.fromRGB(255, 255, 255)
    barFill.Transparency = 1; barFill.Thickness = 1
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(60, 50, 0); hl.OutlineColor = Color3.fromRGB(255, 210, 0)
    hl.FillTransparency = 0.6; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model; hl.Parent = model
    state.genEspElements[model] = {
        highlight = hl, nameText = nameText, infoText = infoText,
        barBg = barBg, barFill = barFill, rootPart = root,
    }
end

local function initialScanGen()
    if state._genScanCache and os.clock() - state._genScanTime < 3 then return end
    state._genScanTime = os.clock()
    local found = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Generator" then
            found[obj] = true
            if not state.genEspElements[obj] then
                state._genCounter = state._genCounter + 1
                createGenESP(obj, state._genCounter)
            end
        end
    end
    local resources = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("resources")
    if resources then
        local generatorsFolder = resources:FindFirstChild("Generators")
        if generatorsFolder then
            for _, obj in ipairs(generatorsFolder:GetChildren()) do
                if obj:IsA("Model") and obj.Name == "Generator" then
                    found[obj] = true
                    if not state.genEspElements[obj] then
                        state._genCounter = state._genCounter + 1
                        createGenESP(obj, state._genCounter)
                    end
                end
            end
        end
    end
    for model in pairs(state.genEspElements) do
        if not found[model] then removeGenESP(model) end
    end
    state._genScanCache = found
end

local function removeBearTrapESP(model)
    local e = state.bearTrapEspElements[model]
    if not e then return end
    pcall(function() e.highlight:Destroy() end)
    pcall(function() e.nameText:Remove() end)
    pcall(function() e.distText:Remove() end)
    state.bearTrapEspElements[model] = nil
end

local function createBearTrapESP(model)
    if state.bearTrapEspElements[model] then return end
    local root = model:FindFirstChild("RootPart")
        or model.PrimaryPart
        or model:FindFirstChildOfClass("MeshPart")
        or model:FindFirstChildOfClass("BasePart")
    if not root then return end
    local nameText = Drawing.new("Text")
    nameText.Visible = false; nameText.Text = "BearTrap"; nameText.Size = 14
    nameText.Font = Drawing.Fonts.Plex; nameText.Color = Color3.fromRGB(255,255,255)
    nameText.Outline = true; nameText.Center = true
    local distText = Drawing.new("Text")
    distText.Visible = false; distText.Text = ""; distText.Size = 12
    distText.Font = Drawing.Fonts.Plex; distText.Color = Color3.fromRGB(200,200,200)
    distText.Outline = true; distText.Center = true
    local barBg = Drawing.new("Square")
    barBg.Visible = false; barBg.Filled = true; barBg.Color = Color3.fromRGB(40,40,40)
    barBg.Transparency = 0.4; barBg.Thickness = 1
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(80, 20, 0); hl.OutlineColor = Color3.fromRGB(255, 100, 0)
    hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model; hl.Parent = model
    state.bearTrapEspElements[model] = {
        highlight = hl, nameText = nameText, distText = distText, barBg = barBg, rootPart = root,
    }
end

local function initialScanBearTrap()
    if os.clock() - state._bearTrapScanTime < 0.5 then return end
    state._bearTrapScanTime = os.clock()
    local found = {}
    local mapFolder = workspace:FindFirstChild("Map")
    if not mapFolder then return end
    for _, obj in ipairs(mapFolder:GetDescendants()) do
        if obj:IsA("Model") then
            local lower = string.lower(obj.Name)
            if lower == "beartrap" or lower == "bear_trap" then
                found[obj] = true
                if not state.bearTrapEspElements[obj] then createBearTrapESP(obj) end
            end
        end
    end
    for model in pairs(state.bearTrapEspElements) do
        if not found[model] then removeBearTrapESP(model) end
    end
end

local function removePumpkinESP(model)
    local e = state.pumpkinEspElements[model]
    if not e then return end
    pcall(function() e.highlight:Destroy() end)
    state.pumpkinEspElements[model] = nil
end

local function createPumpkinESP(model)
    if state.pumpkinEspElements[model] then return end
    local root = model.PrimaryPart
        or model:FindFirstChildOfClass("MeshPart")
        or model:FindFirstChildOfClass("BasePart")
    if not root then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(80, 35, 0); hl.OutlineColor = Color3.fromRGB(255, 140, 0)
    hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model; hl.Parent = model
    state.pumpkinEspElements[model] = { highlight = hl, rootPart = root }
end

local function scanPumpkins()
    if os.clock() - state._pumpkinScanTime < 3 then return end
    state._pumpkinScanTime = os.clock()
    local pumpkinFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Pumpkins")
    if not pumpkinFolder then return end
    local found = {}
    for _, obj in ipairs(pumpkinFolder:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            found[obj] = true
            if not state.pumpkinEspElements[obj] then createPumpkinESP(obj) end
        end
    end
    for model in pairs(state.pumpkinEspElements) do
        if not found[model] then removePumpkinESP(model) end
    end
end

local function addBoxOutline(part)
    if part:FindFirstChildOfClass("BoxHandleAdornment") then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = part; box.Color3 = Color3.fromRGB(255,255,255); box.Transparency = 0.5
    box.Size = part.Size; box.AlwaysOnTop = true; box.ZIndex = 0; box.Parent = part
end

local function addHighlight(parent, fillColor, outlineColor)
    if parent:FindFirstChildOfClass("Highlight") then return end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = fillColor or Color3.fromRGB(0,0,0)
    highlight.OutlineColor = outlineColor or Color3.fromRGB(255,255,255)
    highlight.FillTransparency = 0.5; highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = parent; highlight.Parent = parent
end

local function removeVaultESP(obj)
    local e = state.vaultEspElements[obj]
    if not e then return end
    pcall(function() e.highlight:Destroy() end)
    pcall(function()
        local box = obj:FindFirstChildOfClass("BoxHandleAdornment")
        if box then box:Destroy() end
    end)
    state.vaultEspElements[obj] = nil
end

local function removePalletESP(model)
    local e = state.palletEspElements[model]
    if not e then return end
    pcall(function() e.highlight:Destroy() end)
    state.palletEspElements[model] = nil
end

local function createVaultESP(obj)
    if state.vaultEspElements[obj] then return end
    if not obj or not obj.Parent then return end
    addBoxOutline(obj)
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(0,0,0); hl.OutlineColor = Color3.fromRGB(255,255,255)
    hl.FillTransparency = 0.8; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = obj; hl.Parent = obj
    state.vaultEspElements[obj] = { highlight = hl }
end

local function createPalletESP(model)
    if state.palletEspElements[model] then return end
    if not model or not model.Parent then return end
    addHighlight(model)
    local hl = model:FindFirstChildOfClass("Highlight")
    state.palletEspElements[model] = { highlight = hl }
end

local function isPalletObj(obj)
    if not obj:IsA("Model") then return false end
    return string.lower(obj.Name) == "newpallet"
end

local function isVaultObj(obj)
    if obj.ClassName == "Part" and obj.Name == "Bottom" then
        if obj.Parent and obj.Parent.Name == "Window" then return true end
    end
    return false
end

local function clearMapEspConns()
    for _, c in ipairs(state._mapEspConns) do pcall(c.Disconnect, c) end
    table.clear(state._mapEspConns)
end

local function setupMapEspListeners(mapFolder)
    clearMapEspConns()
    local conn = mapFolder.DescendantAdded:Connect(function(obj)
        task.wait()
        if state.vaultEspEnabled and isVaultObj(obj) then createVaultESP(obj) end
        if state.palletEspEnabled and isPalletObj(obj) then createPalletESP(obj) end
    end)
    table.insert(state._mapEspConns, conn)
    local conn2 = mapFolder.DescendantRemoving:Connect(function(obj)
        if state.vaultEspElements[obj] then removeVaultESP(obj) end
        if state.palletEspElements[obj] then removePalletESP(obj) end
    end)
    table.insert(state._mapEspConns, conn2)
end

local function scanVaultAndPallet()
    local mapFolder = workspace:FindFirstChild("Map")
    if not mapFolder then return end
    setupMapEspListeners(mapFolder)
    if state.vaultEspEnabled then
        for _, obj in ipairs(mapFolder:GetDescendants()) do
            if isVaultObj(obj) then createVaultESP(obj) end
        end
    else
        for obj in pairs(state.vaultEspElements) do removeVaultESP(obj) end
    end
    if state.palletEspEnabled then
        for _, obj in ipairs(mapFolder:GetDescendants()) do
            if isPalletObj(obj) then createPalletESP(obj) end
        end
    else
        for model in pairs(state.palletEspElements) do removePalletESP(model) end
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Map" then
        task.wait(1)
        for obj in pairs(state.vaultEspElements) do removeVaultESP(obj) end
        for model in pairs(state.palletEspElements) do removePalletESP(model) end
        if state.vaultEspEnabled or state.palletEspEnabled then pcall(scanVaultAndPallet) end
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child.Name == "Map" then clearMapEspConns() end
end)
pcall(scanVaultAndPallet)

local function refreshPallets()
	local out, byParent = {}, {}
	for _, d in ipairs(Workspace:GetDescendants()) do
		local ok, nm = pcall(function() return d.Name end)
		if not ok then continue end
		if (nm == "PalletPoint" and d.ClassName == "Part") or (string.lower(nm):find("pallet") and d:IsA("BasePart")) then
			local par = d.Parent
			if par then
				local e = byParent[par]
				if not e then
					local board = par:FindFirstChild("PrimaryPartPallet") or par:FindFirstChild("Board") or d
					local boardId
					pcall(function() boardId = board:GetDebugId(0) end)
					if not boardId then boardId = tostring(board) end
					e = { board = board, pts = {}, id = boardId }
					byParent[par] = e
					out[#out + 1] = e
				end
				local p = d.Position
				if p then e.pts[#e.pts + 1] = { p.X, p.Y, p.Z } end
			end
		end
	end
	pallets = out
end

local function refreshKiller()
	local killers = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and isKillerPlayer(plr) then
			local ch = plr.Character
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			if root then killers[#killers + 1] = root end
		end
	end
	state.killerRoots = killers
	local me = myRoot()
	local mp = me and me.Position
	if not mp then state.pStat.killD = nil; return end
	local best
	for i = 1, #state.killerRoots do
		local kp = state.killerRoots[i].Position
		if kp then
			local dx,dy,dz = mp.X-kp.X, mp.Y-kp.Y, mp.Z-kp.Z
			local d2 = dx*dx+dy*dy+dz*dz
			if not best or d2 < best then best = d2 end
		end
	end
	state.pStat.killD = best and math.sqrt(best) or nil
end

pcall(refreshPallets); pcall(refreshKiller)
task.spawn(function() while state.running do pcall(refreshPallets); task.wait(1.5) end end)
task.spawn(function() while state.running do pcall(refreshKiller); task.wait(0.3) end end)

local function getSkillCooldownState()
	local now = tick()
	if (now - state._skillCDLastCheck) < 2 then return state._skillCDCache end
	state._skillCDLastCheck = now
	local ok, result = pcall(function()
		local pg   = Players.LocalPlayer:FindFirstChild("PlayerGui")
		local sla  = pg  and pg:FindFirstChild("Slasher")
		local gen  = sla and sla:FindFirstChild("bottom left")
		local mv2  = gen and gen:FindFirstChild("Move2")
		local bar  = mv2 and mv2:FindFirstChild("Bar")
		local grad = bar and bar:FindFirstChild("UIGradient")
		if not grad then return false end
		return grad.Offset.Y == 0
	end)
	state._skillCDCache = ok and result
	return state._skillCDCache
end

local function calculateSpearAim(origin, targetPos, targetVel, overrideSpeed)
    if typeof(overrideSpeed) ~= "number" then overrideSpeed = nil end
    local cdReady = (type(getSkillCooldownState) == "function" and getSkillCooldownState()) or false
    local speed = overrideSpeed or (cdReady and SPEAR_SPEED_READY or SPEAR_SPEED_CD)
    local g = cdReady and SPEAR_GRAV_READY or SPEAR_GRAV_CD
    local adjustedTargetPos = targetPos + Vector3.new(0, AIM_HEIGHT_OFFSET, 0)
    local diff = adjustedTargetPos - origin
    local dist = diff.Magnitude
    if dist < 0.1 then return adjustedTargetPos end
    local t = dist / math.max(speed, 1)
    for _ = 1, 3 do
        local dropEst = 0.5 * g * (t * t)
        local aimPos = Vector3.new(adjustedTargetPos.X, adjustedTargetPos.Y + dropEst, adjustedTargetPos.Z)
        t = (aimPos - origin).Magnitude / math.max(speed, 1)
    end
    local drop = 0.5 * g * (t * t)
    return Vector3.new(adjustedTargetPos.X, adjustedTargetPos.Y + drop, adjustedTargetPos.Z)
end

local function getSpearTarget()
	local me = myRoot()
	if not me then return nil, nil, nil end
	local cam = workspace.CurrentCamera
	if not cam then return nil, nil, nil end
	local mousePos = UserInputService:GetMouseLocation()
	local best, bestChar, minDist = nil, nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Character then
			local char = plr.Character
			local root = char:FindFirstChild("HumanoidRootPart")
			local hum  = char:FindFirstChildOfClass("Humanoid")
			local knocked = char:GetAttribute("Knocked")
			if root and hum and hum.Health > 0 and not knocked then
				if not isKillerPlayer(plr) and not isSpectator() then
					local screenPos, onScreen = cam:WorldToViewportPoint(root.Position)
					if onScreen and screenPos.Z > 0 then
						local dx = screenPos.X - mousePos.X
						local dy = screenPos.Y - mousePos.Y
						local screenDist = math.sqrt(dx*dx + dy*dy)
						if screenDist < minDist then
							minDist  = screenDist
							best     = root
							bestChar = char
						end
					end
				end
			end
		end
	end
	return best, "survivor", bestChar
end

local function doRightClick()
    pcall(function()
        if typeof(mouse2click) == "function" then mouse2click(); return end
        if typeof(mouse2press) == "function" and typeof(mouse2release) == "function" then
            mouse2press(); mouse2release(); return
        end
        VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
    end)
end

local function ap_hasParryingDagger()
    local ch = lp.Character
    if not ch then return false end
    for _, o in ipairs(ch:GetChildren()) do
        if o.Name == "Parrying Dagger" then return true end
    end
    return false
end

local function ap_isDowned(char)
    if not char then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    return h and h.Health <= 0
end

local function ap_safeToParry(char)
    if not state.cfg.ap_safety then return true end
    local ci = char and char:FindFirstChild("CheckInterractable")
    if not ci then return true end
    for _, a in ipairs({"isVaulting","isRepairing","isUnhooking","isHealing","isSliding"}) do
        if ci:GetAttribute(a) == true then return false end
    end
    return true
end

local function ap_killerFacingMe(kRoot)
    local me = myRoot()
    if not kRoot or not me then return false end
    local d = me.Position - kRoot.Position
    local flat = Vector3.new(d.X, 0, d.Z)
    if flat.Magnitude < 0.15 then return true end
    local look = Vector3.new(kRoot.CFrame.LookVector.X, 0, kRoot.CFrame.LookVector.Z)
    if look.Magnitude < 0.05 then return false end
    return look.Unit:Dot(flat.Unit) >= (state.cfg.ap_faceTh or 0.35)
end

local function ap_tapParry()
    if state.cfg.ap_cdFromServer and state.ap_parryCD then return end
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then return end
    local mob   = pg:FindFirstChild("Survivor-mob")
    local ctrl  = mob and mob:FindFirstChild("Controls")
    local guiMob = ctrl and ctrl:FindFirstChild("Gui-mob")
    if not guiMob or not guiMob.Visible then return end
    if type(firesignal) ~= "function" then
        pcall(function()
            if typeof(mouse2click) == "function" then mouse2click(); return end
            if typeof(mouse2press) == "function" and typeof(mouse2release) == "function" then
                mouse2press(); mouse2release(); return
            end
            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
        end)
        return
    end
    pcall(function()
        firesignal(guiMob.MouseButton1Down)
        task.wait(0.02)
        firesignal(guiMob.MouseButton1Up)
    end)
end

local function ap_triggerCrouch()
    pcall(function()
        local pg  = lp:FindFirstChild("PlayerGui")
        local mob = pg and pg:FindFirstChild("Survivor-mob")
        local ct  = mob and mob:FindFirstChild("Controls")
        local b   = ct and ct:FindFirstChild("crouch")
        local ic  = b and b:FindFirstChild("icon")
        local pr  = ic and ic.Parent
        if pr and pr:IsA("GuiButton") and pr.Visible and type(firesignal)=="function" then
            firesignal(pr.MouseButton1Click); task.wait(1.4)
            firesignal(pr.MouseButton1Click); return
        end
        VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.LeftControl, false, game)
        task.wait(1.4)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
    end)
end

local function ap_onKillerAnimPlayed(track, kRoot)
    if not state.cfg.ap_enabled then return end
    local animId = getAnimAssetId(track)
    if not animId then return end

    if animId == AP_ABYSSAL_S1_ID then return end

    if not HIT_ANIM_IDS[animId] then return end

    local char = lp.Character
    if not char or ap_isDowned(char) then return end
    if not ap_safeToParry(char) then return end
    if not ap_hasParryingDagger() then return end
    if not (kRoot and kRoot.Parent) then return end

    local me = myRoot()
    if not me then return end

    local dist = (me.Position - kRoot.Position).Magnitude
    local radius = state.cfg.ap_range or 12
    if radius + 6 < dist then return end

    local ideal = radius + 2
    local function fire()
        if state.ap_parryCD then return true end
        if ap_isDowned(char) then return true end
        if not (me.Parent and kRoot.Parent) then return true end
        if (me.Position - kRoot.Position).Magnitude > ((state.cfg.ap_mode == "Aggressive") and radius+5 or ideal) then return false end
        if not ap_killerFacingMe(kRoot) then return false end
        local now = tick()
        if (now - state.ap_lastParryTime) < 0.08 then return false end
        state.ap_lastParryTime = now
        task.spawn(ap_tapParry)
        return true
    end

    if state.cfg.ap_mode == "Aggressive" then
        if fire() then return end
        local start = os.clock()
        local conn; conn = RunService.Heartbeat:Connect(function()
            if os.clock() - start >= 0.85 or fire() then
                if conn then conn:Disconnect() end
            end
        end)
    else
        if dist <= ideal and ap_killerFacingMe(kRoot) then
            fire(); return
        end
        local start = os.clock()
        local conn; conn = RunService.Heartbeat:Connect(function()
            if os.clock() - start >= 0.28 and not fire() then
                if conn then conn:Disconnect() end
            end
        end)
    end
end

local function ap_attachKiller(kRoot)
    local char = kRoot and kRoot.Parent
    if not char or state.ap_monitoredKillers[char] then return end
    state.ap_monitoredKillers[char] = true
    state.ap_animConns[char] = {}
    local attached = false
    local function doAttach()
        if attached then return end
        local anim = findAnimator(char)
        if not anim then return end
        attached = true
        local c1 = anim.AnimationPlayed:Connect(function(t)
            ap_onKillerAnimPlayed(t, kRoot)
        end)
        table.insert(state.ap_animConns[char], c1)
        local c2 = char.DescendantAdded:Connect(function(o)
            if o:IsA("Animator") then
                state.ap_monitoredKillers[char] = nil
                task.wait(0.05); ap_attachKiller(kRoot)
            end
        end)
        table.insert(state.ap_animConns[char], c2)
    end
    doAttach()
    if not attached then
        local c2 = char.DescendantAdded:Connect(function(o)
            if o:IsA("Animator") then task.wait(0.05); doAttach() end
        end)
        table.insert(state.ap_animConns[char], c2)
    end
    char.AncestryChanged:Connect(function()
        if char.Parent then return end
        for _, c in ipairs(state.ap_animConns[char] or {}) do pcall(c.Disconnect, c) end
        state.ap_animConns[char] = nil
        state.ap_monitoredKillers[char] = nil
    end)
end

task.spawn(function()
    while state.running do
        if state.cfg.ap_enabled then
            pcall(function()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if isKillerPlayer(plr) then
                        local ch = plr.Character
                        local rt = ch and ch:FindFirstChild("HumanoidRootPart")
                        if rt then ap_attachKiller(rt) end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

task.spawn(function()
    local rs  = ReplicatedStorage:WaitForChild("Remotes", 10)
    local it  = rs and rs:WaitForChild("Items", 10)
    local pd  = it and it:WaitForChild("Parrying Dagger", 10)
    local res = pd and pd:WaitForChild("parryResult", 10)
    if not res then return end
    res.OnClientEvent:Connect(function(arg, arg2)
        local cd = tonumber(arg2) or (arg == true and 90 or 60)
        state.ap_parryCD    = true
        state.ap_parryCDTok = state.ap_parryCDTok + 1
        local tok = state.ap_parryCDTok
        if state.ap_parryCDThr then pcall(function() task.cancel(state.ap_parryCDThr) end) end
        state.ap_parryCDThr = task.delay(cd, function()
            if state.ap_parryCDTok == tok then state.ap_parryCD = false end
        end)
        OasisUI:Notify({ Title="Auto Parry",
            Content=string.format("Parry! CD: %ds", math.floor(cd)), Duration=3 })
    end)
end)

local ap_circle = Instance.new("CylinderHandleAdornment")
ap_circle.Name = "ROLL_HUB_ParryRangeCircle"
ap_circle.Height = 0.05; ap_circle.Transparency = 1; ap_circle.AlwaysOnTop = false
pcall(function() ap_circle.Parent = game:GetService("CoreGui") end)
if not ap_circle.Parent then ap_circle.Parent = lp:WaitForChild("PlayerGui") end

local _ap_lastCircleRoot, _ap_lastCircleR = nil, -1
RunService.Heartbeat:Connect(function()
    if not state.cfg.ap_enabled or not state.cfg.ap_showCircle then
        if ap_circle.Transparency ~= 1 then ap_circle.Transparency = 1 end
        return
    end
    local hrp = myRoot()
    if not hrp then ap_circle.Transparency = 1; return end
    local r = state.cfg.ap_range or 12
    if hrp ~= _ap_lastCircleRoot or r ~= _ap_lastCircleR then
        _ap_lastCircleRoot, _ap_lastCircleR = hrp, r
        ap_circle.Adornee     = hrp
        ap_circle.CFrame      = CFrame.new(0, -3, 0) * CFrame.Angles(math.rad(90), 0, 0)
        ap_circle.Radius      = r
        ap_circle.InnerRadius = math.max(0.1, r - 0.15)
    end
    ap_circle.Color3 = state.ap_parryCD and Color3.fromRGB(100,100,100) or (state.cfg.ap_circleColor or Color3.fromRGB(0,255,200))
    ap_circle.Transparency = state.ap_parryCD and 0.55 or 0.25
end)

local function startFlashlightAim()
    if state.flashlightAimConn then return end
    state.flashlightAimConn = RunService.RenderStepped:Connect(function(dt)
        if not state.flashlightAimEnabled then return end
        if not isSurvivor() then return end
        local ch = lp.Character
        if not ch then return end
        local hasFlashlight = ch:FindFirstChild("Flashlight")
        if not hasFlashlight then
            if not state._flashlightNotified then
                state._flashlightNotified = true
                OasisUI:Notify({ Title = "Flashlight Aimbot", Content = "No Flashlight found in your inventory!", Duration = 5 })
            end
            return
        end
        state._flashlightNotified = false
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local me = myRoot()
        if not me then return end
        local bestRoot = nil
        local bestDist = math.huge
        local maxDist  = state.cfg.flashlightAim_maxDist or 30
        for _, kRoot in ipairs(state.killerRoots) do
            if kRoot and kRoot.Parent then
                local d = (me.Position - kRoot.Position).Magnitude
                if d < bestDist and d <= maxDist then
                    bestDist = d; bestRoot = kRoot
                end
            end
        end
        if not bestRoot then return end
        local killerChar = bestRoot.Parent
        local head = killerChar and killerChar:FindFirstChild("Head")
        local aimTarget = (head or bestRoot).Position
        local camCF = cam.CFrame
        local targetCF = CFrame.lookAt(camCF.Position, aimTarget)
        cam.CFrame = camCF:Lerp(targetCF, math.min(dt * 25, 1))
    end)
end

local function stopFlashlightAim()
	if state.flashlightAimConn then
		state.flashlightAimConn:Disconnect()
		state.flashlightAimConn = nil
	end
end

startFlashlightAim()

local function createMeESP()
    local char = lp.Character
    if not char then return end
    if state.render.meHighlight then
        pcall(function() state.render.meHighlight:Destroy() end)
        state.render.meHighlight = nil
    end

    local hl = Instance.new("Highlight")
    hl.Name                = "ROLL_HUB_Me_Highlight"
    hl.FillColor           = Color3.fromRGB(0, 150, 255)
    hl.OutlineColor        = Color3.fromRGB(0, 200, 255)
    hl.FillTransparency    = 1
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee             = char
    hl.Parent              = char
    state.render.meHighlight = hl
end

local function removeMeESP()
    if state.render.meHighlight then
        pcall(function() state.render.meHighlight:Destroy() end)
        state.render.meHighlight = nil
    end
end

local function makePFAgentParams()
	local hum  = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not hum or not root then
		return { AgentHeight = 5, AgentRadius = 2, AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 2 }
	end
	return {
		AgentHeight    = math.max(2, hum.HipHeight + root.Size.Y) + 0.5,
		AgentRadius    = 2, AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 2,
	}
end

local function pfClearDots()
	for _, v in ipairs(pfDotFolder:GetChildren()) do v:Destroy() end
end

local function pfCreateDot(position, index, isLast)
	local dot = Instance.new("Part")
	dot.Name = "Dot_" .. index; dot.Size = Vector3.new(0.4, 0.4, 0.4)
	dot.Shape = Enum.PartType.Ball; dot.Material = Enum.Material.Neon
	dot.Anchored = true; dot.CanCollide = false; dot.CastShadow = false
	dot.Position = position + Vector3.new(0, 0.5, 0)
	dot.Color = isLast and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 200, 100)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 30, 0, 20); bb.StudsOffset = Vector3.new(0, 0.8, 0)
	bb.AlwaysOnTop = true; bb.Parent = dot
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1); lbl.BackgroundTransparency = 1
	lbl.Text = tostring(index); lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.TextScaled = true; lbl.Font = Enum.Font.GothamBold; lbl.Parent = bb
	dot.Parent = pfDotFolder
end

local function pfHighlightDot(index)
	local dot = pfDotFolder:FindFirstChild("Dot_" .. index)
	if dot then dot.Color = Color3.fromRGB(255, 220, 0); dot.Size = Vector3.new(0.7, 0.7, 0.7) end
end

local function pfRemoveDot(index)
	local dot = pfDotFolder:FindFirstChild("Dot_" .. index)
	if dot then dot:Destroy() end
end

local function pfSnapToGround(pos, excludeModel)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character, pfDotFolder, excludeModel }
	local origin = pos + Vector3.new(0, 6, 0)
	local result = workspace:Raycast(origin, Vector3.new(0, -30, 0), rayParams)
	if result then return result.Position + Vector3.new(0, 1.5, 0) end
	return pos
end

local function pfGetPumpkins()
	local list = {}
	local mapFolder = workspace:FindFirstChild("Map")
	if not mapFolder then return list end
	local pumpkins = mapFolder:FindFirstChild("Pumpkins")
	if not pumpkins then return list end
	for _, obj in ipairs(pumpkins:GetChildren()) do
		if obj:IsA("Model") then
			local hb = obj:FindFirstChild("HB")
			if hb and hb:IsA("BasePart") then
				local existing = obj:FindFirstChild("_PF_Target")
				local target = existing
				if not target then
					target = Instance.new("Part")
					target.Name = "_PF_Target"; target.Size = Vector3.new(1,1,1)
					target.Anchored = true; target.CanCollide = false
					target.Transparency = 1; target.Position = hb.Position + Vector3.new(0,3,0)
					target.Parent = obj
				end
				list[#list + 1] = { model = obj, hb = hb, target = target, manualTarget = existing ~= nil }
			end
		end
	end
	table.sort(list, function(a, b)
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return false end
		return (root.Position - a.hb.Position).Magnitude < (root.Position - b.hb.Position).Magnitude
	end)
	return list
end

local function pfBuildTargetPos(pumpkin, attempt)
	local a = PF_ATTEMPT_ANGLES[((attempt - 1) % #PF_ATTEMPT_ANGLES) + 1]
	local root = character:FindFirstChild("HumanoidRootPart")
	local basePos
	if pumpkin.manualTarget then
		basePos = pumpkin.target.Position
	else
		local dir = root and (root.Position - pumpkin.hb.Position) or Vector3.new(1, 0, 0)
		dir = Vector3.new(dir.X, 0, dir.Z)
		if dir.Magnitude > 0 then dir = dir.Unit end
		local offset = 4 + math.max(pumpkin.hb.Size.X, pumpkin.hb.Size.Z) * 0.5
		basePos = pumpkin.hb.Position + (dir * offset)
	end
	if a ~= 0 then
		local rel = basePos - pumpkin.hb.Position
		local rot = CFrame.fromAxisAngle(Vector3.yAxis, a)
		basePos = pumpkin.hb.Position + rot:VectorToWorldSpace(rel)
	end
	return pfSnapToGround(basePos, pumpkin.model)
end

local function pfStartStuck()
	state.pfStuckGen += 1
	state.pfStuckSignal = false
	local gen = state.pfStuckGen
	task.spawn(function()
		local root    = character:FindFirstChild("HumanoidRootPart")
		local lastPos = root and root.Position or Vector3.zero
		while gen == state.pfStuckGen do
			task.wait(PF_STUCK_TIMEOUT)
			if gen ~= state.pfStuckGen then return end
			root = character:FindFirstChild("HumanoidRootPart")
			if not root then return end
			local moved = (root.Position - lastPos).Magnitude
			if moved < PF_STUCK_THRESHOLD then
				if gen == state.pfStuckGen then
					state.pfStuckSignal = true
				end
				return
			end
			lastPos = root.Position
		end
	end)
end

local function pfStopStuck()
	state.pfStuckGen += 1
	state.pfStuckSignal = false
end

local function pfComputePath(startPos, targetPos)
	local path = PathfindingService:CreatePath(makePFAgentParams())
	local ok = pcall(function() path:ComputeAsync(startPos, targetPos) end)
	if ok and path.Status == Enum.PathStatus.Success then return path end
	return nil
end

local function pfFollowWaypoints(path)
	local hum  = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return false end
	local waypoints = path:GetWaypoints()
	pfClearDots()
	for i, wp in ipairs(waypoints) do pfCreateDot(wp.Position, i, i == #waypoints) end
	local blocked = false
	local blockedConn = path.Blocked:Connect(function() blocked = true end)
	pfStartStuck()
	for i, wp in ipairs(waypoints) do
		if state.pfStuckSignal or blocked then
			blockedConn:Disconnect(); pfStopStuck(); pfClearDots()
			task.wait(0.1); return false
		end
		if wp.Action == Enum.PathWaypointAction.Jump then continue end
		pfHighlightDot(i)
		hum:MoveTo(wp.Position)
		hum.MoveToFinished:Wait()
		pfRemoveDot(i)
	end
	blockedConn:Disconnect(); pfStopStuck(); pfClearDots()
	return true
end

local function pfGoToPoint(pumpkin)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return true end
	for attempt = 1, #PF_ATTEMPT_ANGLES do
		if not state.cfg.autoPumpkin_enabled then return false end
		local targetPos = pfBuildTargetPos(pumpkin, attempt)
		local dist = (root.Position - targetPos).Magnitude
		if dist <= 4 then return true end
		local path = pfComputePath(root.Position, targetPos)
		if path then
			local done = pfFollowWaypoints(path)
			if done then return true end
		end
		task.wait(0.2)
	end
	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum then hum:MoveTo(pumpkin.hb.Position); hum.MoveToFinished:Wait() end
	return true
end

local function pfCrushPumpkin(hb)
	local ok, crushEvent = pcall(function()
		return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Events")
			:WaitForChild("Halloween"):WaitForChild("Crush")
	end)
	if ok and crushEvent then
		pcall(function() crushEvent:FireServer(hb) end)
	end
end

local function pfStop()
	state.pfRunning = false
	state.cfg.autoPumpkin_enabled = false
	state.pfToggleState = false
	pfStopStuck()
	pfClearDots()
	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then hum:MoveTo(root.Position) end
	end
end

local function pfRun()
	character = lp.Character or lp.CharacterAdded:Wait()
	_humanoid  = character:WaitForChild("Humanoid")
	_rootPart  = character:WaitForChild("HumanoidRootPart")
	task.wait(0.5)
	while state.pfRunning and state.cfg.autoPumpkin_enabled do
		if not isSurvivor() then
			state.pfRunning = false
			state.cfg.autoPumpkin_enabled = false
			state.pfToggleState = false
			pfStopStuck(); pfClearDots()
			OasisUI:Notify({ Title = "Auto Pumpkin", Content = "Stopped: Not a Survivor", Duration = 4 })
			break
		end
		local pumpkins = pfGetPumpkins()
		if #pumpkins == 0 then task.wait(2); continue end
		for idx, pumpkin in ipairs(pumpkins) do
			if not state.pfRunning or not state.cfg.autoPumpkin_enabled then break end
			if not pumpkin.model.Parent then continue end
			local root = character:FindFirstChild("HumanoidRootPart")
			if not root then break end
			local attempts = 0
			while state.pfRunning do
				attempts += 1
				local done = pfGoToPoint(pumpkin)
				if done then pfCrushPumpkin(pumpkin.hb); task.wait(state.cfg.autoPumpkin_delay or 0.3); break end
				if attempts >= 10 then break end
				task.wait(0.3)
			end
			task.wait(0.2)
		end
		task.wait(1)
	end
	state.pfRunning = false
	pfClearDots()
end

local function makeLabel(color, bold)
    local lbl = Drawing.new("Text")
    lbl.Visible = false; lbl.Text = ""; lbl.Size = 16
    lbl.Font = Drawing.Fonts.Plex; lbl.Color = color
    lbl.Outline = true
    return lbl
end

local function breakGen(point)
    pcall(function()
        local BreakEvent  = game:GetService("ReplicatedStorage").Remotes.Generator.BreakGenEvent
        local CommitEvent = game:GetService("ReplicatedStorage").Remotes.Generator.BreakGenCommit
        BreakEvent:FireServer(point); task.wait(0.1); CommitEvent:FireServer(point)
    end)
end

local function getGenPoints(genModel)
    local points = {}
    for _, obj in ipairs(genModel:GetDescendants()) do
        if obj.Name:find("GeneratorPoint") and obj:IsA("BasePart") then
            points[#points + 1] = obj
        end
    end
    return points
end

local function isPointOccupied(point)
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local ok, dist = pcall(function() return (root.Position - point.Position).Magnitude end)
                if ok and dist <= 5 then return true end
            end
        end
    end
    return false
end

local function readSkillRots(Line, Goal)
	local lr, gr
	pcall(function() lr = Line.Rotation; gr = Goal.Rotation end)
	if not lr or not gr then
		pcall(function()
			lr = Line:GetAttribute("Rotation") or Line:GetAttribute("Value")
			gr = Goal:GetAttribute("Rotation") or Goal:GetAttribute("Value")
		end)
	end
	if not lr or not gr then return nil, nil end
	lr = lr < 0 and (lr % 360) or lr
	gr = gr < 0 and (gr % 360) or gr
	return lr, gr
end

local _instantFired       = false
local _instantSnapPending = false

local function startInstantSC()
    if _G.skillconn then _G.skillconn:Disconnect() end
    _instantFired       = false
    _instantSnapPending = false

    local OFFSET_GOAL         = state.cfg.sc_instant_offset  or 110
    local OFFSET_TRAP_PERFECT = state.cfg.sc_trap_offset      or 110
    local OFFSET_TRAP_GOAL    = state.cfg.sc_trapgoal_offset  or 105

    _G.skillconn = RunService.RenderStepped:Connect(function()
        OFFSET_GOAL         = state.cfg.sc_instant_offset  or 110
        OFFSET_TRAP_PERFECT = state.cfg.sc_trap_offset      or 110
        OFFSET_TRAP_GOAL    = state.cfg.sc_trapgoal_offset  or 105

        if not (state.running and state.cfg.sc_enabled) then
            _instantFired = false
            _instantSnapPending = false
            return
        end

        pcall(function()
            local pg  = lp:FindFirstChild("PlayerGui")
            local scr = pg  and pg:FindFirstChild("SkillCheckPromptGui")
            local chk = scr and scr:FindFirstChild("Check")

            if not chk or not chk.Visible then
                _instantFired = false
                _instantSnapPending = false
                return
            end

            local Line        = chk:FindFirstChild("Line")
            local Goal        = chk:FindFirstChild("Goal")
            local TrapPerfect = chk:FindFirstChild("TrapPerfect")
            local TrapGoal    = chk:FindFirstChild("TrapGoal")
            if not Line then return end

            local targetRotation
            if TrapPerfect and TrapPerfect.Visible then
                targetRotation = TrapPerfect.Rotation + OFFSET_TRAP_PERFECT
            elseif TrapGoal and TrapGoal.Visible then
                targetRotation = TrapGoal.Rotation + OFFSET_TRAP_GOAL
            elseif Goal and Goal.Visible then
                targetRotation = Goal.Rotation + OFFSET_GOAL
            end
            if not targetRotation then return end

            TweenService:Create(Line, TweenInfo.new(0), { Rotation = targetRotation }):Play()

            if not _instantFired and not _instantSnapPending then
                _instantSnapPending = true
                task.spawn(function()
                    RunService.RenderStepped:Wait()
                    RunService.RenderStepped:Wait()
                    if chk and chk.Parent and chk.Visible then
                        if state.cfg.sc_pressKey then
                            pressKey(Enum.KeyCode.Space, state.cfg.sc_key)
                        end
                    end
                    _instantFired = true
                    _instantSnapPending = false
                end)
            end
        end)
    end)
end

local function stopInstantSC()
    _instantFired = false
    _instantSnapPending = false
    if _G.skillconn then
        _G.skillconn:Disconnect()
        _G.skillconn = nil
    end
end

task.spawn(function()
	while state.running do
		task.wait(1.0)
		pcall(function()
			local team = lp.Team
			local teamName = team and string.lower(tostring(team.Name or "")) or ""
			if teamName:find("spectator") or teamName:find("spec") or teamName:find("lobby") then
				if next(state.droppedPallets) ~= nil then state.droppedPallets = {} end
			end
			if state.lastTeamName ~= teamName then state.droppedPallets = {}; state.lastTeamName = teamName end
		end)
	end
end)

task.spawn(function()
	while state.running do
		if state.cfg.swiftspeed_enabled and not isSurvivor() then
			pcall(function()
				local charModel = workspace:FindFirstChild(lp.Name)
				if charModel then charModel:SetAttribute("swift", state.cfg.swiftspeed_value) end
			end)
		end
		task.wait(0.2)
	end
end)

task.spawn(function()
	while state.running do
		pcall(function()
			if state.cfg.breakSpeed_enabled then
				local charModel = workspace:FindFirstChild(lp.Name)
				if charModel then
					if charModel:GetAttribute("breakspeed") ~= state.cfg.breakSpeed_value then
						charModel:SetAttribute("breakspeed", state.cfg.breakSpeed_value)
					end
				end
			end
		end)
		task.wait(0.2)
	end
end)

task.spawn(function()
	while state.running do
		if state.cfg.scp_esp_enabled then pcall(scanSCPs)
		else for model in pairs(state.scpEspElements or {}) do removeSCPESP(model) end end
		task.wait(1.0)
	end
end)

task.spawn(function()
	while state.running do
		pcall(function()
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= lp and not isKillerPlayer(plr) then
					if not state.monitoredPlayerAnimators[plr] then
						state.monitoredPlayerAnimators[plr] = true
						local function tryAttach(char)
							if not char then return end
							local anim = findAnimator(char)
							if not anim then return end
						end
						pcall(tryAttach, plr.Character)
						plr.CharacterAdded:Connect(function(char)
							task.wait(0.3); pcall(tryAttach, char)
							state.playerParryState[plr] = nil
						end)
					end
				end
			end
		end)
		task.wait(2.0)
	end
end)

task.spawn(function()
    while state.running do
        task.wait(2)
        pcall(function()
            if state._fullbrightEnabled then applyFullBright() end
            if state._nofogEnabled then applyNoFog() end
        end)
    end
end)

task.spawn(function()
    while state.running do
        if state.genEspEnabled then
            for model in pairs(state.genEspElements) do
                if model.Parent then
                    local repair = model:GetAttribute("RepairProgress") or 0
                    local pct    = math.clamp(repair, 0, 100)
                    local prevPct = state._genPrevProgress[model]
                    if prevPct ~= nil then state._genIsBreaking[model] = pct < prevPct
                    else state._genIsBreaking[model] = false end
                    state._genPrevProgress[model] = pct
                else
                    state._genPrevProgress[model] = nil
                    state._genIsBreaking[model] = nil
                end
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    local cam = workspace.CurrentCamera
    while state.running do
        if state.genEspEnabled then
            pcall(initialScanGen)
            pcall(function()
                cam = workspace.CurrentCamera
                for model, elem in pairs(state.genEspElements) do
                    if not model.Parent then
                        removeGenESP(model)
                        state._genPrevProgress[model] = nil
                        state._genIsBreaking[model] = nil
                    else
                        local repair    = model:GetAttribute("RepairProgress") or 0
                        local repairing = model:GetAttribute("PlayersRepairingCount") or 0
                        local paused    = model:GetAttribute("ProgressPaused")
                        local pct       = math.clamp(repair, 0, 100)
                        local displayPct = math.floor(pct)
                        local isBreaking = state._genIsBreaking[model] or false
                        if pct >= 100 then
                            elem.nameText.Visible = false; elem.infoText.Visible = false
                            elem.barBg.Visible = false; elem.barFill.Visible = false
                            if elem.highlight then elem.highlight.Enabled = false end
                        else
                            local rootPos = elem.rootPart.Position + Vector3.new(0, 3, 0)
                            local screenPos, onScreen = cam:WorldToViewportPoint(rootPos)
                            if not onScreen or screenPos.Z < 0 then
                                elem.nameText.Visible = false; elem.infoText.Visible = false
                                elem.barBg.Visible = false; elem.barFill.Visible = false
                            else
                                local sx = screenPos.X; local sy = screenPos.Y
                                local barW = 50; local barH = 3
                                elem.barBg.Visible = true; elem.barBg.Size = Vector2.new(barW, barH)
                                elem.barBg.Position = Vector2.new(sx - barW/2, sy)
                                local fillW = math.max(1, math.floor(barW * (pct / 100)))
                                elem.barFill.Visible = true; elem.barFill.Size = Vector2.new(fillW, barH)
                                elem.barFill.Position = Vector2.new(sx - barW/2, sy)
                                elem.nameText.Visible = true; elem.nameText.Position = Vector2.new(sx, sy - 16)
                                elem.infoText.Visible = true; elem.infoText.Position = Vector2.new(sx, sy + barH + 2)
                                if repairing > 0 and paused then
                                    elem.barFill.Color = Color3.fromRGB(120,120,120)
                                    elem.nameText.Color = Color3.fromRGB(255,255,255)
                                    elem.infoText.Text = displayPct .. "% | " .. repairing .. "P repairing | paused"
                                elseif repairing > 0 then
                                    elem.barFill.Color = Color3.fromRGB(180,180,180)
                                    elem.nameText.Color = Color3.fromRGB(255,255,255)
                                    elem.infoText.Text = displayPct .. "% | " .. repairing .. " Players repairing"
                                elseif isBreaking and paused then
                                    elem.barFill.Color = Color3.fromRGB(200,40,40)
                                    elem.nameText.Color = Color3.fromRGB(255,80,80)
                                    elem.infoText.Text = displayPct .. "% | breaking | paused"
                                elseif isBreaking then
                                    elem.barFill.Color = Color3.fromRGB(255,60,60)
                                    elem.nameText.Color = Color3.fromRGB(255,80,80)
                                    elem.infoText.Text = displayPct .. "% | breaking"
                                elseif paused then
                                    elem.barFill.Color = Color3.fromRGB(80,80,80)
                                    elem.nameText.Color = Color3.fromRGB(200,200,200)
                                    elem.infoText.Text = displayPct .. "% | idle | paused"
                                else
                                    elem.barFill.Color = Color3.fromRGB(255,255,255)
                                    elem.nameText.Color = Color3.fromRGB(200,200,200)
                                    elem.infoText.Text = displayPct .. "% | idle"
                                end
                                if elem.highlight then elem.highlight.Enabled = true end
                            end
                        end
                    end
                end
            end)
        else
            for model, elem in pairs(state.genEspElements) do
                pcall(function()
                    elem.nameText.Visible = false; elem.infoText.Visible = false
                    elem.barBg.Visible = false; elem.barFill.Visible = false
                end)
                removeGenESP(model)
                state._genPrevProgress[model] = nil
                state._genIsBreaking[model] = nil
            end
        end
        task.wait(0.01)
    end
end)

task.spawn(function()
    local cam = workspace.CurrentCamera
    while state.running do
        if state.bearTrapEspEnabled then
            pcall(initialScanBearTrap)
            pcall(function()
                cam = workspace.CurrentCamera
                local me = myRoot()
                local myPos = me and me.Position
                for model, elem in pairs(state.bearTrapEspElements) do
                    if not model.Parent then removeBearTrapESP(model); continue end
                    local armed = model:GetAttribute("Armed")
                    if not armed then
                        elem.nameText.Visible = false; elem.distText.Visible = false
                        elem.barBg.Visible = false
                        if elem.highlight then elem.highlight.Enabled = false end
                        continue
                    end
                    local rootPos = elem.rootPart.Position + Vector3.new(0, 1.5, 0)
                    local screenPos, onScreen = cam:WorldToViewportPoint(rootPos)
                    if not onScreen or screenPos.Z < 0 then
                        elem.nameText.Visible = false; elem.distText.Visible = false
                        elem.barBg.Visible = false
                        if elem.highlight then elem.highlight.Enabled = false end
                        continue
                    end
                    local sx = screenPos.X; local sy = screenPos.Y
                    local dist = myPos and (myPos - elem.rootPart.Position).Magnitude or 0
                    local barW = 50; local barH = 3
                    elem.barBg.Visible = true; elem.barBg.Size = Vector2.new(barW, barH)
                    elem.barBg.Position = Vector2.new(sx - barW/2, sy)
                    elem.nameText.Visible = true; elem.nameText.Position = Vector2.new(sx, sy - 16)
                    elem.nameText.Color = Color3.fromRGB(255,80,80)
                    elem.distText.Visible = true; elem.distText.Text = string.format("%.0f studs", dist)
                    elem.distText.Position = Vector2.new(sx, sy + barH + 2)
                    if elem.highlight then elem.highlight.Enabled = true end
                end
            end)
        else
            for model, elem in pairs(state.bearTrapEspElements) do
                pcall(function()
                    elem.nameText.Visible = false; elem.distText.Visible = false; elem.barBg.Visible = false
                end)
                removeBearTrapESP(model)
            end
        end
        task.wait(0.01)
    end
end)

task.spawn(function()
    while state.running do
        if state.pumpkinEspEnabled then
            pcall(scanPumpkins)
            for model, elem in pairs(state.pumpkinEspElements) do
                if not model.Parent then removePumpkinESP(model)
                else if elem.highlight then elem.highlight.Enabled = true end end
            end
        else
            for model in pairs(state.pumpkinEspElements or {}) do removePumpkinESP(model) end
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
	while state.running do
		if state.autoBreakGenAura_enabled and not isSurvivor() then
			pcall(function()
				local me = myRoot()
				if not me then return end
				local gens = workspace.Map.Generators:GetChildren()
				for _, gen in ipairs(gens) do
					local repair = gen:GetAttribute("RepairProgress") or 0
					if repair < 100 then
						local points = getGenPoints(gen)
						for _, point in ipairs(points) do
							local ok, dist = pcall(function()
								return (me.Position - point.Position).Magnitude
							end)
							if ok and dist <= state.autoBreakGenAura_radius and not isPointOccupied(point) then
								breakGen(point); task.wait(0.2)
							end
						end
					end
				end
			end)
		end
		task.wait(0.5)
	end
end)

task.spawn(function()
    while state.running do
        pcall(function()
            if not killerInfoVisible then return end
            local killerPlayer = "?"
            local killerMorph  = "?"
            for _, plr in ipairs(Players:GetPlayers()) do
                local team = plr.Team
                local teamName = team and tostring(team.Name) or ""
                if teamName == "Killer" then
                    killerPlayer = plr.Name
                    local ch = plr.Character
                    if ch then
                        local ok, v = pcall(function() return ch:GetAttribute("MorphedKiller") end)
                        if ok and v then killerMorph = tostring(v) end
                    end
                    break
                end
            end
            infoKillerLabel.Text = " Who: " .. killerPlayer
            infoMorphLabel.Text  = " Type: The " .. killerMorph
        end)
        task.wait(1.5)
    end
end)

RunService.Heartbeat:Connect(function()
	if not state.running then return end
	local c = state.cfg
	local spectating = isSpectator()
	if spectating then
		for char in pairs(state.killer2DEspElements or {}) do removeKiller2DESP(char) end
		for char in pairs(state.player2DEspElements or {}) do removePlayer2DESP(char) end
		return
	end
	local cam = workspace.CurrentCamera
	if not cam then return end
	if c.esp_enabled then
		for _, kRoot in ipairs(state.killerRoots) do
			local char = kRoot and kRoot.Parent
			if char then
				if not state.killer2DEspElements[char] then createKiller2DESP(char) end
				local elem = state.killer2DEspElements[char]
				if elem then
					local x, y, width, height, dist = get2DScreenBounds(char)
					if elem.highlight then elem.highlight.Enabled = c.esp_showHighlight end
					if x then
						local vp = cam.ViewportSize
						local labelX    = math.clamp(x + (width/2) - 80, 0, vp.X - 160)
						local labelTopY = math.clamp(y - 22, 0, vp.Y - 30)
						local labelBotY = math.clamp(y + height + 3, 0, vp.Y - 20)
						local dynamicFont = math.clamp(math.floor(height * 0.22), 10, 14)
						elem.container.Visible  = true
						elem.nameLabel.Visible  = c.esp_showName
						elem.nameLabel.Position = UDim2.new(0, labelX, 0, labelTopY)
						elem.nameLabel.TextSize = dynamicFont
						elem.distLabel.Visible  = true
						elem.distLabel.Position = UDim2.new(0, labelX, 0, labelBotY)
						elem.distLabel.TextSize = math.max(9, dynamicFont - 1)
						elem.distLabel.Text     = string.format("[%d studs]", math.floor(dist or 0))
					else
						elem.container.Visible = false
					end
				end
			end
		end
	else
		for char in pairs(state.killer2DEspElements or {}) do removeKiller2DESP(char) end
	end
	if c.p_esp_enabled then
		local now = tick()
		if (now - state._playerCacheTime) > 0.5 then
			state._cachedPlayers = Players:GetPlayers()
			state._playerCacheTime = now
		end
		for char, _ in pairs(state.player2DEspElements) do
			local shouldRemove = true
			for _, plr in ipairs(state._cachedPlayers) do
				if plr.Character == char then
					local team = plr.Team
					local teamName = team and tostring(team.Name) or ""
					if teamName ~= "Killer" and teamName ~= "Spectator" and plr ~= lp then
						shouldRemove = false
					end
					break
				end
			end
			local ok, botId = pcall(function() return char:GetAttribute("BotId") end)
			if ok and botId ~= nil then shouldRemove = false end
			if shouldRemove then removePlayer2DESP(char) end
		end
		for _, plr in ipairs(state._cachedPlayers) do
			if plr ~= lp then
				local team = plr.Team
				local teamName = team and tostring(team.Name) or ""
				if teamName ~= "Killer" and teamName ~= "Spectator" and teamName ~= "" then
					local char = plr.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					if char and root then
						if not state.player2DEspElements[char] then createPlayer2DESP(char) end
						local elem = state.player2DEspElements[char]
						if elem then
							local x, y, width, height, dist = get2DScreenBounds(char)
							updateEspElem(elem, char, x, y, width, height, dist)
						end
					end
				end
			end
		end
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("Model") then
				local ok, botId   = pcall(function() return obj:GetAttribute("BotId") end)
				local ok2, botNetId = pcall(function() return obj:GetAttribute("BotNetId") end)
				local isBot = (ok and botId ~= nil) or (ok2 and botNetId ~= nil)
				if isBot then
					local root = obj:FindFirstChild("HumanoidRootPart")
					local hum  = obj:FindFirstChildOfClass("Humanoid")
					if root and hum and hum.Health > 0 then
						if not state.player2DEspElements[obj] then createPlayer2DESP(obj) end
						local elem = state.player2DEspElements[obj]
						if elem then
							local knocked = obj:GetAttribute("Knocked")
							elem.nameLabel.Text = "[Bot] " .. tostring(obj.Name) .. (knocked and "  [KNOCKED]" or "")
							elem.nameLabel.TextColor3 = knocked and Color3.fromRGB(255,80,80) or Color3.fromRGB(255,255,255)
							elem.distLabel.TextColor3 = Color3.fromRGB(200,200,200)
							if elem.highlight then
								elem.highlight.FillColor    = Color3.fromRGB(255,255,255)
								elem.highlight.OutlineColor = Color3.fromRGB(255,255,255)
							end
							local x, y, width, height, dist = get2DScreenBounds(obj)
							updateEspElem(elem, obj, x, y, width, height, dist)
						end
					else
						removePlayer2DESP(obj)
					end
				end
			end
		end
	else
		for char in pairs(state.player2DEspElements or {}) do removePlayer2DESP(char) end
	end
end)

task.spawn(function()
	while state.running do
		for char in pairs(state.killer2DEspElements) do
			local alive = false
			for _, kRoot in ipairs(state.killerRoots) do
				if kRoot.Parent == char then alive = true; break end
			end
			if not alive then removeKiller2DESP(char) end
		end
		for char in pairs(state.player2DEspElements) do
			local alive = false
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr.Character == char and not isKillerPlayer(plr) then alive = true; break end
			end
			if not alive then removePlayer2DESP(char) end
		end
		task.wait(1.0)
	end
end)

RunService.Heartbeat:Connect(function()
	if not state.running then return end
	if not state.moonwalkEnabled then return end
	state.moonwalkAdT = state.moonwalkAdT + (RunService.Heartbeat:Wait() or 0)
	if state.moonwalkAdT >= AD_INTERVAL then
		state.moonwalkAdT = 0
		state.moonwalkAdDir = -state.moonwalkAdDir
		if state.moonwalkAdDir > 0 then
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game)
			VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.A, false, game)
		else
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.A, false, game)
			VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.D, false, game)
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if not state.running then return end
	if not state.cfg.noFlashBlind then return end
	pcall(function()
		local selectedKiller = lp:GetAttribute("SelectedKiller")
		if not selectedKiller then return end
		local pg = lp:FindFirstChild("PlayerGui")
		local killerGui = pg and pg:FindFirstChild(selectedKiller)
		if killerGui and killerGui:FindFirstChild("Blind") then
			killerGui.Blind.Visible = false
		end
	end)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == state.cfg.spear_key then
		state.cfg.spear_isHolding = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == state.cfg.spear_key then
		state.cfg.spear_isHolding = false
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == state.moonwalkKey then
		state.moonwalkEnabled = not state.moonwalkEnabled
		state.moonwalkAdT     = 0
		state.moonwalkAdDir   = 1
		if not state.moonwalkEnabled then
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.A, false, game)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game)
		end
	end
end)

RunService.RenderStepped:Connect(function()
    if not (state.running and state.cfg.spear_enabled and state.cfg.spear_isHolding) then return end
    local team = lp.Team
    local teamName = team and tostring(team.Name) or ""
    if teamName ~= "Killer" then return end
    local target, targetType, _targetChar = getSpearTarget()
    if not target then return end
    local camCF = workspace.CurrentCamera.CFrame
    local aimPos
    if targetType == "spear" then
        aimPos = target.Position
    else
        local targetVel = target.AssemblyLinearVelocity or target.Velocity
        aimPos = calculateSpearAim(camCF.Position, target.Position, targetVel)
    end
    if not aimPos then return end
    workspace.CurrentCamera.CFrame = CFrame.lookAt(camCF.Position, aimPos)
end)

RunService.RenderStepped:Connect(function()
    if not (state.running and state.cfg.tof_enabled) then return end
    if not isSurvivor() then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    local me = myRoot()
    if not me then return end
    local target = nil
    if state.cfg.tof_target == "Killer" then
        local mousePos = UserInputService:GetMouseLocation()
        local best = nil; local bestDist = math.huge
        for _, kRoot in ipairs(state.killerRoots) do
            if kRoot and kRoot.Parent then
                local worldDist = (me.Position - kRoot.Position).Magnitude
                if worldDist <= state.cfg.tof_maxDist then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(kRoot.Position)
                    if onScreen and screenPos.Z > 0 then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < bestDist then bestDist = dist; best = kRoot end
                    end
                end
            end
        end
        target = best
    else
        local mousePos = UserInputService:GetMouseLocation()
        local bestT, bestDist2 = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= lp and plr.Team and plr.Team.Name == "Survivors" and plr.Character then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root and (me.Position - root.Position).Magnitude <= state.cfg.tof_maxDist then
                    local sp, vis = Camera:WorldToViewportPoint(root.Position)
                    if vis and sp.Z > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                        if d < bestDist2 then bestDist2 = d; bestT = root end
                    end
                end
            end
        end
        target = bestT
    end
    if not target or not target.Parent then return end
    local camCF = workspace.CurrentCamera.CFrame
    workspace.CurrentCamera.CFrame = CFrame.lookAt(camCF.Position, target.Position)
end)

RunService.Heartbeat:Connect(function()
	if not state.running or not state.cfg.scp_esp_enabled then return end
	local now = tick()
	if now - state._scpTick < 0.1 then return end
	state._scpTick = now
	for model, elem in pairs(state.scpEspElements) do
		if not model.Parent then removeSCPESP(model); continue end
		if elem.highlight then elem.highlight.Enabled = state.cfg.scp_esp_showHighlight end
	end
end)

task.spawn(function()
    while state.running do
        if state.vaultEspEnabled or state.palletEspEnabled then
            for obj in pairs(state.vaultEspElements) do
                if not obj.Parent then removeVaultESP(obj) end
            end
            for model in pairs(state.palletEspElements) do
                if not model.Parent then removePalletESP(model) end
            end
        end
        task.wait(3.0)
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(newChar)
        for char in pairs(state.player2DEspElements) do
            if char ~= newChar then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p == plr and p.Character ~= char then
                        removePlayer2DESP(char)
                    end
                end
            end
        end
    end)
end)

for _, plr in ipairs(Players:GetPlayers()) do
    plr.CharacterAdded:Connect(function(newChar)
        task.wait(0.1)
        for char in pairs(state.player2DEspElements) do
            local found = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character == char then found = true; break end
            end
            if not found then removePlayer2DESP(char) end
        end
    end)
end

Players.PlayerRemoving:Connect(function(plr)
	state.playerParryState[plr] = nil
	state.monitoredPlayerAnimators[plr] = nil
end)

lp.CharacterAdded:Connect(function(char)
    state._fvController = nil
    _fvLastDiscover = 0
    _fvFailCount = 0
    state._fsCD          = 0
    state._fsOverrideEnd = 0
    fvHookAnim(char)
    task.delay(1.5, function()
        if state.cfg.fastVault_enabled then
            pcall(fvDiscover); pcall(fvPatch)
        end
        if state.cfg.flowstate_enabled then
            pcall(fsApplyAttr)
        end
    end)
end)

task.spawn(function()
    local accD, accA = 0, 0
    while state.running do
        local dt = task.wait()
        accD += dt; accA += dt

        if accD >= 5 then
            accD = 0
            if state.cfg.fastVault_enabled then
                pcall(fvPatch)
                pcall(fvDiscover)
            end
        end

        if accA >= 0.1 then
            accA = 0
            pcall(fsApplyAttr)
        end
    end
end)

local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local selfName = ""
    if typeof(self) == "Instance" then
        pcall(function() selfName = tostring(self.Name or "") end)
    end

    if method == "GetChildren" or method == "GetDescendants" or
       method == "FindFirstChild" or method == "FindFirstChildOfClass" or
       method == "FindFirstAncestor" or method == "FindFirstAncestorOfClass" or
       method == "GetAttribute" or method == "GetAttributes" or
       method == "IsA" or method == "GetFullName" or
       method == "GetPropertyChangedSignal" or method == "WaitForChild" or
       method == "pcall" or method == "GetService" or method == "HttpGet" then
        return oldNamecall(self, ...)
    end

    if typeof(self) ~= "Instance" or (method ~= "FireServer" and method ~= "InvokeServer") then
        return oldNamecall(self, ...)
    end

    return oldNamecall(self, ...)
end)

local function agl_PressSkillCheck()

    local v4 = lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("Survivor-mob")
    if v4 then
        local controls = v4:FindFirstChild("Controls")
        local btn = controls and (controls:FindFirstChild("action") or controls:FindFirstChild("check"))
        if btn and btn:IsA("GuiObject") and btn.Visible then
            if type(firesignal) == "function" then
                pcall(function()
                    firesignal(btn.MouseButton1Down)
                    task.wait(0.005)
                    firesignal(btn.MouseButton1Up)
                end)
                return
            end
            pcall(function()
                local ap = btn.AbsolutePosition
                local as = btn.AbsoluteSize
                local gi = game:GetService("GuiService"):GetGuiInset()
                local id = 8822 + math.random(1, 9999)
                VirtualInputManager:SendTouchEvent(id, 0, ap.X + as.X/2 + gi.X, ap.Y + as.Y/2 + gi.Y)
                task.wait(0.005)
                VirtualInputManager:SendTouchEvent(id, 2, ap.X + as.X/2 + gi.X, ap.Y + as.Y/2 + gi.Y)
            end)
            return
        end
    end

    pcall(function()
        VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
        task.wait(0.005)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
end

local _aglConn = nil

local function agl_stop()
    if _aglConn then
        _aglConn:Disconnect()
        _aglConn = nil
    end
    state.autoGenLegit_busy = false
end

local function agl_start()
    agl_stop()
    _aglConn = RunService.Heartbeat:Connect(function()
        if not state.running or not state.autoGenLegit_enabled then
            agl_stop(); return
        end
        if not isSurvivor() then return end
        if state.autoGenLegit_busy then return end

        local pg   = lp:FindFirstChild("PlayerGui")
        local scr  = pg  and pg:FindFirstChild("SkillCheckPromptGui")
        local chk  = scr and scr:FindFirstChild("Check")
        if not chk or not chk.Visible then
            state.autoGenLegit_busy = false
            return
        end

        local Line        = chk:FindFirstChild("Line")
        local Goal        = chk:FindFirstChild("Goal")
        local TrapPerfect = chk:FindFirstChild("TrapPerfect")
        local TrapGoal    = chk:FindFirstChild("TrapGoal")
        if not Line then return end

        local mode = state.autoGenLegit_mode or "Normal"

        if mode == "Instant" then

            local targetRot
            if TrapPerfect and TrapPerfect.Visible then
                targetRot = TrapPerfect.Rotation + (state.cfg.sc_trap_offset or 110)
            elseif TrapGoal and TrapGoal.Visible then
                targetRot = TrapGoal.Rotation + (state.cfg.sc_trapgoal_offset or 105)
            elseif Goal and Goal.Visible then
                targetRot = Goal.Rotation + (state.cfg.sc_instant_offset or 110)
            end
            if not targetRot then return end
            TweenService:Create(Line, TweenInfo.new(0), { Rotation = targetRot }):Play()
            if not state.autoGenLegit_busy then
                state.autoGenLegit_busy = true
                task.spawn(function()
                    task.wait(0.5)
                    if chk and chk.Parent and chk.Visible then
                        agl_PressSkillCheck()
                    end
                    task.wait(0.05)
                    state.autoGenLegit_busy = false
                end)
            end
        else

            if not (Line and Goal and Goal.Visible) then return end
            local lr = Line.Rotation % 360
            local gr = Goal.Rotation % 360
            local hitMin = (gr + 108) % 360
            local hitMax = (gr + 136) % 360
            local inZone
            if hitMax >= hitMin then
                inZone = lr >= hitMin and lr <= hitMax
            else
                inZone = lr >= hitMin or lr <= hitMax
            end
            if inZone and not state.autoGenLegit_busy then
                state.autoGenLegit_busy = true
                task.spawn(function()
                    agl_PressSkillCheck()
                    task.wait(0.05)
                    state.autoGenLegit_busy = false
                end)
            end
        end
    end)
end

state.ui.Tabs = {
	Survivor  = state.ui.Window:Tab({ Title = "Survivor", Icon = "user" }),
	Killer    = state.ui.Window:Tab({ Title = "Killer", Icon = "swords" }),
	ESP       = state.ui.Window:Tab({ Title = "ESP", Icon = "eye" }),
	World     = state.ui.Window:Tab({ Title = "World", Icon = "globe" }),
	Pumpkin   = state.ui.Window:Tab({ Title = "Pumpkin", Icon = "ghost" }),
}

state.ui.GenLegitBox = state.ui.Tabs.Survivor:Section({ Title = "Auto Skillcheck", Icon = "zap", Side = "Left" })
state.ui.GenLegitBox:Toggle({
    Title    = "Auto Skillcheck",
    Default  = false,

    Callback = function(v)
        state.autoGenLegit_enabled = v
        if v then agl_start() else agl_stop() end
    end,
})
state.ui.GenLegitBox:Dropdown({
    Title    = "Mode",
    Values   = { "Normal", "Instant" },
    Default  = "Normal",
    Callback = function(v)
        state.autoGenLegit_mode = v
    end,
})

state.ui.ParryBox = state.ui.Tabs.Survivor:Section({ Title = "Auto Parry", Icon = "swords", Side = "Left" })
state.ui.ParryBox:Toggle({ Title = "Enable Auto Parry", Default = state.cfg.ap_enabled,
    Callback = function(v) state.cfg.ap_enabled = v end })
state.ui.ParryBox:Dropdown({ Title = "Mode", Values = {"Normal","Aggressive"}, Default = state.cfg.ap_mode,
    Callback = function(v) state.cfg.ap_mode = v end })
state.ui.ParryBox:Slider({ Title = "Range", Min = 6, Max = 20, Default = state.cfg.ap_range, Step = 1, Suffix = " studs",
    Callback = function(v) state.cfg.ap_range = v end })
state.ui.ParryBox:Slider({ Title = "Face Threshold", Min = 0.1, Max = 1.0, Step = 0.05, Default = state.cfg.ap_faceTh,
    Callback = function(v) state.cfg.ap_faceTh = v end })
state.ui.ParryBox:Toggle({ Title = "Safety (skip saat vault/heal)", Default = state.cfg.ap_safety,
    Callback = function(v) state.cfg.ap_safety = v end })

state.ui.ParryBox:Toggle({ Title = "Server CD", Default = state.cfg.ap_cdFromServer,

    Callback = function(v) state.cfg.ap_cdFromServer = v end })
state.ui.ParryBox:Toggle({ Title = "Show Circle", Default = state.cfg.ap_showCircle,
    Callback = function(v) state.cfg.ap_showCircle = v end })
state.ui.ParryBox:Dropdown({ Title = "Circle Color", Values = {"Cyan","Green","Red","Purple","White"}, Default = "Cyan",
    Callback = function(v)
        local map = {
            Cyan=Color3.fromRGB(0,255,200), Green=Color3.fromRGB(0,255,80),
            Red=Color3.fromRGB(255,80,80),  Purple=Color3.fromRGB(180,100,255),
            White=Color3.fromRGB(255,255,255),
        }
        state.cfg.ap_circleColor = map[v] or Color3.fromRGB(0,255,200)
    end })

state.ui.VaultBox = state.ui.Tabs.Survivor:Section({ Title = "Vault & Flowstate", Icon = "wind", Side = "Right" })
state.ui.VaultBox:Toggle({
    Title    = "Always Fast Vault",
    Default  = false,
    Callback = function(v)
        state.cfg.fastVault_enabled = v
        if v then pcall(fvDiscover); pcall(fvPatch)
        else fvUnpatch() end
    end,
})
state.ui.VaultBox:Toggle({
    Title    = "Force Flowstate",
    Default  = false,
    Callback = function(v)
        state.cfg.flowstate_enabled = v
        if v then
            state._fsCD          = 0
            state._fsOverrideEnd = 0
            local char = lp.Character
            if char then
                pcall(fvHookAnim, char)
            end
            task.defer(function()
                pcall(fsApplyAttr)
            end)
        else
            state._fsCD          = 0
            state._fsOverrideEnd = 0
            fsClearAttr()
        end
    end,
})
state.ui.VaultBox:Slider({
    Title    = "Flowstate Cooldown",
    Default  = 15,
    Min      = 5,
    Max      = 30,
    Step     = 1,
    Suffix   = "s",
    Callback = function(v)
        state.cfg.flowstate_cooldown = v
        if state.cfg.flowstate_enabled then
            local now = tick()
            if now < state._fsCD then
                if not state._fsCDLock or now > state._fsCDLock then
                    state._fsCD = now + v
                    state._fsCDLock = now + 0.2
                end
            end
        end
    end,
})

state.ui.BreakSpeedBox = state.ui.Tabs.Killer:Section({ Title = "Break Speed", Icon = "hammer", Side = "Right" })
state.ui.BreakSpeedBox:Toggle({ Title = "Enable Break Speed", Default = state.cfg.breakSpeed_enabled, Callback = function(v) state.cfg.breakSpeed_enabled = v end })
state.ui.BreakSpeedBox:Slider({ Title = "Break Speed Value", Default = state.cfg.breakSpeed_value, Min = 1, Max = 10, Step = 0.1, Callback = function(v) state.cfg.breakSpeed_value = v end })

state.ui.BreakGenBox = state.ui.Tabs.Killer:Section({ Title = "Auto Break Generator", Icon = "wrench", Side = "Left" })
state.ui.BreakGenBox:Toggle({ Title = "Auto Break Gen Aura", Default = false, Callback = function(v) state.autoBreakGenAura_enabled = v end })
state.ui.BreakGenBox:Slider({ Title = "Aura Radius", Default = 20, Min = 5, Max = 60, Step = 1, Suffix = " studs", Callback = function(v) state.autoBreakGenAura_radius = v end })

state.ui.MaskedBox = state.ui.Tabs.Killer:Section({ Title = "The Masked", Icon = "venetian-mask", Side = "Left" })
state.ui.maskList = { "Alex", "Brandon", "Cobra", "Rabbit", "Richter", "Richard", "Tony" }
state.ui.MaskedBox:Dropdown({ Title = "Select Mask", Default = state.cfg.selectMask, Values = state.ui.maskList, Callback = function(v) state.cfg.selectMask = v end })
state.ui.MaskedBox:Button({ Title = "Use Mask Power", Callback = function()
	pcall(function()
		game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Killers")
			:WaitForChild("Masked"):WaitForChild("Activatepower"):FireServer(state.cfg.selectMask)
	end)
end })

state.ui.Swiftbox = state.ui.Tabs.Killer:Section({ Title = "Vault", Icon = "door-open", Side = "Left" })
state.ui.Swiftbox:Toggle({ Title = "Vault Speed", Default = false, Callback = function(v)
	state.cfg.swiftspeed_enabled = v
	if not v then pcall(function() local c = workspace:FindFirstChild(lp.Name); if c then c:SetAttribute("swift", nil) end end) end
end })
state.ui.Swiftbox:Slider({ Title = "Swift Speed Value", Default = 1.5, Min = 1, Max = 10, Step = 0.1, Callback = function(v) state.cfg.swiftspeed_value = v end })

state.ui.VaultPalletESPBox = state.ui.Tabs.ESP:Section({ Title = "Object Esp", Icon = "boxes", Side = "Left" })
state.ui.VaultPalletESPBox:Toggle({ Title = "Enable Vault ESP", Default = false, Callback = function(v)
	state.vaultEspEnabled = v
	if not v then for obj in pairs(state.vaultEspElements) do removeVaultESP(obj) end
	else pcall(scanVaultAndPallet) end
end })
state.ui.VaultPalletESPBox:Toggle({ Title = "Enable Pallet ESP", Default = false, Callback = function(v)
	state.palletEspEnabled = v
	if not v then for model in pairs(state.palletEspElements) do removePalletESP(model) end
	else pcall(scanVaultAndPallet) end
end })

state.ui.ESPBox = state.ui.Tabs.ESP:Section({ Title = "Killer ESP", Icon = "eye", Side = "Left" })
state.ui.ESPBox:Toggle({ Title = "Enable Killer ESP", Default = state.cfg.esp_enabled, Callback = function(v) state.cfg.esp_enabled = v end })

state.ui.SCPEspBox = state.ui.Tabs.ESP:Section({ Title = "SCP ESP", Icon = "ghost", Side = "Left" })
state.ui.SCPEspBox:Toggle({ Title = "Enable SCP ESP", Default = false, Callback = function(v)
	state.cfg.scp_esp_enabled = v
	if not v then for model in pairs(state.scpEspElements or {}) do removeSCPESP(model) end end
end })

state.ui.GenESPBox = state.ui.Tabs.ESP:Section({ Title = "Generator ESP", Icon = "wrench", Side = "Right" })
state.ui.GenESPBox:Toggle({ Title = "Enable Generator ESP", Default = false, Callback = function(v)
	state.genEspEnabled = v
	if v then pcall(initialScanGen)
	else for model in pairs(state.genEspElements or {}) do removeGenESP(model) end end
end })
state.ui.GenESPBox:Toggle({ Title = "Enable Bear Trap ESP", Default = false, Callback = function(v)
	state.bearTrapEspEnabled = v
	if v then pcall(initialScanBearTrap)
	else for model in pairs(state.bearTrapEspElements or {}) do removeBearTrapESP(model) end end
end })
state.ui.GenESPBox:Toggle({ Title = "Enable Pumpkin ESP", Default = false, Callback = function(v)
	state.pumpkinEspEnabled = v
	if v then pcall(scanPumpkins)
	else for model in pairs(state.pumpkinEspElements or {}) do removePumpkinESP(model) end end
end })

state.ui.PlayerESPBox = state.ui.Tabs.ESP:Section({ Title = "Player ESP", Icon = "users", Side = "Right" })
state.ui.PlayerESPBox:Toggle({ Title = "Enable Player ESP", Default = state.cfg.p_esp_enabled, Callback = function(v) state.cfg.p_esp_enabled = v end })
state.ui.PlayerESPBox:Toggle({
    Title    = "Me ESP",
    Default  = false,
    Callback = function(v)
        state.cfg.meEsp_enabled = v
        if v then
            createMeESP()
        else
            removeMeESP()
        end
    end,
})

local _noClipEnabled = false
local _noClipConn = nil
local function startNoClip()
    if _noClipConn then return end
    _noClipConn = RunService.Stepped:Connect(function()
        if not _noClipEnabled then return end
        local ch = lp.Character
        if not ch then return end
        for _, part in ipairs(ch:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end
local function stopNoClip()
    if _noClipConn then
        _noClipConn:Disconnect()
        _noClipConn = nil
    end
    local ch = lp.Character
    if ch then
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CanCollide = true end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end
startNoClip()

local killerWarnGui = Instance.new("BillboardGui")
killerWarnGui.Name           = "ROLL_HUB_KillerWarn"
killerWarnGui.ResetOnSpawn   = false
killerWarnGui.AlwaysOnTop    = true
killerWarnGui.Size           = UDim2.new(0, 220, 0, 36)
killerWarnGui.StudsOffset    = Vector3.new(0, 3.5, 0)
killerWarnGui.Enabled        = false

local killerWarnLabel = Instance.new("TextLabel")
killerWarnLabel.BackgroundTransparency = 1
killerWarnLabel.Size                   = UDim2.new(1, 0, 1, 0)
killerWarnLabel.TextColor3             = Color3.fromRGB(255, 30, 30)
killerWarnLabel.TextStrokeTransparency = 0.3
killerWarnLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
killerWarnLabel.Font                   = Enum.Font.GothamBold
killerWarnLabel.TextSize               = 20
killerWarnLabel.TextXAlignment         = Enum.TextXAlignment.Center
killerWarnLabel.Text                   = "⚠ KILLER! 0 STUDS"
killerWarnLabel.Parent                 = killerWarnGui

local killerWarnEnabled   = false
local killerWarnThreshold = 70

local function updateKillerWarnAdornee()
    local ch = lp.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if hrp then
        killerWarnGui.Adornee = hrp
        killerWarnGui.Parent  = hrp
    end
end

lp.CharacterAdded:Connect(function(ch)
    task.wait(0.3)
    updateKillerWarnAdornee()
end)
updateKillerWarnAdornee()

task.spawn(function()
    while state.running do
        task.wait(0.15)
        if not killerWarnEnabled then
            killerWarnGui.Enabled = false
        else
            local me = myRoot()
            if not me then killerWarnGui.Enabled = false; continue end
            local closest = nil
            for _, kRoot in ipairs(state.killerRoots) do
                if kRoot and kRoot.Parent then
                    local d = (me.Position - kRoot.Position).Magnitude
                    if not closest or d < closest then closest = d end
                end
            end
            if closest and closest <= killerWarnThreshold then
                killerWarnGui.Enabled = true
                killerWarnLabel.Text  = string.format("⚠ KILLER! %d STUDS", math.floor(closest))
            else
                killerWarnGui.Enabled = false
            end
        end
    end
end)

state.ui.InfoBox = state.ui.Tabs.World:Section({ Title = "Killer Info", Icon = "ghost", Side = "Right" })
state.ui.InfoBox:Toggle({
    Title    = "Show Killer Info",
    Default  = false,

    Callback = function(v)
        killerInfoVisible           = v
        infoKillerLabel.Visible     = v
        infoMorphLabel.Visible      = v
        palletCountFrame.Visible    = v
    end,
})

state.ui.Map = state.ui.Tabs.World:Section({ Title = "Visual", Icon = "globe", Side = "Left" })
state.ui.Map:Toggle({ Title = "Full Bright", Default = false, Callback = function(v)
	state._fullbrightEnabled = v
	if v then applyFullBright() else restoreFullBright() end
end })
state.ui.Map:Toggle({ Title = "No Clip", Default = false, Callback = function(v)
	_noClipEnabled = v
	if not v then stopNoClip() else startNoClip() end
end })
state.ui.Map:Toggle({ Title = "No Fog", Default = false, Callback = function(v)
	state._nofogEnabled = v
	if v then applyNoFog() else restoreNoFog() end
end })
state.ui.Map:Label({ Text = "— Killer Warn —" })
state.ui.Map:Toggle({ Title = "Enable Killer Warn", Default = false, Callback = function(v)
	killerWarnEnabled = v
	if not v then killerWarnGui.Enabled = false end
end })
state.ui.Map:Slider({ Title = "Warn Distance", Default = 70, Min = 30, Max = 100, Step = 1, Suffix = " studs",
	Callback = function(v) killerWarnThreshold = v end })
state.ui.Map:Button({ Title = "Hop Server (Lowest Players)", Icon = "shuffle", Callback = function()
	if state._hopServerBusy then return end
	state._hopServerBusy = true
	OasisUI:Notify({ Title = "Server Hop", Content = "Searching for a low-population server...", Duration = 4 })
	task.spawn(function()
		local HttpService      = game:GetService("HttpService")
		local TeleportService  = game:GetService("TeleportService")
		local PlaceId          = game.PlaceId
		local JobId            = game.JobId
		local ok, result = pcall(function()
			return HttpService:JSONDecode(
				game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(PlaceId)
					.. "/servers/Public?sortOrder=Asc&limit=100")
			)
		end)
		local data = ok and result and result.data
		local targetId
		if data then
			table.sort(data, function(a, b) return a.playing < b.playing end)
			for _, server in ipairs(data) do
				if server.id ~= JobId and server.playing < server.maxPlayers then
					targetId = server.id; break
				end
			end
		end
		if targetId then
			OasisUI:Notify({ Title = "Server Hop", Content = "Teleporting to server...", Duration = 3 })
			TeleportService:TeleportToPlaceInstance(PlaceId, targetId, lp)
		else
			OasisUI:Notify({ Title = "Server Hop", Content = "No available server found.", Duration = 4 })
			state._hopServerBusy = false
		end
	end)
end })

local pumpkinTab = state.ui.Tabs.Pumpkin
local pfControlBox = pumpkinTab:Section({ Title = "Auto Pumpkin", Icon = "ghost", Side = "Left" })

state.pfToggleElem = pfControlBox:Toggle({
	Title    = "Auto Pumpkin",
	Default  = false,
	Callback = function(v)
		if not v then
			if state.pfRunning then pfStop() end
			state.pfToggleState = false
			return
		end
		if not isSurvivor() then
			OasisUI:Notify({ Title = "Auto Pumpkin", Content = "Survivors only!", Duration = 4 })
			state.pfToggleState = false
			task.defer(function()
				if state.pfToggleElem then pcall(function() state.pfToggleElem:SetValue(false) end) end
			end)
			return
		end
		if state.pfRunning then return end
		state.pfToggleState = true
		state.pfRunning = true
		state.cfg.autoPumpkin_enabled = true
		state.pfThread = task.spawn(pfRun)
	end,
})

pfControlBox:Slider({
	Title    = "Crush Delay",
	Default  = state.cfg.autoPumpkin_delay,
	Min      = 0,
	Max      = 2,
	Step     = 0.1,
	Suffix   = "s",
	Callback = function(v) state.cfg.autoPumpkin_delay = v end,
})

OasisUI:OnUnload(function()
    state.running = false
    task.wait(0.1)

    pcall(agl_stop)
    if _G.skillconn then
        pcall(function() _G.skillconn:Disconnect() end)
        _G.skillconn = nil
    end

    state.pfRunning = false
    state.cfg.autoPumpkin_enabled = false
    state.pfToggleState = false
    pcall(pfStopStuck)
    pcall(pfClearDots)

    state.moonwalkEnabled = false
    pcall(function()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.A, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game)
    end)

    state.autoBreakGenAura_enabled = false

    pcall(clearMapEspConns)
    pcall(stopFlashlightAim)
    pcall(restoreFullBright)
    pcall(restoreNoFog)
    pcall(lungeRestoreBoost)
    pcall(lungeRestoreMaxHold)
    pcall(fvUnpatch)
    pcall(fsClearAttr)

    if _lungeHbConn then
        pcall(function() _lungeHbConn:Disconnect() end)
        _lungeHbConn = nil
    end
    if state._fvAnimConn then
        pcall(function() state._fvAnimConn:Disconnect() end)
        state._fvAnimConn = nil
    end

    pcall(function()
        local mt2 = getrawmetatable(game)
        setreadonly(mt2, false)
        mt2.__namecall = oldNamecall
        setreadonly(mt2, true)
    end)

    for char in pairs(state.killer2DEspElements or {}) do pcall(removeKiller2DESP, char) end
    for char in pairs(state.player2DEspElements or {}) do pcall(removePlayer2DESP, char) end
    for model in pairs(state.scpEspElements or {}) do pcall(removeSCPESP, model) end
    for model in pairs(state.genEspElements or {}) do pcall(removeGenESP, model) end
    for model in pairs(state.bearTrapEspElements or {}) do pcall(removeBearTrapESP, model) end
    for model in pairs(state.pumpkinEspElements or {}) do pcall(removePumpkinESP, model) end
    for obj in pairs(state.vaultEspElements or {}) do pcall(removeVaultESP, obj) end
    for model in pairs(state.palletEspElements or {}) do pcall(removePalletESP, model) end

    for char, conns in pairs(state.ap_animConns or {}) do
        for _, c in ipairs(conns) do pcall(c.Disconnect, c) end
    end
    pcall(function() ap_circle.Parent = nil end)

    pcall(function() espGui:Destroy() end)
    pcall(function() palletCountGui:Destroy() end)

    state.scpEspElements           = {}
    state.killer2DEspElements      = {}
    state.player2DEspElements      = {}
    state.genEspElements           = {}
    state.bearTrapEspElements      = {}
    state.pumpkinEspElements       = {}
    state.vaultEspElements         = {}
    state.palletEspElements        = {}
    state.playerParryState         = {}
    state.monitoredPlayerAnimators = {}
    state.ap_monitoredKillers      = {}
    state.ap_animConns             = {}
    state.ap_lastParryTime         = 0
    state.ap_parryCD          = false
    state.ap_parryCDTok       = 0
    state.ap_parryCDThr       = nil

    pcall(stopNoClip)
    _noClipEnabled = false

    killerWarnEnabled = false
    pcall(function() killerWarnGui.Enabled = false end)

    print("[ROLL HUB v1.3] Unloaded!")
end)
