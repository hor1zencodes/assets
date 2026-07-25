--[[
    
                 ETERNITY V1 SCRIPT           
             Premium Universal Script         
                                              
      Key: horizen                            
    
    
    Loaded via: loadstring(game:HttpGet(URL))()
]]

-- 
-- WHITELIST GUARD (prevents direct execution without loader)
-- 
do
    local success, response = pcall(function()
        return game:HttpGetAsync("https://raw.githubusercontent.com/hor1zencodes/patanahi/main/whitelist.json?t=" .. tostring(tick()))
    end)
    if success then
        local isWhitelisted = false
        pcall(function()
            local HttpService = game:GetService("HttpService")
            local whitelist = HttpService:JSONDecode(response)
            local myName = game:GetService("Players").LocalPlayer.Name
            for _, name in ipairs(whitelist) do
                if string.lower(name) == string.lower(myName) then
                    isWhitelisted = true
                    break
                end
            end
        end)
        if not isWhitelisted then
            warn("[Eternity] Access denied. You are not whitelisted.")
            return
        end
    else
        warn("[Eternity] Could not verify whitelist. Access denied.")
        return
    end
end


-- 
-- SERVICES
-- 
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local character = lp.Character or lp.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- reconnect on respawn
lp.CharacterAdded:Connect(function(char)
    -- Clear PhysicsRepRootPart on old rootPart before it gets destroyed
    pcall(function()
        if rootPart and typeof(sethiddenproperty) == "function" then
            sethiddenproperty(rootPart, "PhysicsRepRootPart", nil)
        end
    end)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    
    if not IsKeyVerified then return end


    -- If facebang was active, the Stepped connection will re-call fbActivate()
    -- on next frame when it detects facebangSetupChar ~= character
end)

-- 
-- CONFIGURATION
-- 
local VALID_KEY = "zzzen"
local SCRIPT_VERSION = "v2.0"
local SCRIPT_NAME = "Eternity"
local IsKeyVerified = false

-- globals
local TargetPlayer = nil
local ctxTargetPlayer = nil
local FacebangTarget = nil
HeadsitTarget = nil
BackhugTarget = nil
ProposeTarget = nil
BagpackTarget = nil
GoonTarget = nil
HipbangTarget = nil
local PatTarget = nil
local FacebangSpeed = 2.5
local FacebangDistance = 2.0
HipbangSpeed = 2.5
HipbangDistance = 2.0
-- Global: selected Big Baseplate color (shared between page and engine)
_bigBPSelectedColor = Color3.fromRGB(128, 128, 128)
_bigBPGrid = {}

-- Global: selected UI Theme color
_themeColor = nil

-- feature toggle states
local FeatureStates = {
    ContextMenu = false,
    AdminDisabled = false,
    GlitchMoveEnabled = false,
    GlitchMoveActive = false,
    SupermanFlyEnabled = false,
    SupermanFlyActive = false,
    FacebangEnabled = false, -- UI toggle arms the keybind
    Facebang = false,        -- actual active state (keybind activates)
    PatEnabled = false,
    Pat = false,
    HeadsitEnabled = false,
    Headsit = false,
    BackhugEnabled = false,
    Backhug = false,
    FronthugEnabled = false,
    Fronthug = false,
    ProposeEnabled = false,
    Propose = false,
    HipbangEnabled = false,
    Hipbang = false,
    BagpackEnabled = false,
    Bagpack = false,
    GoonEnabled = false,
    Goon = false,
    ClickToTarget = false,
    ViewTarget = false,
    Noclip = false,
    ClickTeleport = false,
    AnimatedTeleport = false,
    Trip = false,
    Reverse = false,
    InfiniteJump = false,
    SpeedBoost = false,
    BigBaseplateActive = false,
    ESP = false,
    Fullbright = false,
    NoFog = false,
    ChatSpamActive = false,
    VCBypassActive = false,  -- VC bypass has been activated
    FakeoutEnabled = false,  -- Fakeout armed (toggle)
    GhostBaitEnabled = false, -- Ghost Bait armed (toggle)
    ExtremeGlitchDesyncEnabled = false,
    NormalGlitchDesyncEnabled = false,
    HiddenPlayers = {},
    
    -- Auto Execute Settings
    AutoFacebang = false,
    AutoInfiniteJump = false,
    AutoSpeedBoost = false,
    AutoNoclip = false,
    AutoClickTeleport = false,
    AutoAnimatedTeleport = false,

    AutoGlitch = false,
    AutoTrip = false,
    AutoReverse = false,
    AutoPat = false,
    SavedAnimations = {},
    FavoriteAnimations = {},
    ForceWalkAnimation = false,
    GoUnderground = false,
}

local ToggleRegistry = {}
local GridButtonVisuals = {}
local AttachFeatures = {"Facebang", "Hipbang", "Pat", "Headsit", "Backhug", "Propose", "Fronthug", "Bagpack", "Goon"}

local function SetAttachState(featureName, on)
    if on then
        for _, otherFeature in ipairs(AttachFeatures) do
            if otherFeature ~= featureName and FeatureStates[otherFeature] then
                FeatureStates[otherFeature] = false
                if GridButtonVisuals[otherFeature] then
                    GridButtonVisuals[otherFeature](false)
                end
                if otherFeature == "Facebang" then FacebangTarget = nil
                elseif otherFeature == "Hipbang" then HipbangTarget = nil
                elseif otherFeature == "Pat" then PatTarget = nil
                elseif otherFeature == "Headsit" then HeadsitTarget = nil
                elseif otherFeature == "Backhug" then BackhugTarget = nil
                elseif otherFeature == "Fronthug" then FronthugTarget = nil
                elseif otherFeature == "Propose" then ProposeTarget = nil
                elseif otherFeature == "Bagpack" then BagpackTarget = nil
                elseif otherFeature == "Goon" then GoonTarget = nil
                end
            end
        end
    end
    FeatureStates[featureName] = on
    if GridButtonVisuals[featureName] then
        GridButtonVisuals[featureName](on)
    end
    if _G.SetActiveFeature then
        _G.SetActiveFeature(on and featureName or nil)
    end
end

local CONFIG_FILE = "eternity_config.json"

local Keybinds = {
    GlitchMove = Enum.KeyCode.G,
    SupermanFly = Enum.KeyCode.H,
    ClickTeleport = Enum.KeyCode.F,
    AnimatedTeleport = Enum.KeyCode.F,
    Trip = Enum.KeyCode.T,
    Reverse = Enum.KeyCode.R,
    Facebang = Enum.KeyCode.Z,
    Pat = Enum.KeyCode.P,
    Headsit = Enum.KeyCode.X,
    Backhug = Enum.KeyCode.B,
    Fronthug = Enum.KeyCode.M,
    Propose = Enum.KeyCode.V,
    Hipbang = Enum.KeyCode.N,
    Bagpack = Enum.KeyCode.J,
    Goon = Enum.KeyCode.N,
    Fakeout = Enum.KeyCode.K,
    GhostBait = Enum.KeyCode.J,
    GlitchDesync = Enum.KeyCode.L,
    GoUnderground = Enum.KeyCode.U,
}

-- SpeedMultiplier declared here so both saveSettings and loadSettings
-- can read/write it as an upvalue (Lua closure capture is at definition time)
local SpeedMultiplier = 100

local function saveSettings()
    pcall(function()
        if writefile and typeof(writefile) == "function" then
            local data = {
                SpeedValue = SpeedMultiplier,
                Bind_GlitchMove = Keybinds.GlitchMove.Name,
                Bind_ClickTeleport = Keybinds.ClickTeleport.Name,
                Bind_AnimatedTeleport = Keybinds.AnimatedTeleport.Name,
                Bind_Trip = Keybinds.Trip.Name,
                Bind_Reverse = Keybinds.Reverse.Name,
                Bind_Facebang = Keybinds.Facebang.Name,
                Bind_Pat = Keybinds.Pat.Name,
                Bind_Headsit = Keybinds.Headsit.Name,
                Bind_Backhug = Keybinds.Backhug.Name,
                Bind_Fronthug = Keybinds.Fronthug.Name,
                Bind_Propose = Keybinds.Propose.Name,
                Bind_Hipbang = Keybinds.Hipbang.Name,
                Bind_Bagpack = Keybinds.Bagpack.Name,
                Bind_Goon = Keybinds.Goon.Name,
                Bind_Fakeout = Keybinds.Fakeout.Name,
                Bind_GhostBait = Keybinds.GhostBait.Name,
                Bind_GlitchDesync = Keybinds.GlitchDesync.Name,
                Bind_GoUnderground = Keybinds.GoUnderground.Name,
                SavedAnimations = FeatureStates.SavedAnimations,
                FavoriteAnimations = FeatureStates.FavoriteAnimations,
                BigBaseplateColorR = math.floor(_bigBPSelectedColor.R * 255 + 0.5),
                BigBaseplateColorG = math.floor(_bigBPSelectedColor.G * 255 + 0.5),
                BigBaseplateColorB = math.floor(_bigBPSelectedColor.B * 255 + 0.5),
                ThemeColorR = _themeColor and math.floor(_themeColor.R * 255 + 0.5) or nil,
                ThemeColorG = _themeColor and math.floor(_themeColor.G * 255 + 0.5) or nil,
                ThemeColorB = _themeColor and math.floor(_themeColor.B * 255 + 0.5) or nil,
                Toggles = {}
            }
            
            local featuresToSave = {
                Noclip = true, InfiniteJump = true, ClickTeleport = true, AnimatedTeleport = true, Trip = true, Reverse = true,
                GlitchMoveEnabled = true, SupermanFlyEnabled = true, SpeedBoost = true,
                ForceWalkAnimation = true,
                BigBaseplateActive = true,
                FacebangEnabled = true, PatEnabled = true, HeadsitEnabled = true, BackhugEnabled = true, FronthugEnabled = true, ProposeEnabled = true, HipbangEnabled = true, BagpackEnabled = true, GoonEnabled = true,
                FakeoutEnabled = true,
                GhostBaitEnabled = true,
                ExtremeGlitchDesyncEnabled = true, NormalGlitchDesyncEnabled = true,
                AntiHeadsit = true, AntiFacebang = true, AntiKidnap = true, AntiVoid = true, InfFallVoid = true
            }

            for k, _ in pairs(ToggleRegistry) do
                if featuresToSave[k] and FeatureStates[k] then
                    data.Toggles[k] = true
                end
            end
            local success, content = pcall(function()
                return game:GetService("HttpService"):JSONEncode(data)
            end)
            if success then
                writefile(CONFIG_FILE, content)
            end
        end
    end)
end

local function loadSettings()
    pcall(function()
        if readfile and typeof(readfile) == "function" then
            if isfile and typeof(isfile) == "function" and isfile(CONFIG_FILE) then
                local content = readfile(CONFIG_FILE)
                local success, data = pcall(function()
                    return game:GetService("HttpService"):JSONDecode(content)
                end)
                if success and typeof(data) == "table" then
                    if data.Toggles and typeof(data.Toggles) == "table" then
                        local allowedToggles = {
                            Noclip = true, InfiniteJump = true, ClickTeleport = true, AnimatedTeleport = true, Trip = true, Reverse = true,
                            GlitchMoveEnabled = true, SupermanFlyEnabled = true, SpeedBoost = true,
                            BigBaseplateActive = true,
                            FacebangEnabled = true, PatEnabled = true, HeadsitEnabled = true, BackhugEnabled = true, FronthugEnabled = true, ProposeEnabled = true, HipbangEnabled = true, BagpackEnabled = true, GoonEnabled = true,
                            FakeoutEnabled = true,
                            GhostBaitEnabled = true,
                            ExtremeGlitchDesyncEnabled = true, NormalGlitchDesyncEnabled = true,
                            AntiHeadsit = true, AntiFacebang = true, AntiKidnap = true, AntiVoid = true, InfFallVoid = true
                        }
                        for k, v in pairs(data.Toggles) do
                            if allowedToggles[k] then
                                FeatureStates[k] = v
                            end
                        end
                    end
                    -- fallback for old format auto executes
                    if data.AutoFacebang then FeatureStates.FacebangEnabled = true end
                    if data.AutoInfiniteJump then FeatureStates.InfiniteJump = true end
                    if data.AutoSpeedBoost then FeatureStates.SpeedBoost = true end
                    if data.AutoNoclip then FeatureStates.Noclip = true end
                    if data.AutoClickTeleport then FeatureStates.ClickTeleport = true end
                    if data.AutoAnimatedTeleport then FeatureStates.AnimatedTeleport = true end
                    if data.AutoGlitch then FeatureStates.GlitchMoveEnabled = true end
                    if data.AutoTrip then FeatureStates.Trip = true end
                    if data.AutoReverse then FeatureStates.Reverse = true end
                    if data.AutoPat then FeatureStates.PatEnabled = true end
                    if data.AutoHeadsit then FeatureStates.HeadsitEnabled = true end
                    if data.AutoBackhug then FeatureStates.BackhugEnabled = true end
                    if data.AutoFronthug then FeatureStates.FronthugEnabled = true end
                    if data.AutoPropose then FeatureStates.ProposeEnabled = true end
                    if data.AutoHipbang then FeatureStates.HipbangEnabled = true end
                    if data.AutoBagpack then FeatureStates.BagpackEnabled = true end
                    if data.AutoGoon then FeatureStates.GoonEnabled = true end

                    if data.SpeedValue and tonumber(data.SpeedValue) and tonumber(data.SpeedValue) > 0 then
                        SpeedMultiplier = tonumber(data.SpeedValue)
                    end
                    if data.FacebangSpeedValue and tonumber(data.FacebangSpeedValue) then
                        FacebangSpeed = tonumber(data.FacebangSpeedValue)
                    end
                    if data.FacebangDistanceValue and tonumber(data.FacebangDistanceValue) then
                        FacebangDistance = tonumber(data.FacebangDistanceValue)
                    end
                    if data.HipbangSpeedValue and tonumber(data.HipbangSpeedValue) then
                        HipbangSpeed = tonumber(data.HipbangSpeedValue)
                    end
                    if data.HipbangDistanceValue and tonumber(data.HipbangDistanceValue) then
                        HipbangDistance = tonumber(data.HipbangDistanceValue)
                    end
                    if data.BigBaseplateColorR and data.BigBaseplateColorG and data.BigBaseplateColorB then
                        pcall(function()
                            _bigBPSelectedColor = Color3.fromRGB(
                                tonumber(data.BigBaseplateColorR) or 128,
                                tonumber(data.BigBaseplateColorG) or 128,
                                tonumber(data.BigBaseplateColorB) or 128
                            )
                        end)
                    end
                    if data.ThemeColorR and data.ThemeColorG and data.ThemeColorB then
                        pcall(function()
                            _themeColor = Color3.fromRGB(
                                tonumber(data.ThemeColorR) or 245,
                                tonumber(data.ThemeColorG) or 190,
                                tonumber(data.ThemeColorB) or 75
                            )
                        end)
                    end
                    if data.Bind_GlitchMove then pcall(function() Keybinds.GlitchMove = Enum.KeyCode[data.Bind_GlitchMove] end) end
                    if data.Bind_ClickTeleport then pcall(function() Keybinds.ClickTeleport = Enum.KeyCode[data.Bind_ClickTeleport] end) end
                    if data.Bind_AnimatedTeleport then pcall(function() Keybinds.AnimatedTeleport = Enum.KeyCode[data.Bind_AnimatedTeleport] end) end
                    if data.Bind_Trip then pcall(function() Keybinds.Trip = Enum.KeyCode[data.Bind_Trip] end) end
                    if data.Bind_Reverse then pcall(function() Keybinds.Reverse = Enum.KeyCode[data.Bind_Reverse] end) end
                    if data.Bind_Facebang then pcall(function() Keybinds.Facebang = Enum.KeyCode[data.Bind_Facebang] end) end
                    if data.Bind_Pat then pcall(function() Keybinds.Pat = Enum.KeyCode[data.Bind_Pat] end) end
                    if data.Bind_Headsit then pcall(function() Keybinds.Headsit = Enum.KeyCode[data.Bind_Headsit] end) end
                    if data.Bind_Backhug then pcall(function() Keybinds.Backhug = Enum.KeyCode[data.Bind_Backhug] end) end
                    if data.Bind_Fronthug then pcall(function() Keybinds.Fronthug = Enum.KeyCode[data.Bind_Fronthug] end) end
                    if data.Bind_Propose then pcall(function() Keybinds.Propose = Enum.KeyCode[data.Bind_Propose] end) end
                    if data.Bind_Hipbang then pcall(function() Keybinds.Hipbang = Enum.KeyCode[data.Bind_Hipbang] end) end
                    if data.Bind_Bagpack then pcall(function() Keybinds.Bagpack = Enum.KeyCode[data.Bind_Bagpack] end) end
                    if data.Bind_Goon then pcall(function() Keybinds.Goon = Enum.KeyCode[data.Bind_Goon] end) end
                    if data.Bind_Fakeout then pcall(function() Keybinds.Fakeout = Enum.KeyCode[data.Bind_Fakeout] end) end
                    if data.Bind_GhostBait then pcall(function() Keybinds.GhostBait = Enum.KeyCode[data.Bind_GhostBait] end) end
                    if data.Bind_GlitchDesync then pcall(function() Keybinds.GlitchDesync = Enum.KeyCode[data.Bind_GlitchDesync] end) end
                    if data.Bind_GoUnderground then pcall(function() Keybinds.GoUnderground = Enum.KeyCode[data.Bind_GoUnderground] end) end
                    if data.SavedAnimations and typeof(data.SavedAnimations) == "table" then FeatureStates.SavedAnimations = data.SavedAnimations end
                    if data.FavoriteAnimations and typeof(data.FavoriteAnimations) == "table" then FeatureStates.FavoriteAnimations = data.FavoriteAnimations end
                end
            end
        end
    end)
end

local function runAutoExecutes()
    task.spawn(function()
        task.wait(1.5) -- wait longer so humanoid/rootPart are ready

        for key, setToggle in pairs(ToggleRegistry) do
            if FeatureStates[key] then
                pcall(function() setToggle(true) end)
            end
        end
    end)
end

loadSettings()
local ChatSpamMessage = ""
local ChatSpamDelay = 1.0
local OriginalAmbient = Lighting.Ambient
local OriginalFogEnd = Lighting.FogEnd
local OriginalBrightness = Lighting.Brightness
local OriginalShadows = Lighting.GlobalShadows
local OriginalDiffuse = Lighting.EnvironmentDiffuseScale
local OriginalSpecular = Lighting.EnvironmentSpecularScale

-- 
-- COLOR PALETTE (Dark Glassmorphism)
-- 
local C = {
    bg              = Color3.fromRGB(8, 8, 8),
    bgCard          = Color3.fromRGB(14, 14, 14),
    surface         = Color3.fromRGB(20, 20, 20),
    surfaceHover    = Color3.fromRGB(28, 28, 28),
    input           = Color3.fromRGB(24, 24, 24),
    accent          = _themeColor or Color3.fromRGB(245, 190, 75),
    accentDim       = _themeColor and Color3.new(_themeColor.R * 0.75, _themeColor.G * 0.75, _themeColor.B * 0.75) or Color3.fromRGB(180, 140, 50),
    accentGlow      = _themeColor or Color3.fromRGB(245, 190, 75),
    danger          = Color3.fromRGB(230, 70, 70),
    dangerDim       = Color3.fromRGB(160, 50, 50),
    success         = Color3.fromRGB(80, 220, 140),
    warning         = Color3.fromRGB(240, 180, 60),
    text            = Color3.fromRGB(220, 220, 228),
    textMuted       = Color3.fromRGB(100, 100, 115),
    textDim         = Color3.fromRGB(60, 60, 72),
    white           = Color3.fromRGB(245, 245, 250),
    black           = Color3.fromRGB(6, 6, 8),
    toggleOn        = _themeColor or Color3.fromRGB(245, 190, 75),
    toggleOff       = Color3.fromRGB(50, 50, 60),
    toggleKnob      = Color3.fromRGB(240, 240, 245),
    divider         = Color3.fromRGB(35, 35, 45),
    sidebarBg       = Color3.fromRGB(12, 12, 16),
    sidebarIcon     = Color3.fromRGB(160, 160, 170),
    sidebarActive   = _themeColor or Color3.fromRGB(245, 190, 75),
    statsBg         = Color3.fromRGB(18, 18, 24),
}

local function getRGBString(c)
    return math.floor(c.R*255+0.5)..","..math.floor(c.G*255+0.5)..","..math.floor(c.B*255+0.5)
end
local accentRgbStr = getRGBString(C.accent)

-- 
-- UTILITY FUNCTIONS
-- 
local function tween(obj, props, dur, style, dir)
    if not obj or not obj.Parent then return end
    local info = TweenInfo.new(dur or 0.3, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
end

local function tweenWait(obj, props, dur, style, dir)
    if not obj or not obj.Parent then return end
    local info = TweenInfo.new(dur or 0.3, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    tw.Completed:Wait()
end

local function corner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 8)
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or C.accent
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.6
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

local function padding(parent, t, b, l, r)
    local p = Instance.new("UIPadding", parent)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    return p
end

local function gradient(parent, c1, c2, rotation)
    local g = Instance.new("UIGradient", parent)
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rotation or 90
    return g
end

local function sendChat(msg)
    task.spawn(function()
        pcall(function()
            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if channel then channel:SendAsync(msg) end
            else
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
            end
        end)
    end)
end

local function getTimeGreeting()
    local hour = tonumber(os.date("%H"))
    if hour < 12 then return "Good morning"
    elseif hour < 17 then return "Good afternoon"
    elseif hour < 21 then return "Good evening"
    else return "Good night" end
end

local function getExecutorName()
    local name = "Unknown"
    pcall(function()
        if identifyexecutor then
            name = identifyexecutor()
        elseif getexecutorname then
            name = getexecutorname()
        end
    end)
    return name
end

local function getAccountAge()
    local days = lp.AccountAge
    if days >= 365 then
        return math.floor(days / 365) .. " Years"
    elseif days >= 30 then
        return math.floor(days / 30) .. " Months"
    else
        return days .. " Days"
    end
end

-- 
-- SCREEN GUI
-- 
-- cleanup any existing eternity gui (fixes lag from multiple executions)
if getgenv().EternityV1_UI then
    pcall(function() getgenv().EternityV1_UI:Destroy() end)
end
pcall(function()
    if gethui then
        local existing = gethui():FindFirstChild("EternityV1")
        if existing then existing:Destroy() end
    end
    local existing2 = game:GetService("CoreGui"):FindFirstChild("EternityV1")
    if existing2 then existing2:Destroy() end
    local existing3 = lp:WaitForChild("PlayerGui"):FindFirstChild("EternityV1")
    if existing3 then existing3:Destroy() end
end)

local sg = Instance.new("ScreenGui")
sg.Name = "EternityV1"
getgenv().EternityV1_UI = sg

-- 
-- ASSET LOADER (Images only)
-- 
local getasset = getcustomasset or getsynasset
local repoBase = "https://raw.githubusercontent.com/hor1zencodes/assets/main/"

local function getAssetUrl(fileName)
    if getasset and isfile and readfile and writefile then
        local filePath = "ZenV1_Media_v2/" .. fileName
        if not isfolder("ZenV1_Media_v2") then makefolder("ZenV1_Media_v2") end
        
        local needsDownload = true
        if isfile(filePath) then
            local success, content = pcall(function() return readfile(filePath) end)
            if success and content and string.len(content) > 100 then
                needsDownload = false
            end
        end

        if needsDownload then
            pcall(function()
                local data = game:HttpGet(repoBase .. fileName)
                if data and string.len(data) > 100 and not string.find(data, "404: Not Found") then
                    writefile(filePath, data)
                end
            end)
        end
        
        if isfile(filePath) then
            return getasset(filePath)
        end
    end
    return repoBase .. fileName
end

local LogoAssetUrl = "rbxassetid://139175707588865"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- executor compatibility: try gethui > CoreGui > PlayerGui
local guiParent
pcall(function()
    if gethui then
        guiParent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(sg)
        guiParent = game:GetService("CoreGui")
    end
end)
sg.Parent = guiParent or lp:WaitForChild("PlayerGui")

-- 
-- SOUND EFFECTS
-- Parented to the ScreenGui so they are safe & non-blocking
-- 
local function makeSound(id, volume)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = volume or 0.6
    s.RollOffMaxDistance = 0
    s.Parent = sg
    return s
end

local SFX_LAUNCH = makeSound("rbxassetid://123360185505109", 0.7)
local SFX_CLICK  = makeSound("rbxassetid://116271631941040", 0.5)

local function playClick()
    pcall(function()
        SFX_CLICK:Stop()
        SFX_CLICK.TimePosition = 0
        SFX_CLICK:Play()
    end)
end

-- 

-- 
-- MAIN GUI (hidden until key verified)
-- 
mainFrame = Instance.new("Frame", sg)
mainFrame.Name = "MainGUI"
mainFrame.AnchorPoint = Vector2.new(0, 1)
mainFrame.Size = UDim2.new(1, -40, 0.65, 0) -- 100% width - 40px padding, 65% height
local mainSizeConstraint = Instance.new("UISizeConstraint", mainFrame)
mainSizeConstraint.MaxSize = Vector2.new(500, math.huge)
mainFrame.Position = UDim2.new(0, 20, 1, -85) -- Left side X, Bottom Y
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.ClipsDescendants = false
corner(mainFrame, 16) -- Curved top edges only

mainGradient = Instance.new("UIGradient", mainFrame)
mainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 24)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 8))
})
mainGradient.Rotation = 90

local mainBgImage = Instance.new("ImageLabel", mainFrame)
mainBgImage.Name = "BgImage"
mainBgImage.Size = UDim2.new(1, 0, 1, 0)
mainBgImage.Position = UDim2.new(0, 0, 0, 0)
mainBgImage.BackgroundTransparency = 1
mainBgImage.ImageTransparency = 0.55
mainBgImage.ScaleType = Enum.ScaleType.Crop
mainBgImage.Image = "rbxassetid://72660622902200"
mainBgImage.ImageColor3 = C.accent
mainBgImage.ZIndex = 0
corner(mainBgImage, 16)

-- Bottom corner mask: covers rounded bottom corners to make them sharp
    
    mainStroke = stroke(mainFrame, C.accent, 2.5, 0)
strokeGradient = Instance.new("UIGradient", mainStroke)
strokeGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.45, 1),
    NumberSequenceKeypoint.new(0.5, 0), -- Static white line
    NumberSequenceKeypoint.new(0.55, 1),
    NumberSequenceKeypoint.new(1, 1)
})

-- 
-- MAIN GUI TITLE BAR (minimize / close)
-- 
titleBar = Instance.new("Frame", mainFrame)
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = C.bgCard
titleBar.BackgroundTransparency = 1
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 10
corner(titleBar, 16)

floatingTopContainer = Instance.new("CanvasGroup", sg)
floatingTopContainer.Name = "FloatingTopContainer"
floatingTopContainer.AnchorPoint = Vector2.new(0.5, 1)
floatingTopContainer.Size = UDim2.new(0, 500, 0, 125)
floatingTopContainer.Position = UDim2.new(0, 270, 0.25, -30)
floatingTopContainer.BackgroundTransparency = 1
floatingTopContainer.GroupTransparency = 1
floatingTopContainer.Visible = false
floatingTopContainer.ZIndex = 100

local floatingLayout = Instance.new("UIListLayout", floatingTopContainer)
floatingLayout.FillDirection = Enum.FillDirection.Vertical
floatingLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
floatingLayout.VerticalAlignment = Enum.VerticalAlignment.Top
floatingLayout.SortOrder = Enum.SortOrder.LayoutOrder
floatingLayout.Padding = UDim.new(0, 8)

local infoCard = Instance.new("ImageLabel", floatingTopContainer)
infoCard.Name = "InfoCard"
infoCard.Size = UDim2.new(1, 0, 0, 125)
infoCard.BackgroundColor3 = C.bgCard
infoCard.BorderSizePixel = 0
infoCard.LayoutOrder = 1
infoCard.Image = "rbxassetid://72660622902200"
infoCard.ImageColor3 = C.accent
infoCard.ImageTransparency = 0.5
infoCard.ScaleType = Enum.ScaleType.Crop
corner(infoCard, 14)
infoCardStroke = stroke(infoCard, C.accent, 2.5, 0)
infoCardGradient = Instance.new("UIGradient", infoCardStroke)
infoCardGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.45, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(0.55, 1),
    NumberSequenceKeypoint.new(1, 1)
})

local infoLayout = Instance.new("UIListLayout", infoCard)
infoLayout.FillDirection = Enum.FillDirection.Vertical
infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
infoLayout.Padding = UDim.new(0, 0)



do
    titleText = Instance.new("TextLabel", titleBar)
    titleText.Size = UDim2.new(1, 0, 1, 0)
    titleText.Position = UDim2.new(0, 80, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "ETERNITY"
    titleText.RichText = true
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 13
    titleText.TextColor3 = C.accent
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.ZIndex = 11

    titleLogo = Instance.new("ImageLabel", titleBar)
    titleLogo.Size = UDim2.new(0, 60, 0, 16)
    titleLogo.Position = UDim2.new(0, 12, 0.5, -8)
    titleLogo.Image = LogoAssetUrl
    titleLogo.BackgroundTransparency = 1
    titleLogo.ScaleType = Enum.ScaleType.Fit
    titleLogo.ZIndex = 11
end

-- FPS & Ping Container
fpsPingContainer = Instance.new("Frame", titleBar)
fpsPingContainer.Size = UDim2.new(0, 200, 1, 0)
fpsPingContainer.Position = UDim2.new(0.5, -150, 0, 0)
fpsPingContainer.BackgroundTransparency = 1
fpsPingContainer.Visible = false
fpsPingContainer.ZIndex = 11

fpsLabel = Instance.new("TextLabel", fpsPingContainer)
fpsLabel.Size = UDim2.new(0.5, -10, 1, 0)
fpsLabel.Position = UDim2.new(0, 0, 0, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: --"
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextSize = 11
fpsLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
fpsLabel.ZIndex = 11

-- Active Feature Tracker
task.spawn(function()
    local activeFeatureContainer = Instance.new("Frame", titleBar)
    activeFeatureContainer.Name = "ActiveFeatureTracker"
    activeFeatureContainer.AnchorPoint = Vector2.new(1, 0.5)
    activeFeatureContainer.Size = UDim2.new(0, 0, 0, 20)
    activeFeatureContainer.Position = UDim2.new(1, -95, 0.5, 0)
    activeFeatureContainer.AutomaticSize = Enum.AutomaticSize.X
    activeFeatureContainer.BackgroundColor3 = Color3.fromRGB(15, 28, 20)
    activeFeatureContainer.BorderSizePixel = 0
    activeFeatureContainer.Visible = false
    activeFeatureContainer.ZIndex = 11
    corner(activeFeatureContainer, 10)
    
    local pad = Instance.new("UIPadding", activeFeatureContainer)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)

    local trackerStroke = stroke(activeFeatureContainer, Color3.fromRGB(60, 180, 100), 1.2, 0.5)

    local cw = Instance.new("Frame", activeFeatureContainer)
    cw.Size = UDim2.new(1, 0, 1, 0)
    cw.BackgroundTransparency = 1
    cw.ZIndex = 11

    local ll = Instance.new("UIListLayout", cw)
    ll.FillDirection = Enum.FillDirection.Horizontal
    ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ll.VerticalAlignment = Enum.VerticalAlignment.Center
    ll.Padding = UDim.new(0, 6)

    local dc = Instance.new("Frame", cw)
    dc.Size = UDim2.new(0, 14, 0, 14)
    dc.BackgroundTransparency = 1
    dc.LayoutOrder = 1
    dc.ZIndex = 11

    local statusGlow = Instance.new("Frame", dc)
    statusGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    statusGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    statusGlow.Size = UDim2.new(0, 12, 0, 12)
    statusGlow.BackgroundColor3 = Color3.fromRGB(80, 220, 130)
    statusGlow.BackgroundTransparency = 0.8
    statusGlow.BorderSizePixel = 0
    statusGlow.ZIndex = 11
    corner(statusGlow, 6)

    local statusDot = Instance.new("Frame", dc)
    statusDot.AnchorPoint = Vector2.new(0.5, 0.5)
    statusDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    statusDot.Size = UDim2.new(0, 6, 0, 6)
    statusDot.BackgroundColor3 = Color3.fromRGB(80, 220, 130)
    statusDot.BorderSizePixel = 0
    statusDot.ZIndex = 12
    corner(statusDot, 3)

    local activeFeatureLabel = Instance.new("TextLabel", cw)
    activeFeatureLabel.AutomaticSize = Enum.AutomaticSize.X
    activeFeatureLabel.Size = UDim2.new(0, 0, 1, 0)
    activeFeatureLabel.BackgroundTransparency = 1
    activeFeatureLabel.Text = "Feature is active"
    activeFeatureLabel.RichText = true
    activeFeatureLabel.Font = Enum.Font.Gotham
    activeFeatureLabel.TextSize = 10
    activeFeatureLabel.TextColor3 = Color3.fromRGB(80, 220, 130)
    activeFeatureLabel.TextXAlignment = Enum.TextXAlignment.Center
    activeFeatureLabel.LayoutOrder = 2
    activeFeatureLabel.ZIndex = 12

    local isPulsing = false

    task.spawn(function()
        while statusGlow and statusGlow.Parent do
            if activeFeatureContainer.Visible and isPulsing then
                tweenWait(statusGlow, {Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 0.6}, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tweenWait(statusGlow, {Size = UDim2.new(0, 10, 0, 10), BackgroundTransparency = 0.8}, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            else
                task.wait(0.2)
            end
        end
    end)

    local featureToKey = {
        ["Glitch Movement"] = "GlitchMove",
        ["Extreme Glitch Desync"] = "ExtremeGlitchDesync",
        ["Normal Glitch Desync"] = "NormalGlitchDesync",
        ["Facebang"] = "Facebang",
        ["Hipbang"] = "Hipbang",
        ["Fronthug"] = "Fronthug",
        ["Backhug"] = "Backhug",
        ["Headsit"] = "Headsit",
        ["Pat"] = "Pat",
        ["Goon"] = "Goon",
        ["Propose"] = "Propose",
        ["Bagpack"] = "Bagpack",
        ["Fakeout"] = "Fakeout"
    }

    _G.SetActiveFeature = function(featureName)
        if featureName then
            local keybindStr = ""
            local kbName = featureToKey[featureName]
            if kbName and Keybinds and Keybinds[kbName] then
                keybindStr = " <font color='rgb(80, 110, 80)'>[" .. Keybinds[kbName].Name .. "]</font>"
            end
            activeFeatureLabel.Text = "<b>" .. tostring(featureName) .. "</b>" .. keybindStr
            if not activeFeatureContainer.Visible then
                isPulsing = true
                activeFeatureContainer.Visible = true
                activeFeatureContainer.BackgroundTransparency = 1
                if trackerStroke then trackerStroke.Transparency = 1 end
                activeFeatureLabel.TextTransparency = 1
                statusDot.BackgroundTransparency = 1
                statusGlow.BackgroundTransparency = 1
                tween(activeFeatureContainer, {BackgroundTransparency = 0}, 0.3)
                if trackerStroke then tween(trackerStroke, {Transparency = 0.5}, 0.3) end
                tween(activeFeatureLabel, {TextTransparency = 0}, 0.3)
                tween(statusDot, {BackgroundTransparency = 0}, 0.3)
                tween(statusGlow, {BackgroundTransparency = 0.8}, 0.3)
            end
        else
            isPulsing = false
            tween(activeFeatureContainer, {BackgroundTransparency = 1}, 0.3)
            if trackerStroke then tween(trackerStroke, {Transparency = 1}, 0.3) end
            tween(activeFeatureLabel, {TextTransparency = 1}, 0.3)
            tween(statusDot, {BackgroundTransparency = 1}, 0.3)
            tween(statusGlow, {BackgroundTransparency = 1}, 0.3)
            task.delay(0.3, function()
                activeFeatureContainer.Visible = false
            end)
        end
    end
end)

pingLabel = Instance.new("TextLabel", fpsPingContainer)
pingLabel.Size = UDim2.new(0.5, -10, 1, 0)
pingLabel.Position = UDim2.new(0.5, 10, 0, 0)
pingLabel.BackgroundTransparency = 1
pingLabel.Text = "Ping: --"
pingLabel.Font = Enum.Font.GothamBold
pingLabel.TextSize = 11
pingLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
pingLabel.TextXAlignment = Enum.TextXAlignment.Left
pingLabel.ZIndex = 11

task.spawn(function()
    local RS = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    local lastUpdate = tick()
    local frames = 0
    RS.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - lastUpdate >= 1 then
            local fps = math.floor(frames / (now - lastUpdate))
            if fpsLabel then fpsLabel.Text = "FPS: " .. tostring(fps) end
            frames = 0
            lastUpdate = now
            pcall(function()
                local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                if pingLabel then pingLabel.Text = "Ping: " .. tostring(ping) .. "ms" end
            end)
        end
    end)
end)
-- mini tag toggle
miniTagLabel = Instance.new("TextLabel", titleBar)
miniTagLabel.Size = UDim2.new(0, 32, 0, 12)
miniTagLabel.Position = UDim2.new(0, 80, 0.5, -6)
miniTagLabel.BackgroundTransparency = 1
miniTagLabel.Text = "TAGS"
miniTagLabel.Font = Enum.Font.GothamBold
miniTagLabel.TextSize = 10
miniTagLabel.TextColor3 = C.accent
miniTagLabel.TextXAlignment = Enum.TextXAlignment.Left
miniTagLabel.Visible = false
miniTagLabel.ZIndex = 11

miniTagBtn = Instance.new("TextButton", titleBar)
miniTagBtn.Size = UDim2.new(0, 24, 0, 12)
miniTagBtn.Position = UDim2.new(0, 115, 0.5, -6)
miniTagBtn.Text = ""
miniTagBtn.BackgroundColor3 = C.success
miniTagBtn.AutoButtonColor = false
miniTagBtn.Visible = false
miniTagBtn.ZIndex = 11
corner(miniTagBtn, 6)

miniTagKnob = Instance.new("Frame", miniTagBtn)
miniTagKnob.Size = UDim2.new(0, 8, 0, 8)
miniTagKnob.Position = UDim2.new(1, -10, 0.5, -4)
miniTagKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
miniTagKnob.ZIndex = 11
corner(miniTagKnob, 4)

local isMinimized = false
local preMiniSize = UDim2.new(0, 500, 0.65, 0)

local function animateDockMinimize(minimized)
    if not dockContainer then return end
    if minimized then
        tween(dockContainer, {Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0.5, 0, 1, 9)}, 0.3, Enum.EasingStyle.Quint)
        if topNav then
            for _, child in ipairs(topNav:GetChildren()) do
                if child:IsA("TextButton") and string.sub(child.Name, 1, 3) == "SB_" then
                    local icon = child:FindFirstChildOfClass("ImageLabel")
                    if icon then tween(icon, {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(0, 18, 0.5, -12)}, 0.3, Enum.EasingStyle.Quint) end
                end
            end
        end
    else
        tween(dockContainer, {Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0.5, 0, 1, 25)}, 0.3, Enum.EasingStyle.Quint)
        if topNav then
            for _, child in ipairs(topNav:GetChildren()) do
                if child:IsA("TextButton") and string.sub(child.Name, 1, 3) == "SB_" then
                    local icon = child:FindFirstChildOfClass("ImageLabel")
                    if icon then tween(icon, {Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(0, 12, 0.5, -18)}, 0.3, Enum.EasingStyle.Quint) end
                end
            end
        end
    end
end

-- minimize button
do
    local miniBtn = Instance.new("TextButton", titleBar)
    miniBtn.Size = UDim2.new(0, 12, 0, 12)
    miniBtn.Position = UDim2.new(1, -38, 0.5, -6)
    miniBtn.Text = ""
    miniBtn.BackgroundColor3 = Color3.fromRGB(255, 189, 46) -- Mac Yellow
    miniBtn.BorderSizePixel = 0
    miniBtn.AutoButtonColor = false
    miniBtn.ZIndex = 11
    corner(miniBtn, 12)

    miniBtn.MouseEnter:Connect(function()
        tween(miniBtn, {BackgroundColor3 = Color3.fromRGB(255, 209, 86)}, 0.15)
    end)
    miniBtn.MouseLeave:Connect(function()
        tween(miniBtn, {BackgroundColor3 = Color3.fromRGB(255, 189, 46)}, 0.15)
    end)

    miniBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        local focusedBox = UserInputService:GetFocusedTextBox()
        if focusedBox then focusedBox:ReleaseFocus() end
        if isMinimized then
            fpsPingContainer.Visible = true
            if miniTagLabel then miniTagLabel.Visible = true end
            if titleText then titleText.Visible = false end
            if miniTagBtn then miniTagBtn.Visible = true end
            if floatingTopContainer then
                tween(floatingTopContainer, {GroupTransparency = 1, Position = UDim2.new(floatingTopContainer.Position.X.Scale, floatingTopContainer.Position.X.Offset, 0.25, 10)}, 0.3, Enum.EasingStyle.Quint)
                task.delay(0.3, function() if isMinimized then floatingTopContainer.Visible = false end end)
            end
            if bottomMask then bottomMask.Visible = false end
            animateDockMinimize(true)
            preMiniSize = mainFrame.Size
            tween(mainFrame, {Size = UDim2.new(0, mainFrame.AbsoluteSize.X, 0, 36), Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 1, -45)}, 0.3, Enum.EasingStyle.Quint)
        else
            fpsPingContainer.Visible = false
            if miniTagLabel then miniTagLabel.Visible = false end
            if titleText then titleText.Visible = true end
            if miniTagBtn then miniTagBtn.Visible = false end
            if floatingTopContainer then
                floatingTopContainer.Visible = true
                floatingTopContainer.Position = UDim2.new(floatingTopContainer.Position.X.Scale, floatingTopContainer.Position.X.Offset, 0.25, 10)
                tween(floatingTopContainer, {GroupTransparency = 0, Position = UDim2.new(floatingTopContainer.Position.X.Scale, floatingTopContainer.Position.X.Offset, 0.25, -12)}, 0.3, Enum.EasingStyle.Quint)
            end
            if bottomMask then bottomMask.Visible = true end
            animateDockMinimize(false)
            tween(mainFrame, {Size = preMiniSize, Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 1, -85)}, 0.3, Enum.EasingStyle.Quint)
        end
    end)
end

-- resize button
do
    local maxBtn = Instance.new("TextButton", titleBar)
    maxBtn.Size = UDim2.new(0, 12, 0, 12)
    maxBtn.Position = UDim2.new(1, -56, 0.5, -6)
    maxBtn.Text = ""
    maxBtn.BackgroundColor3 = Color3.fromRGB(40, 201, 64) -- Mac Green
    maxBtn.BorderSizePixel = 0
    maxBtn.AutoButtonColor = false
    maxBtn.ZIndex = 11
    corner(maxBtn, 12)

    maxBtn.MouseEnter:Connect(function()
        tween(maxBtn, {BackgroundColor3 = Color3.fromRGB(50, 221, 74)}, 0.15)
    end)
    maxBtn.MouseLeave:Connect(function()
        tween(maxBtn, {BackgroundColor3 = Color3.fromRGB(40, 201, 64)}, 0.15)
    end)

    local resizing = false
    local resizeStart
    local startAbsSize

    maxBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isMinimized then return end
            resizing = true
            resizeStart = input.Position
            startAbsSize = mainFrame.AbsoluteSize
            
            local connectionMove
            local connectionEnd
            
            connectionMove = UserInputService.InputChanged:Connect(function(changeInput)
                if resizing and (changeInput.UserInputType == Enum.UserInputType.MouseMovement or changeInput.UserInputType == Enum.UserInputType.Touch) then
                    local delta = changeInput.Position - resizeStart
                    local newWidth = math.clamp(startAbsSize.X + delta.X, 400, 2000)
                    local newHeight = math.clamp(startAbsSize.Y - delta.Y, 200, 2000)
                    mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
                end
            end)
            
            connectionEnd = UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                    resizing = false
                    if connectionMove then connectionMove:Disconnect() end
                    if connectionEnd then connectionEnd:Disconnect() end
                end
            end)
        end
    end)
end


UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Comma then
        isMinimized = not isMinimized
        local focusedBox = UserInputService:GetFocusedTextBox()
        if focusedBox then focusedBox:ReleaseFocus() end
        if isMinimized then
            fpsPingContainer.Visible = true
            if miniTagLabel then miniTagLabel.Visible = true end
            if titleText then titleText.Visible = false end
            if miniTagBtn then miniTagBtn.Visible = true end
            if floatingTopContainer then
                tween(floatingTopContainer, {GroupTransparency = 1, Position = UDim2.new(floatingTopContainer.Position.X.Scale, floatingTopContainer.Position.X.Offset, 0.25, 10)}, 0.3, Enum.EasingStyle.Quint)
                task.delay(0.3, function() if isMinimized then floatingTopContainer.Visible = false end end)
            end
            if dockContainer then animateDockMinimize(true) end
            tween(mainFrame, {Size = UDim2.new(0, mainFrame.AbsoluteSize.X, 0, 36), Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 1, -45)}, 0.3, Enum.EasingStyle.Quint)
        else
            fpsPingContainer.Visible = false
            if miniTagLabel then miniTagLabel.Visible = false end
            if titleText then titleText.Visible = true end
            if miniTagBtn then miniTagBtn.Visible = false end
            if floatingTopContainer then
                floatingTopContainer.Visible = true
                floatingTopContainer.Position = UDim2.new(floatingTopContainer.Position.X.Scale, floatingTopContainer.Position.X.Offset, 0.25, 10)
                tween(floatingTopContainer, {GroupTransparency = 0, Position = UDim2.new(floatingTopContainer.Position.X.Scale, floatingTopContainer.Position.X.Offset, 0.25, -12)}, 0.3, Enum.EasingStyle.Quint)
            end
            if dockContainer then animateDockMinimize(false) end
            tween(mainFrame, {Size = preMiniSize, Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 1, -85)}, 0.3, Enum.EasingStyle.Quint)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if not isMinimized and mainFrame and mainFrame.Visible then
            local pos = input.Position
            local ax, ay = mainFrame.AbsolutePosition.X, mainFrame.AbsolutePosition.Y
            local asx, asy = mainFrame.AbsoluteSize.X, mainFrame.AbsoluteSize.Y
            
            local isOutsideMain = pos.X < ax or pos.X > ax + asx or pos.Y < ay or pos.Y > ay + asy
            local isOutsideTop = true
            
            if floatingTopContainer and floatingTopContainer.Visible then
                local tx, ty = floatingTopContainer.AbsolutePosition.X, floatingTopContainer.AbsolutePosition.Y
                local tsx, tsy = floatingTopContainer.AbsoluteSize.X, floatingTopContainer.AbsoluteSize.Y
                isOutsideTop = pos.X < tx or pos.X > tx + tsx or pos.Y < ty or pos.Y > ty + tsy
            end
            
            local isOutsideDock = true
            if dockContainer and dockContainer.Visible then
                local dx, dy = dockContainer.AbsolutePosition.X, dockContainer.AbsolutePosition.Y
                local dsx, dsy = dockContainer.AbsoluteSize.X, dockContainer.AbsoluteSize.Y
                isOutsideDock = pos.X < dx or pos.X > dx + dsx or pos.Y < dy or pos.Y > dy + dsy
            end
            
            -- If click is outside all bounds
            if isOutsideMain and isOutsideTop and isOutsideDock then
                isMinimized = true
                local focusedBox = UserInputService:GetFocusedTextBox()
                if focusedBox then focusedBox:ReleaseFocus() end
                
                fpsPingContainer.Visible = true
                if miniTagLabel then miniTagLabel.Visible = true end
            if titleText then titleText.Visible = false end
                if miniTagBtn then miniTagBtn.Visible = true end
                if floatingTopContainer then
                    tween(floatingTopContainer, {GroupTransparency = 1, Position = UDim2.new(floatingTopContainer.Position.X.Scale, floatingTopContainer.Position.X.Offset, 0.25, 10)}, 0.3, Enum.EasingStyle.Quint)
                    task.delay(0.3, function() if isMinimized then floatingTopContainer.Visible = false end end)
                end
                if bottomMask then bottomMask.Visible = false end
                animateDockMinimize(true)
                preMiniSize = mainFrame.Size
                tween(mainFrame, {Size = UDim2.new(0, mainFrame.AbsoluteSize.X, 0, 36), Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 1, -45)}, 0.3, Enum.EasingStyle.Quint)
            end
        end
    end
end)

-- close button
do
    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0, 12, 0, 12)
    closeBtn.Position = UDim2.new(1, -20, 0.5, -6)
    closeBtn.Text = ""
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 89, 89) -- Mac Red
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 11
    corner(closeBtn, 12)

    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 109, 109)}, 0.15)
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 89, 89)}, 0.15)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)
end

-- make main frame and floating container draggable
local dragging, dragInput, dragStart, startPos, startPosTop

local function handleDragStart(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        if floatingTopContainer then
            startPosTop = floatingTopContainer.Position
        end
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end

mainFrame.InputBegan:Connect(handleDragStart)
if floatingTopContainer then
    floatingTopContainer.InputBegan:Connect(handleDragStart)
end

local function handleDragMove(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end

mainFrame.InputChanged:Connect(handleDragMove)
if floatingTopContainer then
    floatingTopContainer.InputChanged:Connect(handleDragMove)
end

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset)
        if floatingTopContainer and startPosTop then
            floatingTopContainer.Position = UDim2.new(startPosTop.X.Scale, startPosTop.X.Offset + delta.X, startPosTop.Y.Scale, startPosTop.Y.Offset)
        end
    end
end)

-- 
-- TOP NAVIGATION (formerly sidebar)
-- 
dockContainer = Instance.new("Frame", mainFrame)
dockContainer.Name = "BottomDockContainer"
dockContainer.AnchorPoint = Vector2.new(0.5, 0)
dockContainer.Size = UDim2.new(1, 0, 0, 60)
dockContainer.Position = UDim2.new(0.5, 0, 1, 25)
dockContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
dockContainer.BackgroundTransparency = 0
dockContainer.BorderSizePixel = 0
dockContainer.ZIndex = 10
corner(dockContainer, 12)

local dockGradient = Instance.new("UIGradient", dockContainer)
dockGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 24)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 8))
})
dockGradient.Rotation = 90

dockBgImage = Instance.new("ImageLabel", dockContainer)
dockBgImage.Name = "DockBgImage"
dockBgImage.Size = UDim2.new(1, 0, 1, 0)
dockBgImage.BackgroundTransparency = 1
dockBgImage.ImageTransparency = 0.55
dockBgImage.ScaleType = Enum.ScaleType.Crop
dockBgImage.Image = "rbxassetid://72660622902200"
dockBgImage.ImageColor3 = C.accent
dockBgImage.ZIndex = 11
corner(dockBgImage, 12)

topNav = Instance.new("ScrollingFrame", dockContainer)
topNav.Name = "BottomDock"
topNav.Size = UDim2.new(1, 0, 1, 0)
topNav.BackgroundTransparency = 1
topNav.BorderSizePixel = 0
topNav.ScrollBarThickness = 0
topNav.ScrollingDirection = Enum.ScrollingDirection.X
topNav.AutomaticCanvasSize = Enum.AutomaticSize.X
topNav.CanvasSize = UDim2.new(0, 0, 0, 0)
topNav.ZIndex = 12

local topNavLayout = Instance.new("UIListLayout", topNav)
topNavLayout.FillDirection = Enum.FillDirection.Horizontal
topNavLayout.VerticalAlignment = Enum.VerticalAlignment.Center
topNavLayout.SortOrder = Enum.SortOrder.LayoutOrder
topNavLayout.Padding = UDim.new(0, 12)
padding(topNav, 0, 0, 12, 12)

local scrollIndicatorRight = Instance.new("TextLabel", dockContainer)
scrollIndicatorRight.Name = "ScrollIndicatorRight"
scrollIndicatorRight.AnchorPoint = Vector2.new(1, 0.5)
scrollIndicatorRight.Position = UDim2.new(1, -2, 0.5, 0)
scrollIndicatorRight.Size = UDim2.new(0, 20, 0, 20)
scrollIndicatorRight.BackgroundTransparency = 1
scrollIndicatorRight.Text = ">"
scrollIndicatorRight.Font = Enum.Font.GothamBold
scrollIndicatorRight.TextSize = 24
scrollIndicatorRight.TextColor3 = Color3.fromRGB(200, 200, 200)
scrollIndicatorRight.TextTransparency = 0.5
scrollIndicatorRight.ZIndex = 15

local scrollIndicatorLeft = Instance.new("TextLabel", dockContainer)
scrollIndicatorLeft.Name = "ScrollIndicatorLeft"
scrollIndicatorLeft.AnchorPoint = Vector2.new(0, 0.5)
scrollIndicatorLeft.Position = UDim2.new(0, 2, 0.5, 0)
scrollIndicatorLeft.Size = UDim2.new(0, 20, 0, 20)
scrollIndicatorLeft.BackgroundTransparency = 1
scrollIndicatorLeft.Text = "<"
scrollIndicatorLeft.Font = Enum.Font.GothamBold
scrollIndicatorLeft.TextSize = 24
scrollIndicatorLeft.TextColor3 = Color3.fromRGB(200, 200, 200)
scrollIndicatorLeft.TextTransparency = 1 -- hidden initially
scrollIndicatorLeft.ZIndex = 15

task.spawn(function()
    while task.wait(0.5) do
        if not dockContainer or not dockContainer.Parent then break end
        
        -- Pulse Right Arrow
        if scrollIndicatorRight.TextTransparency < 1 then
            tween(scrollIndicatorRight, {Position = UDim2.new(1, 1, 0.5, 0)}, 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        end
        -- Pulse Left Arrow
        if scrollIndicatorLeft.TextTransparency < 1 then
            tween(scrollIndicatorLeft, {Position = UDim2.new(0, -1, 0.5, 0)}, 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        end
        
        task.wait(0.4)
        
        if scrollIndicatorRight.TextTransparency < 1 then
            tween(scrollIndicatorRight, {Position = UDim2.new(1, -5, 0.5, 0)}, 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        end
        if scrollIndicatorLeft.TextTransparency < 1 then
            tween(scrollIndicatorLeft, {Position = UDim2.new(0, 5, 0.5, 0)}, 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        end
    end
end)

topNav:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    local maxScroll = math.max(0, topNav.AbsoluteCanvasSize.X - topNav.AbsoluteSize.X)
    
    -- Right arrow logic
    if topNav.CanvasPosition.X >= maxScroll - 10 then
        tween(scrollIndicatorRight, {TextTransparency = 1}, 0.2)
    else
        tween(scrollIndicatorRight, {TextTransparency = 0.5}, 0.2)
    end
    
    -- Left arrow logic
    if topNav.CanvasPosition.X > 10 then
        tween(scrollIndicatorLeft, {TextTransparency = 0.5}, 0.2)
    else
        tween(scrollIndicatorLeft, {TextTransparency = 1}, 0.2)
    end
end)

local sidebarPages = {}
local currentPage = "home"

local sidebarIcons = {
    {id = "home",     text = "HOME",       order = 1, icon = "rbxassetid://91945101969531"},
    {id = "vcbypass", text = "VC BYPASS",  order = 2, icon = "rbxassetid://121961630742766"},
    {id = "features", text = "MOVEMENT",   order = 3, icon = "rbxassetid://115586327025577"},
    {id = "combat",   text = "ATTACH",     order = 4, icon = "rbxassetid://87936296110048"},
    {id = "target",   text = "TARGET",     order = 5, icon = "rbxassetid://120988916578721"},
    {id = "visual",   text = "VISUAL",     order = 6, icon = "rbxassetid://88990947887262"},
    {id = "chat",     text = "CHAT SPAM",  order = 7, icon = "rbxassetid://137437049544775"},
    {id = "animations", text = "ANIMATIONS", order = 8, icon = "rbxassetid://72867848813550"},
    {id = "antiStuffs", text = "ANTI STUFFS",  order = 9, icon = "rbxassetid://136121946714463"},
    {id = "animcopy",   text = "ANIM COPY",    order = 10, icon = "rbxassetid://83724509518019"},
    {id = "bigbaseplate", text = "BIG BASEPLATE", order = 11, icon = "rbxassetid://73073921325605"},
    {id = "hideuser",   text = "HIDE USER",    order = 12, icon = "rbxassetid://93438783282007"},
    {id = "settings", text = "SETTINGS", order = 13, icon = "rbxassetid://122990197090027"},
}

local sidebarButtons = {}

for _, data in ipairs(sidebarIcons) do
    local btn = Instance.new("TextButton", topNav)
    btn.Name = "SB_" .. data.id
    
    local txtSize = game:GetService("TextService"):GetTextSize("  " .. data.text, 12, Enum.Font.GothamBold, Vector2.new(1000, 24))
    local expandedWidth = 60 + txtSize.X + 8
    local collapsedWidth = 60
    
    local isHome = (currentPage == data.id)
    local startWidth = isHome and expandedWidth or collapsedWidth

    btn.Size = UDim2.new(0, startWidth, 1, 0)
    btn.Text = ""
    btn.BackgroundColor3 = C.sidebarBg
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.LayoutOrder = data.order
    btn.ClipsDescendants = true
    corner(btn, 10)
    
    local iconImg = Instance.new("ImageLabel", btn)
    iconImg.Size = UDim2.new(0, 36, 0, 36)
    iconImg.Position = UDim2.new(0, 12, 0.5, -18)
    iconImg.BackgroundTransparency = 1
    iconImg.Image = data.icon
    iconImg.ImageColor3 = isHome and C.accent or C.sidebarIcon

    local txt = Instance.new("TextLabel", btn)
    txt.Name = "Title"
    txt.Size = UDim2.new(0, txtSize.X, 1, 0)
    txt.Position = UDim2.new(0, 60, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = data.text
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 12
    txt.TextColor3 = isHome and C.accent or C.sidebarIcon
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextTransparency = isHome and 0 or 1

    local underline = Instance.new("Frame", btn)
    underline.Size = UDim2.new(0, 0, 0, 2)
    underline.Position = UDim2.new(0, 0, 1, -2)
    underline.BackgroundColor3 = C.accent
    underline.BorderSizePixel = 0
    underline.BackgroundTransparency = 0.2
    corner(underline, 1)

    btn.MouseEnter:Connect(function()
        if currentPage ~= data.id then
            tween(btn, {BackgroundTransparency = 0.85, BackgroundColor3 = C.surfaceHover, Size = UDim2.new(0, expandedWidth, 1, 0)}, 0.3, Enum.EasingStyle.Quint)
            tween(iconImg, {ImageColor3 = C.white}, 0.2)
            tween(txt, {TextColor3 = C.white, TextTransparency = 0}, 0.3)
        end
        tween(underline, {Size = UDim2.new(1, 0, 0, 2)}, 0.3, Enum.EasingStyle.Quint)
    end)
    btn.MouseLeave:Connect(function()
        if currentPage ~= data.id then
            tween(btn, {BackgroundTransparency = 1, Size = UDim2.new(0, collapsedWidth, 1, 0)}, 0.3, Enum.EasingStyle.Quint)
            tween(iconImg, {ImageColor3 = C.sidebarIcon}, 0.2)
            tween(txt, {TextColor3 = C.sidebarIcon, TextTransparency = 1}, 0.3)
        end
        tween(underline, {Size = UDim2.new(0, 0, 0, 2)}, 0.3, Enum.EasingStyle.Quint)
    end)
    
    btn:SetAttribute("ExpandedWidth", expandedWidth)
    btn:SetAttribute("CollapsedWidth", collapsedWidth)

    sidebarButtons[data.id] = btn
end

-- Overhead Tag Toggle
FeatureStates.ShowOverheadLogo = true

local function setTagVisibility(state)
    FeatureStates.ShowOverheadLogo = state
    
    local ts = game:GetService("TweenService")
    local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    if state then
        -- Mini toggle on titlebar
        ts:Create(miniTagKnob, ti, {Position = UDim2.new(1, -10, 0.5, -4)}):Play()
        ts:Create(miniTagBtn, ti, {BackgroundColor3 = C.success}):Play()
        ts:Create(miniTagLabel, ti, {TextColor3 = C.accent}):Play()
    else
        -- Mini toggle on titlebar
        ts:Create(miniTagKnob, ti, {Position = UDim2.new(0, 2, 0.5, -4)}):Play()
        ts:Create(miniTagBtn, ti, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        ts:Create(miniTagLabel, ti, {TextColor3 = C.textDim}):Play()
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            if head:FindFirstChild("EternityOverhead") then
                head.EternityOverhead.Enabled = state
            end
        end
    end
end

miniTagBtn.MouseButton1Click:Connect(function()
    playClick()
    setTagVisibility(not FeatureStates.ShowOverheadLogo)
end)

-- 
-- CONTENT AREA (right of sidebar)
-- 
local contentArea = Instance.new("Frame", mainFrame)
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, 0, 1, -36)
contentArea.Position = UDim2.new(0, 0, 0, 36)
contentArea.BackgroundTransparency = 1
contentArea.ClipsDescendants = true

-- 
-- HEADER (player info banner)
-- 
local headerFrame = Instance.new("Frame", infoCard)
headerFrame.Name = "Header"
headerFrame.Size = UDim2.new(1, 0, 0, 80)
headerFrame.Position = UDim2.new(0, 0, 0, 0)
headerFrame.BackgroundTransparency = 1
headerFrame.BorderSizePixel = 0
headerFrame.LayoutOrder = 0

local hDiv = Instance.new("Frame", infoCard)
hDiv.Size = UDim2.new(1, 0, 0, 1)
hDiv.BackgroundColor3 = C.divider
hDiv.BorderSizePixel = 0
hDiv.LayoutOrder = 1

-- avatar thumbnail
local avatarFrame = Instance.new("ImageLabel", headerFrame)
avatarFrame.Name = "Avatar"
avatarFrame.Size = UDim2.new(0, 50, 0, 50)
avatarFrame.Position = UDim2.new(0, 16, 0.5, -25)
avatarFrame.BackgroundColor3 = C.surface
avatarFrame.BorderSizePixel = 0
avatarFrame.Image = ""
corner(avatarFrame, 25)

local mainAvatarStroke = stroke(avatarFrame, C.accent, 2.5, 0)
mainAvatarGradient = Instance.new("UIGradient", mainAvatarStroke)
mainAvatarGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.45, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(0.55, 1),
    NumberSequenceKeypoint.new(1, 1)
})

pcall(function()
    avatarFrame.Image = Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
end)

-- greeting text
local greetLabel = Instance.new("TextLabel", headerFrame)
greetLabel.Size = UDim2.new(1, -90, 0, 22)
greetLabel.Position = UDim2.new(0, 76, 0, 12)
greetLabel.RichText = true
greetLabel.Text = '<b>' .. getTimeGreeting() .. ', ' .. lp.DisplayName .. '!</b>'
greetLabel.Font = Enum.Font.GothamBold
greetLabel.TextSize = 14
greetLabel.TextColor3 = C.white
greetLabel.TextXAlignment = Enum.TextXAlignment.Left
greetLabel.BackgroundTransparency = 1

-- account info
local infoLabel = Instance.new("TextLabel", headerFrame)
infoLabel.Size = UDim2.new(1, -90, 0, 14)
infoLabel.Position = UDim2.new(0, 76, 0, 34)
infoLabel.Text = "Account ID: " .. tostring(lp.UserId) .. "  |  Account Age: " .. getAccountAge()
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 10
infoLabel.TextColor3 = C.textMuted
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.BackgroundTransparency = 1

-- time display
local timeLabel = Instance.new("TextLabel", headerFrame)
timeLabel.Size = UDim2.new(1, -90, 0, 14)
timeLabel.Position = UDim2.new(0, 76, 0, 50)
timeLabel.Text = os.date("%I:%M %p | %B %dth, %Y")
timeLabel.Font = Enum.Font.Gotham
timeLabel.TextSize = 10
timeLabel.TextColor3 = C.accentDim
timeLabel.TextXAlignment = Enum.TextXAlignment.Left
timeLabel.BackgroundTransparency = 1

-- header logo
local headerLogo = Instance.new("ImageLabel", headerFrame)
headerLogo.Name = "HeaderLogo"
headerLogo.Size = UDim2.new(0, 160, 0, 50)
headerLogo.Position = UDim2.new(1, -176, 0.5, -25) -- 16px padding from right
headerLogo.BackgroundTransparency = 1
headerLogo.Image = LogoAssetUrl
headerLogo.ScaleType = Enum.ScaleType.Fit

-- 
-- STATS BAR (FPS / Ping / Executor)
-- 
local statsBar = Instance.new("Frame", infoCard)
statsBar.Name = "StatsBar"
statsBar.Size = UDim2.new(1, 0, 0, 44)
statsBar.Position = UDim2.new(0, 0, 0, 0)
statsBar.BackgroundTransparency = 1
statsBar.BorderSizePixel = 0
statsBar.LayoutOrder = 2



local statsLayout = Instance.new("UIListLayout", statsBar)
statsLayout.FillDirection = Enum.FillDirection.Horizontal
statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
statsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
statsLayout.Padding = UDim.new(0, 0)

local function createStatBlock(name, labelText, valueText, order, wide)
    local block = Instance.new("Frame", statsBar)
    block.Name = name
    block.Size = UDim2.new(0, wide and 130 or 85, 1, 0)
    block.BackgroundTransparency = 1
    block.LayoutOrder = order

    local lbl = Instance.new("TextLabel", block)
    lbl.Name = "Label"
    lbl.Size = UDim2.new(1, 0, 0, 12)
    lbl.Position = UDim2.new(0, 12, 0, 6)
    lbl.Text = labelText
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 8
    lbl.TextColor3 = C.textMuted
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1

    local val = Instance.new("TextLabel", block)
    val.Name = "Value"
    val.Size = UDim2.new(1, 0, 0, 18)
    val.Position = UDim2.new(0, 12, 0, 18)
    val.Text = valueText
    val.Font = Enum.Font.GothamBold
    val.TextSize = 16
    val.TextColor3 = C.white
    val.TextXAlignment = Enum.TextXAlignment.Left
    val.BackgroundTransparency = 1

    -- divider
    if order < 3 then
        local div = Instance.new("Frame", block)
        div.Size = UDim2.new(0, 1, 0.6, 0)
        div.Position = UDim2.new(1, 0, 0.2, 0)
        div.BackgroundColor3 = C.divider
        div.BorderSizePixel = 0
    end

    return val
end

local fpsValue = createStatBlock("FPS", "FPS", "0", 1)
local pingValue = createStatBlock("Ping", "PING", "0ms", 2)
local execValue = createStatBlock("Executor", "EXECUTOR", getExecutorName(), 3, true)
execValue.TextColor3 = C.accent

-- live FPS/Ping counter
task.spawn(function()
    local frameCount = 0
    local lastTime = tick()
    RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        local now = tick()
        if now - lastTime >= 1 then
            fpsValue.Text = tostring(frameCount)
            frameCount = 0
            lastTime = now
        end
    end)
end)

task.spawn(function()
    while mainFrame and mainFrame.Parent do
        local ping = math.floor(lp:GetNetworkPing() * 1000)
        pingValue.Text = tostring(ping) .. "ms"
        if ping < 80 then
            pingValue.TextColor3 = C.success
        elseif ping < 150 then
            pingValue.TextColor3 = C.warning
        else
            pingValue.TextColor3 = C.danger
        end
        task.wait(1)
    end
end)

-- 
-- PAGE CONTAINER (scrollable area)
-- 
local pageContainer = Instance.new("Frame", contentArea)
pageContainer.Name = "PageContainer"
pageContainer.Size = UDim2.new(1, 0, 1, 0)
pageContainer.Position = UDim2.new(0, 0, 0, 0)
pageContainer.BackgroundTransparency = 1
pageContainer.ClipsDescendants = true




-- page creation helper
local function createPage(name)
    local scroll = Instance.new("ScrollingFrame", pageContainer)
    scroll.Name = name
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.Position = UDim2.new(0, 0, 0, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = C.accent
    scroll.ScrollBarImageTransparency = 0.6
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Visible = (name == "home")
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout", scroll)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    padding(scroll, 8, 8, 8, 8)

    sidebarPages[name] = scroll
    return scroll
end

-- 
-- UI COMPONENT BUILDERS
-- 

-- section header
local function createSection(parent, title, order)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -8, 0, 28)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = order or 0

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.Text = string.upper(title)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = C.textMuted
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1

    return frame
end

-- Grid Container for 2-column layouts
local function createGridContainer(parent, order)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -8, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.LayoutOrder = order or 0

    local grid = Instance.new("UIGridLayout", container)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.CellSize = UDim2.new(0.5, -4, 0, 36)
    grid.CellPadding = UDim2.new(0, 8, 0, 6)
    
    return container
end

-- Global Tooltip System
local tooltipGui = Instance.new("Frame", sg)
tooltipGui.Name = "Tooltip"
tooltipGui.Size = UDim2.new(0, 0, 0, 24)
tooltipGui.Position = UDim2.new(0, -1000, 0, -1000)
tooltipGui.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
tooltipGui.BackgroundTransparency = 0.2
tooltipGui.BorderSizePixel = 0
tooltipGui.ZIndex = 100
tooltipGui.Visible = false
corner(tooltipGui, 6)

local tooltipStroke = Instance.new("UIStroke", tooltipGui)
tooltipStroke.Color = Color3.fromRGB(60, 60, 70)
tooltipStroke.Transparency = 0.5
tooltipStroke.Thickness = 1
tooltipStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local tooltipLabel = Instance.new("TextLabel", tooltipGui)
tooltipLabel.Size = UDim2.new(1, -16, 1, 0)
tooltipLabel.Position = UDim2.new(0, 8, 0, 0)
tooltipLabel.BackgroundTransparency = 1
tooltipLabel.Text = ""
tooltipLabel.Font = Enum.Font.Gotham
tooltipLabel.TextSize = 11
tooltipLabel.TextColor3 = C.white
tooltipLabel.TextXAlignment = Enum.TextXAlignment.Left
tooltipLabel.ZIndex = 101

local tooltipConn

local function bindTooltip(guiObject, text)
    if not text or text == "" then return end
    guiObject.MouseEnter:Connect(function()
        tooltipLabel.Text = text
        local textSize = game:GetService("TextService"):GetTextSize(text, 11, Enum.Font.Gotham, Vector2.new(1000, 24))
        tooltipGui.Size = UDim2.new(0, textSize.X + 16, 0, 24)
        tooltipGui.Visible = true
        
        if tooltipConn then tooltipConn:Disconnect() end
        tooltipConn = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                local pos = input.Position
                tooltipGui.Position = UDim2.new(0, pos.X + 15, 0, pos.Y + 15)
            end
        end)
        local pos = UserInputService:GetMouseLocation()
        tooltipGui.Position = UDim2.new(0, pos.X + 15, 0, pos.Y + 15)
    end)
    guiObject.MouseLeave:Connect(function()
        tooltipGui.Visible = false
        if tooltipConn then
            tooltipConn:Disconnect()
            tooltipConn = nil
        end
    end)
end

-- toggle switch
local function createToggle(parent, title, description, featureKey, order, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -8, 0, 36)
    frame.BackgroundColor3 = C.surface
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 0
    corner(frame, 10)

    -- hover effect
    frame.MouseEnter:Connect(function()
        tween(frame, {BackgroundColor3 = C.surfaceHover}, 0.2)
    end)
    frame.MouseLeave:Connect(function()
        tween(frame, {BackgroundColor3 = C.surface}, 0.2)
    end)
    
    bindTooltip(frame, description)

    local titleLbl = Instance.new("TextLabel", frame)
    titleLbl.Size = UDim2.new(1, -70, 1, 0)
    titleLbl.Position = UDim2.new(0, 14, 0, 0)
    titleLbl.Text = title
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextColor3 = C.white
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextTruncate = Enum.TextTruncate.AtEnd

    -- toggle track
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(0, 40, 0, 22)
    track.Position = UDim2.new(1, -54, 0.5, -11)
    track.BackgroundColor3 = C.toggleOff
    track.BorderSizePixel = 0
    corner(track, 11)

    -- toggle knob
    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = C.toggleKnob
    knob.BorderSizePixel = 0
    corner(knob, 8)

    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 5

    local isOn = FeatureStates[featureKey] or false

    local function updateVisual()
        if isOn then
            tween(track, {BackgroundColor3 = C.toggleOn}, 0.25)
            tween(knob, {Position = UDim2.new(0, 21, 0.5, -8)}, 0.25, Enum.EasingStyle.Back)
        else
            tween(track, {BackgroundColor3 = C.toggleOff}, 0.25)
            tween(knob, {Position = UDim2.new(0, 3, 0.5, -8)}, 0.25, Enum.EasingStyle.Back)
        end
    end

    local function setToggle(val)
        if val and FeatureStates.AdminDisabled then return end
        isOn = val
        FeatureStates[featureKey] = val
        updateVisual()
        if callback then callback(val) end
        task.spawn(saveSettings)
    end
    ToggleRegistry[featureKey] = setToggle

    toggleBtn.MouseButton1Click:Connect(function()
        playClick()
        setToggle(not isOn)
    end)

    updateVisual()
    return frame
end

-- toggle switch with keybind
local function createKeybindToggle(parent, title, description, featureKey, bindKeyStr, defaultKey, order, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -8, 0, 36)
    frame.BackgroundColor3 = C.surface
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 0
    corner(frame, 10)

    -- hover effect
    frame.MouseEnter:Connect(function()
        tween(frame, {BackgroundColor3 = C.surfaceHover}, 0.2)
    end)
    frame.MouseLeave:Connect(function()
        tween(frame, {BackgroundColor3 = C.surface}, 0.2)
    end)
    
    bindTooltip(frame, description)

    local titleLbl = Instance.new("TextLabel", frame)
    titleLbl.Size = UDim2.new(1, -130, 1, 0)
    titleLbl.Position = UDim2.new(0, 14, 0, 0)
    titleLbl.Text = title
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextColor3 = C.white
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextTruncate = Enum.TextTruncate.AtEnd

    -- keybind button
    local bindBtn = Instance.new("TextButton", frame)
    bindBtn.Size = UDim2.new(0, 44, 0, 22)
    bindBtn.Position = UDim2.new(1, -54, 0.5, -11)
    bindBtn.BackgroundColor3 = C.input
    bindBtn.BorderSizePixel = 0
    bindBtn.Text = defaultKey.Name
    bindBtn.Font = Enum.Font.GothamBold
    bindBtn.TextSize = 10
    bindBtn.TextColor3 = C.white
    corner(bindBtn, 6)
    stroke(bindBtn, C.divider, 1, 0.5)

    -- toggle track
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(0, 40, 0, 22)
    track.Position = UDim2.new(1, -104, 0.5, -11)
    track.BackgroundColor3 = C.toggleOff
    track.BorderSizePixel = 0
    corner(track, 11)

    -- toggle knob
    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = C.toggleKnob
    knob.BorderSizePixel = 0
    corner(knob, 8)

    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Size = UDim2.new(1, -60, 1, 0) -- don't cover bind button
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 5

    local isOn = FeatureStates[featureKey] or false

    local function updateVisual()
        if isOn then
            tween(track, {BackgroundColor3 = C.toggleOn}, 0.25)
            tween(knob, {Position = UDim2.new(0, 21, 0.5, -8)}, 0.25, Enum.EasingStyle.Back)
        else
            tween(track, {BackgroundColor3 = C.toggleOff}, 0.25)
            tween(knob, {Position = UDim2.new(0, 3, 0.5, -8)}, 0.25, Enum.EasingStyle.Back)
        end
    end

    local function setToggle(val)
        if val and FeatureStates.AdminDisabled then return end
        isOn = val
        FeatureStates[featureKey] = val
        updateVisual()
        if callback then callback(val) end
        task.spawn(saveSettings)
    end
    ToggleRegistry[featureKey] = setToggle

    toggleBtn.MouseButton1Click:Connect(function()
        setToggle(not isOn)
    end)

    _G.SyncKeybindUI = _G.SyncKeybindUI or {}
    _G.SyncKeybindUI[bindKeyStr] = _G.SyncKeybindUI[bindKeyStr] or {}
    table.insert(_G.SyncKeybindUI[bindKeyStr], bindBtn)

    local isListening = false
    bindBtn.MouseButton1Click:Connect(function()
        isListening = true
        for _, b in ipairs(_G.SyncKeybindUI[bindKeyStr]) do
            b.Text = "..."
            tween(b, {BackgroundColor3 = C.accentDim}, 0.2)
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if isListening and input.UserInputType == Enum.UserInputType.Keyboard then
            isListening = false
            local newKey = input.KeyCode
            for _, b in ipairs(_G.SyncKeybindUI[bindKeyStr]) do
                b.Text = newKey.Name
                tween(b, {BackgroundColor3 = C.input}, 0.2)
            end
            Keybinds[bindKeyStr] = newKey
            saveSettings()
        end
    end)

    updateVisual()
    return frame
end

-- action button (run button)
local function createActionButton(parent, title, description, order, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -8, 0, 36)
    frame.BackgroundColor3 = C.surface
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 0
    corner(frame, 10)

    frame.MouseEnter:Connect(function()
        tween(frame, {BackgroundColor3 = C.surfaceHover}, 0.2)
    end)
    frame.MouseLeave:Connect(function()
        tween(frame, {BackgroundColor3 = C.surface}, 0.2)
    end)
    
    bindTooltip(frame, description)

    local titleLbl = Instance.new("TextLabel", frame)
    titleLbl.Size = UDim2.new(1, -80, 1, 0)
    titleLbl.Position = UDim2.new(0, 14, 0, 0)
    titleLbl.Text = title
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = C.white
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.BackgroundTransparency = 1

    local runBtn = Instance.new("TextButton", frame)
    runBtn.Size = UDim2.new(0, 44, 0, 26)
    runBtn.Position = UDim2.new(1, -58, 0.5, -13)
    runBtn.Text = "Run"
    runBtn.Font = Enum.Font.GothamBold
    runBtn.TextSize = 11
    runBtn.TextColor3 = C.bg
    runBtn.BackgroundColor3 = C.accentDim
    runBtn.BorderSizePixel = 0
    runBtn.AutoButtonColor = false
    runBtn.ZIndex = 5
    corner(runBtn, 6)

    runBtn.MouseEnter:Connect(function()
        tween(runBtn, {BackgroundColor3 = C.accent}, 0.2)
    end)
    runBtn.MouseLeave:Connect(function()
        tween(runBtn, {BackgroundColor3 = C.accentDim}, 0.2)
    end)
    runBtn.MouseButton1Click:Connect(function()
        tween(runBtn, {BackgroundColor3 = C.success}, 0.1)
        runBtn.Text = ""
        if callback then callback() end
        task.wait(0.6)
        runBtn.Text = "Run"
        tween(runBtn, {BackgroundColor3 = C.accentDim}, 0.2)
    end)

    return frame
end

-- slider component
local function createSlider(parent, title, description, minVal, maxVal, defaultVal, decimalPlaces, order, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -8, 0, 60)
    frame.BackgroundColor3 = C.surface
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 0
    corner(frame, 10)

    frame.MouseEnter:Connect(function() tween(frame, {BackgroundColor3 = C.surfaceHover}, 0.2) end)
    frame.MouseLeave:Connect(function() tween(frame, {BackgroundColor3 = C.surface}, 0.2) end)

    local titleLbl = Instance.new("TextLabel", frame)
    titleLbl.Size = UDim2.new(1, -60, 0, 18)
    titleLbl.Position = UDim2.new(0, 14, 0, 8)
    titleLbl.Text = title
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = C.white
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.BackgroundTransparency = 1

    local descLbl = Instance.new("TextLabel", frame)
    descLbl.Size = UDim2.new(1, -60, 0, 14)
    descLbl.Position = UDim2.new(0, 14, 0, 28)
    descLbl.Text = description
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextSize = 10
    descLbl.TextColor3 = C.textMuted
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.BackgroundTransparency = 1

    local valLbl = Instance.new("TextLabel", frame)
    valLbl.Size = UDim2.new(0, 40, 0, 18)
    valLbl.Position = UDim2.new(1, -54, 0, 8)
    local formatStr = "%." .. (decimalPlaces or 1) .. "f"
    valLbl.Text = string.format(formatStr, defaultVal)
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 11
    valLbl.TextColor3 = C.accent
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.BackgroundTransparency = 1

    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(0, 100, 0, 6)
    track.Position = UDim2.new(1, -114, 0, 32)
    track.BackgroundColor3 = C.toggleOff
    track.BorderSizePixel = 0
    corner(track, 3)

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    corner(fill, 3)

    local knob = Instance.new("Frame", fill)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(1, -6, 0.5, -6)
    knob.BackgroundColor3 = C.white
    knob.BorderSizePixel = 0
    corner(knob, 6)

    local dragging = false
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        local val = minVal + (maxVal - minVal) * pos
        valLbl.Text = string.format(formatStr, val)
        if callback then callback(val) end
    end

    local slideBtn = Instance.new("TextButton", track)
    slideBtn.Size = UDim2.new(1, 0, 1, 20)
    slideBtn.Position = UDim2.new(0, 0, 0.5, -10)
    slideBtn.BackgroundTransparency = 1
    slideBtn.Text = ""

    slideBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)

    return frame
end



-- text input field
local function createInputField(parent, label, placeholder, defaultText, order)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -8, 0, 60)
    frame.BackgroundColor3 = C.surface
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 0
    corner(frame, 10)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -16, 0, 14)
    lbl.Position = UDim2.new(0, 14, 0, 8)
    lbl.Text = label
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = C.textMuted
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1

    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(1, -28, 0, 26)
    box.Position = UDim2.new(0, 14, 0, 26)
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = C.textDim
    box.Text = defaultText or ""
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextColor3 = C.text
    box.BackgroundColor3 = C.input
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    corner(box, 6)
    padding(box, 0, 0, 8, 8)

    return box
end

local function createDropdown(parent, title, options, order, callback, supportsFavorites, initialSelection)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -8, 0, 42)
    frame.BackgroundColor3 = C.surface
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.ClipsDescendants = true
    corner(frame, 6)

    local topBar = Instance.new("Frame", frame)
    topBar.Size = UDim2.new(1, 0, 0, 42)
    topBar.BackgroundTransparency = 1

    local titleLbl = Instance.new("TextLabel", topBar)
    titleLbl.Size = UDim2.new(1, -30, 1, 0)
    titleLbl.Position = UDim2.new(0, 14, 0, 0)
    titleLbl.RichText = true
    titleLbl.Text = initialSelection and (title .. ': <font color="rgb(' .. getRGBString(C.accent) .. ')">' .. initialSelection .. "</font>") or title
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.TextSize = 13
    titleLbl.TextColor3 = C.text
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.BackgroundTransparency = 1

    local arrow = Instance.new("TextLabel", topBar)
    arrow.Size = UDim2.new(0, 20, 0, 20)
    arrow.Position = UDim2.new(1, -26, 0.5, -10)
    arrow.Text = ""
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 12
    arrow.TextColor3 = C.textDim
    arrow.BackgroundTransparency = 1

    local btn = Instance.new("TextButton", topBar)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Text = ""
    btn.BackgroundTransparency = 1
    
    local searchBox = Instance.new("TextBox", frame)
    searchBox.Size = UDim2.new(1, -20, 0, 24)
    searchBox.Position = UDim2.new(0, 10, 0, 44)
    searchBox.BackgroundColor3 = C.input
    searchBox.BorderSizePixel = 0
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 12
    searchBox.TextColor3 = C.text
    searchBox.PlaceholderText = "Search..."
    searchBox.PlaceholderColor3 = C.textDim
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    corner(searchBox, 4)
    padding(searchBox, 0, 0, 6, 6)
    
    local scroll = Instance.new("ScrollingFrame", frame)
    scroll.Size = UDim2.new(1, 0, 1, -74)
    scroll.Position = UDim2.new(0, 0, 0, 72)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = C.accent

    local listLayout = Instance.new("UIListLayout", scroll)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 2)

    local isOpen = false
    local optionHeight = 26
    local maxItems = 6
    local optionBtns = {}

    local function updateDropdownSize()
        if not isOpen then
            tween(frame, {Size = UDim2.new(1, -8, 0, 42)}, 0.2)
            return
        end
        local visibleCount = 0
        for _, optBtn in ipairs(optionBtns) do
            if optBtn.Visible then visibleCount = visibleCount + 1 end
        end
        local targetHeight = math.min(visibleCount * optionHeight + 4, maxItems * optionHeight + 4)
        local searchOffset = 30 -- height of searchbox + padding
        tween(frame, {Size = UDim2.new(1, -8, 0, 42 + searchOffset + targetHeight)}, 0.2)
    end

    local function toggleDropdown()
        isOpen = not isOpen
        tween(arrow, {Rotation = isOpen and 180 or 0}, 0.2)
        if isOpen then searchBox.Text = "" end -- reset search on open
        updateDropdownSize()
    end

    btn.MouseButton1Click:Connect(toggleDropdown)

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = searchBox.Text:lower()
        for _, optBtn in ipairs(optionBtns) do
            local match = query == "" or optBtn.Text:lower():find(query, 1, true)
            optBtn.Visible = match
        end
        updateDropdownSize()
    end)

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton", scroll)
        optBtn.Size = UDim2.new(1, 0, 0, optionHeight)
        optBtn.Text = "  " .. opt
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 12
        optBtn.TextColor3 = C.textDim
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.BackgroundTransparency = 1
        optBtn.ZIndex = 7
        
        local originalIndex = i
        if supportsFavorites then
            optBtn.LayoutOrder = FeatureStates.FavoriteAnimations[opt] and originalIndex or (originalIndex + 10000)
            
            local starBtn = Instance.new("TextButton", optBtn)
            starBtn.Size = UDim2.new(0, optionHeight, 0, optionHeight)
            starBtn.Position = UDim2.new(1, -optionHeight - 5, 0, 0)
            starBtn.BackgroundTransparency = 1
            starBtn.Font = Enum.Font.Gotham
            starBtn.TextSize = 14
            starBtn.TextColor3 = C.accent
            starBtn.Text = FeatureStates.FavoriteAnimations[opt] and "" or ""
            starBtn.ZIndex = 8
            
            starBtn.MouseButton1Click:Connect(function()
                FeatureStates.FavoriteAnimations[opt] = not FeatureStates.FavoriteAnimations[opt]
                starBtn.Text = FeatureStates.FavoriteAnimations[opt] and "" or ""
                optBtn.LayoutOrder = FeatureStates.FavoriteAnimations[opt] and originalIndex or (originalIndex + 10000)
                saveSettings()
            end)
        else
            optBtn.LayoutOrder = originalIndex
        end
        
        optBtn.MouseEnter:Connect(function()
            tween(optBtn, {TextColor3 = C.accent}, 0.1)
        end)
        optBtn.MouseLeave:Connect(function()
            tween(optBtn, {TextColor3 = C.textDim}, 0.1)
        end)
        
        optBtn.MouseButton1Click:Connect(function()
            titleLbl.Text = title .. ': <font color="rgb(' .. getRGBString(C.accent) .. ')">' .. opt .. "</font>"
            toggleDropdown()
            if callback then callback(opt) end
        end)
        table.insert(optionBtns, optBtn)
    end

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end)
end


-- 
-- PAGE: HOME
-- 
task.spawn(function()
-- 

-- premium card effects
breathingGradients = {}
function applyPremiumCardEffect(card)
    local strk = Instance.new("UIStroke", card)
    strk.Color = C.accent
    strk.Thickness = 1.5
    strk.Transparency = 0 -- Fully visible
    strk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local grad = Instance.new("UIGradient", strk)
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.3, 1),
        NumberSequenceKeypoint.new(0.5, 0), -- Solid running line
        NumberSequenceKeypoint.new(0.7, 1),
        NumberSequenceKeypoint.new(1, 1)
    })
    table.insert(breathingGradients, grad)

    card.Active = true

    card.MouseEnter:Connect(function()
        tween(card, {BackgroundColor3 = Color3.fromRGB(35, 35, 40)}, 0.2)
    end)
    card.MouseLeave:Connect(function()
        tween(card, {BackgroundColor3 = C.surface}, 0.2)
    end)
end

RunService.RenderStepped:Connect(function(dt)
    for _, grad in ipairs(breathingGradients) do
        if grad.Parent then
            grad.Rotation = (grad.Rotation + 45 * dt) % 360
        end
    end
end)

local homePage = createPage("home")

if floatingTopContainer then
    local info = floatingTopContainer:FindFirstChild("InfoCard")
    if info then
        info.Parent = homePage
        info.Size = UDim2.new(1, -8, 0, 125)
        info.Position = UDim2.new(0, 4, 0, 0)
        info.AnchorPoint = Vector2.new(0, 0)
        info.LayoutOrder = -2
        
        local spacer = Instance.new("Frame", homePage)
        spacer.Name = "StatusSpacer"
        spacer.Size = UDim2.new(1, 0, 0, 10)
        spacer.BackgroundTransparency = 1
        spacer.LayoutOrder = -1
    end
    floatingTopContainer:Destroy()
    floatingTopContainer = nil
end



-- discord text
local discordCard = Instance.new("Frame", homePage)
discordCard.Size = UDim2.new(1, -8, 0, 42)
discordCard.BackgroundColor3 = C.surface
discordCard.BorderSizePixel = 0
discordCard.LayoutOrder = 1
corner(discordCard, 10)
    applyPremiumCardEffect(discordCard)

local discordIconHome = Instance.new("ImageLabel", discordCard)
discordIconHome.Size = UDim2.new(0, 18, 0, 18)
discordIconHome.Position = UDim2.new(0, 14, 0.5, -9)
discordIconHome.BackgroundTransparency = 1
discordIconHome.Image = getAssetUrl("discord.png")

local discordLabel = Instance.new("TextLabel", discordCard)
discordLabel.Size = UDim2.new(0.6, 0, 1, 0)
discordLabel.Position = UDim2.new(0, 40, 0, 0)
discordLabel.Text = "Developer Discord : @hor1zxn."
discordLabel.Font = Enum.Font.GothamBold
discordLabel.TextSize = 12
discordLabel.TextColor3 = C.white
discordLabel.TextXAlignment = Enum.TextXAlignment.Left
discordLabel.BackgroundTransparency = 1

local discordBtn = Instance.new("TextButton", discordCard)
discordBtn.Size = UDim2.new(0, 44, 0, 26)
discordBtn.Position = UDim2.new(1, -58, 0.5, -13)
discordBtn.Text = "Copy"
discordBtn.Font = Enum.Font.GothamBold
discordBtn.TextSize = 11
discordBtn.TextColor3 = C.bg
discordBtn.BackgroundColor3 = C.accentDim
discordBtn.BorderSizePixel = 0
discordBtn.AutoButtonColor = false
discordBtn.ZIndex = 5
corner(discordBtn, 6)

discordBtn.MouseEnter:Connect(function()
    tween(discordBtn, {BackgroundColor3 = C.accent}, 0.2)
end)
discordBtn.MouseLeave:Connect(function()
    tween(discordBtn, {BackgroundColor3 = C.accentDim}, 0.2)
end)
discordBtn.MouseButton1Click:Connect(function()
    pcall(function()
        setclipboard("hor1zxn")
    end)
    discordBtn.Text = ""
    tween(discordBtn, {BackgroundColor3 = C.success}, 0.1)
    task.wait(1)
    discordBtn.Text = "Copy"
    tween(discordBtn, {BackgroundColor3 = C.accentDim}, 0.2)
end)

-- basic controls
createSection(homePage, "Basic Controls", 1.5)

do
    local controlsCard = Instance.new("Frame", homePage)
    controlsCard.Size = UDim2.new(1, -8, 0, 64)
    controlsCard.BackgroundColor3 = C.surface
    controlsCard.BorderSizePixel = 0
    controlsCard.LayoutOrder = 1.6
    corner(controlsCard, 10)

    local cl = Instance.new("UIListLayout", controlsCard)
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    cl.Padding = UDim.new(0, 6)
    cl.VerticalAlignment = Enum.VerticalAlignment.Center
    
    local pad = Instance.new("UIPadding", controlsCard)
    pad.PaddingLeft = UDim.new(0, 16)

    local c1 = Instance.new("TextLabel", controlsCard)
    c1.Size = UDim2.new(1, 0, 0, 16)
    c1.Text = "<font color='rgb(" .. accentRgbStr .. ")'><b>Right CTRL</b></font> <font color='rgb(100, 100, 115)'></font> Toggle Interface Visibility"
    c1.RichText = true
    c1.Font = Enum.Font.Gotham
    c1.TextSize = 12
    c1.TextColor3 = C.text
    c1.TextXAlignment = Enum.TextXAlignment.Left
    c1.BackgroundTransparency = 1
    c1.LayoutOrder = 1

    local c2 = Instance.new("TextLabel", controlsCard)
    c2.Size = UDim2.new(1, 0, 0, 16)
    c2.Text = "<font color='rgb(" .. accentRgbStr .. ")'><b>Comma ( , )</b></font> <font color='rgb(100, 100, 115)'></font> Minimize & Maximize Window"
    c2.RichText = true
    c2.Font = Enum.Font.Gotham
    c2.TextSize = 12
    c2.TextColor3 = C.text
    c2.TextXAlignment = Enum.TextXAlignment.Left
    c2.BackgroundTransparency = 1
    c2.LayoutOrder = 2
    
    applyPremiumCardEffect(controlsCard)
end

-- server info
createSection(homePage, "Current Game", 2)

local serverCard = Instance.new("Frame", homePage)
serverCard.Size = UDim2.new(1, -8, 0, 110)
serverCard.BackgroundColor3 = C.surface
serverCard.BorderSizePixel = 0
serverCard.LayoutOrder = 3
serverCard.ClipsDescendants = true
corner(serverCard, 12)
applyPremiumCardEffect(serverCard)

local serverIcon = Instance.new("ImageLabel", serverCard)
serverIcon.Size = UDim2.new(1, 0, 1, 0)
serverIcon.BackgroundTransparency = 1
corner(serverIcon, 12)
serverIcon.ScaleType = Enum.ScaleType.Crop
serverIcon.Image = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. tostring(game.PlaceId) .. "&width=768&height=432&format=png"

local overlayInfo = Instance.new("Frame", serverCard)
overlayInfo.Size = UDim2.new(1, 0, 1, 0)
overlayInfo.BackgroundColor3 = Color3.new(0, 0, 0)
overlayInfo.BorderSizePixel = 0
corner(overlayInfo, 12)

local gradInfo = Instance.new("UIGradient", overlayInfo)
gradInfo.Rotation = 90
gradInfo.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.4, 0.8),
    NumberSequenceKeypoint.new(1, 0.1)
})

local gameNameInfo = Instance.new("TextLabel", serverCard)
gameNameInfo.Size = UDim2.new(1, -30, 0, 22)
gameNameInfo.Position = UDim2.new(0, 15, 1, -55)
gameNameInfo.Text = "Loading Game Info..."
gameNameInfo.Font = Enum.Font.GothamBold
gameNameInfo.TextSize = 18
gameNameInfo.TextColor3 = C.white
gameNameInfo.TextXAlignment = Enum.TextXAlignment.Left
gameNameInfo.BackgroundTransparency = 1

local serverStats = Instance.new("TextLabel", serverCard)
serverStats.Size = UDim2.new(1, -30, 0, 16)
serverStats.Position = UDim2.new(0, 15, 1, -30)
serverStats.Text = "Players: ?  Uptime: 00:00:00"
serverStats.Font = Enum.Font.Gotham
serverStats.TextSize = 12
serverStats.TextColor3 = Color3.new(0.8, 0.8, 0.8)
serverStats.TextXAlignment = Enum.TextXAlignment.Left
serverStats.BackgroundTransparency = 1

task.spawn(function()
    local s, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if s and info and info.Name then
        gameNameInfo.Text = info.Name
    else
        gameNameInfo.Text = "Unknown Game"
    end
end)

local startTime = tick()
task.spawn(function()
    while true do
        local players = 0
        pcall(function() players = #game:GetService("Players"):GetPlayers() end)
        
        local maxPlayers = 0
        pcall(function() maxPlayers = game:GetService("Players").MaxPlayers end)
        
        local elapsed = math.floor(tick() - startTime)
        local hours = math.floor(elapsed / 3600)
        local mins = math.floor((elapsed % 3600) / 60)
        local secs = elapsed % 60
        
        local timeStr = string.format("%02d:%02d:%02d", hours, mins, secs)
        serverStats.Text = "Players: " .. tostring(players) .. "/" .. tostring(maxPlayers) .. "  Uptime: " .. timeStr
        task.wait(1)
    end
end)

-- friend activity
createSection(homePage, "Friend Activity", 4)

task.spawn(function()
    local success, friends = pcall(function()
        return lp:GetFriendsOnline(200)
    end)
    if success and friends then
        local friendsContainer = Instance.new("Frame", homePage)
        friendsContainer.Size = UDim2.new(1, -8, 0, 0)
        friendsContainer.BackgroundTransparency = 1
        friendsContainer.LayoutOrder = 10
        
        local grid = Instance.new("UIGridLayout", friendsContainer)
        grid.CellSize = UDim2.new(0.5, -12, 0, 160)
        grid.CellPadding = UDim2.new(0, 24, 0, 24)
        grid.SortOrder = Enum.SortOrder.LayoutOrder
        
        friendsContainer.AutomaticSize = Enum.AutomaticSize.Y
        
        local count = 0
        for _, friend in ipairs(friends) do
            if friend.LastLocation and friend.LastLocation ~= "Website" and friend.LastLocation ~= "Offline" and friend.PlaceId then
                count = count + 1
                
                local card = Instance.new("TextButton", friendsContainer)
                card.Size = UDim2.new(1, 0, 1, 0)
                card.BackgroundColor3 = C.surface
                card.BorderSizePixel = 0
                card.LayoutOrder = count
                card.ClipsDescendants = true
                card.Text = ""
                card.AutoButtonColor = false
                corner(card, 12)
                
                local gameIcon = Instance.new("ImageLabel", card)
                gameIcon.Size = UDim2.new(1, 0, 1, 0)
                gameIcon.BackgroundTransparency = 1
                gameIcon.ScaleType = Enum.ScaleType.Crop
                gameIcon.Image = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. tostring(friend.PlaceId) .. "&width=768&height=432&format=png"
                corner(gameIcon, 12)
                
                local overlay = Instance.new("Frame", card)
                overlay.Size = UDim2.new(1, 0, 1, 0)
                overlay.BackgroundColor3 = Color3.new(0, 0, 0)
                overlay.BorderSizePixel = 0
                corner(overlay, 12)
                
                local grad = Instance.new("UIGradient", overlay)
                grad.Rotation = 90
                grad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.5, 0.5),
                    NumberSequenceKeypoint.new(1, 0)
                })
                
                local cardStroke = stroke(card, Color3.new(1, 1, 1), 1.2, 0.85)
                
                local avatar = Instance.new("ImageLabel", card)
                avatar.Size = UDim2.new(0, 32, 0, 32)
                avatar.Position = UDim2.new(0, 10, 1, -45)
                avatar.BackgroundTransparency = 1
                avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(friend.VisitorId) .. "&w=150&h=150"
                corner(avatar, 16)
                stroke(avatar, C.accent, 1.5, 0)
                
                local gameName = Instance.new("TextLabel", card)
                gameName.Size = UDim2.new(1, -120, 0, 16)
                gameName.Position = UDim2.new(0, 52, 1, -45)
                gameName.Text = friend.LastLocation
                gameName.Font = Enum.Font.GothamBold
                gameName.TextSize = 13
                gameName.TextColor3 = C.white
                gameName.TextXAlignment = Enum.TextXAlignment.Left
                gameName.BackgroundTransparency = 1
                gameName.TextStrokeTransparency = 0.5
                gameName.TextStrokeColor3 = Color3.new(0, 0, 0)
                
                local onlineDot = Instance.new("Frame", card)
                onlineDot.Size = UDim2.new(0, 6, 0, 6)
                onlineDot.Position = UDim2.new(0, 52, 1, -19)
                onlineDot.AnchorPoint = Vector2.new(0, 0.5)
                onlineDot.BackgroundColor3 = Color3.fromRGB(80, 220, 130)
                onlineDot.BorderSizePixel = 0
                corner(onlineDot, 3)

                local friendName = Instance.new("TextLabel", card)
                friendName.Size = UDim2.new(1, -130, 0, 14)
                friendName.Position = UDim2.new(0, 64, 1, -26)
                friendName.Text = "@" .. tostring(friend.UserName)
                if friend.DisplayName and friend.DisplayName ~= friend.UserName then
                    friendName.Text = tostring(friend.DisplayName)
                end
                friendName.Font = Enum.Font.Gotham
                friendName.TextSize = 11
                friendName.TextColor3 = Color3.new(0.85, 0.85, 0.85)
                friendName.TextXAlignment = Enum.TextXAlignment.Left
                friendName.BackgroundTransparency = 1
                friendName.TextStrokeTransparency = 0.5
                friendName.TextStrokeColor3 = Color3.new(0, 0, 0)

                local joinBtn = Instance.new("TextButton", card)
                joinBtn.Size = UDim2.new(0, 56, 0, 26)
                joinBtn.Position = UDim2.new(1, -66, 1, -41)
                joinBtn.BackgroundColor3 = Color3.new(0, 0, 0)
                joinBtn.BackgroundTransparency = 0.4
                joinBtn.BorderSizePixel = 0
                joinBtn.Text = "JOIN"
                joinBtn.Font = Enum.Font.GothamBold
                joinBtn.TextSize = 11
                joinBtn.TextColor3 = C.white
                joinBtn.ZIndex = 2
                corner(joinBtn, 8)
                
                local jStroke = stroke(joinBtn, C.accent, 1, 0)

                joinBtn.MouseButton1Click:Connect(function()
                    if friend.PlaceId and friend.GameId then
                        joinBtn.Text = "..."
                        pcall(function()
                            game:GetService("TeleportService"):TeleportToPlaceInstance(friend.PlaceId, friend.GameId, lp)
                        end)
                        task.wait(2)
                        joinBtn.Text = "JOIN"
                    end
                end)

                joinBtn.MouseEnter:Connect(function()
                    tween(joinBtn, {BackgroundColor3 = C.accent, BackgroundTransparency = 0.1, TextColor3 = C.black}, 0.25)
                end)
                
                joinBtn.MouseLeave:Connect(function()
                    tween(joinBtn, {BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, TextColor3 = C.white}, 0.25)
                end)

                card.MouseEnter:Connect(function()
                    tween(cardStroke, {Transparency = 0, Color = C.accent}, 0.3)
                end)
                
                card.MouseLeave:Connect(function()
                    tween(cardStroke, {Transparency = 0.85, Color = Color3.new(1, 1, 1)}, 0.3)
                end)
            end
        end
        
        if count == 0 then
            local none = Instance.new("TextLabel", homePage)
            none.Size = UDim2.new(1, -8, 0, 40)
            none.Text = "No friends currently in-game."
            none.Font = Enum.Font.Gotham
            none.TextSize = 12
            none.TextColor3 = C.textMuted
            none.BackgroundTransparency = 1
            none.LayoutOrder = 10
        end
    end
end)
end) -- end PAGE: HOME

-- 
-- PAGE: FEATURES (Movement & Physics)
-- 
task.spawn(function()
-- 
local featuresPage = createPage("features")


createSection(featuresPage, "Movement & Physics", 1)

local moveGrid = createGridContainer(featuresPage, 2)

createKeybindToggle(moveGrid, "Click Teleport", "Press key to teleport to your mouse position", "ClickTeleport", "ClickTeleport", Keybinds.ClickTeleport, 1, function(on)
    if on and FeatureStates.AnimatedTeleport and ToggleRegistry["AnimatedTeleport"] then
        ToggleRegistry["AnimatedTeleport"](false)
    end
end)

createKeybindToggle(moveGrid, "Animated Teleport", "Teleport with an emote", "AnimatedTeleport", "AnimatedTeleport", Keybinds.AnimatedTeleport, 2, function(on)
    if on and FeatureStates.ClickTeleport and ToggleRegistry["ClickTeleport"] then
        ToggleRegistry["ClickTeleport"](false)
    end
end)

createKeybindToggle(moveGrid, "Trip", "Trip and fall forward", "Trip", "Trip", Keybinds.Trip, 3, function(on)
    -- handled in input listener below
end)

createKeybindToggle(moveGrid, "Reverse", "Rewind time/movement backwards", "Reverse", "Reverse", Keybinds.Reverse, 4, function(on)
    -- handled in heartbeat loop
end)

-- Noclip
createToggle(moveGrid, "Noclip", "Walk through walls", "Noclip", 5, function(on)
    -- handled in stepped below
end)

-- Force Walk Animation
createToggle(moveGrid, "Force Walk Animation", "Replaces your run with your walk anim", "ForceWalkAnimation", 6, function(on)
    FeatureStates.ForceWalkAnimation = on
    local char = Players.LocalPlayer.Character
    local Animate = char and char:FindFirstChild("Animate")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not Animate then return end
    
    local function stopTracks()
        if hum then
            for _, t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop(0) end
        end
    end
    
    if on then
        local walkAnim = Animate:FindFirstChild("walk") and Animate.walk:FindFirstChild("WalkAnim")
        if walkAnim and walkAnim.AnimationId ~= "" then
            stopTracks()
            Animate.run.RunAnim.AnimationId = walkAnim.AnimationId
            animRefresh()
        end
    else
        if FeatureStates.SavedAnimations.Run then
            stopTracks()
            Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. FeatureStates.SavedAnimations.Run
            animRefresh()
        elseif DefaultAnimationsCache and DefaultAnimationsCache.run then
            stopTracks()
            Animate.run.RunAnim.AnimationId = DefaultAnimationsCache.run
            animRefresh()
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if FeatureStates.ForceWalkAnimation then
        local char = Players.LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
                if t.Name == "RunAnim" or t.Name == "WalkAnim" then
                    t:AdjustSpeed(1)
                end
            end
        end
    end
end)

-- Glitch Movement
createKeybindToggle(moveGrid, "Glitch Movement", "Toggle ON then press key to glitch left/right", "GlitchMoveEnabled", "GlitchMove", Keybinds.GlitchMove, 7, function(on)
    FeatureStates.GlitchMoveEnabled = on
    if not on then
        FeatureStates.GlitchMoveActive = false
        stopGlitchLoop()
        SendNotification("Eternity", "Glitch Movement disabled.", 2)
    else
        SendNotification("Eternity", "Glitch Movement armed! Press keybind to activate.", 2)
    end
end)

createKeybindToggle(moveGrid, "Go Underground", "Arm toggle, then press keybind to hide inside the floor", "GoUndergroundEnabled", "Go Underground", Enum.KeyCode.U, 10, function(on)
    FeatureStates.GoUndergroundEnabled = on
    if on then
        SendNotification("Eternity", "Go Underground armed! Press keybind to trigger.", 2)
    else
        if FeatureStates.GoUndergroundActive then
            FeatureStates.goUndergroundDeactivate()
        end
        SendNotification("Eternity", "Go Underground disarmed.", 2)
    end
end)

lp.CharacterAdded:Connect(function(char)
    if FeatureStates.GoUndergroundEnabled and ToggleRegistry["GoUndergroundEnabled"] then
        ToggleRegistry["GoUndergroundEnabled"](false)
    end
end)

-- Superman Fly
local sfSpeedSlider
createKeybindToggle(moveGrid, "Superman Fly", "Toggle ON to arm & show settings", "SupermanFlyEnabled", "SupermanFly", Keybinds.SupermanFly, 8, function(on)
    FeatureStates.SupermanFlyEnabled = on
    if sfSpeedSlider then sfSpeedSlider.Visible = on end
    if not on then
        FeatureStates.SupermanFlyActive = false
        if _G.stopSfly then _G.stopSfly() end
    end
end)

sfSpeedSlider = createSlider(featuresPage, "Superman Fly Speed", "Adjust flight speed", 20, 300, 120, 0, 6, function(val)
    _G.sflySpeed = val
end)
sfSpeedSlider.Visible = FeatureStates.SupermanFlyEnabled

-- Speed Boost (with inline speed input)
do
    local frame = Instance.new("Frame", moveGrid)
    frame.Size = UDim2.new(1, -8, 0, 36)
    frame.BackgroundColor3 = C.surface
    frame.BorderSizePixel = 0
    frame.LayoutOrder = 10
    corner(frame, 10)
    
    bindTooltip(frame, "Increase walk speed")

    frame.MouseEnter:Connect(function()
        tween(frame, {BackgroundColor3 = C.surfaceHover}, 0.2)
    end)
    frame.MouseLeave:Connect(function()
        tween(frame, {BackgroundColor3 = C.surface}, 0.2)
    end)

    local titleLbl = Instance.new("TextLabel", frame)
    titleLbl.Size = UDim2.new(1, -130, 1, 0)
    titleLbl.Position = UDim2.new(0, 14, 0, 0)
    titleLbl.Text = "Speed Boost"
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextColor3 = C.white
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextTruncate = Enum.TextTruncate.AtEnd

    -- speed value input box
    local speedBox = Instance.new("TextBox", frame)
    speedBox.Size = UDim2.new(0, 40, 0, 22)
    speedBox.Position = UDim2.new(1, -54, 0.5, -11)
    speedBox.BackgroundColor3 = C.input
    speedBox.BorderSizePixel = 0
    speedBox.Text = tostring(SpeedMultiplier)
    speedBox.Font = Enum.Font.GothamBold
    speedBox.TextSize = 11
    speedBox.TextColor3 = C.white
    speedBox.PlaceholderText = "100"
    speedBox.ClearTextOnFocus = false
    speedBox.ZIndex = 6
    corner(speedBox, 6)
    stroke(speedBox, C.divider, 1, 0.5)

    speedBox.FocusLost:Connect(function()
        local val = tonumber(speedBox.Text)
        if val and val > 0 then
            SpeedMultiplier = val
            if FeatureStates.SpeedBoost then
                pcall(function() humanoid.WalkSpeed = SpeedMultiplier end)
            end
            saveSettings() -- persist the new speed value
        else
            speedBox.Text = tostring(SpeedMultiplier)
        end
    end)

    -- toggle track
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(0, 40, 0, 22)
    track.Position = UDim2.new(1, -104, 0.5, -11)
    track.BackgroundColor3 = C.toggleOff
    track.BorderSizePixel = 0
    corner(track, 11)

    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = C.toggleKnob
    knob.BorderSizePixel = 0
    corner(knob, 8)

    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Size = UDim2.new(1, -60, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 5

    local isOn = FeatureStates.SpeedBoost or false

    local function updateVisual()
        if isOn then
            tween(track, {BackgroundColor3 = C.toggleOn}, 0.25)
            tween(knob, {Position = UDim2.new(0, 21, 0.5, -8)}, 0.25, Enum.EasingStyle.Back)
        else
            tween(track, {BackgroundColor3 = C.toggleOff}, 0.25)
            tween(knob, {Position = UDim2.new(0, 3, 0.5, -8)}, 0.25, Enum.EasingStyle.Back)
        end
    end

    local function setToggle(val)
        isOn = val
        FeatureStates.SpeedBoost = val
        updateVisual()
        if val then
            pcall(function()
                local currHum = lp.Character and lp.Character:FindFirstChild("Humanoid")
                if currHum then currHum.WalkSpeed = SpeedMultiplier end
            end)
        else
            pcall(function()
                local currHum = lp.Character and lp.Character:FindFirstChild("Humanoid")
                if currHum then currHum.WalkSpeed = 16 end
            end)
        end
        task.spawn(saveSettings)
    end
    ToggleRegistry["SpeedBoost"] = setToggle

    RunService.Stepped:Connect(function()
        if IsKeyVerified and FeatureStates.SpeedBoost then
            pcall(function()
                local hum = lp.Character and lp.Character:FindFirstChild("Humanoid")
                if hum and hum.WalkSpeed ~= SpeedMultiplier then
                    hum.WalkSpeed = SpeedMultiplier
                end
            end)
        end
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        setToggle(not isOn)
    end)

    updateVisual()
end

-- Infinite Jump
createToggle(moveGrid, "Infinite Jump", "Jump while in the air", "InfiniteJump", 9, function(on)
    -- handled in input listener below
end)
end) -- end PAGE: FEATURES

-- 
-- PAGE: ATTACH
-- 
combatPage = createPage("combat")


createSection(combatPage, "Facebang & Hipbang Controls", 1)

local fbSpeedSlider
local fbDistSlider

createKeybindToggle(combatPage, "Facebang", "Toggle ON to arm & show settings", "FacebangEnabled", "Facebang", Keybinds.Facebang, 2, function(on)
    FeatureStates.FacebangEnabled = on
    if fbSpeedSlider then fbSpeedSlider.Visible = on end
    if fbDistSlider then fbDistSlider.Visible = on end
    if not on then
        -- When toggle is turned OFF, also stop any active facebang
        FeatureStates.Facebang = false
        FacebangTarget = nil
        SendNotification("Eternity", "Facebang disabled.", 2)
    else
        SendNotification("Eternity", "Facebang armed! Press keybind to activate.", 2)
    end
end)

fbSpeedSlider = createSlider(combatPage, "Facebang Speed", "Adjust facebang speed", 1, 20, FacebangSpeed, 1, 3, function(val)
    FacebangSpeed = val
end)
fbSpeedSlider.Visible = FeatureStates.FacebangEnabled

fbDistSlider = createSlider(combatPage, "Facebang Distance", "Adjust facebang distance range", 0.5, 10, FacebangDistance, 1, 4, function(val)
    FacebangDistance = val
end)
fbDistSlider.Visible = FeatureStates.FacebangEnabled



local hbSpeedSlider
local hbDistSlider

createKeybindToggle(combatPage, "Hipbang", "Toggle ON to arm & show settings", "HipbangEnabled", "Hipbang", Keybinds.Hipbang, 5, function(on)
    FeatureStates.HipbangEnabled = on
    if hbSpeedSlider then hbSpeedSlider.Visible = on end
    if hbDistSlider then hbDistSlider.Visible = on end
    if not on then
        FeatureStates.Hipbang = false
        HipbangTarget = nil
        SendNotification("Eternity", "Hipbang disabled.", 2)
    else
        SendNotification("Eternity", "Hipbang armed! Press keybind to activate.", 2)
    end
end)

hbSpeedSlider = createSlider(combatPage, "Hipbang Speed", "Adjust hipbang speed", 1, 20, HipbangSpeed, 1, 6, function(val)
    HipbangSpeed = val
end)
hbSpeedSlider.Visible = FeatureStates.HipbangEnabled

hbDistSlider = createSlider(combatPage, "Hipbang Distance", "Adjust hipbang distance range", 0.5, 10, HipbangDistance, 1, 7, function(val)
    HipbangDistance = val
end)
hbDistSlider.Visible = FeatureStates.HipbangEnabled



createSection(combatPage, "Other Interactions", 8)
local combatGrid = createGridContainer(combatPage, 9)

createKeybindToggle(combatGrid, "Pat", "Stand in front and pat target", "PatEnabled", "Pat", Keybinds.Pat, 1, function(on)
    FeatureStates.PatEnabled = on
    if not on then
        FeatureStates.Pat = false
        PatTarget = nil
        SendNotification("Eternity", "Pat disabled.", 2)
    else
        SendNotification("Eternity", "Pat armed! Press keybind to activate.", 2)
    end
end)

createKeybindToggle(combatGrid, "Headsit", "Sit on target's head", "HeadsitEnabled", "Headsit", Keybinds.Headsit, 2, function(on)
    FeatureStates.HeadsitEnabled = on
    if not on then
        FeatureStates.Headsit = false
        HeadsitTarget = nil
        SendNotification("Eternity", "Headsit disabled.", 2)
    else
        SendNotification("Eternity", "Headsit armed! Press keybind to activate.", 2)
    end
end)

createKeybindToggle(combatGrid, "Back Hug", "Hug target from behind", "BackhugEnabled", "Backhug", Keybinds.Backhug, 3, function(on)
    FeatureStates.BackhugEnabled = on
    if not on then
        FeatureStates.Backhug = false
        BackhugTarget = nil
        SendNotification("Eternity", "Backhug disabled.", 2)
    else
        SendNotification("Eternity", "Backhug armed! Press keybind to activate.", 2)
    end
end)

createKeybindToggle(combatGrid, "Front Hug", "Hug target from the front", "FronthugEnabled", "Fronthug", Keybinds.Fronthug, 4, function(on)
    FeatureStates.FronthugEnabled = on
    if not on then
        FeatureStates.Fronthug = false
        FronthugTarget = nil
        SendNotification("Eternity", "Fronthug disabled.", 2)
    else
        SendNotification("Eternity", "Fronthug armed! Press keybind to activate.", 2)
    end
end)

createKeybindToggle(combatGrid, "Propose", "Propose to target", "ProposeEnabled", "Propose", Keybinds.Propose, 5, function(on)
    FeatureStates.ProposeEnabled = on
    if not on then
        FeatureStates.Propose = false
        ProposeTarget = nil
        SendNotification("Eternity", "Propose disabled.", 2)
    else
        SendNotification("Eternity", "Propose armed! Press keybind to activate.", 2)
    end
end)

createKeybindToggle(combatGrid, "Bagpack", "Attach to target's back like a backpack", "BagpackEnabled", "Bagpack", Keybinds.Bagpack, 6, function(on)
    FeatureStates.BagpackEnabled = on
    if not on then
        FeatureStates.Bagpack = false
        BagpackTarget = nil
        SendNotification("Eternity", "Bagpack disabled.", 2)
    else
        SendNotification("Eternity", "Bagpack armed! Press keybind to activate.", 2)
    end
end)

createKeybindToggle(combatGrid, "Goon", "Face to face emote", "GoonEnabled", "Goon", Keybinds.Goon, 7, function(on)
    FeatureStates.GoonEnabled = on
    if not on then
        FeatureStates.Goon = false
        GoonTarget = nil
        SendNotification("Eternity", "Goon disabled.", 2)
    else
        SendNotification("Eternity", "Goon armed! Press keybind to activate.", 2)
    end
end)
-- 
-- PAGE: TARGET
-- 
targetPage = createPage("target")

local tgt_updateSelection
local tgt_buildList

do
    local PendingTargetId = nil

    createSection(targetPage, "Target Selection", 1)

--  Selected player display 
local tgt_selContainer = Instance.new("Frame", targetPage)
tgt_selContainer.Size = UDim2.new(1, -8, 0, 146)
tgt_selContainer.BackgroundTransparency = 1
tgt_selContainer.LayoutOrder = 2

local tgt_selRow = Instance.new("Frame", tgt_selContainer)
tgt_selRow.Size = UDim2.new(1, -130, 1, 0)
tgt_selRow.BackgroundColor3 = C.surface
tgt_selRow.BorderSizePixel = 0
corner(tgt_selRow, 8)
applyPremiumCardEffect(tgt_selRow)

local tgt_selThumb = Instance.new("ImageLabel", tgt_selRow)
tgt_selThumb.Size = UDim2.new(0, 60, 0, 60)
tgt_selThumb.Position = UDim2.new(0, 8, 0.5, -30)
tgt_selThumb.BackgroundColor3 = C.bgCard
tgt_selThumb.BorderSizePixel = 0
tgt_selThumb.ZIndex = 2
tgt_selThumb.Image = ""
tgt_selThumb.ImageTransparency = 1
corner(tgt_selThumb, 6)

local tgt_selDisplay = Instance.new("TextLabel", tgt_selRow)
tgt_selDisplay.Text = "No target selected"
tgt_selDisplay.Size = UDim2.new(1, -80, 0, 20)
tgt_selDisplay.Position = UDim2.new(0, 75, 0, 20)
tgt_selDisplay.BackgroundTransparency = 1
tgt_selDisplay.TextColor3 = C.text
tgt_selDisplay.TextXAlignment = Enum.TextXAlignment.Left
tgt_selDisplay.Font = Enum.Font.GothamBold
tgt_selDisplay.TextSize = 13
tgt_selDisplay.ZIndex = 2

local tgt_selUser = Instance.new("TextLabel", tgt_selRow)
tgt_selUser.Text = ""
tgt_selUser.Size = UDim2.new(1, -80, 0, 16)
tgt_selUser.Position = UDim2.new(0, 75, 0, 42)
tgt_selUser.BackgroundTransparency = 1
tgt_selUser.TextColor3 = C.textMuted
tgt_selUser.TextXAlignment = Enum.TextXAlignment.Left
tgt_selUser.Font = Enum.Font.Gotham
tgt_selUser.TextSize = 11
tgt_selUser.ZIndex = 2

local tgt_selAge = Instance.new("TextLabel", tgt_selRow)
tgt_selAge.Text = "Account Age: --"
tgt_selAge.Size = UDim2.new(1, -80, 0, 14)
tgt_selAge.Position = UDim2.new(0, 75, 0, 70)
tgt_selAge.BackgroundTransparency = 1
tgt_selAge.TextColor3 = C.textMuted
tgt_selAge.TextXAlignment = Enum.TextXAlignment.Left
tgt_selAge.Font = Enum.Font.Gotham
tgt_selAge.TextSize = 11
tgt_selAge.ZIndex = 2

local tgt_selFriends = Instance.new("TextLabel", tgt_selRow)
tgt_selFriends.Text = "Friends in server: --"
tgt_selFriends.Size = UDim2.new(1, -80, 0, 14)
tgt_selFriends.Position = UDim2.new(0, 75, 0, 88)
tgt_selFriends.BackgroundTransparency = 1
tgt_selFriends.TextColor3 = C.textMuted
tgt_selFriends.TextXAlignment = Enum.TextXAlignment.Left
tgt_selFriends.Font = Enum.Font.Gotham
tgt_selFriends.TextSize = 11
tgt_selFriends.ZIndex = 2

local tgt_viewFriendsBtn = Instance.new("TextButton", tgt_selRow)
tgt_viewFriendsBtn.Size = UDim2.new(0, 36, 0, 16)
tgt_viewFriendsBtn.Position = UDim2.new(0, 185, 0, 87)
tgt_viewFriendsBtn.BackgroundColor3 = C.bgCard
tgt_viewFriendsBtn.BorderSizePixel = 0
tgt_viewFriendsBtn.Text = "View"
tgt_viewFriendsBtn.TextColor3 = C.text
tgt_viewFriendsBtn.Font = Enum.Font.GothamBold
tgt_viewFriendsBtn.TextSize = 10
tgt_viewFriendsBtn.Visible = false
tgt_viewFriendsBtn.ZIndex = 3
corner(tgt_viewFriendsBtn, 4)
stroke(tgt_viewFriendsBtn, C.accent, 1, 0.4)

local tgt_viewFriendsTooltip = Instance.new("TextLabel", tgt_viewFriendsBtn)
tgt_viewFriendsTooltip.AutomaticSize = Enum.AutomaticSize.Y
tgt_viewFriendsTooltip.Size = UDim2.new(0, 200, 0, 0)
tgt_viewFriendsTooltip.TextWrapped = true
tgt_viewFriendsTooltip.Position = UDim2.new(1, 0, 1, 6)
tgt_viewFriendsTooltip.AnchorPoint = Vector2.new(1, 0)
tgt_viewFriendsTooltip.BackgroundColor3 = C.bgCard
tgt_viewFriendsTooltip.TextColor3 = C.text
tgt_viewFriendsTooltip.Font = Enum.Font.Gotham
tgt_viewFriendsTooltip.TextSize = 11
tgt_viewFriendsTooltip.Visible = false
tgt_viewFriendsTooltip.ZIndex = 10
local ttPadding = Instance.new("UIPadding", tgt_viewFriendsTooltip)
ttPadding.PaddingLeft = UDim.new(0, 6)
ttPadding.PaddingRight = UDim.new(0, 6)
ttPadding.PaddingTop = UDim.new(0, 4)
ttPadding.PaddingBottom = UDim.new(0, 4)
corner(tgt_viewFriendsTooltip, 4)
stroke(tgt_viewFriendsTooltip, C.accent, 1, 0.5)

tgt_viewFriendsBtn.MouseEnter:Connect(function() 
    tween(tgt_viewFriendsBtn, {BackgroundColor3 = C.surfaceHover}, 0.2) 
    tgt_viewFriendsTooltip.Visible = true
end)
tgt_viewFriendsBtn.MouseLeave:Connect(function() 
    tween(tgt_viewFriendsBtn, {BackgroundColor3 = C.bgCard}, 0.2) 
    tgt_viewFriendsTooltip.Visible = false
end)

local function clearActiveTargetActions()
    FeatureStates.Facebang = false; FacebangTarget = nil
    FeatureStates.Pat = false; PatTarget = nil
    FeatureStates.Headsit = false; HeadsitTarget = nil
    FeatureStates.Backhug = false; BackhugTarget = nil
    FeatureStates.Fronthug = false; FronthugTarget = nil
    FeatureStates.Propose = false; ProposeTarget = nil
    FeatureStates.Hipbang = false; HipbangTarget = nil
    FeatureStates.Bagpack = false; BagpackTarget = nil
    FeatureStates.Goon = false; GoonTarget = nil
end

-- Helper: update selected player UI
tgt_updateSelection = function(plr)
    TargetPlayer = plr
    if plr then
        PendingTargetId = nil
        tgt_selThumb.Image = "rbxthumb://type=AvatarHeadShot&id="..plr.UserId.."&w=420&h=420"
        tgt_selThumb.ImageTransparency = 0
        tgt_selDisplay.Text = plr.DisplayName
        tgt_selUser.Text    = "@"..plr.Name
        tgt_selUser.TextColor3 = C.textMuted
        tgt_selAge.Text = "Account Age: " .. tostring(plr.AccountAge) .. " days"
        tgt_selFriends.Text = "Friends in server: Checking..."
        tgt_selFriends.TextColor3 = C.textMuted
        tgt_viewFriendsBtn.Visible = false
        
        task.spawn(function()
            local friendNames = {}
            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= plr and other ~= lp then
                    local s, isFriend = pcall(function() return plr:IsFriendsWith(other.UserId) end)
                    if s and isFriend then
                        table.insert(friendNames, other.DisplayName)
                    end
                end
            end
            if TargetPlayer == plr then
                if #friendNames > 0 then
                    tgt_selFriends.Text = "Friends in server: " .. tostring(#friendNames)
                    tgt_selFriends.TextColor3 = C.danger
                    tgt_viewFriendsTooltip.Text = table.concat(friendNames, ", ")
                    tgt_viewFriendsBtn.Visible = true
                else
                    tgt_selFriends.Text = "Friends in server: None"
                    tgt_selFriends.TextColor3 = C.textMuted
                    tgt_viewFriendsBtn.Visible = false
                end
            end
        end)
        
        tween(tgt_selRow, {BackgroundColor3 = C.surfaceHover}, 0.2)
    else
        tgt_selThumb.Image = ""
        tgt_selThumb.ImageTransparency = 1
        tgt_selDisplay.Text = "No target selected"
        tgt_selUser.Text    = ""
        tgt_selAge.Text = "Account Age: --"
        tgt_selFriends.Text = "Friends in server: --"
        tgt_selFriends.TextColor3 = C.textMuted
        tgt_viewFriendsBtn.Visible = false
        tween(tgt_selRow, {BackgroundColor3 = C.surface}, 0.2)
    end
end

local tgt_utilContainer = Instance.new("Frame", tgt_selContainer)
tgt_utilContainer.Size = UDim2.new(0, 122, 1, 0)
tgt_utilContainer.Position = UDim2.new(1, -122, 0, 0)
tgt_utilContainer.BackgroundTransparency = 1

local utilLayout = Instance.new("UIListLayout", tgt_utilContainer)
utilLayout.FillDirection = Enum.FillDirection.Vertical
utilLayout.SortOrder = Enum.SortOrder.LayoutOrder
utilLayout.Padding = UDim.new(0, 6)

local function createTargetUtilBtn(text, order, stateCheck)
    local btn = Instance.new("TextButton", tgt_utilContainer)
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.LayoutOrder = order
    btn.BackgroundColor3 = C.surface
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = C.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    corner(btn, 6)
    local btnStroke = stroke(btn, C.surfaceHover, 1, 0)
    btn.MouseEnter:Connect(function() 
        if stateCheck and stateCheck() then return end
        tween(btn, {BackgroundColor3 = C.surfaceHover}, 0.2) 
    end)
    btn.MouseLeave:Connect(function() 
        if stateCheck and stateCheck() then return end
        tween(btn, {BackgroundColor3 = C.surface}, 0.2) 
    end)
    return btn
end

local tgt_clickBtn = createTargetUtilBtn("Click Target", 1, function() return FeatureStates.ClickToTarget end)
local tgt_viewBtn = createTargetUtilBtn("View Target", 2, function() 
    local cam = workspace.CurrentCamera
    return (cam.CameraSubject ~= humanoid and cam.CameraSubject ~= nil)
end)
local tgt_tpBtn = createTargetUtilBtn("Teleport", 3)
local tgt_clearBtn = createTargetUtilBtn("Clear", 4)
tgt_clearBtn.MouseEnter:Connect(function() tween(tgt_clearBtn, {BackgroundColor3 = Color3.fromRGB(180, 50, 50), TextColor3 = C.white}, 0.2) end)
tgt_clearBtn.MouseLeave:Connect(function() tween(tgt_clearBtn, {BackgroundColor3 = C.surface, TextColor3 = C.text}, 0.2) end)

tgt_clearBtn.MouseButton1Click:Connect(function()
    if TargetPlayer then
        PendingTargetId = nil
        tgt_updateSelection(nil)
        SendNotification("Eternity", "Target cleared.", 2)
        if workspace.CurrentCamera.CameraSubject ~= humanoid then
            workspace.CurrentCamera.CameraSubject = humanoid
        end
        if type(tgt_buildList) == "function" then tgt_buildList() end
    end
end)

local hoverHighlight = Instance.new("Highlight")
hoverHighlight.Name = "EternityHoverHighlight"
hoverHighlight.FillColor = C.accent
hoverHighlight.OutlineColor = C.accent
hoverHighlight.FillTransparency = 0.8
hoverHighlight.OutlineTransparency = 0
hoverHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

local hoverGui = Instance.new("BillboardGui")
hoverGui.Name = "EternityHoverName"
hoverGui.Size = UDim2.new(0, 150, 0, 40)
hoverGui.StudsOffset = Vector3.new(0, 4, 0)
hoverGui.AlwaysOnTop = true
local hoverNameLbl = Instance.new("TextLabel", hoverGui)
hoverNameLbl.Size = UDim2.new(1, 0, 1, 0)
hoverNameLbl.BackgroundTransparency = 1
hoverNameLbl.Font = Enum.Font.GothamBold
hoverNameLbl.TextSize = 12
hoverNameLbl.TextColor3 = C.accent
hoverNameLbl.TextStrokeTransparency = 0.5

tgt_clickBtn.MouseButton1Click:Connect(function()
    local on = not FeatureStates.ClickToTarget
    FeatureStates.ClickToTarget = on
    pcall(function() StarterGui:SetCore("AvatarContextMenuEnabled", not on) end)
    if not on then
        hoverHighlight.Parent = nil
        hoverGui.Parent = nil
    end
    if on then
        tgt_clickBtn.TextColor3 = C.white
        tgt_clickBtn.Text = "Stop Click"
        tween(tgt_clickBtn, {BackgroundColor3 = Color3.fromRGB(180, 50, 50)}, 0.2)
    else
        tgt_clickBtn.TextColor3 = C.text
        tgt_clickBtn.Text = "Click Target"
        tween(tgt_clickBtn, {BackgroundColor3 = C.surfaceHover}, 0.2)
    end
end)

tgt_viewBtn.MouseButton1Click:Connect(function()
    local cam = workspace.CurrentCamera
    if cam.CameraSubject ~= humanoid then
        if humanoid then cam.CameraSubject = humanoid end
        tgt_viewBtn.TextColor3 = C.text
        tgt_viewBtn.Text = "View Target"
        tween(tgt_viewBtn, {BackgroundColor3 = C.surfaceHover}, 0.2)
    else
        if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("Humanoid") then
            cam.CameraSubject = TargetPlayer.Character.Humanoid
            tgt_viewBtn.TextColor3 = C.white
            tgt_viewBtn.Text = "Stop View"
            tween(tgt_viewBtn, {BackgroundColor3 = Color3.fromRGB(180, 50, 50)}, 0.2)
        else
            SendNotification("Eternity", "No target selected!", 3)
        end
    end
end)

tgt_tpBtn.MouseButton1Click:Connect(function()
    tween(tgt_tpBtn, {BackgroundColor3 = C.accent}, 0.1)
    task.delay(0.1, function() tween(tgt_tpBtn, {BackgroundColor3 = C.surfaceHover}, 0.2) end)
    if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") and rootPart then
        rootPart.CFrame = TargetPlayer.Character.HumanoidRootPart.CFrame
        SendNotification("Eternity", "Teleported to " .. TargetPlayer.DisplayName, 2)
    else
        SendNotification("Eternity", "No target selected!", 3)
    end
end)


RunService.RenderStepped:Connect(function()
    if FeatureStates.ClickToTarget then
        local mouse = lp:GetMouse()
        local target = mouse.Target
        local foundPlr = nil
        if target and target.Parent then
            local model = target.Parent
            if not model:FindFirstChild("Humanoid") then
                model = model.Parent
            end
            if model and model:FindFirstChild("Humanoid") then
                foundPlr = Players:GetPlayerFromCharacter(model)
            end
        end

        if foundPlr and foundPlr ~= lp then
            if hoverHighlight.Parent ~= foundPlr.Character then
                hoverHighlight.Parent = foundPlr.Character
                hoverGui.Parent = foundPlr.Character:FindFirstChild("Head") or foundPlr.Character
                hoverNameLbl.Text = foundPlr.DisplayName .. "\n(@" .. foundPlr.Name .. ")"
            end
        else
            hoverHighlight.Parent = nil
            hoverGui.Parent = nil
        end
    end
end)

--  Target Actions Grid 
createSection(targetPage, "Target Actions", 3)

local actionsContainer = Instance.new("Frame", targetPage)
actionsContainer.Size = UDim2.new(1, -8, 0, 0)
actionsContainer.AutomaticSize = Enum.AutomaticSize.Y
actionsContainer.BackgroundTransparency = 1
actionsContainer.LayoutOrder = 4

local actionsLayout = Instance.new("UIGridLayout", actionsContainer)
actionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
actionsLayout.CellSize = UDim2.new(0.33333, -5, 0, 24)
actionsLayout.CellPadding = UDim2.new(0, 7, 0, 6)

local function createGridButton(title, isToggle, callback, order)
    local btn = Instance.new("TextButton", actionsContainer)
    btn.LayoutOrder = order or 1
    btn.BackgroundColor3 = C.surface
    btn.BorderSizePixel = 0
    btn.Text = title
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = C.text
    corner(btn, 6)
    local btnStroke = stroke(btn, C.surfaceHover, 1, 0)
    
    local stateOn = false
    
    local function updateState(newOn)
        stateOn = newOn
        if stateOn then
            tween(btn, {BackgroundColor3 = Color3.fromRGB(180, 50, 50)}, 0.2)
            btn.TextColor3 = C.white
        else
            tween(btn, {BackgroundColor3 = C.surfaceHover}, 0.2)
            btn.TextColor3 = C.text
        end
    end

    btn.MouseEnter:Connect(function()
        if not stateOn then tween(btn, {BackgroundColor3 = C.surfaceHover}, 0.2) end
        btnStroke.Color = C.accent
    end)
    btn.MouseLeave:Connect(function()
        if not stateOn then tween(btn, {BackgroundColor3 = C.surface}, 0.2) end
        btnStroke.Color = C.surfaceHover
    end)
    
    btn.MouseButton1Click:Connect(function()
        if isToggle then
            local success = callback(not stateOn)
            if success ~= false then
                updateState(not stateOn)
            end
        else
            tween(btn, {BackgroundColor3 = C.accent}, 0.1)
            task.delay(0.1, function() tween(btn, {BackgroundColor3 = C.surfaceHover}, 0.2) end)
            callback()
        end
    end)
    return btn, updateState
end




local function getValidAttachTarget(requireHead)
    if TargetPlayer and TargetPlayer.Character then
        if requireHead and TargetPlayer.Character:FindFirstChild("Head") then return TargetPlayer end
        if (not requireHead) and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then return TargetPlayer end
    end
    local closest, minDist = nil, math.huge
    if rootPart then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= lp and p.Character then
                local pt = requireHead and p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
                if pt then
                    local d = (pt.Position - rootPart.Position).Magnitude
                    if d < minDist then minDist = d; closest = p end
                end
            end
        end
    end
    return closest
end

GridButtonVisuals["Facebang"] = select(2, createGridButton("Facebang", true, function(on)
    if on then
        local target = getValidAttachTarget(true)
        if target then
            FacebangTarget = target
            SetAttachState("Facebang", true)
            SendNotification("Eternity", "Attaching to "..target.DisplayName, 2)
        else
            SendNotification("Eternity", "No valid target found!", 3)
            return false
        end
    else
        SetAttachState("Facebang", false)
        SendNotification("Eternity", "Attach stopped.", 2)
    end
    return false
end, 1))

GridButtonVisuals["Pat"] = select(2, createGridButton("Pat", true, function(on)
    if on then
        local target = getValidAttachTarget(true)
        if target then
            PatTarget = target
            SetAttachState("Pat", true)
            SendNotification("Eternity", "Patting "..target.DisplayName, 2)
        else
            SendNotification("Eternity", "No valid target found!", 3)
            return false
        end
    else
        SetAttachState("Pat", false)
        SendNotification("Eternity", "Pat stopped.", 2)
    end
    return false
end, 2))

GridButtonVisuals["Headsit"] = select(2, createGridButton("Headsit", true, function(on)
    if on then
        local target = getValidAttachTarget(true)
        if target then
            HeadsitTarget = target
            SetAttachState("Headsit", true)
            SendNotification("Eternity", "Headsitting on "..target.DisplayName, 2)
        else
            SendNotification("Eternity", "No valid target found!", 3)
            return false
        end
    else
        SetAttachState("Headsit", false)
        SendNotification("Eternity", "Headsit stopped.", 2)
    end
    return false
end, 3))

GridButtonVisuals["Backhug"] = select(2, createGridButton("Backhug", true, function(on)
    if on then
        local target = getValidAttachTarget(true)
        if target then
            BackhugTarget = target
            SetAttachState("Backhug", true)
            SendNotification("Eternity", "Backhugging "..target.DisplayName, 2)
        else
            SendNotification("Eternity", "No valid target found!", 3)
            return false
        end
    else
        SetAttachState("Backhug", false)
        SendNotification("Eternity", "Backhug stopped.", 2)
    end
    return false
end, 4))

GridButtonVisuals["Fronthug"] = select(2, createGridButton("Fronthug", true, function(on)
    if on then
        local target = getValidAttachTarget(true)
        if target then
            FronthugTarget = target
            SetAttachState("Fronthug", true)
            SendNotification("Eternity", "Fronthugging "..target.DisplayName, 2)
        else
            SendNotification("Eternity", "No valid target found!", 3)
            return false
        end
    else
        SetAttachState("Fronthug", false)
        SendNotification("Eternity", "Fronthug stopped.", 2)
    end
    return false
end, 5))

GridButtonVisuals["Propose"] = select(2, createGridButton("Propose", true, function(on)
    if on then
        local target = getValidAttachTarget(true)
        if target then
            ProposeTarget = target
            SetAttachState("Propose", true)
            SendNotification("Eternity", "Proposing to "..target.DisplayName, 2)
        else
            SendNotification("Eternity", "No valid target found!", 3)
            return false
        end
    else
        SetAttachState("Propose", false)
        SendNotification("Eternity", "Propose stopped.", 2)
    end
    return false
end, 6))

GridButtonVisuals["Hipbang"] = select(2, createGridButton("Hipbang", true, function(on)
    if on then
        local target = getValidAttachTarget(false)
        if target then
            HipbangTarget = target
            SetAttachState("Hipbang", true)
            SendNotification("Eternity", "Hipbanging "..target.DisplayName, 2)
        else
            SendNotification("Eternity", "No valid target found!", 3)
            return false
        end
    else
        SetAttachState("Hipbang", false)
        SendNotification("Eternity", "Hipbang stopped.", 2)
    end
    return false
end, 7))

GridButtonVisuals["Bagpack"] = select(2, createGridButton("Bagpack", true, function(on)
    if on then
        local target = getValidAttachTarget(false)
        if target then
            BagpackTarget = target
            SetAttachState("Bagpack", true)
            SendNotification("Eternity", "Bagpacking "..target.DisplayName, 2)
        else
            SendNotification("Eternity", "No valid target found!", 3)
            return false
        end
    else
        SetAttachState("Bagpack", false)
        SendNotification("Eternity", "Bagpack stopped.", 2)
    end
    return false
end, 8))

GridButtonVisuals["Goon"] = select(2, createGridButton("Goon", true, function(on)
    if on then
        local target = getValidAttachTarget(true)
        if target then
            GoonTarget = target
            SetAttachState("Goon", true)
            SendNotification("Eternity", "Gooning "..target.DisplayName, 2)
        else
            SendNotification("Eternity", "No valid target found!", 3)
            return false
        end
    else
        SetAttachState("Goon", false)
        SendNotification("Eternity", "Goon stopped.", 2)
    end
    return false
end, 9))

--  Player search list 
createSection(targetPage, "Player Search", 6)

local tgt_searchBox = createInputField(targetPage, "SEARCH PLAYERS", "Search by name...", "", 7)
local searchIcon = Instance.new("ImageLabel", tgt_searchBox.Parent)
searchIcon.Size = UDim2.new(0, 12, 0, 12)
searchIcon.Position = UDim2.new(0, 20, 0, 33)
searchIcon.BackgroundTransparency = 1
local success, result = pcall(function() return getasset("eternity_assets/audios/search.png") end)
if success and result then
    searchIcon.Image = result
end
searchIcon.ImageColor3 = C.textMuted
searchIcon.ZIndex = 2
local searchPad = tgt_searchBox:FindFirstChildOfClass("UIPadding")
if searchPad then searchPad.PaddingLeft = UDim.new(0, 24) end

local tgt_listFrame = Instance.new("Frame", targetPage)
tgt_listFrame.Size = UDim2.new(1, -8, 0, 0)
tgt_listFrame.BackgroundTransparency = 1
tgt_listFrame.BorderSizePixel = 0
tgt_listFrame.AutomaticSize = Enum.AutomaticSize.Y
tgt_listFrame.LayoutOrder = 8

local tgt_listLayout = Instance.new("UIListLayout", tgt_listFrame)
tgt_listLayout.Padding = UDim.new(0, 4)
tgt_listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

tgt_buildList = function()
    for _, c in ipairs(tgt_listFrame:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    local filter = tgt_searchBox.Text:lower()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then
            local dn = plr.DisplayName:lower()
            local un = plr.Name:lower()
            if filter == "" or dn:find(filter, 1, true) or un:find(filter, 1, true) then
                local isSelected = (TargetPlayer == plr)
                
                local row = Instance.new("Frame", tgt_listFrame)
                row.Size = UDim2.new(1, -4, 0, 42)
                row.BackgroundColor3 = isSelected and C.accent or C.surface
                row.BackgroundTransparency = isSelected and 0 or 0
                row.BorderSizePixel = 0
                row.ZIndex = 3
                corner(row, 6)
                local rowStroke = stroke(row, isSelected and C.accent or C.surfaceHover, 1, 0)
                
                local thumb = Instance.new("ImageLabel", row)
                thumb.Size = UDim2.new(0, 34, 0, 34)
                thumb.Position = UDim2.new(0, 4, 0.5, -17)
                thumb.BackgroundColor3 = C.bgCard
                thumb.BorderSizePixel = 0
                thumb.ZIndex = 4
                thumb.Image = "rbxthumb://type=AvatarHeadShot&id="..plr.UserId.."&w=420&h=420"
                corner(thumb, 5)

                local dnLbl = Instance.new("TextLabel", row)
                dnLbl.Text = plr.DisplayName
                dnLbl.Size = UDim2.new(1, -46, 0, 16)
                dnLbl.Position = UDim2.new(0, 42, 0, 6)
                dnLbl.BackgroundTransparency = 1
                dnLbl.TextColor3 = isSelected and C.black or C.text
                dnLbl.TextXAlignment = Enum.TextXAlignment.Left
                dnLbl.Font = Enum.Font.GothamBold
                dnLbl.TextSize = 12
                dnLbl.ZIndex = 4

                local unLbl = Instance.new("TextLabel", row)
                unLbl.Text = "@"..plr.Name
                unLbl.Size = UDim2.new(1, -46, 0, 14)
                unLbl.Position = UDim2.new(0, 42, 0, 23)
                unLbl.BackgroundTransparency = 1
                unLbl.TextColor3 = isSelected and C.bg or C.textMuted
                unLbl.TextXAlignment = Enum.TextXAlignment.Left
                unLbl.Font = Enum.Font.Gotham
                unLbl.TextSize = 10
                unLbl.ZIndex = 4

                local sel = Instance.new("TextButton", row)
                sel.Size = UDim2.new(1, 0, 1, 0)
                sel.BackgroundTransparency = 1
                sel.Text = ""
                sel.ZIndex = 5
                
                sel.MouseEnter:Connect(function()
                    if TargetPlayer ~= plr then
                        tween(row, {BackgroundColor3 = C.surfaceHover}, 0.1)
                        rowStroke.Color = C.accent
                    end
                end)
                sel.MouseLeave:Connect(function()
                    if TargetPlayer ~= plr then
                        tween(row, {BackgroundColor3 = C.surface}, 0.1)
                        rowStroke.Color = C.surfaceHover
                    end
                end)
                sel.MouseButton1Click:Connect(function()
                    if TargetPlayer == plr then
                        tgt_updateSelection(nil)
                        SendNotification("Eternity", "Deselected target", 2)
                    else
                        tgt_updateSelection(plr)
                        SendNotification("Eternity", "Selected: "..plr.DisplayName, 2)
                    end
                    tgt_buildList()
                end)
            end
        end
    end
end

tgt_buildList()
tgt_searchBox:GetPropertyChangedSignal("Text"):Connect(tgt_buildList)
Players.PlayerAdded:Connect(function(plr)
    if PendingTargetId and plr.UserId == PendingTargetId then
        SendNotification("Eternity", " TARGET RETURNED: " .. plr.DisplayName .. " has rejoined the game!", 6)
        local savedId = PendingTargetId
        PendingTargetId = nil
        task.delay(1.5, function()
            local returnedPlr = Players:GetPlayerByUserId(savedId)
            if returnedPlr then
                tgt_updateSelection(returnedPlr)
            end
        end)
    end
    tgt_buildList()
end)

Players.PlayerRemoving:Connect(function(plr)
    if TargetPlayer == plr then
        SendNotification("Eternity", " Target " .. plr.DisplayName .. " left the game! Waiting for them to return...", 5)
        PendingTargetId = plr.UserId
        TargetPlayer = nil
        tgt_selUser.Text = "@"..plr.Name .. " (Left the game)"
        tgt_selUser.TextColor3 = C.danger
        if workspace.CurrentCamera.CameraSubject ~= humanoid then
            workspace.CurrentCamera.CameraSubject = humanoid
        end
    end
    tgt_buildList()
end)

end -- end of Target Page UI block

-- 
-- PAGE: VISUAL
-- 
visualPage = createPage("visual")


createSection(visualPage, "Visual Enhancements", 1)

-- ESP
createToggle(visualPage, "ESP", "See players through walls with name + distance", "ESP", 2, function(on)
    if on then
        task.spawn(function()
            while FeatureStates.ESP do
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local head = player.Character:FindFirstChild("Head")
                        if head then
                            local existing = head:FindFirstChild("EternityESP")
                            if not existing then
                                local bb = Instance.new("BillboardGui", head)
                                bb.Name = "EternityESP"
                                bb.Size = UDim2.new(0, 120, 0, 40)
                                bb.StudsOffset = Vector3.new(0, 3, 0)
                                bb.AlwaysOnTop = true

                                local nameLabel = Instance.new("TextLabel", bb)
                                nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
                                nameLabel.BackgroundTransparency = 1
                                nameLabel.Text = player.DisplayName
                                nameLabel.TextColor3 = C.accent
                                nameLabel.Font = Enum.Font.GothamBold
                                nameLabel.TextSize = 13
                                nameLabel.TextStrokeTransparency = 0.5

                                local distLabel = Instance.new("TextLabel", bb)
                                distLabel.Name = "Dist"
                                distLabel.Size = UDim2.new(1, 0, 0.5, 0)
                                distLabel.Position = UDim2.new(0, 0, 0.5, 0)
                                distLabel.BackgroundTransparency = 1
                                distLabel.TextColor3 = C.textMuted
                                distLabel.Font = Enum.Font.Gotham
                                distLabel.TextSize = 11
                                distLabel.TextStrokeTransparency = 0.7
                            end

                            -- update distance
                            local espGui = head:FindFirstChild("EternityESP")
                            if espGui and rootPart then
                                local dist = math.floor((head.Position - rootPart.Position).Magnitude)
                                local distLbl = espGui:FindFirstChild("Dist")
                                if distLbl then
                                    distLbl.Text = "[" .. dist .. " studs]"
                                end
                            end
                        end
                    end
                end
                task.wait(0.5)
            end

            -- cleanup
            for _, player in pairs(Players:GetPlayers()) do
                pcall(function()
                    local head = player.Character and player.Character:FindFirstChild("Head")
                    if head then
                        local esp = head:FindFirstChild("EternityESP")
                        if esp then esp:Destroy() end
                    end
                end)
            end
        end)
    end
end)

local graphicsInstances = {}

createToggle(visualPage, "Enhance Graphics", "High fidelity lighting, shadows, and bloom", "EnhanceGraphics", 3, function(on)
    if on then
        pcall(function()
            Lighting.GlobalShadows = true
            Lighting.Ambient = Color3.fromRGB(30, 30, 30)
            Lighting.Brightness = 1.2
            Lighting.EnvironmentDiffuseScale = 1
            Lighting.EnvironmentSpecularScale = 1
            
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Brightness = 0
            cc.Contrast = 0.1
            cc.Saturation = 0.15
            cc.Parent = Lighting
            table.insert(graphicsInstances, cc)
            
            local bloom = Instance.new("BloomEffect")
            bloom.Intensity = 0.2
            bloom.Size = 24
            bloom.Threshold = 0.8
            bloom.Parent = Lighting
            table.insert(graphicsInstances, bloom)

            local sun = Instance.new("SunRaysEffect")
            sun.Intensity = 0.05
            sun.Spread = 0.1
            sun.Parent = Lighting
            table.insert(graphicsInstances, sun)
        end)
    else
        pcall(function()
            Lighting.Ambient = OriginalAmbient
            Lighting.Brightness = OriginalBrightness
            Lighting.EnvironmentDiffuseScale = OriginalDiffuse
            Lighting.EnvironmentSpecularScale = OriginalSpecular
            Lighting.GlobalShadows = OriginalShadows
            
            for _, inst in ipairs(graphicsInstances) do
                if inst and inst.Parent then inst:Destroy() end
            end
            table.clear(graphicsInstances)
        end)
    end
end)

--  SHADES 
createSection(visualPage, "Shades", 5)



ShaderCache = {}

function applyShade(url, shadeName)
    task.spawn(function()
        -- 1. Get and run reset first
        if not ShaderCache["reset"] then
            pcall(function()
                ShaderCache["reset"] = loadstring(game:HttpGet("https://raw.githubusercontent.com/hor1zencodes/Shaders/main/reset.lua"))
            end)
        end
        if ShaderCache["reset"] then
            pcall(ShaderCache["reset"])
        end
        
        -- 2. If it's a reset action, we stop here
        if not url then
            SendNotification("Eternity", "Shaders reset to default!", 2)
            return
        end
        
        -- 3. Get and run new shade
        if not ShaderCache[url] then
            pcall(function()
                ShaderCache[url] = loadstring(game:HttpGet(url))
            end)
        end
        if ShaderCache[url] then
            pcall(ShaderCache[url])
            SendNotification("Eternity", shadeName .. " shader applied!", 2)
        end
    end)
end

function resetShades()
    applyShade(nil, "Reset")
end

do
    local shadeList = {
        {name = "Pink", file = "pink.lua", id = "122829837678898"},
        {name = "Space", file = "space.lua", id = "106984686196579"},
        {name = "Anime", file = "anime.lua", id = "105751183389195"},
        {name = "Aurora", file = "aurora.lua", id = "123452484757326"},
        {name = "Night Sky", file = "night_sky.lua", id = "79768435657163"},
        {name = "Aesthetic", file = "aesthetic.lua", id = "84943553385685"},
        {name = "Red Cosmos", file = "red_cosmos.lua", id = "89049198136773"},
        {name = "Cyan Space", file = "cyan_space.lua", id = "80067831833674"}
    }

    local shadeGridFrame = Instance.new("Frame", visualPage)
    shadeGridFrame.Size = UDim2.new(1, -8, 0, 160)
    shadeGridFrame.BackgroundColor3 = C.surface
    shadeGridFrame.BorderSizePixel = 0
    shadeGridFrame.LayoutOrder = 6
    corner(shadeGridFrame, 10)

    local shadeGridLayout = Instance.new("UIGridLayout", shadeGridFrame)
    shadeGridLayout.CellSize = UDim2.new(0.24, -2, 0, 68)
    shadeGridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
    shadeGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    shadeGridLayout.FillDirection = Enum.FillDirection.Horizontal
    shadeGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    padding(shadeGridFrame, 8, 8, 8, 8)

    local shadeSelectedIndicators = {}
    local activeShadeName = "Reset"

    for i, info in ipairs(shadeList) do
        local cell = Instance.new("Frame", shadeGridFrame)
        cell.Name = info.name
        cell.BackgroundColor3 = C.surfaceHover
        cell.BorderSizePixel = 0
        cell.LayoutOrder = i
        corner(cell, 8)

        local swatch = Instance.new("ImageLabel", cell)
        swatch.Size = UDim2.new(1, -8, 0, 32)
        swatch.Position = UDim2.new(0, 4, 0, 4)
        swatch.Image = "rbxassetid://" .. info.id
        swatch.ScaleType = Enum.ScaleType.Crop
        swatch.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        swatch.BorderSizePixel = 0
        corner(swatch, 6)

        local ring = Instance.new("UIStroke", swatch)
        ring.Thickness = 2
        ring.Color = C.accent
        ring.Transparency = 1
        shadeSelectedIndicators[i] = ring

        local lbl = Instance.new("TextLabel", cell)
        lbl.Size = UDim2.new(1, -4, 0, 18)
        lbl.Position = UDim2.new(0, 2, 1, -22)
        lbl.BackgroundTransparency = 1
        lbl.Text = info.name
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 9
        lbl.TextColor3 = C.text
        lbl.TextTruncate = Enum.TextTruncate.AtEnd

        local btn = Instance.new("TextButton", cell)
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = 5

        btn.MouseEnter:Connect(function()
            tween(cell, {BackgroundColor3 = C.input}, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            tween(cell, {BackgroundColor3 = C.surfaceHover}, 0.15)
        end)

        btn.MouseButton1Click:Connect(function()
            playClick()
            if activeShadeName == info.name then
                activeShadeName = "Reset"
                for j, r in ipairs(shadeSelectedIndicators) do
                    tween(r, {Transparency = 1}, 0.2)
                end
                resetShades()
            else
                activeShadeName = info.name
                for j, r in ipairs(shadeSelectedIndicators) do
                    tween(r, {Transparency = (j == i) and 0 or 1}, 0.2)
                end
                applyShade("https://raw.githubusercontent.com/hor1zencodes/Shaders/main/" .. info.file, info.name)
            end
        end)
    end
end

createActionButton(visualPage, "Reset Shaders", "Restore default game lighting", 7, function()
    for _, child in ipairs(visualPage:GetDescendants()) do
        if child:IsA("UIStroke") and child.Parent and child.Parent:IsA("ImageLabel") then
            tween(child, {Transparency = 1}, 0.2)
        end
    end
    resetShades()
    SendNotification("Eternity", "Shaders reset to default!", 2)
end)

-- 
chatPage = createPage("chat")

createSection(chatPage, "NORMAL CHAT SPAM", 0)

local chatMsgBox = createInputField(chatPage, "MESSAGE", "Enter your message...", "", 1)
local chatDelayBox = createInputField(chatPage, "DELAY (seconds)", "0.5", "1.0", 2)


-- start/stop buttons
local chatStartFrame = Instance.new("Frame", chatPage)
chatStartFrame.Size = UDim2.new(1, -8, 0, 42)
chatStartFrame.BackgroundColor3 = C.accentDim
chatStartFrame.BorderSizePixel = 0
chatStartFrame.LayoutOrder = 4
corner(chatStartFrame, 10)

local chatStartBtn = Instance.new("TextButton", chatStartFrame)
chatStartBtn.Size = UDim2.new(1, 0, 1, 0)
chatStartBtn.Text = "START SPAM"
chatStartBtn.Font = Enum.Font.GothamBold
chatStartBtn.TextSize = 13
chatStartBtn.TextColor3 = C.bg
chatStartBtn.BackgroundTransparency = 1
chatStartBtn.AutoButtonColor = false

chatStartFrame.MouseEnter:Connect(function()
    tween(chatStartFrame, {BackgroundColor3 = C.accent}, 0.2)
end)
chatStartFrame.MouseLeave:Connect(function()
    if not FeatureStates.ChatSpamActive then
        tween(chatStartFrame, {BackgroundColor3 = C.accentDim}, 0.2)
    end
end)

local chatStopFrame = Instance.new("Frame", chatPage)
chatStopFrame.Size = UDim2.new(1, -8, 0, 42)
chatStopFrame.BackgroundColor3 = C.dangerDim
chatStopFrame.BorderSizePixel = 0
chatStopFrame.LayoutOrder = 5
corner(chatStopFrame, 10)

local chatStopBtn = Instance.new("TextButton", chatStopFrame)
chatStopBtn.Size = UDim2.new(1, 0, 1, 0)
chatStopBtn.Text = "STOP SPAM"
chatStopBtn.Font = Enum.Font.GothamBold
chatStopBtn.TextSize = 13
chatStopBtn.TextColor3 = C.bg
chatStopBtn.BackgroundTransparency = 1
chatStopBtn.AutoButtonColor = false

chatStopFrame.MouseEnter:Connect(function()
    tween(chatStopFrame, {BackgroundColor3 = C.danger}, 0.2)
end)
chatStopFrame.MouseLeave:Connect(function()
    tween(chatStopFrame, {BackgroundColor3 = C.dangerDim}, 0.2)
end)

-- chat status
local chatStatusLabel = Instance.new("TextLabel", chatPage)
chatStatusLabel.Size = UDim2.new(1, -8, 0, 20)
chatStatusLabel.BackgroundTransparency = 1
chatStatusLabel.Text = "Status: IDLE"
chatStatusLabel.Font = Enum.Font.Gotham
chatStatusLabel.TextSize = 10
chatStatusLabel.TextColor3 = C.textMuted
chatStatusLabel.LayoutOrder = 6

chatStartBtn.MouseButton1Click:Connect(function()
    if FeatureStates.ChatSpamActive then return end
    local msg = chatMsgBox.Text
    if msg == "" then
        chatStatusLabel.Text = "Status: Enter a message first!"
        chatStatusLabel.TextColor3 = C.danger
        return
    end
    local delay = tonumber(chatDelayBox.Text) or 1.0
    if delay < 0.2 then delay = 0.2 end
    FeatureStates.ChatSpamActive = true
    chatStatusLabel.Text = "Status: SPAMMING  " .. delay .. "s interval"
    chatStatusLabel.TextColor3 = C.accent
    tween(chatStartFrame, {BackgroundColor3 = C.toggleOff}, 0.2)
    chatStartBtn.Text = "ACTIVE..."

    task.spawn(function()
        while FeatureStates.ChatSpamActive do
            sendChat(msg)
            task.wait(delay)
        end
    end)
end)

chatStopBtn.MouseButton1Click:Connect(function()
    FeatureStates.ChatSpamActive = false
    chatStatusLabel.Text = "Status: IDLE"
    chatStatusLabel.TextColor3 = C.textMuted
    chatStartBtn.Text = "START SPAM"
    tween(chatStartFrame, {BackgroundColor3 = C.accentDim}, 0.2)
end)

task.spawn(function()
createSection(chatPage, "DEMONKING TYPE CHAT SPAM", 7)

local dkTargetBox = createInputField(chatPage, "TARGET NAME", "Target Name...", "", 8)
local dkDelayBox = createInputField(chatPage, "DELAY (seconds)", "3.0", "3.0", 9)
local dkStyleBox = createInputField(chatPage, "SYMBOL STYLE", "Symbol Style (e.g. @)", "@", 10)

local dkStartFrame = Instance.new("Frame", chatPage)
dkStartFrame.Size = UDim2.new(1, -8, 0, 42)
dkStartFrame.BackgroundColor3 = C.accentDim
dkStartFrame.BorderSizePixel = 0
dkStartFrame.LayoutOrder = 11
corner(dkStartFrame, 10)

local dkStartBtn = Instance.new("TextButton", dkStartFrame)
dkStartBtn.Size = UDim2.new(1, 0, 1, 0)
dkStartBtn.Text = "START SPAM"
dkStartBtn.Font = Enum.Font.GothamBold
dkStartBtn.TextSize = 13
dkStartBtn.TextColor3 = C.bg
dkStartBtn.BackgroundTransparency = 1
dkStartBtn.AutoButtonColor = false

dkStartFrame.MouseEnter:Connect(function()
    tween(dkStartFrame, {BackgroundColor3 = C.accent}, 0.2)
end)

local isDKSpamming = false
dkStartFrame.MouseLeave:Connect(function()
    if not isDKSpamming then
        tween(dkStartFrame, {BackgroundColor3 = C.accentDim}, 0.2)
    end
end)

local dkStopFrame = Instance.new("Frame", chatPage)
dkStopFrame.Size = UDim2.new(1, -8, 0, 42)
dkStopFrame.BackgroundColor3 = C.dangerDim
dkStopFrame.BorderSizePixel = 0
dkStopFrame.LayoutOrder = 12
corner(dkStopFrame, 10)

local dkStopBtn = Instance.new("TextButton", dkStopFrame)
dkStopBtn.Size = UDim2.new(1, 0, 1, 0)
dkStopBtn.Text = "STOP SPAM"
dkStopBtn.Font = Enum.Font.GothamBold
dkStopBtn.TextSize = 13
dkStopBtn.TextColor3 = C.bg
dkStopBtn.BackgroundTransparency = 1
dkStopBtn.AutoButtonColor = false

dkStopFrame.MouseEnter:Connect(function()
    tween(dkStopFrame, {BackgroundColor3 = C.danger}, 0.2)
end)
dkStopFrame.MouseLeave:Connect(function()
    tween(dkStopFrame, {BackgroundColor3 = C.dangerDim}, 0.2)
end)

local dkStatusLabel = Instance.new("TextLabel", chatPage)
dkStatusLabel.Size = UDim2.new(1, -8, 0, 20)
dkStatusLabel.BackgroundTransparency = 1
dkStatusLabel.Text = "Status: IDLE"
dkStatusLabel.Font = Enum.Font.Gotham
dkStatusLabel.TextSize = 10
dkStatusLabel.TextColor3 = C.textMuted
dkStatusLabel.LayoutOrder = 13

local rawLines = {
    "[REACT] ", "[DRAGON] ", "[RELATIONSHIP] ", "[HULK] ", "[GAS] ", "[CAT] ", "[GODZILLA] ", 
    "[VENOM] ", "[HALWA] ", "[SIGMA] ", "[VOID] ", "[HAGGYS] ", "[NEW SMITH] ", "[DOOR] ", 
    "[BEAST] ", "[SEA] ", "[RAINBOW] ", "[SHIP] ", "[HUG] ", "[CHAIR] ", "[PARLE G] ", 
    "[ALPHA] ", "[CHAOS] ", "[BUILDING] ", "[CHAPPAL] ", "[JUTA] ", "[BELAN] ", "[KURKURE] ", 
    "[SAMOSA] ", "[MIRCHI] ", "[KELA] ", "[BIRYANI] ", "[EGO] ", "[KACHRA] ", "[BRICK] ",
    "[CHAPPAL] ", "[JUTA] ", "[BELAN] ", "[JHARU] ", "[PARLE G] ", "[KURKURE] ", "[SAMOSA] ", "[MIRCHI] ", "[KELA] ", "[PATILA] ",
    "[BIRYANI] ", "[DANDA] ", "[EGO] ", "[KACHRA] ", "[BRICK] ", "[BOTTLE] ", "[KEYBOARD] ", "[MOUSE] ", "[TAAR] ", "[GUBBARA] ",
    "[PETROL] ", "[CAKE] ", "[BISCUIT] ", "[FAN] ", "[GLITCH] ", "[CHAI] ", "[ALOO] ", "[PYAAZ] ", "[CHAKU] ", "[JALWA] ",
    "[TV] ", "[FRIDGE] ", "[WASHING MACHINE] ", "[AC] ", "[PANKHA] ", "[TIRE] ", "[TRUCK] ", "[CAR] ", "[BIKE] ", "[SCOOTY] ",
    "[LAPTOP] ", "[PC] ", "[WIFI] ", "[ROUTER] ", "[HEADPHONE] ", "[SPEAKER] ", "[MIC] ", "[CAMERA] ", "[PHONE] ", "[CHARGER] ",
    "[BED] ", "[SOFA] ", "[TABLE] ", "[CUPBOARD] ", "[MIRROR] ", "[WINDOW] ", "[WALL] ", "[ROOF] ", "[FLOOR] ", "[CEILING] ",
    "[PLATE] ", "[SPOON] ", "[FORK] ", "[KNIFE] ", "[BOWL] ", "[CUP] ", "[GLASS] ", "[JUG] ", "[TRAY] ", "[BOX] ",
    "[BAG] ", "[POCKET] ", "[SHOES] ", "[SOCKS] ", "[SHIRT] ", "[PANTS] ", "[JACKET] ", "[HAT] ", "[GLASSES] ", "[WATCH] ",
    "[SUN] ", "[MOON] ", "[STAR] ", "[CLOUD] ", "[RAIN] ", "[SNOW] ", "[WIND] ", "[FIRE] ", "[ICE] ", "[WATER] ",
    "[TREE] ", "[FLOWER] ", "[GRASS] ", "[ROCK] ", "[DIRT] ", "[SAND] ", "[MUD] ", "[DUST] ", "[ASH] ", "[SMOKE] ",
    "[DOG] ", "[BIRD] ", "[FISH] ", "[BUG] ", "[ANT] ", "[SPIDER] ", "[SNAKE] ", "[FROG] ", "[RAT] ", "[MOUSE] ",
    "[TRAIN] ", "[PLANE] ", "[BOAT] ", "[ROCKET] ", "[UFO] ", "[ALIEN] ", "[GHOST] ", "[ZOMBIE] ", "[VAMPIRE] ", "[MONSTER] ",
    "[ROBOT] ", "[CYBORG] ", "[NINJA] ", "[PIRATE] ", "[KNIGHT] ", "[WIZARD] ", "[WITCH] ", "[FAIRY] ", "[ELF] ", "[TROLL] "
}

dkStartBtn.MouseButton1Click:Connect(function()
    if isDKSpamming then return end
    
    local target = dkTargetBox.Text ~= "" and dkTargetBox.Text or "PLAYER"
    local delay = tonumber(dkDelayBox.Text) or 3.0
    if delay < 0.2 then delay = 0.2 end
    local sym = dkStyleBox.Text ~= "" and dkStyleBox.Text or "@"
    
    isDKSpamming = true
    dkStatusLabel.Text = "Status: SPAMMING  " .. delay .. "s interval"
    dkStatusLabel.TextColor3 = C.accent
    tween(dkStartFrame, {BackgroundColor3 = C.toggleOff}, 0.2)
    dkStartBtn.Text = "ACTIVE..."

    task.spawn(function()
        if isDKSpamming then
            local playerName = game.Players.LocalPlayer.DisplayName or game.Players.LocalPlayer.Name
            local symLine = string.rep(sym, 145)
            sendChat(symLine .. "\n" .. playerName .. " On Top >")
            task.wait(delay)
        end
        while isDKSpamming do
            for _, word in ipairs(rawLines) do
                if not isDKSpamming then break end
                
                local symLine = string.rep(sym, 145) 
                

                local finalMsg = symLine .. "\n" .. target .. " TMKX MEH " .. word .. " >"
                
                sendChat(finalMsg)
                task.wait(delay)
            end
        end
    end)
end)

dkStopBtn.MouseButton1Click:Connect(function()
    isDKSpamming = false
    dkStatusLabel.Text = "Status: IDLE"
    dkStatusLabel.TextColor3 = C.textMuted
    dkStartBtn.Text = "START SPAM"
    tween(dkStartFrame, {BackgroundColor3 = C.accentDim}, 0.2)
end)
end)

-- 
-- PAGE: VC BYPASS
-- 
local vcbypassPage = createPage("vcbypass")

createSection(vcbypassPage, "Voice Chat Bypass", 0)

-- VC bypass status card
local vcStatusCard = Instance.new("Frame", vcbypassPage)
vcStatusCard.Size = UDim2.new(1, -8, 0, 70)
vcStatusCard.BackgroundColor3 = C.surface
vcStatusCard.BorderSizePixel = 0
vcStatusCard.LayoutOrder = 1
corner(vcStatusCard, 10)

local vcStatusIcon = Instance.new("ImageLabel", vcStatusCard)
vcStatusIcon.Size = UDim2.new(0, 30, 0, 30)
vcStatusIcon.Position = UDim2.new(0, 14, 0.5, -15)
vcStatusIcon.Image = getAssetUrl("speakermute.png")
vcStatusIcon.BackgroundTransparency = 1

local vcStatusTitle = Instance.new("TextLabel", vcStatusCard)
vcStatusTitle.Size = UDim2.new(1, -60, 0, 18)
vcStatusTitle.Position = UDim2.new(0, 52, 0, 12)
vcStatusTitle.Text = "Status: Not Active"
vcStatusTitle.Font = Enum.Font.GothamBold
vcStatusTitle.TextSize = 12
vcStatusTitle.TextColor3 = C.textMuted
vcStatusTitle.TextXAlignment = Enum.TextXAlignment.Left
vcStatusTitle.BackgroundTransparency = 1

local vcStatusDesc = Instance.new("TextLabel", vcStatusCard)
vcStatusDesc.Size = UDim2.new(1, -60, 0, 28)
vcStatusDesc.Position = UDim2.new(0, 52, 0, 32)
vcStatusDesc.Text = "Bypass voice chat restrictions to use VC in any game."
vcStatusDesc.Font = Enum.Font.Gotham
vcStatusDesc.TextSize = 10
vcStatusDesc.TextColor3 = C.textMuted
vcStatusDesc.TextXAlignment = Enum.TextXAlignment.Left
vcStatusDesc.TextWrapped = true
vcStatusDesc.BackgroundTransparency = 1

createSection(vcbypassPage, "Instructions", 2)

-- Instructions card
local vcInstructionsCard = Instance.new("Frame", vcbypassPage)
vcInstructionsCard.Size = UDim2.new(1, -8, 0, 82)
vcInstructionsCard.BackgroundColor3 = C.surface
vcInstructionsCard.BorderSizePixel = 0
vcInstructionsCard.LayoutOrder = 3
corner(vcInstructionsCard, 10)

local vcInstructions = {
    {y = 10, text = "1.  Click 'Activate VC Bypass' below"},
    {y = 26, text = "2.  Unmute your microphone when prompted"},
    {y = 42, text = "3.  Wait for the bypass to complete (~6s)"},
    {y = 58, text = "4.  Use the mic button normally after"},
}
for _, info in ipairs(vcInstructions) do
    local lbl = Instance.new("TextLabel", vcInstructionsCard)
    lbl.Size = UDim2.new(1, -28, 0, 14)
    lbl.Position = UDim2.new(0, 14, 0, info.y)
    lbl.Text = info.text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 10
    lbl.TextColor3 = C.textMuted
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
end

createSection(vcbypassPage, "Actions", 4)

-- Activate VC Bypass button
local vcActivateFrame = Instance.new("Frame", vcbypassPage)
vcActivateFrame.Size = UDim2.new(1, -8, 0, 46)
vcActivateFrame.BackgroundColor3 = C.accentDim
vcActivateFrame.BorderSizePixel = 0
vcActivateFrame.LayoutOrder = 5
corner(vcActivateFrame, 10)

local vcActivateBtn = Instance.new("TextButton", vcActivateFrame)
vcActivateBtn.Size = UDim2.new(1, 0, 1, 0)
vcActivateBtn.Text = "ACTIVATE VC BYPASS"
vcActivateBtn.Font = Enum.Font.GothamBold
vcActivateBtn.TextSize = 13
vcActivateBtn.TextColor3 = C.bg
vcActivateBtn.BackgroundTransparency = 1
vcActivateBtn.AutoButtonColor = false

vcActivateFrame.MouseEnter:Connect(function()
    tween(vcActivateFrame, {BackgroundColor3 = C.accent}, 0.2)
end)
vcActivateFrame.MouseLeave:Connect(function()
    if not FeatureStates.VCBypassActive then
        tween(vcActivateFrame, {BackgroundColor3 = C.accentDim}, 0.2)
    end
end)

-- VC Bypass progress label
local vcProgressLabel = Instance.new("TextLabel", vcbypassPage)
vcProgressLabel.Size = UDim2.new(1, -8, 0, 20)
vcProgressLabel.BackgroundTransparency = 1
vcProgressLabel.Text = ""
vcProgressLabel.Font = Enum.Font.Gotham
vcProgressLabel.TextSize = 10
vcProgressLabel.TextColor3 = C.textMuted
vcProgressLabel.LayoutOrder = 6

-- The actual VC Bypass logic
vcActivateBtn.MouseButton1Click:Connect(function()
    if FeatureStates.VCBypassActive then
        SendNotification("Eternity", "VC Bypass is already active!", 2)
        return
    end

    -- Disable button
    vcActivateBtn.Text = "ACTIVATING..."
    tween(vcActivateFrame, {BackgroundColor3 = C.toggleOff}, 0.2)

    task.spawn(function()
        local ok, err = pcall(function()
            local clonereference = cloneref or function(...) return ... end
            local clonefunc = clonefunction or function(...) return ... end

            local voicechatservice = clonereference(game:GetService("VoiceChatService"))
            local voicechatinternal = clonereference(game:GetService("VoiceChatInternal"))
            local coregui = game:GetService("CoreGui")
            local getconnectionsfunc = clonefunc(getconnections)

            local mutedimage = "rbxasset://textures/ui/VoiceChat/MicLight/Muted.png"
            local ismuted = true
            local hiddenfolder = Instance.new("Folder", game:GetService("RobloxReplicatedStorage"))

            -- Step 1: Find the mic button in TopBar
            vcProgressLabel.Text = "Step 1/5: Locating mic button..."
            vcProgressLabel.TextColor3 = C.accent

            local topbarapp = coregui:WaitForChild("TopBarApp", 15)
            if topbarapp then topbarapp = topbarapp:WaitForChild("TopBarApp", 15) end
            if not topbarapp then error("TopBarApp not found") end

            local unibarleft = topbarapp:WaitForChild("UnibarLeftFrame", 15)
            local unibarmenu = unibarleft:WaitForChild("UnibarMenu", 15) or unibarleft:WaitForChild("ChromeMenu", 15)
            local unibarcontainer
            local micmutebutton
            
            -- Try to recursively find the mic button (bypasses A/B testing path differences)
            for _ = 1, 30 do
                micmutebutton = unibarmenu:FindFirstChild("toggle_mic_mute", true)
                if micmutebutton then
                    unibarcontainer = micmutebutton.Parent
                    break
                end
                task.wait(0.5)
            end

            local function geticonlabel(button)
                button = button or micmutebutton
                if not button then return nil end
                local intIcon = button:FindFirstChild("IntegrationIcon", true)
                if intIcon then
                    return intIcon:FindFirstChild("1") or intIcon:FindFirstChildWhichIsA("ImageLabel")
                end
                return button:FindFirstChildWhichIsA("ImageLabel", true)
            end

            local function setmutestate(state)
                pcall(function() voicechatinternal:PublishPause(state) end)
                local audiodereviceinput = lp:FindFirstChildWhichIsA("AudioDeviceInput", true)
                if audiodereviceinput then
                    pcall(function() audiodereviceinput.Muted = state end)
                end
            end

            if not micmutebutton then
                voicechatservice:joinVoice()
                for _ = 1, 20 do
                    micmutebutton = unibarmenu:FindFirstChild("toggle_mic_mute", true)
                    if micmutebutton then
                        unibarcontainer = micmutebutton.Parent
                        break
                    end
                    task.wait(0.5)
                end
            end

            if not micmutebutton then
                error("Mic button not found  UI path may have changed or voice chat is disabled.")
            end

            -- Step 2: Wait for unmute
            vcProgressLabel.Text = "Step 2/5: Unmute your mic to continue..."
            vcStatusTitle.Text = "Status: Waiting for unmute..."
            vcStatusTitle.TextColor3 = C.warning
            vcStatusIcon.Image = getAssetUrl("speakerunmute.png")
            SendNotification("Eternity", "Unmute your microphone to continue!", 5)

            local icon
            repeat 
                task.wait(2) 
                icon = geticonlabel()
            until icon and icon.Image ~= mutedimage

            -- Step 3: Leave voice
            vcProgressLabel.Text = "Step 3/5: Leaving voice channel..."
            voicechatservice:leaveVoice()
            task.wait(2)

            -- Step 4: Disable connections & rejoin
            vcProgressLabel.Text = "Step 4/5: Disabling state handlers..."
            local connections = getconnectionsfunc(voicechatinternal.StateChanged)
            for i = 7, #connections do
                if connections[i] then connections[i]:Disable() end
            end

            task.wait(2)
            vcProgressLabel.Text = "Step 5/5: Rejoining voice..."
            voicechatservice:joinVoice()

            pcall(function()
                unibarcontainer = unibarmenu:WaitForChild("2", 15):WaitForChild("3", 15)
                micmutebutton = unibarcontainer:WaitForChild("toggle_mic_mute", 15)
            end)

            -- Step 5: Clone mic button
            if micmutebutton and unibarcontainer then
                local clonedmutebutton = micmutebutton:Clone()
                micmutebutton.Parent = hiddenfolder
                clonedmutebutton.Name = "toggle_mic_mute_new"
                clonedmutebutton.Parent = unibarcontainer

                local clonedicon = geticonlabel(clonedmutebutton)
                local originalicon = geticonlabel(micmutebutton)

                setmutestate(true)
                clonedmutebutton:WaitForChild("IconHitArea_toggle_mic_mute", 15).Activated:Connect(function()
                    ismuted = not ismuted
                    setmutestate(ismuted)
                    if ismuted then
                        clonedicon.Image = mutedimage
                    else
                        clonedicon.Image = originalicon.Image
                    end
                end)
            end

            FeatureStates.VCBypassActive = true
        end)

        if ok then
            vcProgressLabel.Text = " VC Bypass active! Use the mic button normally."
            vcProgressLabel.TextColor3 = C.success
            vcStatusTitle.Text = "Status: Active "
            vcStatusTitle.TextColor3 = C.success
            vcStatusIcon.Image = getAssetUrl("mic.png")
            vcActivateBtn.Text = "VC BYPASS ACTIVE"
            tween(vcActivateFrame, {BackgroundColor3 = C.success}, 0.3)
            SendNotification("Eternity", "VC Bypass activated successfully!", 3)
        else
            vcProgressLabel.Text = " Error: " .. tostring(err)
            vcProgressLabel.TextColor3 = C.danger
            vcStatusTitle.Text = "Status: Failed"
            vcStatusTitle.TextColor3 = C.danger
            vcStatusIcon.Image = getAssetUrl("speakermute.png")
            vcActivateBtn.Text = "RETRY VC BYPASS"
            tween(vcActivateFrame, {BackgroundColor3 = C.dangerDim}, 0.3)
            task.wait(2)
            tween(vcActivateFrame, {BackgroundColor3 = C.accentDim}, 0.3)
            SendNotification("Eternity", "VC Bypass failed: " .. tostring(err), 4)
        end
    end)
end)

createSection(vcbypassPage, "ETERNITY METHOD", 7)

local vcAltActivateFrame = Instance.new("Frame", vcbypassPage)
vcAltActivateFrame.Size = UDim2.new(1, -8, 0, 46)
vcAltActivateFrame.BackgroundColor3 = C.accentDim
vcAltActivateFrame.BorderSizePixel = 0
vcAltActivateFrame.LayoutOrder = 8
corner(vcAltActivateFrame, 10)

local vcAltActivateBtn = Instance.new("TextButton", vcAltActivateFrame)
vcAltActivateBtn.Size = UDim2.new(1, 0, 1, 0)
vcAltActivateBtn.Text = "ETERNITY METHOD (Recommended)"
vcAltActivateBtn.Font = Enum.Font.GothamBold
vcAltActivateBtn.TextSize = 13
vcAltActivateBtn.TextColor3 = C.bg
vcAltActivateBtn.BackgroundTransparency = 1
vcAltActivateBtn.AutoButtonColor = false

vcAltActivateFrame.MouseEnter:Connect(function()
    tween(vcAltActivateFrame, {BackgroundColor3 = C.accent}, 0.2)
end)
vcAltActivateFrame.MouseLeave:Connect(function()
    tween(vcAltActivateFrame, {BackgroundColor3 = C.accentDim}, 0.2)
end)

vcAltActivateBtn.MouseButton1Click:Connect(function()
    task.spawn(function()
        local ok, err = pcall(function()
            local clonereference = cloneref or function(...) return ... end
            local clonefunc = clonefunction or function(...) return ... end
            
            local voicechatservice = clonereference(game:GetService("VoiceChatService"))
            local voicechatinternal = clonereference(game:GetService("VoiceChatInternal"))
            local coregui = game:GetService("CoreGui")
            local getconnectionsfunc = clonefunc(getconnections)

            if not getconnectionsfunc then
                error("Your executor does not support getconnections()")
            end

            local mutedimage = "rbxasset://textures/ui/VoiceChat/MicLight/Muted.png"
            local ismuted = true

            local topbarapp = coregui:WaitForChild("TopBarApp", 15)
            if topbarapp then topbarapp = topbarapp:WaitForChild("TopBarApp", 15) end
            
            local unibarleft = topbarapp:WaitForChild("UnibarLeftFrame", 15)
            local unibarmenu = unibarleft:WaitForChild("UnibarMenu", 15) or unibarleft:WaitForChild("ChromeMenu", 15)
            local micmutebutton
            
            for _ = 1, 30 do
                micmutebutton = unibarmenu:FindFirstChild("toggle_mic_mute", true)
                if micmutebutton then break end
                task.wait(0.5)
            end

            if not micmutebutton then
                error("Could not find toggle_mic_mute button in CoreGui")
            end

            
            local function geticonlabel()
                local intIcon = micmutebutton:FindFirstChild("IntegrationIcon", true)
                if intIcon then
                    return intIcon:FindFirstChild("1") or intIcon:FindFirstChildWhichIsA("ImageLabel")
                end
                return micmutebutton:FindFirstChildWhichIsA("ImageLabel", true)
            end

            local function setmutestate(state)
                pcall(function() voicechatinternal:PublishPause(state) end)
                local audiodereviceinput = lp:FindFirstChildWhichIsA("AudioDeviceInput", true)
                if audiodereviceinput then
                    pcall(function() audiodereviceinput.Muted = state end)
                end
            end

            SendNotification("Eternity", "Wait for unmute... Please unmute mic.", 5)
            local icon
            repeat 
                task.wait(2) 
                icon = geticonlabel()
            until icon and icon.Image ~= mutedimage

            local originalicon_image = icon.Image

            voicechatservice:leaveVoice()
            task.wait(2)

            local state_connections = getconnectionsfunc(voicechatinternal.StateChanged)
            if state_connections then
                for i = 7, #state_connections do
                    if state_connections[i] then state_connections[i]:Disable() end
                end
            end

            task.wait(2)
            voicechatservice:joinVoice()

            -- Re-fetch the button because the old one was destroyed during the rejoin!
            for _ = 1, 30 do
                micmutebutton = unibarmenu:FindFirstChild("toggle_mic_mute", true)
                if micmutebutton then break end
                task.wait(0.5)
            end

            if not micmutebutton then
                error("Could not find toggle_mic_mute button after rejoining")
            end

            local hitArea = micmutebutton:FindFirstChild("IconHitArea_toggle_mic_mute", true) or micmutebutton
            icon = geticonlabel() -- Re-fetch the new icon

            local count = 0
            for _, conn in ipairs(getconnectionsfunc(hitArea.Activated)) do
                conn:Disable()
                count = count + 1
            end
            for _, conn in ipairs(getconnectionsfunc(hitArea.MouseButton1Click)) do
                conn:Disable()
                count = count + 1
            end

            -- Create a custom pill-shaped toggle switch overlay
            local customMicBtn = Instance.new("TextButton")
            customMicBtn.Name = "EternityCustomMic"
            customMicBtn.Size = UDim2.new(0, 40, 0, 22)
            customMicBtn.AnchorPoint = Vector2.new(0.5, 0.5)
            customMicBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
            customMicBtn.BackgroundTransparency = 1
            customMicBtn.Text = ""
            customMicBtn.ZIndex = 100
            customMicBtn.Active = true -- Guarantee clicks register

            local track = Instance.new("Frame", customMicBtn)
            track.Size = UDim2.new(1, 0, 1, 0)
            track.BackgroundColor3 = C.accent -- Starts ON (unmuted)
            track.ZIndex = 100
            local uic = Instance.new("UICorner", track)
            uic.CornerRadius = UDim.new(1, 0)
            
            local knb = Instance.new("Frame", track)
            knb.Size = UDim2.new(0, 16, 0, 16)
            knb.Position = UDim2.new(1, -19, 0.5, -8) -- Starts ON (right side)
            knb.BackgroundColor3 = Color3.new(1, 1, 1)
            knb.ZIndex = 101
            local uic2 = Instance.new("UICorner", knb)
            uic2.CornerRadius = UDim.new(1, 0)

            if icon then
                customMicBtn.Parent = icon.Parent
                icon.ImageTransparency = 1
                icon:GetPropertyChangedSignal("ImageTransparency"):Connect(function()
                    icon.ImageTransparency = 1
                end)
            else
                customMicBtn.Parent = hitArea
            end

            -- Start unmuted (because user unmuted to begin bypass)
            local ismuted = false
            setmutestate(false)
            
            local isToggling = false
            local function toggleMic()
                if isToggling then return end
                isToggling = true
                
                ismuted = not ismuted
                setmutestate(ismuted)
                
                local d = 0.2
                if not ismuted then
                    -- Mic is ON
                    tween(track, {BackgroundColor3 = C.accent}, d)
                    tween(knb, {Position = UDim2.new(1, -19, 0.5, -8), BackgroundColor3 = Color3.new(1, 1, 1)}, d)
                else
                    -- Mic is OFF (Muted)
                    tween(track, {BackgroundColor3 = C.toggleOff}, d)
                    tween(knb, {Position = UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = Color3.fromRGB(140, 140, 140)}, d)
                end
                
                task.wait(0.1)
                isToggling = false
            end
            
            customMicBtn.MouseButton1Click:Connect(toggleMic)
            hitArea.MouseButton1Click:Connect(toggleMic)
            hitArea.Activated:Connect(toggleMic)

            if count > 0 then
                SendNotification("Eternity", "Successfully bypassed VC! (" .. count .. " handlers disabled)", 3)
            else
                SendNotification("Eternity", "Bypassed VC, but no UI handlers found to disable.", 3)
            end
        end)

        if not ok then
            SendNotification("Eternity", "Anti-VC Error: " .. tostring(err), 4)
            warn("Anti-VC Error:", err)
        end
    end)
end)

-- 
-- PAGE: ANIMATIONS
-- 
animPage = createPage("animations")


createSection(animPage, "Reanimations", 1)

do
    local hintCard = Instance.new("Frame", animPage)
    hintCard.Size = UDim2.new(1, -8, 0, 84)
    hintCard.BackgroundColor3 = C.surface
    hintCard.BorderSizePixel = 0
    hintCard.LayoutOrder = 2
    corner(hintCard, 10)

    local cl = Instance.new("UIListLayout", hintCard)
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    cl.Padding = UDim.new(0, 6)
    cl.VerticalAlignment = Enum.VerticalAlignment.Center

    local pad = Instance.new("UIPadding", hintCard)
    pad.PaddingLeft = UDim.new(0, 16)
    pad.PaddingRight = UDim.new(0, 16)

    local titleLbl = Instance.new("TextLabel", hintCard)
    titleLbl.Size = UDim2.new(1, 0, 0, 16)
    titleLbl.Text = "DIRECTION OF USE"
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 10
    titleLbl.TextColor3 = C.textMuted
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.BackgroundTransparency = 1
    titleLbl.LayoutOrder = 0

    local c1 = Instance.new("TextLabel", hintCard)
    c1.Size = UDim2.new(1, 0, 0, 36)
    c1.Text = "Do not use the enable/disable reanim buttons; it will automatically toggle when you select or deselect a reanimation. Please be patient as reanimations may take a moment to load (still in development)."
    c1.RichText = true
    c1.Font = Enum.Font.Gotham
    c1.TextSize = 11
    c1.TextColor3 = C.text
    c1.TextXAlignment = Enum.TextXAlignment.Left
    c1.TextYAlignment = Enum.TextYAlignment.Top
    c1.TextWrapped = true
    c1.BackgroundTransparency = 1
    c1.LayoutOrder = 1
    
    applyPremiumCardEffect(hintCard)
end

createActionButton(animPage, "Load Reanimations", "Loads the Reanimations script", 3, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/horizen-rblx/reanimsource/main/runner.lua"))()
end)

createSection(animPage, "Emotes", 10)
createActionButton(animPage, "Load Emote Wheel", "Loads the Emote Wheel script", 11, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hor1zencodes/EmoteWheel/main/zenemotewheel.lua"))()
end)

createSection(animPage, "Character Animations", 20)

local AnimDB = {
	["Idle"] = {
		["superhero aura"]                = {"116944673851292","105356446763414"},
		["Intimidating nonchalant"]       = {"107993486985036","123280570171478"},
		["moonwalker"]                    = {"130821503426609","107982740338300"},
		["Floating aura"]                 = {"133226513780673","86910986368891"},
		["non chalant"]                   = {"98485460652889","133778657817563"},
		["Theif"]                         = {"70765889938975","87903617826484"},
		["Furry"]                         = {"111821292044705","90705157329932"},
		["Gojo"]                          = {"91833267843461","126614275663887"},
		["Animal"]                        = {"99689776099970","128838183008466"},
		["2016 Animation (mm2)"]          = {"387947158","387947464"},
		["(UGC) Oh Really?"]              = {"98004748982532","98004748982532"},
		["Astronaut"]                     = {"891621366","891633237"},
		["Adidas Community"]              = {"122257458498464","102357151005774"},
        ["Adidas Aura"]                   = {"110211186840347","114191137265065"},
		["Bold"]                          = {"16738333868","16738334710"},
		["(UGC) Slasher"]                 = {"140051337061095","140051337061095"},
		["(UGC) Retro"]                   = {"80479383912838","80479383912838"},
		["(UGC) Magician"]                = {"139433213852503","139433213852503"},
		["(UGC) John Doe"]                = {"72526127498800","72526127498800"},
		["(UGC) Noli"]                    = {"139360856809483","139360856809483"},
		["(UGC) Coolkid"]                 = {"95203125292023","95203125292023"},
		["(UGC) Survivor Injured"]        = {"73905365652295","73905365652295"},
		["(UGC) Retro Zombie"]            = {"90806086002292","90806086002292"},
		["(UGC) 1x1x1x1"]                 = {"76780522821306","76780522821306"},
		["Borock"]                        = {"3293641938","3293642554"},
		["Bubbly"]                        = {"910004836","910009958"},
		["Cartoony"]                      = {"742637544","742638445"},
		["Confident"]                     = {"1069977950","1069987858"},
		["Catwalk Glam"]                  = {"133806214992291","94970088341563"},
		["Cowboy"]                        = {"1014390418","1014398616"},
		["Drooling Zombie"]               = {"3489171152","3489171152"},
		["Elder"]                         = {"10921101664","10921102574"},
		["Ghost"]                         = {"616006778","616008087"},
		["Knight"]                        = {"657595757","657568135"},
		["Levitation"]                    = {"616006778","616008087"},
		["Mage"]                          = {"707742142","707855907"},
		["MrToilet"]                      = {"4417977954","4417978624"},
		["Ninja"]                         = {"656117400","656118341"},
		["NFL"]                           = {"92080889861410","74451233229259"},
		["OldSchool"]                     = {"10921230744","10921232093"},
		["Patrol"]                        = {"1149612882","1150842221"},
		["Pirate"]                        = {"750781874","750782770"},
		["Default Retarget"]              = {"95884606664820","95884606664820"},
		["Very Long"]                     = {"18307781743","18307781743"},
		["Sway"]                          = {"560832030","560833564"},
		["Popstar"]                       = {"1212900985","1150842221"},
		["Princess"]                      = {"941003647","941013098"},
		["R6"]                            = {"12521158637","12521162526"},
		["R15 Reanimated"]                = {"4211217646","4211218409"},
		["Realistic"]                     = {"17172918855","17173014241"},
		["Robot"]                         = {"616088211","616089559"},
		["Sneaky"]                        = {"1132473842","1132477671"},
		["Sports (Adidas)"]               = {"18537376492","18537371272"},
		["Soldier"]                       = {"3972151362","3972151362"},
		["Stylish"]                       = {"616136790","616138447"},
		["Stylized Female"]               = {"4708191566","4708192150"},
		["Superhero"]                     = {"10921288909","10921290167"},
		["Toy"]                           = {"782841498","782845736"},
		["Udzal"]                         = {"3303162274","3303162549"},
		["Vampire"]                       = {"1083445855","1083450166"},
		["Werewolf"]                      = {"1083195517","1083214717"},
		["Wicked (Popular)"]              = {"118832222982049","76049494037641"},
		["No Boundaries (Walmart)"]       = {"18747067405","18747063918"},
		["Zombie"]                        = {"616158929","616160636"},
		["(UGC) Zombie"]                  = {"77672872857991","77672872857991"},
		["(UGC) TailWag"]                 = {"129026910898635","129026910898635"},
		["[VOTE] warming up"]             = {"83573330053643","83573330053643"},
		["cesus"]                         = {"115879733952840","115879733952840"},
		["[VOTE] Float"]                  = {"110375749767299","110375749767299"},
		["UGC Oneleft"]                   = {"121217497452435","121217497452435"},
		["AuraFarming"]                   = {"138665010911335","138665010911335"},
		["[VOTE] Mech Float"]             = {"74447366032908","74447366032908"},
		["Badware"]                       = {"140131631438778","140131631438778"},
		["Wicked Dancing Through Life"]   = {"92849173543269","132238900951109"},
		["Unboxed By Amazon"]             = {"98281136301627","138183121662404"},
	},
	["Walk"] = {
		["superhero aura"]                = "97462772841800",
		["Intimidating nonchalant"]       = "114949725526779",
		["moonwalker"]                    = "87459032537337",
		["Floating aura"]                 = "84782014405060",
		["non chalant"]                   = "78999489338983",
		["Theif"]                         = "116391452602396",
		["Furry"]                         = "104011441852459",
		["Gojo"]                          = "110581890588888",
		["Animal"]                        = "112238064449133",
		["Geto"]                          = "85811471336028",
        ["Adidas Aura"]                   = "83842218823011",
		["Patrol"]                        = "1151231493",
		["Drooling Zombie"]               = "3489174223",
		["Adidas Community"]              = "122150855457006",
		["Levitation"]                    = "616013216",
		["Catwalk Glam"]                  = "109168724482748",
		["Knight"]                        = "10921127095",
		["Pirate"]                        = "750785693",
		["Bold"]                          = "16738340646",
		["Sports (Adidas)"]               = "18537392113",
		["Zombie"]                        = "616168032",
		["Astronaut"]                     = "891667138",
		["Cartoony"]                      = "742640026",
		["Ninja"]                         = "656121766",
		["Confident"]                     = "1070017263",
		["Wicked Dancing Through Life"]   = "73718308412641",
		["Unboxed By Amazon"]             = "90478085024465",
		["R15 Reanimated"]                = "4211223236",
		["Ghost"]                         = "616013216",
		["2016 Animation (mm2)"]          = "387947975",
		["(UGC) Zombie"]                  = "113603435314095",
		["No Boundaries (Walmart)"]       = "18747074203",
		["Rthro"]                         = "10921269718",
		["Werewolf"]                      = "1083178339",
		["Wicked (Popular)"]              = "92072849924640",
		["Vampire"]                       = "1083473930",
		["Popstar"]                       = "1212980338",
		["Mage"]                          = "707897309",
		["(UGC) Smooth"]                  = "76630051272791",
		["R6"]                            = "12518152696",
		["NFL"]                           = "110358958299415",
		["Bubbly"]                        = "910034870",
		["(UGC) Retro"]                   = "107806791584829",
		["(UGC) Retro Zombie"]            = "140703855480494",
		["OldSchool"]                     = "10921244891",
		["Elder"]                         = "10921111375",
		["Stylish"]                       = "616146177",
		["Stylized Female"]               = "4708193840",
		["Robot"]                         = "616095330",
		["Sneaky"]                        = "1132510133",
		["Superhero"]                     = "10921298616",
		["Udzal"]                         = "3303162967",
		["Toy"]                           = "782843345",
		["Default Retarget"]              = "115825677624788",
		["Princess"]                      = "941028902",
		["Cowboy"]                        = "1014421541",
	},
	["Run"] = {
		["superhero aura"]                = "72394449489636",
		["Intimidating nonchalant"]       = "114949725526779",
		["moonwalker"]                    = "106250550654373",
		["Floating aura"]                 = "85232146719894",
		["non chalant"]                   = "121063851088879",
		["Theif"]                         = "100222972388612",
		["Furry"]                         = "87770060317862",
		["Gojo"]                          = "125582828675515",
		["Animal"]                        = "97412731442167",
		["Robot"]                         = "10921250460",
        ["Adidas Aura"]                   = "118320322718866",
		["Patrol"]                        = "1150967949",
		["Drooling Zombie"]               = "3489173414",
		["Adidas Community"]              = "82598234841035",
		["Heavy Run (Udzal/Borock)"]      = "3236836670",
		["Catwalk Glam"]                  = "81024476153754",
		["Knight"]                        = "10921121197",
		["Pirate"]                        = "750783738",
		["Bold"]                          = "16738337225",
		["Sports (Adidas)"]               = "18537384940",
		["Zombie"]                        = "616163682",
		["Astronaut"]                     = "10921039308",
		["Cartoony"]                      = "10921076136",
		["Ninja"]                         = "656118852",
		["(UGC) Dog"]                     = "130072963359721",
		["Wicked Dancing Through Life"]   = "135515454877967",
		["Unboxed By Amazon"]             = "134824450619865",
		["[UGC] Flipping"]                = "124427738251511",
		["Sneaky"]                        = "1132494274",
		["R6"]                            = "12518152696",
		["[VOTE] Aura"]                   = "120142877225965",
		["Popstar"]                       = "1212980348",
		["[UGC] reset"]                   = "0",
		["Wicked (Popular)"]              = "72301599441680",
		["[UGC] chibi"]                   = "85887415033585",
		["R15 Reanimated"]                = "4211220381",
		["Mage"]                          = "10921148209",
		["Ghost"]                         = "616013216",
		["Rthro"]                         = "10921261968",
		["Confident"]                     = "1070001516",
		["Stylized Female"]               = "4708192705",
		["No Boundaries (Walmart)"]       = "18747070484",
		["Elder"]                         = "10921104374",
		["Werewolf"]                      = "10921336997",
		["[UGC] Girly"]                   = "128578785610052",
		["Stylish"]                       = "10921276116",
		["(UGC) Pride"]                   = "116462200642360",
		["NFL"]                           = "117333533048078",
		["(UGC) Soccer"]                  = "116881956670910",
		["MrToilet"]                      = "4417979645",
		["[VOTE] Float"]                  = "71267457613791",
		["Levitation"]                    = "616010382",
		["(UGC) Retro"]                   = "107806791584829",
		["(UGC) Retro Zombie"]            = "140703855480494",
		["OldSchool"]                     = "10921240218",
		["Vampire"]                       = "10921320299",
		["Bubbly"]                        = "10921057244",
		["fake wicked"]                   = "138992096476836",
		["2016 Animation (mm2)"]          = "387947975",
		["[UGC] ball"]                    = "132499588684957",
		["Superhero"]                     = "10921291831",
		["Toy"]                           = "10921306285",
		["Default Retarget"]              = "102294264237491",
		["Princess"]                      = "941015281",
		["Cowboy"]                        = "1014401683",
	},
	["Jump"] = {
		["superhero aura"]                = "110741235266373",
		["Intimidating nonchalant"]       = "71753879936654",
		["moonwalker"]                    = "98654991147591",
		["Floating aura"]                 = "140300561900880",
		["non chalant"]                   = "131467045077224",
		["Theif"]                         = "117109494570159",
		["Furry"]                         = "102635582722041",
		["Gojo"]                          = "126302440229906",
		["Animal"]                        = "123565665274439",
		["Robot"]                         = "616090535",
        ["Adidas Aura"]                   = "109996626521204",
		["Patrol"]                        = "1148811837",
		["Adidas Community"]              = "75290611992385",
		["Levitation"]                    = "616008936",
		["Catwalk Glam"]                  = "116936326516985",
		["Knight"]                        = "910016857",
		["Pirate"]                        = "750782230",
		["Bold"]                          = "16738336650",
		["Sports (Adidas)"]               = "18537380791",
		["Zombie"]                        = "616161997",
		["Astronaut"]                     = "891627522",
		["Cartoony"]                      = "742637942",
		["Ninja"]                         = "656117878",
		["Confident"]                     = "1069984524",
		["Wicked Dancing Through Life"]   = "78508480717326",
		["Unboxed By Amazon"]             = "121454505477205",
		["R6"]                            = "12520880485",
		["R15 Reanimated"]                = "4211219390",
		["Ghost"]                         = "616008936",
		["Rthro"]                         = "10921263860",
		["No Boundaries (Walmart)"]       = "18747069148",
		["Werewolf"]                      = "1083218792",
		["Cowboy"]                        = "1014394726",
		["UGC"]                           = "91788124131212",
		["[VOTE] Animal"]                 = "131203832825082",
		["Popstar"]                       = "1212954642",
		["Mage"]                          = "10921149743",
		["Sneaky"]                        = "1132489853",
		["Superhero"]                     = "10921294559",
		["Elder"]                         = "10921107367",
		["(UGC) Retro"]                   = "139390570947836",
		["NFL"]                           = "119846112151352",
		["OldSchool"]                     = "10921242013",
		["Stylized Female"]               = "4708188025",
		["Stylish"]                       = "616139451",
		["Bubbly"]                        = "910016857",
		["[VOTE] Float"]                  = "75611679208549",
		["[VOTE] Aura"]                   = "93382302369459",
		["Vampire"]                       = "1083455352",
		["Wicked (Popular)"]              = "104325245285198",
		["Toy"]                           = "10921308158",
		["Default Retarget"]              = "117150377950987",
		["Princess"]                      = "941008832",
		["[UGC] happy"]                   = "72388373557525",
	},
	["Fall"] = {
		["superhero aura"]                = "88037637684328",
		["Intimidating nonchalant"]       = "83909243974536",
		["moonwalker"]                    = "136353144297748",
		["Floating aura"]                 = "129591520941189",
		["non chalant"]                   = "135694727101792",
		["Theif"]                         = "84593260785426",
		["Furry"]                         = "137079985547592",
		["Gojo"]                          = "90046220955251",
		["Animal"]                        = "124705831982259",
		["Robot"]                         = "616087089",
		["Patrol"]                        = "1148863382",
		["Adidas Community"]              = "98600215928904",
		["Levitation"]                    = "616005863",
		["Catwalk Glam"]                  = "92294537340807",
		["Knight"]                        = "10921122579",
		["Pirate"]                        = "750780242",
		["Bold"]                          = "16738333171",
		["Sports (Adidas)"]               = "18537367238",
		["Zombie"]                        = "616157476",
		["Astronaut"]                     = "891617961",
		["Cartoony"]                      = "742637151",
		["Ninja"]                         = "656115606",
		["Confident"]                     = "1069973677",
		["Wicked Dancing Through Life"]   = "78147885297412",
		["Unboxed By Amazon"]             = "94788218468396",
		["R6"]                            = "12520972571",
		["[UGC] skydiving"]               = "102674302534126",
		["R15 Reanimated"]                = "4211216152",
		["Rthro"]                         = "10921262864",
		["No Boundaries (Walmart)"]       = "18747062535",
		["Werewolf"]                      = "1083189019",
		["[VOTE] TPose"]                  = "139027266704971",
		["Mage"]                          = "707829716",
		["[VOTE] Animal"]                 = "77069224396280",
		["Wicked (Popular)"]              = "121152442762481",
		["Popstar"]                       = "1212900995",
		["NFL"]                           = "129773241321032",
		["OldSchool"]                     = "10921241244",
		["Sneaky"]                        = "1132469004",
		["Elder"]                         = "10921105765",
		["Bubbly"]                        = "910001910",
		["Stylish"]                       = "616134815",
		["Stylized Female"]               = "4708186162",
		["Vampire"]                       = "1083443587",
		["Superhero"]                     = "10921293373",
		["Toy"]                           = "782846423",
		["Default Retarget"]              = "110205622518029",
		["Princess"]                      = "941000007",
		["Cowboy"]                        = "1014384571",
	},
	["Climb"] = {
		["Intimidating nonchalant"]       = "82707738967601",
		["moonwalker"]                    = "135135787387462",
		["Floating aura"]                 = "94364927317793",
		["non chalant"]                   = "103588829648163",
		["Theif"]                         = "92740123805321",
		["Furry"]                         = "76660530164497",
		["Gojo"]                          = "107688486516091",
		["Animal"]                        = "75085836535654",
		["Robot"]                         = "616086039",
		["Patrol"]                        = "1148811837",
		["Adidas Community"]              = "88763136693023",
		["Levitation"]                    = "10921132092",
		["Catwalk Glam"]                  = "119377220967554",
		["Knight"]                        = "10921125160",
		["[VOTE] Animal"]                 = "124810859712282",
		["Bold"]                          = "16738332169",
		["Sports (Adidas)"]               = "18537363391",
		["Zombie"]                        = "616156119",
		["Astronaut"]                     = "10921032124",
		["Cartoony"]                      = "742636889",
		["Ninja"]                         = "656114359",
		["Confident"]                     = "1069946257",
		["Wicked Dancing Through Life"]   = "129447497744818",
		["Unboxed By Amazon"]             = "121145883950231",
		["R6"]                            = "12520982150",
		["Ghost"]                         = "616003713",
		["Rthro"]                         = "10921257536",
		["Cowboy"]                        = "1014380606",
		["No Boundaries (Walmart)"]       = "18747060903",
		["Mage"]                          = "707826056",
		["[VOTE] sticky"]                 = "77520617871799",
		["Reanimated R15"]                = "4211214992",
		["Popstar"]                       = "1213044953",
		["(UGC) Retro"]                   = "121075390792786",
		["NFL"]                           = "134630013742019",
		["OldSchool"]                     = "10921229866",
		["Sneaky"]                        = "1132461372",
		["Elder"]                         = "845392038",
		["Stylized Female"]               = "4708184253",
		["Stylish"]                       = "10921271391",
		["Superhero"]                     = "10921286911",
		["Werewolf"]                      = "10921329322",
		["Vampire"]                       = "1083439238",
		["Toy"]                           = "10921300839",
		["Wicked (Popular)"]              = "131326830509784",
		["Princess"]                      = "940996062",
		["[VOTE] Rope"]                   = "134977367563514",
	},
	["Swim"] = {
		["Intimidating nonchalant"]       = "80425473017511",
		["Sneaky"]                        = "1132500520",
		["Patrol"]                        = "1151204998",
		["Adidas Community"]              = "133308483266208",
		["Levitation"]                    = "10921138209",
		["Catwalk Glam"]                  = "134591743181628",
		["Knight"]                        = "10921125160",
		["Pirate"]                        = "750784579",
		["Bold"]                          = "16738339158",
		["Sports (Adidas)"]               = "18537389531",
		["Zombie"]                        = "616165109",
		["Astronaut"]                     = "891663592",
		["Cartoony"]                      = "10921079380",
		["Wicked (Popular)"]              = "99384245425157",
		["Mage"]                          = "707876443",
		["Popstar"]                       = "1212998578",
		["Unboxed By Amazon"]             = "105962919001086",
		["R6"]                            = "12518152696",
		["[VOTE] Boat"]                   = "85689117221382",
		["Rthro"]                         = "10921264784",
		["Cowboy"]                        = "1014406523",
		["No Boundaries (Walmart)"]       = "18747073181",
		["Werewolf"]                      = "10921340419",
		["NFL"]                           = "132697394189921",
		["OldSchool"]                     = "10921243048",
		["Wicked Dancing Through Life"]   = "110657013921774",
		["Elder"]                         = "10921108971",
		["Bubbly"]                        = "910028158",
		["Robot"]                         = "10921253142",
		["[VOTE] Aura"]                   = "80645586378736",
		["Vampire"]                       = "10921324408",
		["Stylish"]                       = "10921281000",
		["Toy"]                           = "10921309319",
		["Superhero"]                     = "10921295495",
		["Princess"]                      = "941018893",
		["Confident"]                     = "1070009914",
	},
	["SwimIdle"] = {
		["Intimidating nonchalant"]       = "80425473017511",
		["Sneaky"]                        = "1132506407",
		["Superhero"]                     = "10921297391",
		["Adidas Community"]              = "109346520324160",
		["Levitation"]                    = "10921139478",
		["Catwalk Glam"]                  = "98854111361360",
		["Knight"]                        = "10921125935",
		["Pirate"]                        = "750785176",
		["Bold"]                          = "16738339817",
		["Sports (Adidas)"]               = "18537387180",
		["Stylized Female"]               = "4708190607",
		["Astronaut"]                     = "891663592",
		["Cartoony"]                      = "10921079380",
		["Wicked (Popular)"]              = "113199415118199",
		["Mage"]                          = "707894699",
		["Wicked Dancing Through Life"]   = "129183123083281",
		["Unboxed By Amazon"]             = "129126268464847",
		["R6"]                            = "12518152696",
		["Rthro"]                         = "10921265698",
		["Cowboy"]                        = "1014411816",
		["No Boundaries (Walmart)"]       = "18747071682",
		["Werewolf"]                      = "10921341319",
		["NFL"]                           = "79090109939093",
		["OldSchool"]                     = "10921244018",
		["Robot"]                         = "10921253767",
		["Elder"]                         = "10921110146",
		["Bubbly"]                        = "910030921",
		["Patrol"]                        = "1151221899",
		["Vampire"]                       = "10921325443",
		["Popstar"]                       = "1212998578",
		["Ninja"]                         = "656118341",
		["Toy"]                           = "10921310341",
		["Confident"]                     = "1070012133",
		["Princess"]                      = "941025398",
		["Stylish"]                       = "10921281964",
	},
}

-- ---- Animation apply logic ----

local function animFreeze()
	local player = Players.LocalPlayer
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = true end
	if char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and not part.Anchored then part.Anchored = true end
		end
	end
end

local function animUnfreeze()
	local player = Players.LocalPlayer
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
	if char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.Anchored then part.Anchored = false end
		end
	end
end

local function animRefresh()
	local char = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	hum:ChangeState(Enum.HumanoidStateType.Freefall)
end

local function animRefreshSwim()
	local char = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	task.wait(0.1)
	hum:ChangeState(Enum.HumanoidStateType.Swimming)
end

local function animRefreshClimb()
	local char = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	task.wait(0.1)
	hum:ChangeState(Enum.HumanoidStateType.Climbing)
end

local function setAnimation(animationType, animationId)
	if type(animationId) ~= "table" and type(animationId) ~= "string" then return end
	local player = Players.LocalPlayer
	if not player.Character then return end
	local Char = player.Character
	local Animate = Char:FindFirstChild("Animate")
	if not Animate then return end

	animFreeze()
	task.wait(0.1)

	local ok, err = pcall(function()
		local hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
		if hum then
			for _, t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop(0) end
		end
		if animationType == "Idle" then
			FeatureStates.SavedAnimations.Idle = animationId
			Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId[1]
			Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId[2]
			animRefresh()
		elseif animationType == "Walk" then
			FeatureStates.SavedAnimations.Walk = animationId
			Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId
			if FeatureStates.ForceWalkAnimation then
				Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId
			end
			animRefresh()
		elseif animationType == "Run" then
			FeatureStates.SavedAnimations.Run = animationId
			if not FeatureStates.ForceWalkAnimation then
				Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId
				animRefresh()
			end
		elseif animationType == "Jump" then
			FeatureStates.SavedAnimations.Jump = animationId
			Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId
			animRefresh()
		elseif animationType == "Fall" then
			FeatureStates.SavedAnimations.Fall = animationId
			Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId
			animRefresh()
		elseif animationType == "Swim" and Animate:FindFirstChild("swim") then
			FeatureStates.SavedAnimations.Swim = animationId
			Animate.swim.Swim.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId
			animRefreshSwim()
		elseif animationType == "SwimIdle" and Animate:FindFirstChild("swimidle") then
			FeatureStates.SavedAnimations.SwimIdle = animationId
			Animate.swimidle.SwimIdle.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId
			animRefreshSwim()
		elseif animationType == "Climb" then
			FeatureStates.SavedAnimations.Climb = animationId
			Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. animationId
			animRefreshClimb()
		end
	end)
	if not ok then warn("Anim error:", err) end

	task.wait(0.1)
	animUnfreeze()
	saveSettings()
end

local function applySavedAnimations()
    if FeatureStates.SavedAnimations.Idle     then setAnimation("Idle",     FeatureStates.SavedAnimations.Idle)     end
	if FeatureStates.SavedAnimations.Walk     then setAnimation("Walk",     FeatureStates.SavedAnimations.Walk)     end
	if FeatureStates.SavedAnimations.Run      then setAnimation("Run",      FeatureStates.SavedAnimations.Run)      end
	if FeatureStates.SavedAnimations.Jump     then setAnimation("Jump",     FeatureStates.SavedAnimations.Jump)     end
	if FeatureStates.SavedAnimations.Fall     then setAnimation("Fall",     FeatureStates.SavedAnimations.Fall)     end
	if FeatureStates.SavedAnimations.Swim     then setAnimation("Swim",     FeatureStates.SavedAnimations.Swim)     end
	if FeatureStates.SavedAnimations.SwimIdle then setAnimation("SwimIdle", FeatureStates.SavedAnimations.SwimIdle) end
	if FeatureStates.SavedAnimations.Climb    then setAnimation("Climb",    FeatureStates.SavedAnimations.Climb)    end
end

DefaultAnimationsCache = nil

function cacheDefaultAnimations(char)
    if DefaultAnimationsCache then return end
    if not char then return end
    local Animate = char:WaitForChild("Animate", 5)
    if not Animate then return end
    DefaultAnimationsCache = {
        idle1 = Animate:FindFirstChild("idle") and Animate.idle:FindFirstChild("Animation1") and Animate.idle.Animation1.AnimationId,
        idle2 = Animate:FindFirstChild("idle") and Animate.idle:FindFirstChild("Animation2") and Animate.idle.Animation2.AnimationId,
        walk = Animate:FindFirstChild("walk") and Animate.walk:FindFirstChild("WalkAnim") and Animate.walk.WalkAnim.AnimationId,
        run = Animate:FindFirstChild("run") and Animate.run:FindFirstChild("RunAnim") and Animate.run.RunAnim.AnimationId,
        jump = Animate:FindFirstChild("jump") and Animate.jump:FindFirstChild("JumpAnim") and Animate.jump.JumpAnim.AnimationId,
        fall = Animate:FindFirstChild("fall") and Animate.fall:FindFirstChild("FallAnim") and Animate.fall.FallAnim.AnimationId,
        climb = Animate:FindFirstChild("climb") and Animate.climb:FindFirstChild("ClimbAnim") and Animate.climb.ClimbAnim.AnimationId,
        swim = Animate:FindFirstChild("swim") and Animate.swim:FindFirstChild("Swim") and Animate.swim.Swim.AnimationId,
        swimidle = Animate:FindFirstChild("swimidle") and Animate.swimidle:FindFirstChild("SwimIdle") and Animate.swimidle.SwimIdle.AnimationId,
    }
end

local function resetAnimations()
    local player = Players.LocalPlayer
    local char = player.Character
    if not char then return end
    local Animate = char:FindFirstChild("Animate")
    if not Animate or not DefaultAnimationsCache then return end
    pcall(function()
        if DefaultAnimationsCache.idle1 then Animate.idle.Animation1.AnimationId = DefaultAnimationsCache.idle1 end
        if DefaultAnimationsCache.idle2 then Animate.idle.Animation2.AnimationId = DefaultAnimationsCache.idle2 end
        if DefaultAnimationsCache.walk then Animate.walk.WalkAnim.AnimationId = DefaultAnimationsCache.walk end
        if DefaultAnimationsCache.run then Animate.run.RunAnim.AnimationId = DefaultAnimationsCache.run end
        if DefaultAnimationsCache.jump then Animate.jump.JumpAnim.AnimationId = DefaultAnimationsCache.jump end
        if DefaultAnimationsCache.fall then Animate.fall.FallAnim.AnimationId = DefaultAnimationsCache.fall end
        if DefaultAnimationsCache.climb then Animate.climb.ClimbAnim.AnimationId = DefaultAnimationsCache.climb end
        if DefaultAnimationsCache.swim and Animate:FindFirstChild("swim") then Animate.swim.Swim.AnimationId = DefaultAnimationsCache.swim end
        if DefaultAnimationsCache.swimidle and Animate:FindFirstChild("swimidle") then Animate.swimidle.SwimIdle.AnimationId = DefaultAnimationsCache.swimidle end
        
        -- Force-reload by briefly changing humanoid state
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop(0) end
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
        end
    end)
    -- Clear saved animations from config
    FeatureStates.SavedAnimations = {}
    saveSettings()
    SendNotification("Eternity", "Animations reset to your equipped defaults!", 2)
end

-- Re-apply animations on respawn and load
Players.LocalPlayer.CharacterAdded:Connect(function(character)
    if not IsKeyVerified then return end
	local hum = character:WaitForChild("Humanoid")
	local animate = character:WaitForChild("Animate", 10)
	if not animate then return end
    cacheDefaultAnimations(character)
	task.wait(1)
    applySavedAnimations()
end)

-- ---- Build the UI sections with dropdowns ----
local animTypeOrder = {"Idle", "Walk", "Run", "Jump", "Fall", "Climb", "Swim", "SwimIdle"}

local function findAnimNameById(animType, id)
    if not id then return nil end
    for name, val in pairs(AnimDB[animType]) do
        if type(val) == "table" and type(id) == "table" then
            if val[1] == id[1] and val[2] == id[2] then return name end
        elseif val == id then
            return name
        end
    end
    return nil
end

for orderIndex, animType in ipairs(animTypeOrder) do
	local names = {}
	for name in pairs(AnimDB[animType]) do
		table.insert(names, name)
	end
	table.sort(names)
    
	local savedId = FeatureStates.SavedAnimations[animType]
	local currentName = findAnimNameById(animType, savedId)
    
	createDropdown(animPage, animType, names, orderIndex + 20, function(selected)
		local id = AnimDB[animType][selected]
		if id then
			setAnimation(animType, id)
			SendNotification("Eternity", "Animation applied: " .. selected, 2)
		end
	end, true, currentName)
end

createSection(animPage, "Restore", 30)
createActionButton(animPage, "Reset Animations", "Restore all animations back to Roblox defaults", 31, function()
	resetAnimations()
end)

-- 
-- PAGE: ANTI STUFFS
-- 
antiStuffsPage = createPage("antiStuffs")

createSection(antiStuffsPage, "Anti Stuffs", 10)

local AntiStates = {
    Headsit = false,
    Facebang = false,
    Kidnap = false,
    KidnapConn = nil,
    Void = false,
    InfFallVoid = false,
    VoidPart = nil,
    VoidHeight = tonumber("nan"),
    GodMode = false,
    GodModeConn = nil,
    GodModeConnections = {},
    GodModeCharConn = nil,
}

pcall(function()
    AntiStates.VoidHeight = Workspace.FallenPartsDestroyHeight
end)

createToggle(antiStuffsPage, "Anti Head Sit", "Prevents players from sitting on your head", "AntiHeadsit", 20, function(on)
    AntiStates.Headsit = on
end)

createToggle(antiStuffsPage, "Anti Facebang", "Prevents players from using facebang scripts on you", "AntiFacebang", 30, function(on)
    AntiStates.Facebang = on
end)

local function startAntiKidnap()
    local char = lp.Character; if not char then return end
    local hm = char:FindFirstChild("Humanoid"); if not hm then return end
    
    if AntiStates.KidnapConn then AntiStates.KidnapConn:Disconnect() end
    AntiStates.KidnapConn = RunService.Heartbeat:Connect(function()
        if FeatureStates.Headsit or FeatureStates.Bagpack then
            if not hm:GetStateEnabled(Enum.HumanoidStateType.Seated) then
                hm:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            end
            return
        end

        if hm:GetStateEnabled(Enum.HumanoidStateType.Seated) then
            hm:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        end
        if hm.Sit then hm.Sit = false end
        if hm:GetState() == Enum.HumanoidStateType.Seated then hm:ChangeState(Enum.HumanoidStateType.Running) end
        local rp = char:FindFirstChild("HumanoidRootPart")
        if rp then 
            local sw = rp:FindFirstChild("SeatWeld")
            if sw then sw:Destroy() end 
        end
    end)
end

local function stopAntiKidnap()
    local char = lp.Character
    if char then 
        local hm = char:FindFirstChild("Humanoid")
        if hm then hm:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end 
    end
    if AntiStates.KidnapConn then AntiStates.KidnapConn:Disconnect(); AntiStates.KidnapConn = nil end
end

lp.CharacterAdded:Connect(function()
    task.wait(1)
    if AntiStates.Kidnap then startAntiKidnap() end
end)

createToggle(antiStuffsPage, "Anti Kidnap", "Prevents you from being forcibly seated/kidnapped", "AntiKidnap", 40, function(on)
    AntiStates.Kidnap = on
    if on then startAntiKidnap() else stopAntiKidnap() end
end)

createSection(antiStuffsPage, "Anti Voids", 50)

do
    local hintCard = Instance.new("Frame", antiStuffsPage)
    hintCard.Size = UDim2.new(1, -8, 0, 84)
    hintCard.BackgroundColor3 = C.surface
    hintCard.BorderSizePixel = 0
    hintCard.LayoutOrder = 55
    corner(hintCard, 10)

    local cl = Instance.new("UIListLayout", hintCard)
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    cl.Padding = UDim.new(0, 6)
    cl.VerticalAlignment = Enum.VerticalAlignment.Center

    local pad = Instance.new("UIPadding", hintCard)
    pad.PaddingLeft = UDim.new(0, 16)

    local titleLbl = Instance.new("TextLabel", hintCard)
    titleLbl.Size = UDim2.new(1, 0, 0, 16)
    titleLbl.Text = "DIRECTION OF USE"
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 10
    titleLbl.TextColor3 = C.textMuted
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.BackgroundTransparency = 1
    titleLbl.LayoutOrder = 0

    local c1 = Instance.new("TextLabel", hintCard)
    c1.Size = UDim2.new(1, 0, 0, 16)
    c1.Text = "<font color='rgb(" .. accentRgbStr .. ")'><b>Anti Void</b></font> <font color='rgb(100, 100, 115)'>-</font> Prevents you from falling into the void"
    c1.RichText = true
    c1.Font = Enum.Font.Gotham
    c1.TextSize = 12
    c1.TextColor3 = C.text
    c1.TextXAlignment = Enum.TextXAlignment.Left
    c1.BackgroundTransparency = 1
    c1.LayoutOrder = 1

    local c2 = Instance.new("TextLabel", hintCard)
    c2.Size = UDim2.new(1, 0, 0, 16)
    c2.Text = "<font color='rgb(" .. accentRgbStr .. ")'><b>Infinite Fall Void</b></font> <font color='rgb(100, 100, 115)'>-</font> Fall infinitely without dying"
    c2.RichText = true
    c2.Font = Enum.Font.Gotham
    c2.TextSize = 12
    c2.TextColor3 = C.text
    c2.TextXAlignment = Enum.TextXAlignment.Left
    c2.BackgroundTransparency = 1
    c2.LayoutOrder = 2
    
    applyPremiumCardEffect(hintCard)
end

createToggle(antiStuffsPage, "Anti Void", "Prevents you from falling into the void", "AntiVoid", 60, function(on)
    AntiStates.Void = on
    if on then
        if AntiStates.InfFallVoid and ToggleRegistry["InfFallVoid"] then
            ToggleRegistry["InfFallVoid"](false)
        end
        if AntiStates.VoidPart then AntiStates.VoidPart:Destroy() end
        local v = Instance.new("Part")
        v.Parent = Workspace
        v.Name = "AntiVoid"
        v.Transparency = 1
        v.Anchored = true
        v.CanCollide = true
        v.Size = Vector3.new(2048, 1, 2048)
        v.Position = Vector3.new(0, AntiStates.VoidHeight, 0)
        v.Locked = true
        AntiStates.VoidPart = v
        
        task.spawn(function()
            while AntiStates.Void and AntiStates.VoidPart do
                pcall(function()
                    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                        AntiStates.VoidPart.Position = Vector3.new(lp.Character.HumanoidRootPart.Position.X, AntiStates.VoidHeight, lp.Character.HumanoidRootPart.Position.Z)
                    end
                end)
                task.wait(0)
            end
        end)
    else
        if AntiStates.VoidPart then
            AntiStates.VoidPart:Destroy()
            AntiStates.VoidPart = nil
        end
    end
end)

createToggle(antiStuffsPage, "Infinite Fall Void", "Fall infinitely without dying", "InfFallVoid", 70, function(on)
    AntiStates.InfFallVoid = on
    if on then
        if AntiStates.Void and ToggleRegistry["AntiVoid"] then
            ToggleRegistry["AntiVoid"](false)
        end
        pcall(function()
            Workspace.FallenPartsDestroyHeight = 0/0
        end)
    else
        pcall(function()
            Workspace.FallenPartsDestroyHeight = AntiStates.VoidHeight
        end)
    end
end)

-- God Mode
AntiStates.applyGodMode = function(char)
    if not char then return end
    for _, c in pairs(AntiStates.GodModeConnections) do pcall(function() c:Disconnect() end) end
    table.clear(AntiStates.GodModeConnections)

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- 1) ForceField blocks TakeDamage() calls from scripts
    local ff = char:FindFirstChildOfClass("ForceField")
    if not ff then
        ff = Instance.new("ForceField")
        ff.Visible = false
        ff.Parent = char
    end

    -- 2) Disable the Dead humanoid state so the character can't die
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)

    -- 3) MaxHealth = huge so any direct health assignments fail to kill
    hum.MaxHealth = math.huge
    hum.Health = math.huge

    -- 4) Noclip & Untouchable: make all parts ignore physical hits AND script touch events
    local function applyNoclip()
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    if part.Name ~= "HumanoidRootPart" then
                        part.CanCollide = false
                    end
                    part.CanTouch = false
                    part.CanQuery = false
                end)
            end
        end
    end
    applyNoclip()
    -- Also apply to newly added parts (accessories, tools, etc.)
    AntiStates.GodModeConnections[#AntiStates.GodModeConnections + 1] = char.DescendantAdded:Connect(function(part)
        if not AntiStates.GodMode then return end
        if part:IsA("BasePart") then
            pcall(function()
                if part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = false
                end
                part.CanTouch = false
                part.CanQuery = false
            end)
        end
    end)

    -- 5) HealthChanged: instantly restore if something still reduces HP
    AntiStates.GodModeConnections[#AntiStates.GodModeConnections + 1] = hum.HealthChanged:Connect(function(hp)
        if AntiStates.GodMode and hp < math.huge then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        end
    end)

    -- 6) Heartbeat fallback: keep untouchable, ForceField, and MaxHealth enforced every frame
    AntiStates.GodModeConnections[#AntiStates.GodModeConnections + 1] = RunService.Heartbeat:Connect(function()
        if not AntiStates.GodMode then return end
        pcall(function()
            if hum.MaxHealth ~= math.huge then hum.MaxHealth = math.huge end
            if hum.Health ~= math.huge then hum.Health = math.huge end
            if not char:FindFirstChildOfClass("ForceField") then
                local nff = Instance.new("ForceField")
                nff.Visible = false
                nff.Parent = char
            end
            -- Re-enforce untouchable every frame
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if part.Name ~= "HumanoidRootPart" and part.CanCollide then 
                        part.CanCollide = false 
                    end
                    if part.CanTouch then part.CanTouch = false end
                    if part.CanQuery then part.CanQuery = false end
                end
            end
        end)
    end)
end


createToggle(antiStuffsPage, "God Mode", "Immune to damage, cutters, and kill scripts", "GodMode", 75, function(on)
    AntiStates.GodMode = on
    if AntiStates.GodModeCharConn then AntiStates.GodModeCharConn:Disconnect(); AntiStates.GodModeCharConn = nil end
    for _, c in pairs(AntiStates.GodModeConnections) do pcall(function() c:Disconnect() end) end
    table.clear(AntiStates.GodModeConnections)

    if on then
        AntiStates.applyGodMode(lp.Character)
        AntiStates.GodModeCharConn = lp.CharacterAdded:Connect(function(char)
            task.wait(0.2)
            if AntiStates.GodMode then AntiStates.applyGodMode(char) end
        end)
        SendNotification("Eternity", "God Mode ON - immune to damage.", 3)
    else
        pcall(function()
            local char = lp.Character
            if not char then return end
            local ff = char:FindFirstChildOfClass("ForceField")
            if ff then ff:Destroy() end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
                hum.MaxHealth = 100
                hum.Health = 100
            end
            -- Restore physical interaction
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        part.CanTouch = true
                        part.CanQuery = true
                        -- Don't force CanCollide on accessories to prevent physics glitches,
                        -- but restore it for main body parts.
                        if part.Name == "Torso" or part.Name == "UpperTorso" or part.Name == "LowerTorso" or part.Name == "Head" or part.Name == "HumanoidRootPart" then
                            part.CanCollide = true
                        end
                    end)
                end
            end
        end)
        SendNotification("Eternity", "God Mode OFF.", 2)
    end
end)


-- Fakeout
createKeybindToggle(antiStuffsPage, "Fakeout", "Arm toggle, then press key to fake-void yourself", "FakeoutEnabled", "Fakeout", Keybinds.Fakeout, 80, function(on)
    FeatureStates.FakeoutEnabled = on
    if on then
        SendNotification("Eternity", "Fakeout armed! Press keybind to trigger.", 2)
    else
        SendNotification("Eternity", "Fakeout disarmed.", 2)
    end
end)

createSection(antiStuffsPage, "Evade Bangs", 82)



-- Ghost Bait
createKeybindToggle(antiStuffsPage, "Ghost Bait", "Arms a trap: press key to yeet your body beyond render distance, crashing any weld attacker's client, then snap back", "GhostBaitEnabled", "GhostBait", Keybinds.GhostBait, 85, function(on)
    FeatureStates.GhostBaitEnabled = on
    if on then
        SendNotification("Eternity", "Ghost Bait armed! Press keybind to trigger.", 2)
    else
        SendNotification("Eternity", "Ghost Bait disarmed.", 2)
    end
end)

-- 
-- GLITCH DESYNC ENGINE
-- 
local glitchActivate, glitchDeactivate, GlitchStates
task.spawn(function()
    GlitchStates = {
        Active        = false,
        RealCF        = nil,
        RealVel       = Vector3.zero,
        RealRot       = Vector3.zero
    }

    _G.UpdateGlitchCF = function(newCF)
        if GlitchStates.Active then
            GlitchStates.RealCF = newCF
        end
    end

    glitchActivate = function(mode)
        pcall(function()
            local char = lp.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            if GlitchStates.HeartbeatConn then GlitchStates.HeartbeatConn:Disconnect() end
            RunService:UnbindFromRenderStep("GlitchRestore")
            
            GlitchStates.RealVel = Vector3.zero
            GlitchStates.RealCF = nil
            GlitchStates.OriginCF = hrp.CFrame

            -- Run Stepped restore to fix any Physics-step based coordinate leaking
            GlitchStates.SteppedConn = RunService.Stepped:Connect(function()
                if char and hrp and hrp.Parent and GlitchStates.RealCF then
                    hrp.CFrame = GlitchStates.RealCF
                    local finalVel = GlitchStates.RealVel
                    if finalVel and finalVel.Magnitude < 1 then finalVel = Vector3.new(0, 0.05, 0) end
                    hrp.AssemblyLinearVelocity = finalVel or Vector3.zero
                    hrp.AssemblyAngularVelocity = GlitchStates.RealRot or Vector3.zero
                end
            end)

            -- Inject randomized massive velocity AND erratic CFrame on Heartbeat (post-physics, pre-replication)
            -- This makes the server see us teleporting and vibrating randomly even when idle, countering zero-delay welds.
            GlitchStates.HeartbeatConn = RunService.Heartbeat:Connect(function()
                if char and hrp and hrp.Parent then
                    GlitchStates.RealCF = hrp.CFrame
                    
                    GlitchStates.RealVel = hrp.AssemblyLinearVelocity
                    GlitchStates.RealRot = hrp.AssemblyAngularVelocity
                    
                    local rx, ry, rz
                    local tgtCF
                    
                    if mode == "Extreme" then
                        rx = math.random(-50000, 50000)
                        ry = math.random(50, 1000)
                        rz = math.random(-50000, 50000)
                        
                        -- Flicker between normal local desync and the extreme bunker coordinate
                        if tick() % 0.1 < 0.05 then
                            tgtCF = CFrame.new(2598.325, -9200, 74288.234)
                        else
                            local cx = math.random(-100, 100)
                            local cy = math.random(10, 150)
                            local cz = math.random(-100, 100)
                            tgtCF = CFrame.new(hrp.Position) * CFrame.Angles(0, math.random(0, 314)/100, 0) + Vector3.new(cx, cy, cz)
                        end
                    else -- Normal
                        rx = math.random(-50000, 50000)
                        ry = math.random(50, 1000)
                        rz = math.random(-50000, 50000)
                        local cx = math.random(-100, 100)
                        local cy = math.random(10, 150)
                        local cz = math.random(-100, 100)
                        tgtCF = CFrame.new(hrp.Position) * CFrame.Angles(0, math.random(0, 314)/100, 0) + Vector3.new(cx, cy, cz)
                    end
                    
                    hrp.AssemblyLinearVelocity = Vector3.new(rx, ry, rz)
                    hrp.AssemblyAngularVelocity = Vector3.new(rx, ry, rz)
                    
                    hrp.CFrame = tgtCF
                end
            end)
            
            -- Restore real physics & position on BindToRenderStep at priority 1
            -- By restoring at priority 1 (first), we beat all custom camera scripts and ensure 100% clean POV
            RunService:BindToRenderStep("GlitchRestore", 1, function()
                if char and hrp and hrp.Parent then
                    if GlitchStates.RealCF then
                        hrp.CFrame = GlitchStates.RealCF
                    end
                    
                    -- Force physics engine to stay awake while idle so scramble replicates
                    local finalVel = GlitchStates.RealVel
                    if finalVel.Magnitude < 1 then
                        finalVel = Vector3.new(0, 0.05, 0)
                    end
                    
                    hrp.AssemblyLinearVelocity = finalVel
                    hrp.AssemblyAngularVelocity = GlitchStates.RealRot
                end
            end)

            GlitchStates.Active = true
            if _G.SetActiveFeature then _G.SetActiveFeature("Glitch Desync") end
        end)
    end

    glitchDeactivate = function()
        GlitchStates.Active = false
        if _G.SetActiveFeature then _G.SetActiveFeature(nil) end
        RunService:UnbindFromRenderStep("GlitchRestore")
        if GlitchStates.HeartbeatConn then GlitchStates.HeartbeatConn:Disconnect(); GlitchStates.HeartbeatConn = nil end
        if GlitchStates.SteppedConn then GlitchStates.SteppedConn:Disconnect(); GlitchStates.SteppedConn = nil end
        
        pcall(function()
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if FeatureStates.ExtremeGlitchDesyncEnabled and GlitchStates.OriginCF then
                    hrp.CFrame = GlitchStates.OriginCF
                elseif GlitchStates.RealCF then 
                    hrp.CFrame = GlitchStates.RealCF 
                end
                -- Force a network replication packet to the server if we were idle
                local finalVel = GlitchStates.RealVel or Vector3.zero
                if finalVel.Magnitude < 1 then
                    finalVel = Vector3.new(0, 0.05, 0) -- tiny nudge to wake the physics engine
                end
                hrp.AssemblyLinearVelocity = finalVel
                hrp.AssemblyAngularVelocity = GlitchStates.RealRot or Vector3.zero
            end
        end)
    end

    lp.CharacterAdded:Connect(function()
        task.wait(0.1)
        GlitchStates.Active = false
        RunService:UnbindFromRenderStep("GlitchRestore")
        if GlitchStates.HeartbeatConn then GlitchStates.HeartbeatConn:Disconnect(); GlitchStates.HeartbeatConn = nil end
        if GlitchStates.SteppedConn then GlitchStates.SteppedConn:Disconnect(); GlitchStates.SteppedConn = nil end
        -- (Removed automatic toggle disarming so the keybind stays armed across respawns)
    end)
end)

-- Extreme Glitch Desync toggle
createKeybindToggle(antiStuffsPage, "Extreme Glitch Desync", "Arm toggle, then press key to aggressively scramble your position 1 Million studs away.", "ExtremeGlitchDesyncEnabled", "GlitchDesync", Keybinds.GlitchDesync, 86, function(on)
    FeatureStates.ExtremeGlitchDesyncEnabled = on
    if on then
        if FeatureStates.NormalGlitchDesyncEnabled and ToggleRegistry["NormalGlitchDesyncEnabled"] then
            ToggleRegistry["NormalGlitchDesyncEnabled"](false)
        end
        SendNotification("Eternity", "Extreme Glitch Desync armed!", 2)
    else
        if GlitchStates and GlitchStates.Active then glitchDeactivate() end
        SendNotification("Eternity", "Extreme Glitch Desync disarmed.", 2)
    end
end)

-- Normal Glitch Desync toggle
createKeybindToggle(antiStuffsPage, "Normal Glitch Desync", "Arm toggle, then press key to normally flicker your server position.", "NormalGlitchDesyncEnabled", "GlitchDesync", Keybinds.GlitchDesync, 87, function(on)
    FeatureStates.NormalGlitchDesyncEnabled = on
    if on then
        if FeatureStates.ExtremeGlitchDesyncEnabled and ToggleRegistry["ExtremeGlitchDesyncEnabled"] then
            ToggleRegistry["ExtremeGlitchDesyncEnabled"](false)
        end
        SendNotification("Eternity", "Normal Glitch Desync armed!", 2)
    else
        if GlitchStates and GlitchStates.Active then glitchDeactivate() end
        SendNotification("Eternity", "Normal Glitch Desync disarmed.", 2)
    end
end)

createSection(antiStuffsPage, "Stealth", 100)

FeatureStates.goUndergroundDeactivate = function()
    if not FeatureStates.GoUndergroundActive then return end
    FeatureStates.GoUndergroundActive = false
    local char = lp.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if FeatureStates.UndergroundFloor then
        FeatureStates.UndergroundFloor:Destroy()
        FeatureStates.UndergroundFloor = nil
    end
    
    if hrp then
        hrp.CFrame = hrp.CFrame * CFrame.new(0, 12.5, 0)
    end
    if hum then
        hum.CameraOffset = Vector3.new(0, 0, 0)
    end
    
    if FeatureStates.undergroundLoop then
        FeatureStates.undergroundLoop:Disconnect()
        FeatureStates.undergroundLoop = nil
    end
    SendNotification("Eternity", "You have returned to the surface.", 2)
end

FeatureStates.goUndergroundActivate = function()
    if FeatureStates.GoUndergroundActive then return end
    local char = lp.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if hrp and hum then
        local floor = Instance.new("Part")
        floor.Name = "UndergroundFloor"
        floor.Anchored = true
        floor.CanCollide = true
        floor.Transparency = 1
        floor.Size = Vector3.new(5000, 1, 5000)
        
        floor.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 16, hrp.Position.Z)
        floor.Parent = Workspace
        FeatureStates.UndergroundFloor = floor
        
        hrp.CFrame = hrp.CFrame * CFrame.new(0, -12.5, 0)
        hum.CameraOffset = Vector3.new(0, 12.5, 0)
        
        if not FeatureStates.undergroundLoop then
            FeatureStates.undergroundLoop = RunService.Stepped:Connect(function()
                if FeatureStates.GoUndergroundActive and lp.Character then
                    for _, part in ipairs(lp.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
        FeatureStates.GoUndergroundActive = true
        SendNotification("Eternity", "You are now Underground.", 2)
    end
end

createSection(antiStuffsPage, "AFK Protection", 110)

local VirtualUser = game:GetService("VirtualUser")
local idledConnection

createToggle(antiStuffsPage, "Anti-AFK", "Prevents Roblox from kicking you for being idle for 20 minutes", "AntiAFK", 120, function(on)
    FeatureStates.AntiAFK = on
    if on then
        if idledConnection then idledConnection:Disconnect() end
        idledConnection = lp.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    else
        if idledConnection then
            idledConnection:Disconnect()
            idledConnection = nil
        end
    end
end)

RunService.Stepped:Connect(function()
    if not AntiStates.Headsit and not AntiStates.Facebang then return end
    pcall(function()
        local char = lp.Character; if not char then return end
        local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local oldCF = hrp.CFrame
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= lp and plr.Character then
                local tHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    local tx, ty, tz = tHRP.Position.X, tHRP.Position.Y, tHRP.Position.Z
                    if AntiStates.Headsit then
                        local cx,cy,cz = hrp.CFrame.X, hrp.CFrame.Y, hrp.CFrame.Z
                        local dy = ty - cy
                        if math.abs(tx-cx)<=2.5 and math.abs(tz-cz)<=2.5 and dy>=1.25 then
                            hrp.CFrame=CFrame.new(0,-950,0); task.wait(0.25); hrp.CFrame=oldCF; break
                        end
                    end
                    if AntiStates.Facebang then
                        local c = hrp.CFrame * CFrame.new(0,0,-1.75)
                        if math.abs(tx-c.Position.X)<=1.25 and math.abs(tz-c.Position.Z)<=1.25 then
                            hrp.CFrame=CFrame.new(0,-950,0); task.wait(0.25); hrp.CFrame=oldCF; break
                        end
                    end
                end
            end
        end
    end)
end)

-- 
-- PAGE: ANIM COPY
-- 
task.spawn(function()
    local animCopyPage = createPage("animcopy")

    createSection(animCopyPage, "Anim Copy", 1)

    -- State
    local ac_target = nil
    local ac_active = false
    local ac_side   = "Right"
    local ac_conn   = nil
    local ac_OFFSET = {
        Left  = CFrame.new(-4, 0, 0),
        Right = CFrame.new( 4, 0, 0),
    }

    --  Search bar 
    local ac_searchFrame = Instance.new("Frame", animCopyPage)
    ac_searchFrame.Size = UDim2.new(1, -8, 0, 36)
    ac_searchFrame.BackgroundColor3 = C.input
    ac_searchFrame.BorderSizePixel = 0
    ac_searchFrame.LayoutOrder = 2
    corner(ac_searchFrame, 10)
    local ac_searchStroke = stroke(ac_searchFrame, C.divider, 1, 0.5)

    local ac_searchIcon = Instance.new("ImageLabel", ac_searchFrame)
    ac_searchIcon.Size = UDim2.new(0, 16, 0, 16)
    ac_searchIcon.Position = UDim2.new(0, 10, 0.5, -8)
    ac_searchIcon.Image = getAssetUrl("search.png")
    ac_searchIcon.BackgroundTransparency = 1

    local ac_box = Instance.new("TextBox", ac_searchFrame)
    ac_box.Size = UDim2.new(1, -40, 1, 0)
    ac_box.Position = UDim2.new(0, 34, 0, 0)
    ac_box.PlaceholderText = "Search player..."
    ac_box.PlaceholderColor3 = C.textDim
    ac_box.Text = ""
    ac_box.Font = Enum.Font.Gotham
    ac_box.TextSize = 12
    ac_box.TextColor3 = C.text
    ac_box.BackgroundTransparency = 1
    ac_box.ClearTextOnFocus = false

    ac_box.Focused:Connect(function()
        tween(ac_searchStroke, {Color = C.accent, Transparency = 0.2}, 0.3)
    end)
    ac_box.FocusLost:Connect(function()
        tween(ac_searchStroke, {Color = C.divider, Transparency = 0.5}, 0.3)
    end)

    --  Side selector 
    createSection(animCopyPage, "Mirror Side", 3)

    local ac_sideRow = Instance.new("Frame", animCopyPage)
    ac_sideRow.Size = UDim2.new(1, -8, 0, 38)
    ac_sideRow.BackgroundTransparency = 1
    ac_sideRow.LayoutOrder = 4

    local ac_lftBtn = Instance.new("TextButton", ac_sideRow)
    ac_lftBtn.Size = UDim2.new(0.5, -4, 1, 0)
    ac_lftBtn.Position = UDim2.new(0, 0, 0, 0)
    ac_lftBtn.BackgroundColor3 = C.surface
    ac_lftBtn.TextColor3 = C.text
    ac_lftBtn.Font = Enum.Font.GothamMedium
    ac_lftBtn.TextSize = 12
    ac_lftBtn.Text = "Left"
    ac_lftBtn.BorderSizePixel = 0
    ac_lftBtn.AutoButtonColor = false
    corner(ac_lftBtn, 8)
    local ac_lStroke = stroke(ac_lftBtn, C.divider, 1, 0)

    local ac_rgtBtn = Instance.new("TextButton", ac_sideRow)
    ac_rgtBtn.Size = UDim2.new(0.5, -4, 1, 0)
    ac_rgtBtn.Position = UDim2.new(0.5, 4, 0, 0)
    ac_rgtBtn.BackgroundColor3 = C.accent
    ac_rgtBtn.TextColor3 = C.bg
    ac_rgtBtn.Font = Enum.Font.GothamMedium
    ac_rgtBtn.TextSize = 12
    ac_rgtBtn.Text = "Right"
    ac_rgtBtn.BorderSizePixel = 0
    ac_rgtBtn.AutoButtonColor = false
    corner(ac_rgtBtn, 8)
    local ac_rStroke = stroke(ac_rgtBtn, C.accent, 1, 0)

    local function ac_updateSideBtns()
        if ac_side == "Left" then
            tween(ac_lftBtn, {BackgroundColor3 = C.accent, TextColor3 = C.bg}, 0.15)
            tween(ac_lStroke, {Color = C.accent}, 0.15)
            tween(ac_rgtBtn, {BackgroundColor3 = C.surface, TextColor3 = C.text}, 0.15)
            tween(ac_rStroke, {Color = C.divider}, 0.15)
        else
            tween(ac_rgtBtn, {BackgroundColor3 = C.accent, TextColor3 = C.bg}, 0.15)
            tween(ac_rStroke, {Color = C.accent}, 0.15)
            tween(ac_lftBtn, {BackgroundColor3 = C.surface, TextColor3 = C.text}, 0.15)
            tween(ac_lStroke, {Color = C.divider}, 0.15)
        end
    end

    ac_lftBtn.MouseButton1Click:Connect(function() ac_side = "Left";  ac_updateSideBtns() end)
    ac_rgtBtn.MouseButton1Click:Connect(function() ac_side = "Right"; ac_updateSideBtns() end)

    --  Player list 
    createSection(animCopyPage, "Select Player", 8)

    local ac_listFrame = Instance.new("Frame", animCopyPage)
    ac_listFrame.Size = UDim2.new(1, -8, 0, 0)
    ac_listFrame.BackgroundTransparency = 1
    ac_listFrame.BorderSizePixel = 0
    ac_listFrame.AutomaticSize = Enum.AutomaticSize.Y
    ac_listFrame.LayoutOrder = 9

    local ac_listLayout = Instance.new("UIListLayout", ac_listFrame)
    ac_listLayout.Padding = UDim.new(0, 4)
    ac_listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local ac_rowRefs = {}

    local function ac_buildList()
        for _, c in ipairs(ac_listFrame:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        ac_rowRefs = {}
        local filter = ac_box.Text:lower()
        local allPlayers = Players:GetPlayers()

        if #allPlayers <= 1 then
            local emptyLbl = Instance.new("TextLabel", ac_listFrame)
            emptyLbl.Size = UDim2.new(1, -4, 0, 40)
            emptyLbl.BackgroundColor3 = C.surface
            emptyLbl.BorderSizePixel = 0
            emptyLbl.TextColor3 = C.textMuted
            emptyLbl.Font = Enum.Font.Gotham
            emptyLbl.TextSize = 11
            emptyLbl.Text = "No other players in server"
            emptyLbl.BackgroundTransparency = 0
            corner(emptyLbl, 8)
            return
        end

        for _, plr in ipairs(allPlayers) do
            if plr ~= lp then
                local dn = plr.DisplayName:lower()
                local un = plr.Name:lower()
                if filter == "" or dn:find(filter, 1, true) or un:find(filter, 1, true) then
                    local isSel = (ac_target == plr)

                    local row = Instance.new("Frame", ac_listFrame)
                    row.Size = UDim2.new(1, -4, 0, 42)
                    row.BackgroundColor3 = isSel and C.accent or C.surface
                    row.BorderSizePixel = 0
                    row.ZIndex = 3
                    corner(row, 6)
                    local rowStroke = stroke(row, isSel and C.accent or C.surfaceHover, 1, 0)

                    local thumb = Instance.new("ImageLabel", row)
                    thumb.Size = UDim2.new(0, 32, 0, 32)
                    thumb.Position = UDim2.new(0, 5, 0.5, -16)
                    thumb.BackgroundColor3 = C.bgCard
                    thumb.BorderSizePixel = 0
                    thumb.ZIndex = 4
                    pcall(function()
                        thumb.Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=420&h=420"
                    end)
                    corner(thumb, 6)

                    local nameLbl = Instance.new("TextLabel", row)
                    nameLbl.Size = UDim2.new(1, -50, 0, 16)
                    nameLbl.Position = UDim2.new(0, 44, 0, 7)
                    nameLbl.Text = plr.DisplayName
                    nameLbl.Font = Enum.Font.GothamBold
                    nameLbl.TextSize = 12
                    nameLbl.TextColor3 = isSel and C.bg or C.white
                    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.ZIndex = 4

                    local userLbl = Instance.new("TextLabel", row)
                    userLbl.Size = UDim2.new(1, -50, 0, 13)
                    userLbl.Position = UDim2.new(0, 44, 0, 24)
                    userLbl.Text = "@" .. plr.Name
                    userLbl.Font = Enum.Font.Gotham
                    userLbl.TextSize = 10
                    userLbl.TextColor3 = isSel and C.bg or C.textMuted
                    userLbl.TextXAlignment = Enum.TextXAlignment.Left
                    userLbl.BackgroundTransparency = 1
                    userLbl.ZIndex = 4

                    local selBtn = Instance.new("TextButton", row)
                    selBtn.Size = UDim2.new(1, 0, 1, 0)
                    selBtn.BackgroundTransparency = 1
                    selBtn.Text = ""
                    selBtn.ZIndex = 8
                    selBtn.AutoButtonColor = false

                    local pr = plr
                    selBtn.MouseEnter:Connect(function()
                        if ac_target ~= pr then
                            tween(row, {BackgroundColor3 = C.surfaceHover}, 0.1)
                        end
                    end)
                    selBtn.MouseLeave:Connect(function()
                        if ac_target ~= pr then
                            tween(row, {BackgroundColor3 = C.surface}, 0.1)
                        end
                    end)
                    selBtn.MouseButton1Click:Connect(function()
                        playClick()
                        ac_target = (ac_target == pr) and nil or pr
                        SendNotification("Anim Copy", ac_target and ("Selected: " .. pr.DisplayName) or "Deselected", 2)
                        ac_buildList()
                    end)

                    ac_rowRefs[#ac_rowRefs + 1] = row
                end
            end
        end
    end

    ac_buildList()
    ac_box:GetPropertyChangedSignal("Text"):Connect(ac_buildList)

    --  Action buttons 
    createSection(animCopyPage, "Actions", 5)

    -- Activate/Stop button
    local ac_actFrame = Instance.new("Frame", animCopyPage)
    ac_actFrame.Size = UDim2.new(1, -8, 0, 44)
    ac_actFrame.BackgroundColor3 = C.surface
    ac_actFrame.BorderSizePixel = 0
    ac_actFrame.LayoutOrder = 6
    corner(ac_actFrame, 10)

    local ac_actBtn = Instance.new("TextButton", ac_actFrame)
    ac_actBtn.Size = UDim2.new(1, 0, 1, 0)
    ac_actBtn.BackgroundTransparency = 1
    ac_actBtn.Font = Enum.Font.GothamBold
    ac_actBtn.TextSize = 13
    ac_actBtn.Text = "  Activate Copy"
    ac_actBtn.TextColor3 = C.text
    ac_actBtn.BorderSizePixel = 0
    ac_actBtn.AutoButtonColor = false
    ac_actBtn.ZIndex = 5

    ac_actFrame.MouseEnter:Connect(function()
        if not ac_active then tween(ac_actFrame, {BackgroundColor3 = C.surfaceHover}, 0.2) end
    end)
    ac_actFrame.MouseLeave:Connect(function()
        if not ac_active then tween(ac_actFrame, {BackgroundColor3 = C.surface}, 0.2) end
    end)

    -- Refresh list button
    local ac_refFrame = Instance.new("Frame", animCopyPage)
    ac_refFrame.Size = UDim2.new(1, -8, 0, 44)
    ac_refFrame.BackgroundColor3 = C.surface
    ac_refFrame.BorderSizePixel = 0
    ac_refFrame.LayoutOrder = 7
    corner(ac_refFrame, 10)

    local ac_refBtn = Instance.new("TextButton", ac_refFrame)
    ac_refBtn.Size = UDim2.new(1, 0, 1, 0)
    ac_refBtn.BackgroundTransparency = 1
    ac_refBtn.Font = Enum.Font.GothamMedium
    ac_refBtn.TextSize = 12
    ac_refBtn.Text = "  Refresh Player List"
    ac_refBtn.TextColor3 = C.text
    ac_refBtn.BorderSizePixel = 0
    ac_refBtn.AutoButtonColor = false
    ac_refBtn.ZIndex = 5

    ac_refFrame.MouseEnter:Connect(function()
        tween(ac_refFrame, {BackgroundColor3 = C.surfaceHover}, 0.2)
    end)
    ac_refFrame.MouseLeave:Connect(function()
        tween(ac_refFrame, {BackgroundColor3 = C.surface}, 0.2)
    end)

    ac_refBtn.MouseButton1Click:Connect(function()
        playClick()
        ac_refBtn.Text = "  Refreshing..."
        tween(ac_refBtn, {TextColor3 = C.textMuted}, 0.1)
        ac_buildList()
        task.delay(0.4, function()
            ac_refBtn.Text = "  Refresh Player List"
            tween(ac_refBtn, {TextColor3 = C.text}, 0.2)
        end)
    end)

    --  Stop / cleanup helper 
    local ac_repId = 0
    local function ac_stopCopy()
        ac_repId = ac_repId + 1
        if ac_conn then ac_conn:Disconnect(); ac_conn = nil end
        pcall(function()
            local mc = lp.Character; if not mc then return end
            local mHRP = mc:FindFirstChild("HumanoidRootPart")
            if mHRP then
                pcall(function() sethiddenproperty(mHRP, "PhysicsRepRootPart", nil) end)
            end
            local mHum = mc:FindFirstChildOfClass("Humanoid")
            local mAnim = mHum and mHum:FindFirstChildOfClass("Animator")
            if mAnim then
                for _, tr in ipairs(mAnim:GetPlayingAnimationTracks()) do tr:Stop(0) end
            end
            if mHum then mHum.AutoRotate = true end
            local animScript = mc:FindFirstChild("Animate")
            if animScript then animScript.Disabled = false end
        end)
    end

    --  Activate button logic 
    ac_actBtn.MouseButton1Click:Connect(function()
        playClick()
        if not ac_target then
            SendNotification("Anim Copy", "Select a player first!", 2)
            return
        end
        ac_active = not ac_active
        if ac_active then
            tween(ac_actFrame, {BackgroundColor3 = Color3.fromRGB(45, 180, 80)}, 0.2)
            tween(ac_actBtn, {TextColor3 = C.white}, 0.2)
            ac_actBtn.Text = "  Stop Copy"
            SendNotification("Anim Copy", "Copying " .. (ac_target and ac_target.DisplayName or "?"), 2)
            
            ac_repId = ac_repId + 1
            local currentRepId = ac_repId
            
            -- Anti-delay weld thread (PhysicsRepRootPart)
            task.spawn(function()
                local tChar = ac_target and ac_target.Character
                local tHRP = tChar and tChar:FindFirstChild("HumanoidRootPart")
                local mc = lp.Character
                local mHRP = mc and mc:FindFirstChild("HumanoidRootPart")
                local mHum = mc and mc:FindFirstChildOfClass("Humanoid")
                local animScript = mc and mc:FindFirstChild("Animate")
                
                if mHum then mHum.AutoRotate = false end
                if animScript then animScript.Disabled = true end

                while ac_active and currentRepId == ac_repId do
                    if tHRP and mHRP then
                        pcall(function() sethiddenproperty(mHRP, "PhysicsRepRootPart", tHRP) end)
                    end
                    task.wait()
                end
            end)
            
            ac_conn = RunService.RenderStepped:Connect(function()
                if not ac_active then ac_stopCopy(); return end
                local tChar = ac_target and ac_target.Character
                if not tChar then return end
                local mc = lp.Character
                if not mc then return end
                local tHRP = tChar:FindFirstChild("HumanoidRootPart")
                local mHRP = mc:FindFirstChild("HumanoidRootPart")
                if tHRP and mHRP then
                    mHRP.CFrame = tHRP.CFrame * ac_OFFSET[ac_side]
                    mHRP.AssemblyLinearVelocity = tHRP.AssemblyLinearVelocity
                end
                local tHum  = tChar:FindFirstChildOfClass("Humanoid")
                local tAnim = tHum and tHum:FindFirstChildOfClass("Animator")
                local mHum  = mc:FindFirstChildOfClass("Humanoid")
                local mAnim = mHum and mHum:FindFirstChildOfClass("Animator")
                if tAnim and mAnim then
                    local playing = {}
                    for _, tr in ipairs(tAnim:GetPlayingAnimationTracks()) do
                        playing[tr.Animation.AnimationId] = tr
                    end
                    for _, tr in ipairs(mAnim:GetPlayingAnimationTracks()) do
                        if not playing[tr.Animation.AnimationId] then tr:Stop(0) end
                    end
                    for id, tr in pairs(playing) do
                        local found = false
                        for _, my in ipairs(mAnim:GetPlayingAnimationTracks()) do
                            if my.Animation.AnimationId == id then
                                found = true
                                pcall(function()
                                    if my.Speed ~= tr.Speed then my:AdjustSpeed(tr.Speed) end
                                    -- Sync TimePosition to fix animation delay/lag
                                    if math.abs(my.TimePosition - tr.TimePosition) > 0.1 then
                                        my.TimePosition = tr.TimePosition
                                    end
                                end)
                                break
                            end
                        end
                        if not found then
                            pcall(function()
                                local a = Instance.new("Animation")
                                a.AnimationId = id
                                local t = mAnim:LoadAnimation(a)
                                t:Play(0)
                                t:AdjustSpeed(tr.Speed)
                                t.TimePosition = tr.TimePosition
                            end)
                        end
                    end
                end
            end)
        else
            ac_active = false
            ac_stopCopy()
            tween(ac_actFrame, {BackgroundColor3 = C.surface}, 0.2)
            tween(ac_actBtn, {TextColor3 = C.text}, 0.2)
            ac_actBtn.Text = "  Activate Copy"
            SendNotification("Anim Copy", "Stopped copying", 2)
        end
    end)

    --  Player add/remove hooks 
    Players.PlayerAdded:Connect(function()
        if sidebarPages["animcopy"] and sidebarPages["animcopy"].Visible then
            ac_buildList()
        end
    end)

    Players.PlayerRemoving:Connect(function(p)
        if ac_target == p then
            ac_target = nil
            if ac_active then
                ac_active = false
                ac_stopCopy()
                tween(ac_actFrame, {BackgroundColor3 = C.surface}, 0.2)
                tween(ac_actBtn, {TextColor3 = C.text}, 0.2)
                ac_actBtn.Text = "  Activate Copy"
                SendNotification("Anim Copy", "Target left the game", 2)
            end
        end
        if sidebarPages["animcopy"] and sidebarPages["animcopy"].Visible then
            ac_buildList()
        end
    end)
end) -- AnimCopy Page

-- 
-- PAGE: BIG BASEPLATE
-- 
task.spawn(function()
    local bbPage = createPage("bigbaseplate")


    createSection(bbPage, "Big Baseplate", 1)

    createToggle(bbPage, "Enable Big Baseplate", "Generate infinite 20002000 baseplates around you", "BigBaseplateActive", 2, function(on)
        if not on then
            pcall(function()
                local folder = Workspace:FindFirstChild("ZenBigBaseplates")
                if folder then folder:Destroy() end
            end)
            _bigBPGrid = {}
        end
    end)

    createSection(bbPage, "Baseplate Color", 3)

    -- Color palette (inline themed grid)
    local bbColors = {
        {name = "Slate Grey",      color = Color3.fromRGB(128, 128, 128)},
        {name = "Forest Green",    color = Color3.fromRGB(34, 139, 34)},
        {name = "Royal Blue",      color = Color3.fromRGB(65, 105, 225)},
        {name = "Crimson Red",     color = Color3.fromRGB(220, 20, 60)},
        {name = "Golden Yellow",   color = Color3.fromRGB(255, 215, 0)},
        {name = "Deep Purple",     color = Color3.fromRGB(128, 0, 128)},
        {name = "Sunset Orange",   color = Color3.fromRGB(255, 94, 77)},
        {name = "Emerald Green",   color = Color3.fromRGB(80, 200, 120)},
        {name = "Electric Purple", color = Color3.fromRGB(191, 0, 255)},
        {name = "Aqua Blue",       color = Color3.fromRGB(0, 255, 255)},
    }

    -- Container frame for the color grid
do
    local bbGridFrame = Instance.new("Frame", bbPage)
    bbGridFrame.Size = UDim2.new(1, -8, 0, 160)
    bbGridFrame.BackgroundColor3 = C.surface
    bbGridFrame.BorderSizePixel = 0
    bbGridFrame.LayoutOrder = 4
    corner(bbGridFrame, 10)

    local bbGridLayout = Instance.new("UIGridLayout", bbGridFrame)
    bbGridLayout.CellSize = UDim2.new(0.2, -8, 0, 68)
    bbGridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
    bbGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bbGridLayout.FillDirection = Enum.FillDirection.Horizontal
    bbGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    padding(bbGridFrame, 8, 8, 8, 8)

    local bbSelectedIndicators = {}

    for i, cInfo in ipairs(bbColors) do
        local cell = Instance.new("Frame", bbGridFrame)
        cell.Name = cInfo.name
        cell.BackgroundColor3 = C.surfaceHover
        cell.BorderSizePixel = 0
        cell.LayoutOrder = i
        corner(cell, 8)

        -- Color swatch (top portion)
        local swatch = Instance.new("Frame", cell)
        swatch.Size = UDim2.new(1, -8, 0, 32)
        swatch.Position = UDim2.new(0, 4, 0, 4)
        swatch.BackgroundColor3 = cInfo.color
        swatch.BorderSizePixel = 0
        corner(swatch, 6)

        -- Selection ring
        local ring = Instance.new("UIStroke", swatch)
        ring.Thickness = 2
        ring.Color = C.accent
        ring.Transparency = (cInfo.color == _bigBPSelectedColor) and 0 or 1
        bbSelectedIndicators[i] = ring

        -- Label (bottom)
        local lbl = Instance.new("TextLabel", cell)
        lbl.Size = UDim2.new(1, -4, 0, 18)
        lbl.Position = UDim2.new(0, 2, 1, -22)
        lbl.BackgroundTransparency = 1
        lbl.Text = cInfo.name
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 9
        lbl.TextColor3 = C.text
        lbl.TextTruncate = Enum.TextTruncate.AtEnd

        -- Click button
        local btn = Instance.new("TextButton", cell)
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = 5

        btn.MouseEnter:Connect(function()
            tween(cell, {BackgroundColor3 = C.input}, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            tween(cell, {BackgroundColor3 = C.surfaceHover}, 0.15)
        end)

        btn.MouseButton1Click:Connect(function()
            playClick()
            _bigBPSelectedColor = cInfo.color
            -- Update selection rings
            for j, r in ipairs(bbSelectedIndicators) do
                tween(r, {Transparency = (j == i) and 0 or 1}, 0.2)
            end
            -- Instantly update all existing tiles
            pcall(function()
                local folder = Workspace:FindFirstChild("ZenBigBaseplates")
                if folder then
                    for _, tile in ipairs(folder:GetChildren()) do
                        if tile:IsA("BasePart") then
                            tile.Color = _bigBPSelectedColor
                        end
                    end
                end
            end)
            SendNotification("Big Baseplate", cInfo.name .. " selected", 2)
            task.spawn(saveSettings)
        end)
    end
end

    -- Status label showing current color
    local bbStatusFrame = Instance.new("Frame", bbPage)
    bbStatusFrame.Size = UDim2.new(1, -8, 0, 36)
    bbStatusFrame.BackgroundColor3 = C.surface
    bbStatusFrame.BorderSizePixel = 0
    bbStatusFrame.LayoutOrder = 5
    corner(bbStatusFrame, 10)

    local bbStatusLbl = Instance.new("TextLabel", bbStatusFrame)
    bbStatusLbl.Size = UDim2.new(1, -20, 1, 0)
    bbStatusLbl.Position = UDim2.new(0, 10, 0, 0)
    bbStatusLbl.BackgroundTransparency = 1
    bbStatusLbl.Text = "Current: Slate Grey    Tile Size: 20002000    Transparency: 50%"
    bbStatusLbl.Font = Enum.Font.Gotham
    bbStatusLbl.TextSize = 10
    bbStatusLbl.TextColor3 = C.textMuted
    bbStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
end)

-- 
-- PAGE: HIDE USER
-- 
local hideUserPage = createPage("hideuser")

createSection(hideUserPage, "Hide Players (Client-Side & Mute VC)", 1)

local hide_searchBox = createInputField(hideUserPage, "SEARCH PLAYERS", "Search by name...", "", 2)
local hide_searchIcon = Instance.new("ImageLabel", hide_searchBox.Parent)
hide_searchIcon.Size = UDim2.new(0, 12, 0, 12)
hide_searchIcon.Position = UDim2.new(0, 20, 0, 33)
hide_searchIcon.BackgroundTransparency = 1
do
    local success_hide, result_hide = pcall(function() return getasset("eternity_assets/audios/search.png") end)
    if success_hide and result_hide then
        hide_searchIcon.Image = result_hide
    end
end
hide_searchIcon.ImageColor3 = C.textMuted
hide_searchIcon.ZIndex = 2
if hide_searchBox:FindFirstChildOfClass("UIPadding") then 
    hide_searchBox:FindFirstChildOfClass("UIPadding").PaddingLeft = UDim.new(0, 24) 
end

local hide_listFrame = Instance.new("Frame", hideUserPage)
hide_listFrame.Size = UDim2.new(1, -8, 0, 0)
hide_listFrame.BackgroundTransparency = 1
hide_listFrame.BorderSizePixel = 0
hide_listFrame.AutomaticSize = Enum.AutomaticSize.Y
hide_listFrame.LayoutOrder = 3

do
    local hide_listLayout = Instance.new("UIListLayout", hide_listFrame)
    hide_listLayout.Padding = UDim.new(0, 4)
    hide_listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
end

local function hide_buildList()
    for _, c in ipairs(hide_listFrame:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    local filter = hide_searchBox.Text:lower()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then
            local dn = plr.DisplayName:lower()
            local un = plr.Name:lower()
            if filter == "" or dn:find(filter, 1, true) or un:find(filter, 1, true) then
                local isHidden = FeatureStates.HiddenPlayers[plr.UserId]
                
                local row = Instance.new("Frame", hide_listFrame)
                row.Size = UDim2.new(1, -4, 0, 42)
                row.BackgroundColor3 = isHidden and C.accent or C.surface
                row.BackgroundTransparency = isHidden and 0 or 0
                row.BorderSizePixel = 0
                row.ZIndex = 3
                corner(row, 6)
                local rowStroke = stroke(row, isHidden and C.accent or C.surfaceHover, 1, 0)
                
                local thumb = Instance.new("ImageLabel", row)
                thumb.Size = UDim2.new(0, 34, 0, 34)
                thumb.Position = UDim2.new(0, 4, 0.5, -17)
                thumb.BackgroundColor3 = C.bgCard
                thumb.BorderSizePixel = 0
                thumb.ZIndex = 4
                thumb.Image = "rbxthumb://type=AvatarHeadShot&id="..plr.UserId.."&w=420&h=420"
                corner(thumb, 5)

                local dnLbl = Instance.new("TextLabel", row)
                dnLbl.Text = plr.DisplayName
                dnLbl.Size = UDim2.new(1, -46, 0, 16)
                dnLbl.Position = UDim2.new(0, 42, 0, 6)
                dnLbl.BackgroundTransparency = 1
                dnLbl.TextColor3 = isHidden and Color3.new(0,0,0) or C.text
                dnLbl.TextXAlignment = Enum.TextXAlignment.Left
                dnLbl.Font = Enum.Font.GothamBold
                dnLbl.TextSize = 13
                dnLbl.ZIndex = 4

                local unLbl = Instance.new("TextLabel", row)
                unLbl.Text = "@"..plr.Name
                unLbl.Size = UDim2.new(1, -46, 0, 14)
                unLbl.Position = UDim2.new(0, 42, 0, 22)
                unLbl.BackgroundTransparency = 1
                unLbl.TextColor3 = isHidden and Color3.fromRGB(50,50,50) or C.textMuted
                unLbl.TextXAlignment = Enum.TextXAlignment.Left
                unLbl.Font = Enum.Font.Gotham
                unLbl.TextSize = 11
                unLbl.ZIndex = 4
                
                local checkIcon = Instance.new("TextButton", row)
                checkIcon.Size = UDim2.new(0, 16, 0, 16)
                checkIcon.Position = UDim2.new(1, -26, 0.5, -8)
                checkIcon.BackgroundTransparency = 1
                checkIcon.Text = isHidden and "" or ""
                checkIcon.TextColor3 = isHidden and Color3.new(0,0,0) or C.textMuted
                checkIcon.TextSize = 18
                checkIcon.Font = Enum.Font.GothamBold
                checkIcon.ZIndex = 10
                checkIcon.Active = true

                local btn = Instance.new("TextButton", row)
                btn.Size = UDim2.new(1, 0, 1, 0)
                btn.BackgroundTransparency = 1
                btn.Text = ""
                btn.ZIndex = 5
                btn.Active = true
                
                local function toggleHide()
                    pcall(clickSound)
                    local newState = not FeatureStates.HiddenPlayers[plr.UserId]
                    FeatureStates.HiddenPlayers[plr.UserId] = newState or nil
                    
                    hide_buildList()
                    
                    if newState then
                        SendNotification("Eternity", "Hidden " .. plr.DisplayName .. " locally (Muted VC).", 2)
                    else
                        SendNotification("Eternity", "Unhidden " .. plr.DisplayName .. ".", 2)
                    end
                end

                btn.MouseButton1Click:Connect(toggleHide)
                checkIcon.MouseButton1Click:Connect(toggleHide)

                btn.MouseEnter:Connect(function()
                    if not isHidden then
                        tween(row, {BackgroundColor3 = C.surfaceHover}, 0.2)
                    end
                end)
                btn.MouseLeave:Connect(function()
                    if not isHidden then
                        tween(row, {BackgroundColor3 = C.surface}, 0.2)
                    end
                end)
            end
        end
    end
end

Players.PlayerAdded:Connect(function() task.defer(hide_buildList) end)
Players.PlayerRemoving:Connect(function(plr)
    FeatureStates.HiddenPlayers[plr.UserId] = nil
    task.defer(hide_buildList) 
end)
hide_searchBox:GetPropertyChangedSignal("Text"):Connect(hide_buildList)

hide_buildList()

-- Moves characters to Lighting and teleports them away to completely disable visual rendering, physics, and spatial VC
RunService.Heartbeat:Connect(function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then
            if FeatureStates.HiddenPlayers[plr.UserId] then
                if plr.Character then
                    if plr.Character:IsDescendantOf(workspace) then
                        pcall(function() plr.Character.Parent = game.Lighting end)
                    end
                    local primary = plr.Character.PrimaryPart or plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Head")
                    if primary then
                        pcall(function() primary.CFrame = CFrame.new(0, 999999, 0) end)
                    end
                end
            else
                if plr.Character and plr.Character.Parent == game.Lighting then
                    pcall(function() plr.Character.Parent = workspace end)
                end
            end
        end
    end
end)


-- 
-- PAGE: SETTINGS
-- 
local settingsPage = createPage("settings")

createSection(settingsPage, "General", 0)
local genGrid = createGridContainer(settingsPage, 1)
createToggle(genGrid, "Easy Target", "Right click players to open quick actions menu", "ContextMenu", 1, function(v) end)
createSection(settingsPage, "Theme Settings", 2)

local themeColors = {
    {name = "Eternity Gold", color = Color3.fromRGB(245, 190, 75)},
    {name = "Crimson Red",   color = Color3.fromRGB(220, 20, 60)},
    {name = "Royal Blue",    color = Color3.fromRGB(65, 105, 225)},
    {name = "Forest Green",  color = Color3.fromRGB(34, 139, 34)},
    {name = "Deep Purple",   color = Color3.fromRGB(128, 0, 128)},
    {name = "Hot Pink",      color = Color3.fromRGB(255, 105, 180)},
    {name = "Sunset Orange", color = Color3.fromRGB(255, 94, 77)},
    {name = "Ice Blue",      color = Color3.fromRGB(135, 206, 250)},
    {name = "Lime Green",    color = Color3.fromRGB(50, 205, 50)},
    {name = "Ghost White",   color = Color3.fromRGB(240, 240, 255)},
}

local function applyThemeToUI(newColor)
    local oldAccent = C.accent
    local oldDim = C.accentDim

    C.accent = newColor
    C.accentGlow = newColor
    C.toggleOn = newColor
    C.sidebarActive = newColor
    C.accentDim = Color3.new(newColor.R * 0.75, newColor.G * 0.75, newColor.B * 0.75)
    local oldRgb1 = getRGBString(oldAccent)
    local oldRgb2 = math.floor(oldAccent.R*255+0.5)..", "..math.floor(oldAccent.G*255+0.5)..", "..math.floor(oldAccent.B*255+0.5)
    local newRgb = getRGBString(newColor)

    for _, obj in ipairs(sg:GetDescendants()) do
        pcall(function()
            if obj.Name == "ThemeGridFrame" or obj:FindFirstAncestor("ThemeGridFrame") then return end
            if obj:IsA("GuiObject") then
                if obj.BackgroundColor3 == oldAccent then
                    obj.BackgroundColor3 = C.accent
                elseif obj.BackgroundColor3 == oldDim then
                    obj.BackgroundColor3 = C.accentDim
                end
                
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    if obj.TextColor3 == oldAccent then
                        obj.TextColor3 = C.accent
                    elseif obj.TextColor3 == oldDim then
                        obj.TextColor3 = C.accentDim
                    end
                    
                    if obj.RichText and obj.Text then
                        if string.find(obj.Text, oldRgb1) or string.find(obj.Text, oldRgb2) then
                            local t = string.gsub(obj.Text, oldRgb1, newRgb)
                            t = string.gsub(t, oldRgb2, newRgb)
                            obj.Text = t
                        end
                    end
                end
                
                if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                    if obj.ImageColor3 == oldAccent then
                        obj.ImageColor3 = C.accent
                    elseif obj.ImageColor3 == oldDim then
                        obj.ImageColor3 = C.accentDim
                    end
                end
                
                if obj:IsA("ScrollingFrame") then
                    if obj.ScrollBarImageColor3 == oldAccent then
                        obj.ScrollBarImageColor3 = C.accent
                    elseif obj.ScrollBarImageColor3 == oldDim then
                        obj.ScrollBarImageColor3 = C.accentDim
                    end
                end
            elseif obj:IsA("UIStroke") then
                if obj.Color == oldAccent then
                    obj.Color = C.accent
                elseif obj.Color == oldDim then
                    obj.Color = C.accentDim
                end
            end
        end)
    end
    
    -- Update overhead tags
    pcall(function()
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Head") then
                local bg = p.Character.Head:FindFirstChild("EternityOverhead")
                if bg then
                    local card = bg:FindFirstChildOfClass("Frame")
                    if card then
                        local stroke = card:FindFirstChildOfClass("UIStroke")
                        if stroke then stroke.Color = C.accent end
                    end
                end
            end
        end
    end)
end

do
    local hintCard = Instance.new("Frame", settingsPage)
    hintCard.Size = UDim2.new(1, -8, 0, 64)
    hintCard.BackgroundColor3 = C.surface
    hintCard.BorderSizePixel = 0
    hintCard.LayoutOrder = 3
    corner(hintCard, 10)

    local cl = Instance.new("UIListLayout", hintCard)
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    cl.Padding = UDim.new(0, 6)
    cl.VerticalAlignment = Enum.VerticalAlignment.Center

    local pad = Instance.new("UIPadding", hintCard)
    pad.PaddingLeft = UDim.new(0, 16)
    pad.PaddingRight = UDim.new(0, 16)

    local titleLbl = Instance.new("TextLabel", hintCard)
    titleLbl.Size = UDim2.new(1, 0, 0, 16)
    titleLbl.Text = "CUSTOM THEME COLOR"
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 10
    titleLbl.TextColor3 = C.textMuted
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.BackgroundTransparency = 1
    titleLbl.LayoutOrder = 0

    local c1 = Instance.new("TextLabel", hintCard)
    c1.Size = UDim2.new(1, 0, 0, 16)
    c1.Text = "Select an accent color for the UI. <font color='rgb(" .. accentRgbStr .. ")'><b>Changes apply instantly and are saved for next time.</b></font>"
    c1.RichText = true
    c1.Font = Enum.Font.Gotham
    c1.TextSize = 12
    c1.TextColor3 = C.text
    c1.TextXAlignment = Enum.TextXAlignment.Left
    c1.BackgroundTransparency = 1
    c1.LayoutOrder = 1
    
    applyPremiumCardEffect(hintCard)
end

local themeGridFrame = Instance.new("Frame", settingsPage)
themeGridFrame.Name = "ThemeGridFrame"
themeGridFrame.Size = UDim2.new(1, -8, 0, 0)
themeGridFrame.AutomaticSize = Enum.AutomaticSize.Y
themeGridFrame.BackgroundTransparency = 1
themeGridFrame.LayoutOrder = 4

local uigrid = Instance.new("UIGridLayout", themeGridFrame)
uigrid.CellSize = UDim2.new(0.2, -8, 0, 68)
uigrid.CellPadding = UDim2.new(0, 6, 0, 6)
uigrid.SortOrder = Enum.SortOrder.LayoutOrder
uigrid.FillDirection = Enum.FillDirection.Horizontal
uigrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
padding(themeGridFrame, 8, 8, 8, 8)

for i, tcolor in ipairs(themeColors) do
    local cell = Instance.new("Frame", themeGridFrame)
    cell.Name = tcolor.name
    cell.BackgroundColor3 = C.surfaceHover
    cell.BorderSizePixel = 0
    cell.LayoutOrder = i
    corner(cell, 8)

    local swatch = Instance.new("Frame", cell)
    swatch.Name = "Swatch"
    swatch.Size = UDim2.new(1, -8, 0, 32)
    swatch.Position = UDim2.new(0, 4, 0, 4)
    swatch.BackgroundColor3 = tcolor.color
    swatch.BorderSizePixel = 0
    corner(swatch, 6)

    local ring = Instance.new("UIStroke", swatch)
    ring.Thickness = 2
    ring.Color = C.accent
    ring.Transparency = (tcolor.color == _themeColor) and 0 or 1

    local lbl = Instance.new("TextLabel", cell)
    lbl.Size = UDim2.new(1, -4, 0, 18)
    lbl.Position = UDim2.new(0, 2, 1, -22)
    lbl.BackgroundTransparency = 1
    lbl.Text = tcolor.name
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.TextColor3 = C.text
    lbl.TextTruncate = Enum.TextTruncate.AtEnd

    local btn = Instance.new("TextButton", cell)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 5

    btn.MouseEnter:Connect(function()
        tween(cell, {BackgroundColor3 = C.input}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tween(cell, {BackgroundColor3 = C.surfaceHover}, 0.15)
    end)

    btn.MouseButton1Click:Connect(function()
        playClick()
        
        for _, otherCell in ipairs(themeGridFrame:GetChildren()) do
            if otherCell:IsA("Frame") and otherCell:FindFirstChild("Swatch") then
                local otherRing = otherCell.Swatch:FindFirstChildOfClass("UIStroke")
                if otherRing then otherRing.Transparency = 1 end
            end
        end
        ring.Transparency = 0
        
        _themeColor = tcolor.color
        applyThemeToUI(tcolor.color)
        saveSettings()
        SendNotification("Eternity", "Theme instantly updated to " .. tcolor.name .. "!", 3)
    end)
end

createSection(settingsPage, "Game Actions", 5)

createActionButton(settingsPage, "Rejoin Current Game", "Disconnects and immediately reconnects you to this exact same server", 6, function()
    local TeleportService = game:GetService("TeleportService")
    SendNotification("Eternity", "Rejoining server...", 3)
    task.wait(0.5)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
end)

-- 
-- SIDEBAR NAVIGATION LOGIC
-- 
local function switchPage(pageId)
    if currentPage == pageId then return end

    -- update sidebar button visuals and title text
    for id, btn in pairs(sidebarButtons) do
        local iconImg = btn:FindFirstChildOfClass("ImageLabel")
        local txt = btn:FindFirstChild("Title")
        local expandedWidth = btn:GetAttribute("ExpandedWidth") or 100
        local collapsedWidth = btn:GetAttribute("CollapsedWidth") or 32

        if id == pageId then
            tween(btn, {BackgroundTransparency = 1, Size = UDim2.new(0, expandedWidth, 1, 0)}, 0.3, Enum.EasingStyle.Quint)
            if txt then 
                tween(txt, {TextColor3 = C.accent, TextTransparency = 0}, 0.3)
            end
            if iconImg then tween(iconImg, {ImageColor3 = C.accent}, 0.2) end
        else
            tween(btn, {BackgroundTransparency = 1, Size = UDim2.new(0, collapsedWidth, 1, 0)}, 0.3, Enum.EasingStyle.Quint)
            if txt then 
                tween(txt, {TextColor3 = C.sidebarIcon, TextTransparency = 1}, 0.3)
            end
            if iconImg then tween(iconImg, {ImageColor3 = C.sidebarIcon}, 0.2) end
        end
    end
    
    for _, data in ipairs(sidebarIcons) do
        if data.id == pageId then
            titleText.Text = "ETERNITY"
            break
        end
    end

    -- fade out current page
    local currentScroll = sidebarPages[currentPage]
    if currentScroll then
        for _, child in ipairs(currentScroll:GetChildren()) do
            if child:IsA("Frame") then
                local scale = child:FindFirstChildOfClass("UIScale")
                if scale then
                    tween(scale, {Scale = 0.96}, 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                end
            end
        end
        task.delay(0.15, function()
            currentScroll.Visible = false
        end)
    end

    -- fade in new page
    currentPage = pageId
    local newScroll = sidebarPages[pageId]
    if newScroll then
        newScroll.Position = UDim2.new(0, 0, 0, 0)
        newScroll.Visible = true
        
        local delayOffset = 0
        local children = {}
        for _, child in ipairs(newScroll:GetChildren()) do
            if child:IsA("Frame") then
                table.insert(children, child)
            end
        end
        table.sort(children, function(a, b) return a.LayoutOrder < b.LayoutOrder end)

        for _, child in ipairs(children) do
            if child.Visible then
                local scale = child:FindFirstChildOfClass("UIScale")
                if not scale then
                    scale = Instance.new("UIScale", child)
                end
                scale.Scale = 0.94
                task.delay(delayOffset, function()
                    if currentPage == pageId then
                        tween(scale, {Scale = 1}, 0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                    end
                end)
                delayOffset = delayOffset + 0.02
            end
        end
    end
end

for _, data in ipairs(sidebarIcons) do
    sidebarButtons[data.id].MouseButton1Click:Connect(function()
        playClick()
        if isMinimized then
            isMinimized = false
            fpsPingContainer.Visible = false
            if miniTagLabel then miniTagLabel.Visible = false end
            if titleText then titleText.Visible = true end
            if miniTagBtn then miniTagBtn.Visible = false end
            if floatingTopContainer then
                floatingTopContainer.Visible = true
                floatingTopContainer.Position = UDim2.new(floatingTopContainer.Position.X.Scale, floatingTopContainer.Position.X.Offset, 0.25, 10)
                tween(floatingTopContainer, {GroupTransparency = 0, Position = UDim2.new(floatingTopContainer.Position.X.Scale, floatingTopContainer.Position.X.Offset, 0.25, -12)}, 0.3, Enum.EasingStyle.Quint)
            end
            if bottomMask then bottomMask.Visible = true end
            animateDockMinimize(false)
            tween(mainFrame, {Size = preMiniSize, Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 1, -85)}, 0.3, Enum.EasingStyle.Quint)
        end
        switchPage(data.id)
    end)
end

-- 
-- BORDER HUE DRIFT ANIMATION
-- 
task.spawn(function()
    while mainFrame and mainFrame.Parent do
        task.wait(0.02)
        if strokeGradient and strokeGradient.Parent then
            strokeGradient.Rotation = (strokeGradient.Rotation + 2.5) % 360
        end
        if infoCardGradient and infoCardGradient.Parent then
            infoCardGradient.Rotation = (infoCardGradient.Rotation + 2.5) % 360
        end

        if mainAvatarGradient and mainAvatarGradient.Parent then
            mainAvatarGradient.Rotation = (mainAvatarGradient.Rotation + 2.5) % 360
        end
    end
end)

-- 
-- PAT ENGINE (Anti-Delay Weld + Emote)
-- 

patRepId = 0
patHasHiddenProp = pcall(function() return sethiddenproperty end)
patOriginalParts = {}
patSetupChar = nil
patCFrameId = 0
patAnimTrack = nil
patPhysicsRepActive = false

function patClearPhysicsRep()
    if patPhysicsRepActive and rootPart and patHasHiddenProp then
        pcall(function()
            sethiddenproperty(rootPart, "PhysicsRepRootPart", nil)
        end)
        patPhysicsRepActive = false
    end
end

patWasAnimateDisabled = false

function patCleanup()
    patRepId = patRepId + 1
    patCFrameId = patCFrameId + 1
    patClearPhysicsRep()

    if patAnimTrack then
        pcall(function() patAnimTrack:Stop(0) end)
        patAnimTrack = nil
    end

    if patSetupChar then
        local hum = patSetupChar:FindFirstChild("Humanoid")
        if hum then hum.AutoRotate = true end

        -- Re-enable Animate script
        local animScript = patSetupChar:FindFirstChild("Animate")
        if animScript and patWasAnimateDisabled then
            animScript.Disabled = false
            patWasAnimateDisabled = false
        end

        for part, props in pairs(patOriginalParts) do
            if part and part.Parent then
                part.CanCollide = props.CanCollide
                part.Massless = props.Massless
            end
        end
        table.clear(patOriginalParts)
        patSetupChar = nil
    end
end

function patSetup()
    if not character then return end
    if patSetupChar == character then return end
    patCleanup()

    local hum = character:FindFirstChild("Humanoid")
    if not hum then return end
    hum.AutoRotate = false

    -- Find or create Animator
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    -- Disable Animate script so idle/walk/fall don't fight our animation
    local animScript = character:FindFirstChild("Animate")
    if animScript and not animScript.Disabled then
        animScript.Disabled = true
        patWasAnimateDisabled = true
    end

    -- Stop ALL currently playing animations
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        pcall(function() track:Stop(0) end)
    end

    -- Load and play the pat emote
    local success, err = pcall(function()
        local ok, objs = pcall(function() return game:GetObjects("rbxassetid://123663633846435") end)
        local anim = nil
        if ok and objs and objs[1] then
            local root = objs[1]
            if root:IsA("Animation") then
                anim = root
            else
                anim = root:FindFirstChildOfClass("Animation", true)
            end
        end
        if not anim then
            anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://123663633846435"
        end
        patAnimTrack = animator:LoadAnimation(anim)
        patAnimTrack.Priority = Enum.AnimationPriority.Action4
        patAnimTrack.Looped = true
        patAnimTrack:Play(0.1, 1, 2.5)
    end)
    if not success then warn("Pat Emote Load Error:", err) end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            patOriginalParts[part] = {CanCollide = part.CanCollide}
            part.CanCollide = false
        end
    end

    patSetupChar = character
    return true
end

function patComputeCFrame(targetHead)
    local dist = 2.0
    local look = targetHead.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    flat = flat.Magnitude > 0 and flat.Unit or Vector3.new(0, 0, 1)

    local targetRoot = targetHead.Parent and targetHead.Parent:FindFirstChild("HumanoidRootPart")
    local targetY = targetRoot and targetRoot.Position.Y or (targetHead.Position.Y - 1.5)

    local headPos = targetHead.Position
    local myPos = headPos + (flat * dist)
    myPos = Vector3.new(myPos.X, targetY, myPos.Z)

    return CFrame.lookAt(myPos, Vector3.new(headPos.X, myPos.Y, headPos.Z))
end

function patStartPhysicsRep()
    patRepId = patRepId + 1
    local myId = patRepId
    task.spawn(function()
        while task.wait() do
            if myId ~= patRepId then break end
            if not (FeatureStates.Pat and lp.Character == character) then
                patClearPhysicsRep()
                break
            end
            local tp = nil
            if PatTarget and PatTarget.Character and PatTarget.Character:FindFirstChild("HumanoidRootPart") then
                tp = PatTarget.Character.HumanoidRootPart
            end
            if rootPart and tp then
                pcall(function() sethiddenproperty(rootPart, "PhysicsRepRootPart", tp) end)
                patPhysicsRepActive = true
            end
        end
    end)
end

function patStartCFrameFollow()
    patCFrameId = patCFrameId + 1
    local myId = patCFrameId
    task.spawn(function()
        while FeatureStates.Pat and myId == patCFrameId and task.wait() do
            if PatTarget and PatTarget.Character and PatTarget.Character:FindFirstChild("HumanoidRootPart") and rootPart then
                local targetHead = PatTarget.Character:FindFirstChild("Head")
                if targetHead then
                    rootPart.CFrame = patComputeCFrame(targetHead)
                    rootPart.AssemblyLinearVelocity = Vector3.zero
                    rootPart.AssemblyAngularVelocity = Vector3.zero
                    pcall(function() rootPart.Velocity = Vector3.zero end)
                    pcall(function() rootPart.RotVelocity = Vector3.zero end)
                end
            end
        end
    end)
end

function patApplyCFrame()
    if not (FeatureStates.Pat and PatTarget and PatTarget.Character and rootPart) then return false end
    local targetHead = PatTarget.Character:FindFirstChild("Head")
    if not targetHead then return false end

    local cf = patComputeCFrame(targetHead)
    rootPart.CFrame = cf
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    pcall(function() rootPart.Velocity = Vector3.zero end)
    pcall(function() rootPart.RotVelocity = Vector3.zero end)
    return true
end

function patActivate()
    if not patSetup() then return end
    if patHasHiddenProp then
        patStartPhysicsRep()
    end
    patStartCFrameFollow()
end

function patDeactivate()
    patCleanup()
end

-- 
-- FACEBANG ENGINE (zeroDelayWeld  PhysicsRepRootPart)
-- 
-- Uses sethiddenproperty to set PhysicsRepRootPart on the
-- local player's HumanoidRootPart to the target's Head.
-- The server natively reads the target's Head position as
-- our physics root  true zero-delay, no CFrame spam needed.
-- Falls back to CFrame teleport if sethiddenproperty is unavailable.
-- 

fbHasHiddenProp = (typeof(sethiddenproperty) == "function")
facebangSetupChar = nil
fbWasAnimateDisabled = false
fbOriginalParts = {}       -- store original CanCollide/Massless
fbPhysicsRepActive = false -- track if PhysicsRepRootPart is currently set
fbRepThread = nil          -- the zeroDelayWeld rep() loop coroutine id
fbRepId = 0                -- generation counter to kill stale rep loops
fbCFrameThread = nil       -- CFrame follow loop coroutine id
fbCFrameId = 0             -- generation counter for CFrame follow
fbAnimTrack = nil          -- stores active animation track for facebang

--  PhysicsRep cleanup (clear hidden property) 
function fbClearPhysicsRep()
    if fbPhysicsRepActive and rootPart and fbHasHiddenProp then
        pcall(function()
            sethiddenproperty(rootPart, "PhysicsRepRootPart", nil)
        end)
        fbPhysicsRepActive = false
    end
end

--  Full cleanup (called when facebang stops) 
function fbCleanup()
    -- Kill any running rep / CFrame loops by bumping generation ids
    fbRepId = fbRepId + 1
    fbCFrameId = fbCFrameId + 1

    -- Clear PhysicsRepRootPart
    fbClearPhysicsRep()

    if fbAnimTrack then
        pcall(function() fbAnimTrack:Stop() end)
        pcall(function() fbAnimTrack:Destroy() end)
        fbAnimTrack = nil
    end

    if facebangSetupChar then
        local hum = facebangSetupChar:FindFirstChild("Humanoid")
        if hum then
            hum.AutoRotate = true
            pcall(function() hum.PlatformStand = false end)
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
        if fbWasAnimateDisabled then
            local anim = facebangSetupChar:FindFirstChild("Animate")
            if anim then anim.Disabled = false end
            fbWasAnimateDisabled = false
        end
        -- Restore original part properties
        for part, props in pairs(fbOriginalParts) do
            pcall(function()
                part.CanCollide = props.CanCollide
                part.Massless = props.Massless
            end)
        end
        table.clear(fbOriginalParts)
        facebangSetupChar = nil
    end
end

--  Character setup (disable physics interference) 
function fbSetup()
    if not character then return end
    if facebangSetupChar == character then
        -- Already set up for this character, but check if animation is still playing
        if fbAnimTrack and fbAnimTrack.IsPlaying then return true end
        -- Animation stopped/missing  fall through to reload it
        facebangSetupChar = nil
    end
    fbCleanup()

    local hum = character:FindFirstChild("Humanoid")
    if not hum then return end

    -- Disable auto-rotate so Roblox doesn't fight our CFrame
    hum.AutoRotate = false

    -- Find or create Animator
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    -- Disable Animate script to prevent falling/walking animations from playing
    local animScript = character:FindFirstChild("Animate")
    if animScript and not animScript.Disabled then
        animScript.Disabled = true
        fbWasAnimateDisabled = true
    end

    -- Stop all playing animations
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        pcall(function() track:Stop(0) end)
    end

    -- Load and play facebang animation (auto-detects R6 vs R15 and extracts raw ID)
    local animLoaded = false
    local success, err = pcall(function()
        local isR15 = (hum.RigType == Enum.HumanoidRigType.R15)
        local animId = isR15 and 115942593443190 or 148840371
        
        local anim = nil
        if isR15 then
            -- Attempt to retrieve the actual Animation instance from the catalog asset ID
            local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(animId)) end)
            if ok and objs and objs[1] then
                local root = objs[1]
                if root:IsA("Animation") then
                    anim = root
                else
                    anim = root:FindFirstChildOfClass("Animation", true)
                end
            end
        end
        
        -- Fallback if game:GetObjects is not supported or failed
        if not anim then
            anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. tostring(animId)
        end
        
        fbAnimTrack = animator:LoadAnimation(anim)
        fbAnimTrack.Priority = Enum.AnimationPriority.Action
        fbAnimTrack.Looped = true
        fbAnimTrack:Play()
        animLoaded = fbAnimTrack ~= nil
    end)
    if not success then
        warn("Eternity Facebang Emote Load Error:", err)
        return -- Don't mark as set up; Stepped will retry next frame
    end
    if not animLoaded then
        return -- Animation object missing; retry next frame
    end

    -- Make all parts massless + non-collidable for zero physics resistance
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            fbOriginalParts[part] = {CanCollide = part.CanCollide}
            part.CanCollide = false
        end
    end

    facebangSetupChar = character
    return true
end

-- 
-- CFrame computation (oscillating thrust)
-- 
function fbComputeCFrame(targetHead)
    local thrust = (math.sin(tick() * FacebangSpeed * 10) + 1) / 2
    local dist = 0.5 + (thrust * FacebangDistance)

    local look = targetHead.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    flat = flat.Magnitude > 0 and flat.Unit or Vector3.new(0, 0, 1)

    local headPos = targetHead.Position
    local myPos = headPos + (flat * dist)
    myPos = Vector3.new(myPos.X, headPos.Y + 1.2, myPos.Z)

    return CFrame.lookAt(myPos, Vector3.new(headPos.X, myPos.Y, headPos.Z))
end

-- 
-- METHOD A: zeroDelayWeld (PhysicsRepRootPart)
-- The server reads target's Head as our physics position.
-- A CFrame follow loop keeps our client-side character
-- visually positioned at the target's face for the
-- oscillating "bang" animation.
-- 

-- rep()  continuously sets PhysicsRepRootPart to target's Head
function fbStartPhysicsRep()
    fbRepId = fbRepId + 1
    local myId = fbRepId
    task.spawn(function()
        while task.wait() do
            if myId ~= fbRepId then break end -- stale loop, die
            if not (FeatureStates.Facebang and lp.Character == character) then
                -- Facebang turned off or character changed
                fbClearPhysicsRep()
                break
            end
            -- Update target part (target's Head)
            local tp = nil
            if FacebangTarget and FacebangTarget.Character and FacebangTarget.Character:FindFirstChild("Head") then
                tp = FacebangTarget.Character.Head
            end
            if rootPart and tp then
                pcall(function()
                    sethiddenproperty(rootPart, "PhysicsRepRootPart", tp)
                end)
                fbPhysicsRepActive = true
            end
        end
    end)
end

-- CFrame follow loop  moves our character visually to the bang position
function fbStartCFrameFollow()
    fbCFrameId = fbCFrameId + 1
    local myId = fbCFrameId
    task.spawn(function()
        while FeatureStates.Facebang and myId == fbCFrameId and task.wait() do
            if FacebangTarget and FacebangTarget.Character and FacebangTarget.Character:FindFirstChild("HumanoidRootPart") and rootPart then
                local targetHead = FacebangTarget.Character:FindFirstChild("Head")
                if targetHead then
                    rootPart.CFrame = fbComputeCFrame(targetHead)
                    rootPart.AssemblyLinearVelocity = Vector3.zero
                    rootPart.AssemblyAngularVelocity = Vector3.zero
                    pcall(function() rootPart.Velocity = Vector3.zero end)
                    pcall(function() rootPart.RotVelocity = Vector3.zero end)
                end
            end
        end
    end)
end

-- 
-- METHOD B: Legacy CFrame teleport fallback
-- Used when sethiddenproperty is not available.
-- Sets CFrame in Stepped + Heartbeat + RenderStepped.
-- 

function fbApplyCFrame()
    if not (FeatureStates.Facebang and FacebangTarget and FacebangTarget.Character and rootPart) then return false end
    local targetHead = FacebangTarget.Character:FindFirstChild("Head")
    if not targetHead then return false end

    local cf = fbComputeCFrame(targetHead)
    rootPart.CFrame = cf
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    pcall(function() rootPart.Velocity = Vector3.zero end)
    pcall(function() rootPart.RotVelocity = Vector3.zero end)
    return true
end

-- 
-- FACEBANG ACTIVATION / DEACTIVATION
-- 

-- Called when Facebang is turned ON
function fbActivate()
    if not fbSetup() then return end
    if fbHasHiddenProp then
        -- Use zeroDelayWeld (PhysicsRepRootPart)
        fbStartPhysicsRep()
        fbStartCFrameFollow()
    end
    -- If no sethiddenproperty, the Stepped/Heartbeat/RenderStepped
    -- connections below handle CFrame fallback automatically.
end

-- Called when Facebang is turned OFF
function fbDeactivate()
    fbCleanup()
end

-- 
-- HEADSIT IMPLEMENTATION
-- 
hsSetupChar = nil
hsHasHiddenProp = false
hsCollisionGrp = "HeadsitNoclip"
hsConnPhysics = nil
hsConnCFrame = nil
hsOriginalParts = {}

function hsSetup()
    if not (HeadsitTarget and HeadsitTarget.Character and rootPart and humanoid) then return end
    
    local success, _ = pcall(function() return sethiddenproperty end)
    hsHasHiddenProp = (success and typeof(sethiddenproperty) == "function")

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            hsOriginalParts[part] = {CanCollide = part.CanCollide}
            part.CanCollide = false
        end
    end

    humanoid.Sit = true
    
    hsSetupChar = character
    return true
end

function hsCleanup()
    if hsConnPhysics then hsConnPhysics:Disconnect() hsConnPhysics = nil end
    if hsConnCFrame then hsConnCFrame:Disconnect() hsConnCFrame = nil end
    
    if hsHasHiddenProp and rootPart then
        pcall(function() sethiddenproperty(rootPart, "PhysicsRepRootPart", nil) end)
    end
    
    if humanoid then humanoid.Sit = false end
    
    -- Wait a frame so Roblox's getting-up physics don't overwrite our restored CanCollide states
    task.wait()

    if hsSetupChar == character then
        for part, props in pairs(hsOriginalParts) do
            if part and part.Parent then
                part.CanCollide = props.CanCollide
                part.Massless = props.Massless
            end
        end
        table.clear(hsOriginalParts)
    end
    hsSetupChar = nil
end

function hsComputeCFrame(targetHead)
    -- Align to head and shift up slightly (we use 1.5 studs as a general safe offset above head center for sitting)
    return targetHead.CFrame * CFrame.new(0, 1.5, 0)
end

function hsApplyCFrame()
    if not (FeatureStates.Headsit and HeadsitTarget and HeadsitTarget.Character and rootPart) then return false end
    local targetHead = HeadsitTarget.Character:FindFirstChild("Head")
    if not targetHead then return false end

    local cf = hsComputeCFrame(targetHead)
    rootPart.CFrame = cf
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    pcall(function() rootPart.Velocity = Vector3.zero end)
    pcall(function() rootPart.RotVelocity = Vector3.zero end)
    return true
end

function hsStartPhysicsRep()
    hsConnPhysics = RunService.Stepped:Connect(function()
        if FeatureStates.Headsit and HeadsitTarget and HeadsitTarget.Character and rootPart then
            local targetHead = HeadsitTarget.Character:FindFirstChild("Head")
            if targetHead then
                pcall(function()
                    sethiddenproperty(rootPart, "PhysicsRepRootPart", targetHead)
                end)
            end
        end
    end)
end

function hsStartCFrameFollow()
    hsConnCFrame = RunService.Heartbeat:Connect(function()
        hsApplyCFrame()
    end)
end

function hsActivate()
    if not hsSetup() then return end
    if hsHasHiddenProp then
        hsStartPhysicsRep()
    end
    hsStartCFrameFollow()
end

function hsDeactivate()
    hsCleanup()
end

-- 
-- BACK HUG IMPLEMENTATION
-- 
bhSetupChar = nil
bhHasHiddenProp = false
bhConnPhysics = nil
bhConnCFrame = nil
bhWasAnimateDisabled = false
bhAnimTrack = nil
bhOriginalParts = {}

function bhSetup()
    if not character then return end
    if bhSetupChar == character then return end
    bhCleanup()

    local hum = character:FindFirstChild("Humanoid")
    if not hum then return end
    hum.AutoRotate = false

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    local animScript = character:FindFirstChild("Animate")
    if animScript and not animScript.Disabled then
        animScript.Disabled = true
        bhWasAnimateDisabled = true
    end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        pcall(function() track:Stop(0) end)
    end

    local success, err = pcall(function()
        local ok, objs = pcall(function() return game:GetObjects("rbxassetid://117991975031893") end)
        local anim = nil
        if ok and objs and objs[1] then
            local root = objs[1]
            if root:IsA("Animation") then
                anim = root
            else
                anim = root:FindFirstChildOfClass("Animation", true)
            end
        end
        if not anim then
            anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://117991975031893"
        end
        bhAnimTrack = animator:LoadAnimation(anim)
        bhAnimTrack.Priority = Enum.AnimationPriority.Action4
        bhAnimTrack.Looped = true
        bhAnimTrack:Play(0.1, 1, 1.0)
    end)
    if not success then warn("Backhug Emote Load Error:", err) end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            bhOriginalParts[part] = {CanCollide = part.CanCollide}
            part.CanCollide = false
        end
    end

    local successHidden, _ = pcall(function() return sethiddenproperty end)
    bhHasHiddenProp = (successHidden and typeof(sethiddenproperty) == "function")

    bhSetupChar = character
    return true
end

function bhCleanup()
    if bhConnPhysics then bhConnPhysics:Disconnect() bhConnPhysics = nil end
    if bhConnCFrame then bhConnCFrame:Disconnect() bhConnCFrame = nil end
    
    if bhHasHiddenProp and rootPart then
        pcall(function() sethiddenproperty(rootPart, "PhysicsRepRootPart", nil) end)
    end
    
    if bhAnimTrack then
        pcall(function() bhAnimTrack:Stop() end)
        bhAnimTrack = nil
    end

    for part, props in pairs(bhOriginalParts) do
        if part and part.Parent then
            part.CanCollide = props.CanCollide
            part.Massless = props.Massless
        end
    end
    table.clear(bhOriginalParts)

    if character then
        local hum = character:FindFirstChild("Humanoid")
        if hum then hum.AutoRotate = true end
        
        if bhWasAnimateDisabled then
            local animScript = character:FindFirstChild("Animate")
            if animScript then
                animScript.Disabled = false
            end
            bhWasAnimateDisabled = false
        end
    end

    bhSetupChar = nil
end

function bhComputeCFrame(targetHead)
    local dist = 1.25
    local look = targetHead.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    flat = flat.Magnitude > 0 and flat.Unit or Vector3.new(0, 0, 1)

    local targetRoot = targetHead.Parent and targetHead.Parent:FindFirstChild("HumanoidRootPart")
    local targetY = targetRoot and targetRoot.Position.Y or (targetHead.Position.Y - 1.5)

    local headPos = targetHead.Position
    local myPos = headPos - (flat * dist)
    myPos = Vector3.new(myPos.X, targetY, myPos.Z)

    return CFrame.lookAt(myPos, Vector3.new(headPos.X, myPos.Y, headPos.Z))
end

function bhApplyCFrame()
    if not (FeatureStates.Backhug and BackhugTarget and BackhugTarget.Character and rootPart) then return false end
    local targetHead = BackhugTarget.Character:FindFirstChild("Head")
    if not targetHead then return false end

    local cf = bhComputeCFrame(targetHead)
    rootPart.CFrame = cf
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    pcall(function() rootPart.Velocity = Vector3.zero end)
    pcall(function() rootPart.RotVelocity = Vector3.zero end)
    return true
end

function bhStartPhysicsRep()
    bhConnPhysics = RunService.Stepped:Connect(function()
        if FeatureStates.Backhug and BackhugTarget and BackhugTarget.Character and rootPart then
            local targetHead = BackhugTarget.Character:FindFirstChild("Head")
            if targetHead then
                pcall(function()
                    sethiddenproperty(rootPart, "PhysicsRepRootPart", targetHead)
                end)
            end
        end
    end)
end

function bhStartCFrameFollow()
    bhConnCFrame = RunService.Heartbeat:Connect(function()
        bhApplyCFrame()
    end)
end

function bhActivate()
    if not bhSetup() then return end
    if bhHasHiddenProp then
        bhStartPhysicsRep()
    end
    bhStartCFrameFollow()
end

function bhDeactivate()
    bhCleanup()
end

-- 
-- FRONT HUG IMPLEMENTATION
-- 
fhSetupChar = nil
fhHasHiddenProp = false
fhConnPhysics = nil
fhConnCFrame = nil
fhWasAnimateDisabled = false
fhAnimTrack = nil
fhOriginalParts = {}

function fhSetup()
    if not character then return end
    if fhSetupChar == character then return end
    fhCleanup()

    local hum = character:FindFirstChild("Humanoid")
    if not hum then return end
    hum.AutoRotate = false

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    local animScript = character:FindFirstChild("Animate")
    if animScript and not animScript.Disabled then
        animScript.Disabled = true
        fhWasAnimateDisabled = true
    end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        pcall(function() track:Stop(0) end)
    end

    local success, err = pcall(function()
        local ok, objs = pcall(function() return game:GetObjects("rbxassetid://117991975031893") end)
        local anim = nil
        if ok and objs and objs[1] then
            local root = objs[1]
            if root:IsA("Animation") then
                anim = root
            else
                anim = root:FindFirstChildOfClass("Animation", true)
            end
        end
        if not anim then
            anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://117991975031893"
        end
        fhAnimTrack = animator:LoadAnimation(anim)
        fhAnimTrack.Priority = Enum.AnimationPriority.Action4
        fhAnimTrack.Looped = true
        fhAnimTrack:Play(0.1, 1, 1.0)
    end)
    if not success then warn("Fronthug Emote Load Error:", err) end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            fhOriginalParts[part] = {CanCollide = part.CanCollide}
            part.CanCollide = false
        end
    end

    local successHidden, _ = pcall(function() return sethiddenproperty end)
    fhHasHiddenProp = (successHidden and typeof(sethiddenproperty) == "function")

    fhSetupChar = character
    return true
end

function fhCleanup()
    if fhConnPhysics then fhConnPhysics:Disconnect() fhConnPhysics = nil end
    if fhConnCFrame then fhConnCFrame:Disconnect() fhConnCFrame = nil end
    
    if fhHasHiddenProp and rootPart then
        pcall(function() sethiddenproperty(rootPart, "PhysicsRepRootPart", nil) end)
    end
    
    if fhAnimTrack then
        pcall(function() fhAnimTrack:Stop() end)
        fhAnimTrack = nil
    end

    for part, props in pairs(fhOriginalParts) do
        if part and part.Parent then
            part.CanCollide = props.CanCollide
            part.Massless = props.Massless
        end
    end
    table.clear(fhOriginalParts)

    if character then
        local hum = character:FindFirstChild("Humanoid")
        if hum then hum.AutoRotate = true end
        
        if fhWasAnimateDisabled then
            local animScript = character:FindFirstChild("Animate")
            if animScript then
                animScript.Disabled = false
            end
            fhWasAnimateDisabled = false
        end
    end

    fhSetupChar = nil
end

function fhComputeCFrame(targetHead)
    local dist = 1.25
    local look = targetHead.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    flat = flat.Magnitude > 0 and flat.Unit or Vector3.new(0, 0, 1)

    local targetRoot = targetHead.Parent and targetHead.Parent:FindFirstChild("HumanoidRootPart")
    local targetY = targetRoot and targetRoot.Position.Y or (targetHead.Position.Y - 1.5)

    local headPos = targetHead.Position
    -- Place IN FRONT of the target instead of behind them
    local myPos = headPos + (flat * dist)
    
    -- Align face levels by basing our Y exclusively on their Head Y, ignoring their body height
    local targetY = headPos.Y - 1.5
    myPos = Vector3.new(myPos.X, targetY, myPos.Z)

    return CFrame.lookAt(myPos, Vector3.new(headPos.X, myPos.Y, headPos.Z))
end

function fhApplyCFrame()
    if not (FeatureStates.Fronthug and FronthugTarget and FronthugTarget.Character and rootPart) then return false end
    local targetHead = FronthugTarget.Character:FindFirstChild("Head")
    if not targetHead then return false end

    local cf = fhComputeCFrame(targetHead)
    rootPart.CFrame = cf
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    pcall(function() rootPart.Velocity = Vector3.zero end)
    pcall(function() rootPart.RotVelocity = Vector3.zero end)
    return true
end

function fhStartPhysicsRep()
    fhConnPhysics = RunService.Stepped:Connect(function()
        if FeatureStates.Fronthug and FronthugTarget and FronthugTarget.Character and rootPart then
            local targetHead = FronthugTarget.Character:FindFirstChild("Head")
            if targetHead then
                pcall(function()
                    sethiddenproperty(rootPart, "PhysicsRepRootPart", targetHead)
                end)
            end
        end
    end)
end

function fhStartCFrameFollow()
    fhConnCFrame = RunService.Heartbeat:Connect(function()
        fhApplyCFrame()
    end)
end

function fhActivate()
    if not fhSetup() then return end
    if fhHasHiddenProp then
        fhStartPhysicsRep()
    end
    fhStartCFrameFollow()
end

function fhDeactivate()
    fhCleanup()
end

-- 
-- PROPOSE IMPLEMENTATION
-- 
prSetupChar = nil
prHasHiddenProp = false
prConnPhysics = nil
prConnCFrame = nil
prWasAnimateDisabled = false
prAnimTrack = nil
prOriginalParts = {}

function prSetup()
    if not character then return end
    if prSetupChar == character then return end
    prCleanup()

    local hum = character:FindFirstChild("Humanoid")
    if not hum then return end
    hum.AutoRotate = false

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    local animScript = character:FindFirstChild("Animate")
    if animScript and not animScript.Disabled then
        animScript.Disabled = true
        prWasAnimateDisabled = true
    end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        pcall(function() track:Stop(0) end)
    end

    local success, err = pcall(function()
        local ok, objs = pcall(function() return game:GetObjects("rbxassetid://107416091886634") end)
        local anim = nil
        if ok and objs and objs[1] then
            local root = objs[1]
            if root:IsA("Animation") then
                anim = root
            else
                anim = root:FindFirstChildOfClass("Animation", true)
            end
        end
        if not anim then
            anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://107416091886634"
        end
        prAnimTrack = animator:LoadAnimation(anim)
        prAnimTrack.Priority = Enum.AnimationPriority.Action4
        prAnimTrack.Looped = true
        prAnimTrack:Play(0.1, 1, 1.0)
    end)
    if not success then warn("Propose Emote Load Error:", err) end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            prOriginalParts[part] = {CanCollide = part.CanCollide}
            part.CanCollide = false
        end
    end

    local successHidden, _ = pcall(function() return sethiddenproperty end)
    prHasHiddenProp = (successHidden and typeof(sethiddenproperty) == "function")

    prSetupChar = character
    return true
end

function prCleanup()
    if prConnPhysics then prConnPhysics:Disconnect() prConnPhysics = nil end
    if prConnCFrame then prConnCFrame:Disconnect() prConnCFrame = nil end
    
    if prHasHiddenProp and rootPart then
        pcall(function() sethiddenproperty(rootPart, "PhysicsRepRootPart", nil) end)
    end
    
    if prAnimTrack then
        pcall(function() prAnimTrack:Stop() end)
        prAnimTrack = nil
    end

    for part, props in pairs(prOriginalParts) do
        if part and part.Parent then
            part.CanCollide = props.CanCollide
            part.Massless = props.Massless
        end
    end
    table.clear(prOriginalParts)

    if character then
        local hum = character:FindFirstChild("Humanoid")
        if hum then hum.AutoRotate = true end
        
        if prWasAnimateDisabled then
            local animScript = character:FindFirstChild("Animate")
            if animScript then
                animScript.Disabled = false
            end
            prWasAnimateDisabled = false
        end
    end

    prSetupChar = nil
end

function prComputeCFrame(targetHead)
    local dist = 3.5
    local look = targetHead.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    flat = flat.Magnitude > 0 and flat.Unit or Vector3.new(0, 0, 1)

    local targetRoot = targetHead.Parent and targetHead.Parent:FindFirstChild("HumanoidRootPart")
    local targetY = targetRoot and targetRoot.Position.Y or (targetHead.Position.Y - 1.5)

    local headPos = targetHead.Position
    local myPos = headPos + (flat * dist)
    myPos = Vector3.new(myPos.X, targetY, myPos.Z)

    return CFrame.lookAt(myPos, Vector3.new(headPos.X, myPos.Y, headPos.Z))
end

function prApplyCFrame()
    if not (FeatureStates.Propose and ProposeTarget and ProposeTarget.Character and rootPart) then return false end
    local targetHead = ProposeTarget.Character:FindFirstChild("Head")
    if not targetHead then return false end

    local cf = prComputeCFrame(targetHead)
    rootPart.CFrame = cf
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    pcall(function() rootPart.Velocity = Vector3.zero end)
    pcall(function() rootPart.RotVelocity = Vector3.zero end)
    return true
end

function prStartPhysicsRep()
    prConnPhysics = RunService.Stepped:Connect(function()
        if FeatureStates.Propose and ProposeTarget and ProposeTarget.Character and rootPart then
            local targetHead = ProposeTarget.Character:FindFirstChild("Head")
            if targetHead then
                pcall(function()
                    sethiddenproperty(rootPart, "PhysicsRepRootPart", targetHead)
                end)
            end
        end
    end)
end

function prStartCFrameFollow()
    prConnCFrame = RunService.Heartbeat:Connect(function()
        prApplyCFrame()
    end)
end

function prActivate()
    if not prSetup() then return end
    if prHasHiddenProp then
        prStartPhysicsRep()
    end
    prStartCFrameFollow()
end

function prDeactivate()
    prCleanup()
end

-- 
-- HIPBANG IMPLEMENTATION
-- 
hbSetupChar = nil
hbHasHiddenProp = false
hbConnPhysics = nil
hbConnCFrame = nil
hbWasAnimateDisabled = false
hbAnimTrack = nil
hbOriginalParts = {}

function hbSetup()
    if not character then return end
    if hbSetupChar == character then return end
    hbCleanup()

    local hum = character:FindFirstChild("Humanoid")
    if not hum then return end
    hum.AutoRotate = false

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    local animScript = character:FindFirstChild("Animate")
    if animScript and not animScript.Disabled then
        animScript.Disabled = true
        hbWasAnimateDisabled = true
    end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        pcall(function() track:Stop(0) end)
    end

    local success, err = pcall(function()
        local isR15 = (hum.RigType == Enum.HumanoidRigType.R15)
        local animId = isR15 and 115942593443190 or 148840371
        
        local anim = nil
        if isR15 then
            local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(animId)) end)
            if ok and objs and objs[1] then
                local root = objs[1]
                if root:IsA("Animation") then
                    anim = root
                else
                    anim = root:FindFirstChildOfClass("Animation", true)
                end
            end
        end
        
        if not anim then
            anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. tostring(animId)
        end
        
        hbAnimTrack = animator:LoadAnimation(anim)
        hbAnimTrack.Priority = Enum.AnimationPriority.Action
        hbAnimTrack.Looped = true
        hbAnimTrack:Play()
    end)
    if not success then warn("Hipbang Emote Load Error:", err) end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            hbOriginalParts[part] = {CanCollide = part.CanCollide}
            part.CanCollide = false
        end
    end

    local successHidden, _ = pcall(function() return sethiddenproperty end)
    hbHasHiddenProp = (successHidden and typeof(sethiddenproperty) == "function")

    hbSetupChar = character
    return true
end

function hbCleanup()
    if hbConnPhysics then hbConnPhysics:Disconnect() hbConnPhysics = nil end
    if hbConnCFrame then hbConnCFrame:Disconnect() hbConnCFrame = nil end
    
    if hbHasHiddenProp and rootPart then
        pcall(function() sethiddenproperty(rootPart, "PhysicsRepRootPart", nil) end)
    end
    
    if hbAnimTrack then
        pcall(function() hbAnimTrack:Stop() end)
        hbAnimTrack = nil
    end

    for part, props in pairs(hbOriginalParts) do
        if part and part.Parent then
            part.CanCollide = props.CanCollide
            part.Massless = props.Massless
        end
    end
    table.clear(hbOriginalParts)

    if character then
        local hum = character:FindFirstChild("Humanoid")
        if hum then hum.AutoRotate = true end
        
        if hbWasAnimateDisabled then
            local animScript = character:FindFirstChild("Animate")
            if animScript then
                animScript.Disabled = false
            end
            hbWasAnimateDisabled = false
        end
    end

    hbSetupChar = nil
end

function hbComputeCFrame(targetHead)
    local thrust = (math.sin(tick() * HipbangSpeed * 10) + 1) / 2
    local dist = 0.5 + (thrust * HipbangDistance)

    local look = targetHead.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    flat = flat.Magnitude > 0 and flat.Unit or Vector3.new(0, 0, 1)

    local targetRoot = targetHead.Parent and targetHead.Parent:FindFirstChild("HumanoidRootPart")
    local targetY = targetRoot and targetRoot.Position.Y or (targetHead.Position.Y - 1.5)

    local headPos = targetHead.Position
    local myPos = headPos - (flat * dist)
    myPos = Vector3.new(myPos.X, targetY, myPos.Z)

    return CFrame.lookAt(myPos, Vector3.new(headPos.X, myPos.Y, headPos.Z))
end

function hbApplyCFrame()
    if not (FeatureStates.Hipbang and HipbangTarget and HipbangTarget.Character and rootPart) then return false end
    local targetHead = HipbangTarget.Character:FindFirstChild("Head")
    if not targetHead then return false end

    local cf = hbComputeCFrame(targetHead)
    rootPart.CFrame = cf
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    pcall(function() rootPart.Velocity = Vector3.zero end)
    pcall(function() rootPart.RotVelocity = Vector3.zero end)
    return true
end

function hbStartPhysicsRep()
    hbConnPhysics = RunService.Stepped:Connect(function()
        if FeatureStates.Hipbang and HipbangTarget and HipbangTarget.Character and rootPart then
            local targetHead = HipbangTarget.Character:FindFirstChild("Head")
            if targetHead then
                pcall(function()
                    sethiddenproperty(rootPart, "PhysicsRepRootPart", targetHead)
                end)
            end
        end
    end)
end

function hbStartCFrameFollow()
    hbConnCFrame = RunService.Heartbeat:Connect(function()
        hbApplyCFrame()
    end)
end

function hbActivate()
    if not hbSetup() then return end
    if hbHasHiddenProp then
        hbStartPhysicsRep()
    end
    hbStartCFrameFollow()
end

function hbDeactivate()
    hbCleanup()
end

-- 
-- BAGPACK IMPLEMENTATION
-- 
bgpSetupChar = nil
bgpHasHiddenProp = false
bgpConnPhysics = nil
bgpConnCFrame = nil
bgpOriginalParts = {}

function bgpSetup()
    if not character then return end
    if bgpSetupChar == character then return end
    bgpCleanup()

    local hum = character:FindFirstChild("Humanoid")
    if not hum then return end

    local success, _ = pcall(function() return sethiddenproperty end)
    bgpHasHiddenProp = (success and typeof(sethiddenproperty) == "function")

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            bgpOriginalParts[part] = {CanCollide = part.CanCollide}
            part.CanCollide = false
        end
    end

    hum.Sit = true
    bgpSetupChar = character
    return true
end

function bgpCleanup()
    if bgpConnPhysics then bgpConnPhysics:Disconnect() bgpConnPhysics = nil end
    if bgpConnCFrame then bgpConnCFrame:Disconnect() bgpConnCFrame = nil end
    
    if bgpHasHiddenProp and rootPart then
        pcall(function() sethiddenproperty(rootPart, "PhysicsRepRootPart", nil) end)
    end
    
    if character then
        local hum = character:FindFirstChild("Humanoid")
        if hum then hum.Sit = false end
    end
    
    task.wait()

    if bgpSetupChar == character then
        for part, props in pairs(bgpOriginalParts) do
            if part and part.Parent then
                part.CanCollide = props.CanCollide
                part.Massless = props.Massless
            end
        end
        table.clear(bgpOriginalParts)
    end
    bgpSetupChar = nil
end

function bgpComputeCFrame(targetRoot)
    local dist = 1.0
    local look = targetRoot.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    flat = flat.Magnitude > 0 and flat.Unit or Vector3.new(0, 0, 1)

    local targetPos = targetRoot.Position
    local targetY = targetPos.Y + 0.5 -- Slightly elevated to be on the upper back

    -- Position behind them
    local myPos = targetPos - (flat * dist)
    myPos = Vector3.new(myPos.X, targetY, myPos.Z)

    -- Face away from them so our backs are touching
    return CFrame.lookAt(myPos, myPos - flat)
end

function bgpApplyCFrame()
    if not (FeatureStates.Bagpack and BagpackTarget and BagpackTarget.Character and rootPart) then return false end
    local targetRoot = BagpackTarget.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false end

    local cf = bgpComputeCFrame(targetRoot)
    rootPart.CFrame = cf
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    pcall(function() rootPart.Velocity = Vector3.zero end)
    pcall(function() rootPart.RotVelocity = Vector3.zero end)
    return true
end

function bgpStartPhysicsRep()
    bgpConnPhysics = RunService.Stepped:Connect(function()
        if FeatureStates.Bagpack and BagpackTarget and BagpackTarget.Character and rootPart then
            local targetRoot = BagpackTarget.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                pcall(function()
                    sethiddenproperty(rootPart, "PhysicsRepRootPart", targetRoot)
                end)
            end
        end
    end)
end

function bgpStartCFrameFollow()
    bgpConnCFrame = RunService.Heartbeat:Connect(function()
        bgpApplyCFrame()
    end)
end

function bgpActivate()
    if not bgpSetup() then return end
    if bgpHasHiddenProp then
        bgpStartPhysicsRep()
    end
    bgpStartCFrameFollow()
end

function bgpDeactivate()
    bgpCleanup()
end

-- 
-- GOON IMPLEMENTATION
-- 
goonSetupChar = nil
goonHasHiddenProp = false
goonConnPhysics = nil
goonConnCFrame = nil
goonOriginalParts = {}
goonAnimTrack = nil
goonWasAnimateDisabled = false

function goonSetup()
    if not character then return end
    if goonSetupChar == character then return end
    goonCleanup()

    local hum = character:FindFirstChild("Humanoid")
    if not hum then return end
    hum.AutoRotate = false

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    local animScript = character:FindFirstChild("Animate")
    if animScript and not animScript.Disabled then
        animScript.Disabled = true
        goonWasAnimateDisabled = true
    end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        pcall(function() track:Stop(0) end)
    end

    local success, _ = pcall(function()
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://136828069054505"
        goonAnimTrack = animator:LoadAnimation(anim)
        goonAnimTrack.Priority = Enum.AnimationPriority.Action4
        goonAnimTrack.Looped = true
        goonAnimTrack:Play()
    end)

    local succProps, _ = pcall(function() return sethiddenproperty end)
    goonHasHiddenProp = (succProps and typeof(sethiddenproperty) == "function")

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            goonOriginalParts[part] = {CanCollide = part.CanCollide}
            part.CanCollide = false
        end
    end

    goonSetupChar = character
    return true
end

function goonCleanup()
    if goonConnPhysics then goonConnPhysics:Disconnect() goonConnPhysics = nil end
    if goonConnCFrame then goonConnCFrame:Disconnect() goonConnCFrame = nil end
    
    if goonAnimTrack then
        pcall(function() goonAnimTrack:Stop() goonAnimTrack:Destroy() end)
        goonAnimTrack = nil
    end

    if goonHasHiddenProp and rootPart then
        pcall(function() sethiddenproperty(rootPart, "PhysicsRepRootPart", nil) end)
    end
    
    if character then
        local hum = character:FindFirstChild("Humanoid")
        if hum then hum.AutoRotate = true end
        if goonWasAnimateDisabled then
            local animScript = character:FindFirstChild("Animate")
            if animScript then animScript.Disabled = false end
            goonWasAnimateDisabled = false
        end
    end
    
    task.wait()

    if goonSetupChar == character then
        for part, props in pairs(goonOriginalParts) do
            if part and part.Parent then
                part.CanCollide = props.CanCollide
                part.Massless = props.Massless
            end
        end
        table.clear(goonOriginalParts)
    end
    goonSetupChar = nil
end

function goonComputeCFrame(targetHead)
    local targetRoot = targetHead.Parent and targetHead.Parent:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return targetHead.CFrame end

    local dist = 4.5
    local leftOffset = 1.2 -- Shift to the target's left to counteract the emote leaning to their right

    local look = targetRoot.CFrame.LookVector
    local rightVec = targetRoot.CFrame.RightVector

    local flatForward = Vector3.new(look.X, 0, look.Z)
    flatForward = flatForward.Magnitude > 0 and flatForward.Unit or Vector3.new(0, 0, 1)

    local flatRight = Vector3.new(rightVec.X, 0, rightVec.Z)
    flatRight = flatRight.Magnitude > 0 and flatRight.Unit or Vector3.new(1, 0, 0)

    local headPos = targetHead.Position
    -- Elevate our root part ~1.5 studs above the target's head to align faces
    local targetY = headPos.Y + 1.5

    -- Position strictly IN FRONT of their body and shift to the LEFT
    local myPos = targetRoot.Position + (flatForward * dist) + (-flatRight * leftOffset)
    myPos = Vector3.new(myPos.X, targetY, myPos.Z)

    -- Look exactly opposite to the target's forward direction to ensure bodies are parallel
    return CFrame.lookAt(myPos, myPos - flatForward)
end

function goonApplyCFrame()
    if not (FeatureStates.Goon and GoonTarget and GoonTarget.Character and rootPart) then return false end
    local targetHead = GoonTarget.Character:FindFirstChild("Head")
    if not targetHead then return false end

    local cf = goonComputeCFrame(targetHead)
    rootPart.CFrame = cf
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    pcall(function() rootPart.Velocity = Vector3.zero end)
    pcall(function() rootPart.RotVelocity = Vector3.zero end)
    return true
end

function goonStartPhysicsRep()
    goonConnPhysics = RunService.Stepped:Connect(function()
        if FeatureStates.Goon and GoonTarget and GoonTarget.Character and rootPart then
            local targetRoot = GoonTarget.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                pcall(function()
                    sethiddenproperty(rootPart, "PhysicsRepRootPart", targetRoot)
                end)
            end
        end
    end)
end

function goonStartCFrameFollow()
    goonConnCFrame = RunService.Heartbeat:Connect(function()
        goonApplyCFrame()
    end)
end

function goonActivate()
    if not goonSetup() then return end
    if goonHasHiddenProp then
        goonStartPhysicsRep()
    end
    goonStartCFrameFollow()
end

function goonDeactivate()
    goonCleanup()
end

--  Frame connections (fallback + state management) 

-- Stepped: setup + CFrame fallback
RunService.Stepped:Connect(function()
    
    -- PHASE 1: Deactivations (Run first so cleanup doesn't override subsequent setups!)
    if not (FeatureStates.Pat and PatTarget and PatTarget.Character and rootPart) then
        if patSetupChar then patDeactivate() end
    end
    if not (FeatureStates.Facebang and FacebangTarget and FacebangTarget.Character and rootPart) then
        if facebangSetupChar then fbDeactivate() end
    end
    if not (FeatureStates.Headsit and HeadsitTarget and HeadsitTarget.Character and rootPart) then
        if hsSetupChar then hsDeactivate() end
    end
    if not (FeatureStates.Backhug and BackhugTarget and BackhugTarget.Character and rootPart) then
        if bhSetupChar then bhDeactivate() end
    end
    if not (FeatureStates.Fronthug and FronthugTarget and FronthugTarget.Character and rootPart) then
        if fhSetupChar then fhDeactivate() end
    end
    if not (FeatureStates.Propose and ProposeTarget and ProposeTarget.Character and rootPart) then
        if prSetupChar then prDeactivate() end
    end
    if not (FeatureStates.Hipbang and HipbangTarget and HipbangTarget.Character and rootPart) then
        if hbSetupChar then hbDeactivate() end
    end
    if not (FeatureStates.Bagpack and BagpackTarget and BagpackTarget.Character and rootPart) then
        if bgpSetupChar then bgpDeactivate() end
    end
    if not (FeatureStates.Goon and GoonTarget and GoonTarget.Character and rootPart) then
        if goonSetupChar then goonDeactivate() end
    end

    -- PHASE 2: Activations & CFraming
    if FeatureStates.Pat and PatTarget and PatTarget.Character and rootPart then
        if patSetupChar ~= character then patActivate() end
        if not patHasHiddenProp then patApplyCFrame() end
    end
    if FeatureStates.Facebang and FacebangTarget and FacebangTarget.Character and rootPart then
        if facebangSetupChar ~= character then fbActivate() end
        if not fbHasHiddenProp then fbApplyCFrame() end
    end
    if FeatureStates.Headsit and HeadsitTarget and HeadsitTarget.Character and rootPart then
        if hsSetupChar ~= character then hsActivate() end
        if not hsHasHiddenProp then hsApplyCFrame() end
    end
    if FeatureStates.Backhug and BackhugTarget and BackhugTarget.Character and rootPart then
        if bhSetupChar ~= character then bhActivate() end
        if not bhHasHiddenProp then bhApplyCFrame() end
    end
    if FeatureStates.Fronthug and FronthugTarget and FronthugTarget.Character and rootPart then
        if fhSetupChar ~= character then fhActivate() end
        if not fhHasHiddenProp then fhApplyCFrame() end
    end
    if FeatureStates.Propose and ProposeTarget and ProposeTarget.Character and rootPart then
        if prSetupChar ~= character then prActivate() end
        if not prHasHiddenProp then prApplyCFrame() end
    end
    if FeatureStates.Hipbang and HipbangTarget and HipbangTarget.Character and rootPart then
        if hbSetupChar ~= character then hbActivate() end
        if not hbHasHiddenProp then hbApplyCFrame() end
    end
    if FeatureStates.Bagpack and BagpackTarget and BagpackTarget.Character and rootPart then
        if bgpSetupChar ~= character then bgpActivate() end
        if not bgpHasHiddenProp then bgpApplyCFrame() end
    end
    if FeatureStates.Goon and GoonTarget and GoonTarget.Character and rootPart then
        if goonSetupChar ~= character then goonActivate() end
        if not goonHasHiddenProp then goonApplyCFrame() end
    end
end)

local reverseBuf = {}
-- Heartbeat: runs AFTER physics, before replication. Critical for CFrame fallback.
RunService.Heartbeat:Connect(function()
    
    if FeatureStates.Reverse and humanoid and rootPart then
        if UserInputService:IsKeyDown(Keybinds.Reverse) then
            local fr = table.remove(reverseBuf)
            if fr then 
                rootPart.CFrame = fr[1]
                humanoid:ChangeState(fr[3]) 
            end
        else
            if #reverseBuf >= 300 then table.remove(reverseBuf, 1) end
            reverseBuf[#reverseBuf + 1] = {rootPart.CFrame, rootPart.Velocity, humanoid:GetState()}
        end
    end

    if FeatureStates.Pat and PatTarget and rootPart then
        if not patHasHiddenProp then
            patApplyCFrame()
        end
    end
    
    if FeatureStates.Facebang and FacebangTarget and rootPart then
        if not fbHasHiddenProp then
            fbApplyCFrame()
        end
    end

    if FeatureStates.Headsit and HeadsitTarget and rootPart then
        if not hsHasHiddenProp then
            hsApplyCFrame()
        end
    end

    if FeatureStates.Backhug and BackhugTarget and rootPart then
        if not bhHasHiddenProp then
            bhApplyCFrame()
        end
    end

    if FeatureStates.Propose and ProposeTarget and rootPart then
        if not prHasHiddenProp then
            prApplyCFrame()
        end
    end

    if FeatureStates.Hipbang and HipbangTarget and rootPart then
        if not hbHasHiddenProp then
            hbApplyCFrame()
        end
    end

    if FeatureStates.Bagpack and BagpackTarget and rootPart then
        if not bgpHasHiddenProp then
            bgpApplyCFrame()
        end
    end

    if FeatureStates.Goon and GoonTarget and rootPart then
        if not goonHasHiddenProp then
            goonApplyCFrame()
        end
    end
end)

-- RenderStepped: visual smoothness (CFrame fallback only)
RunService.RenderStepped:Connect(function()
    if not fbHasHiddenProp then
        fbApplyCFrame()
    end
    if not hsHasHiddenProp then
        hsApplyCFrame()
    end
    if not bhHasHiddenProp then
        bhApplyCFrame()
    end
    if not fhHasHiddenProp then
        fhApplyCFrame()
    end
    if not prHasHiddenProp then
        prApplyCFrame()
    end
    if not hbHasHiddenProp then
        hbApplyCFrame()
    end
    if not bgpHasHiddenProp then
        bgpApplyCFrame()
    end
    if not goonHasHiddenProp then
        goonApplyCFrame()
    end
end)

-- 
-- NOCLIP ENGINE
-- 
RunService.Stepped:Connect(function()
    if FeatureStates.Noclip and character then
        pcall(function()
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end
end)

-- 
-- GLITCH ENGINE (Xnoctis-style triplet oscillation)
-- Offsets: +15  -30  +15 in local X each frame
-- This creates the classic Roblox desync glitch effect
-- 
local glitchLoopActive = false

function startGlitchLoop()
    if glitchLoopActive then return end
    glitchLoopActive = true
    if _G.SetActiveFeature then _G.SetActiveFeature("Glitch Movement") end
    task.spawn(function()
        local cf1 = CFrame.new(15, 0, 0)
        local cf2 = CFrame.new(-30, 0, 0)
        local cf3 = CFrame.new(15, 0, 0)
        while glitchLoopActive and rootPart do
            rootPart.CFrame = rootPart.CFrame * cf1
            task.wait()
            if not glitchLoopActive then break end
            rootPart.CFrame = rootPart.CFrame * cf2
            task.wait()
            if not glitchLoopActive then break end
            rootPart.CFrame = rootPart.CFrame * cf3
            task.wait()
        end
        glitchLoopActive = false
    end)
end

function stopGlitchLoop()
    glitchLoopActive = false
    if _G.SetActiveFeature then _G.SetActiveFeature(nil) end
end

-- 
-- BIG BASEPLATE ENGINE
-- 
-- _bigBPSelectedColor and _bigBPGrid are declared near the top of the file
-- so both the page toggle/color-picker and this engine can share them.

task.spawn(function()
    local BP_TILE    = 2000          -- tile footprint in studs (from bigbaseplate.txt)
    local BP_FOLDER  = "ZenBigBaseplates"
    local BP_THICK   = 0.05          -- tile thickness
    local bpLastTick = 0
    local BP_INTERVAL = 1.0          -- seconds between grid refreshes

    local function getBPFolder()
        local f = Workspace:FindFirstChild(BP_FOLDER)
        if not f then
            f = Instance.new("Folder")
            f.Name = BP_FOLDER
            f.Parent = Workspace
        end
        return f
    end

    local function ensureBPTile(folder, gx, gz)
        local key = tostring(gx) .. "," .. tostring(gz)
        -- remove stale tile
        if _bigBPGrid[key] and (not _bigBPGrid[key].Parent) then
            _bigBPGrid[key] = nil
        end
        if _bigBPGrid[key] then return end

        local tile = Instance.new("Part")
        tile.Name      = "GrassBaseplate"
        tile.Anchored  = true
        tile.CanCollide = true
        tile.CanQuery   = false
        tile.CastShadow = false
        tile.Locked     = true
        -- Fixed appearance  immune to shader changes
        tile.Size         = Vector3.new(BP_TILE, BP_THICK, BP_TILE)
        tile.Material     = Enum.Material.SmoothPlastic
        tile.Color        = _bigBPSelectedColor
        tile.Transparency = 0.5
        tile.Reflectance  = 0
        tile.TopSurface    = Enum.SurfaceType.Smooth
        tile.BottomSurface = Enum.SurfaceType.Smooth
        tile.Position = Vector3.new(gx * BP_TILE, 0, gz * BP_TILE)
        tile.Parent   = folder
        _bigBPGrid[key] = tile
    end

    -- Purge tiles that are too far from the player
    local function purgeBPFarTiles(curGX, curGZ)
        for key, tile in pairs(_bigBPGrid) do
            local gxStr, gzStr = key:match("([^,]+),([^,]+)")
            local gx, gz = tonumber(gxStr), tonumber(gzStr)
            if math.abs(gx - curGX) > 2 or math.abs(gz - curGZ) > 2 then
                pcall(function() if tile and tile.Parent then tile:Destroy() end end)
                _bigBPGrid[key] = nil
            end
        end
    end

    RunService.Heartbeat:Connect(function()
        if not IsKeyVerified then return end
        if not FeatureStates.BigBaseplateActive then return end

        local now = tick()
        if now - bpLastTick < BP_INTERVAL then return end
        bpLastTick = now

        local char = lp.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local folder = getBPFolder()
        local pos = hrp.Position
        local sizeMultiplier = BP_TILE
        local curGX = math.floor(pos.X / sizeMultiplier + 0.5)
        local curGZ = math.floor(pos.Z / sizeMultiplier + 0.5)

        -- 3x3 grid of tiles centred on player
        for dx = -1, 1 do
            for dz = -1, 1 do
                pcall(ensureBPTile, folder, curGX + dx, curGZ + dz)
            end
        end

        purgeBPFarTiles(curGX, curGZ)
    end)
end)

-- 
-- SUPERMAN FLY ENGINE
-- Pre-declare startSfly as upvalue: referenced by keybind handler below.
-- 
local startSfly -- upvalue for keybind handler
task.spawn(function() -- scope block to stay under Lua's 200-local limit
    _G.sflySpeed = 120
    local sflyConns = {}
    local sflyState = {forward=0, backward=0, left=0, right=0}
    local sflyVel = Vector3.new(0, 0, 0)
    local sflyCF = nil
    local sflyAnim = nil
    local origGrav = Workspace.Gravity

    local function sflyStopAnim()
        if sflyAnim then sflyAnim:Stop(0.1); sflyAnim = nil end
        local a = lp.Character and lp.Character:FindFirstChild("Animate")
        if a then a.Disabled = false end
        if humanoid then 
            for _, t in ipairs(humanoid:GetPlayingAnimationTracks()) do t:Stop() end 
        end
    end

    local function sflyPlayAnim(id, st, sp)
        sflyStopAnim()
        local a2 = lp.Character and lp.Character:FindFirstChild("Animate")
        if a2 then a2.Disabled = true end
        if humanoid then
            local an = Instance.new("Animation")
            an.AnimationId = "rbxassetid://" .. tostring(id)
            sflyAnim = humanoid:LoadAnimation(an)
            sflyAnim:Play()
            sflyAnim.TimePosition = st
            sflyAnim:AdjustSpeed(sp)
        end
    end

    startSfly = function() -- assigned to upvalue
        if FeatureStates.SupermanFlyActive then return end
        local char = lp.Character
        if not char or not rootPart or not humanoid then return end
        
        FeatureStates.SupermanFlyActive = true
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.1)
        Workspace.Gravity = 0
        humanoid.PlatformStand = true
        sflyPlayAnim(10714347256, 4, 0)
        
        local gyro = Instance.new("BodyGyro")
        gyro.Name = "SflyGyro"
        gyro.P = 90000
        gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        gyro.CFrame = rootPart.CFrame
        gyro.Parent = rootPart
        
        local bv = Instance.new("BodyVelocity")
        bv.Name = "SflyVelocity"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 0.1, 0)
        bv.Parent = rootPart
        
        sflyVel = Vector3.new(0, 0, 0)
        
        local upd = RunService.RenderStepped:Connect(function()
            local cam = Workspace.CurrentCamera
            local fwd = sflyState.forward - sflyState.backward
            local side = sflyState.right - sflyState.left
            local iv = (cam.CFrame.LookVector * fwd) + (cam.CFrame.RightVector * side)
            if fwd ~= 0 then iv = iv + Vector3.new(0, 0.2 * fwd, 0) end
            
            local bob = math.sin(tick() * 3) * 2
            local dv = iv.Magnitude > 0 and iv.Unit * _G.sflySpeed or Vector3.new(0, bob, 0)
            
            sflyVel = sflyVel:Lerp(dv, 0.25)
            bv.Velocity = sflyVel
            
            local dcf = fwd > 0 and cam.CFrame * CFrame.Angles(math.rad(-90), 0, 0) or cam.CFrame * CFrame.Angles(math.rad(-45 * fwd), 0, 0)
            sflyCF = sflyCF and sflyCF:Lerp(dcf, 0.2) or dcf
            gyro.CFrame = sflyCF
        end)
        table.insert(sflyConns, upd)
        
        local kb = UserInputService.InputBegan:Connect(function(inp, gp)
            if gp then return end
            local k = inp.KeyCode
            if k == Enum.KeyCode.W then sflyState.forward = 1; sflyPlayAnim(10714177846, 4.65, 0)
            elseif k == Enum.KeyCode.S then sflyState.backward = 1; sflyPlayAnim(10714347256, 4, 0)
            elseif k == Enum.KeyCode.A then sflyState.left = 1
            elseif k == Enum.KeyCode.D then sflyState.right = 1 end
        end)
        
        local ke = UserInputService.InputEnded:Connect(function(inp)
            local k = inp.KeyCode
            if k == Enum.KeyCode.W then sflyState.forward = 0; sflyPlayAnim(10714347256, 4, 0)
            elseif k == Enum.KeyCode.S then sflyState.backward = 0; sflyPlayAnim(10714347256, 4, 0)
            elseif k == Enum.KeyCode.A then sflyState.left = 0
            elseif k == Enum.KeyCode.D then sflyState.right = 0 end
        end)
        table.insert(sflyConns, kb)
        table.insert(sflyConns, ke)
    end

    _G.stopSfly = function()
        if not FeatureStates.SupermanFlyActive then return end
        FeatureStates.SupermanFlyActive = false
        Workspace.Gravity = origGrav
        if humanoid then humanoid.PlatformStand = false end
        sflyStopAnim()
        if rootPart then
            local g = rootPart:FindFirstChild("SflyGyro"); if g then g:Destroy() end
            local v = rootPart:FindFirstChild("SflyVelocity"); if v then v:Destroy() end
        end
        for _, c in ipairs(sflyConns) do if c.Connected then c:Disconnect() end end
        sflyConns = {}
        sflyState = {forward=0, backward=0, left=0, right=0}
    end

    lp.CharacterAdded:Connect(_G.stopSfly)
end) -- end Superman Fly engine scope block

-- 
-- INPUT HANDLERS (Click Teleport, Infinite Jump, Target)
-- 
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if not IsKeyVerified then return end

    -- Glitch Move Keybind (only works when toggle is ON)
    if input.KeyCode == Keybinds.GlitchMove and FeatureStates.GlitchMoveEnabled then
        if glitchLoopActive then
            stopGlitchLoop()
            FeatureStates.GlitchMoveActive = false
            SendNotification("Eternity", "Glitch Movement stopped.", 2)
        else
            FeatureStates.GlitchMoveActive = true
            startGlitchLoop()
            SendNotification("Eternity", "Glitch Movement active!", 2)
        end
    end

    -- Superman Fly Keybind (only works when toggle is ON)
    if input.KeyCode == Keybinds.SupermanFly and FeatureStates.SupermanFlyEnabled then
        if FeatureStates.SupermanFlyActive then
            _G.stopSfly()
            SendNotification("Eternity", "Superman Fly stopped.", 2)
        else
            startSfly()
            SendNotification("Eternity", "Superman Fly active!", 2)
        end
    end


    -- Pat Keybind
    if input.KeyCode == Keybinds.Pat and FeatureStates.PatEnabled then
        local newState = not FeatureStates.Pat
        SetAttachState("Pat", newState)
        if newState then
            local t = ctxTargetPlayer or TargetPlayer
            if t and t.Character and t.Character:FindFirstChild("Head") then
                PatTarget = t
            else
                local closest = nil
                local dist = math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local d = (p.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                        if d < dist then
                            dist = d
                            closest = p
                        end
                    end
                end
                PatTarget = closest
            end
            if PatTarget then
                SendNotification("Eternity", "Patting "..PatTarget.DisplayName, 2)
            else
                SetAttachState("Pat", false)
                SendNotification("Eternity", "No valid target found!", 2)
            end
        else
            SendNotification("Eternity", "Pat stopped.", 2)
        end
    end

    -- Headsit Keybind
    if input.KeyCode == Keybinds.Headsit and FeatureStates.HeadsitEnabled then
        local newState = not FeatureStates.Headsit
        SetAttachState("Headsit", newState)
        if newState then
            local t = ctxTargetPlayer or TargetPlayer
            if t and t.Character and t.Character:FindFirstChild("Head") then
                HeadsitTarget = t
            else
                local closest = nil
                local dist = math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local d = (p.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                        if d < dist then
                            dist = d
                            closest = p
                        end
                    end
                end
                HeadsitTarget = closest
            end
            if HeadsitTarget then
                SendNotification("Eternity", "Headsitting on "..HeadsitTarget.DisplayName, 2)
            else
                SetAttachState("Headsit", false)
                SendNotification("Eternity", "No valid target found!", 2)
            end
        else
            SendNotification("Eternity", "Headsit stopped.", 2)
        end
    end

    -- Backhug Keybind
    if input.KeyCode == Keybinds.Backhug and FeatureStates.BackhugEnabled then
        local newState = not FeatureStates.Backhug
        SetAttachState("Backhug", newState)
        if newState then
            local t = ctxTargetPlayer or TargetPlayer
            if t and t.Character and t.Character:FindFirstChild("Head") then
                BackhugTarget = t
            else
                local closest = nil
                local dist = math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local d = (p.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                        if d < dist then
                            dist = d
                            closest = p
                        end
                    end
                end
                BackhugTarget = closest
            end
            if BackhugTarget then
                SendNotification("Eternity", "Backhugging "..BackhugTarget.DisplayName, 2)
            else
                SetAttachState("Backhug", false)
                SendNotification("Eternity", "No valid target found!", 2)
            end
        else
            SendNotification("Eternity", "Backhug stopped.", 2)
        end
    end

    -- Fronthug Keybind
    if input.KeyCode == Keybinds.Fronthug and FeatureStates.FronthugEnabled then
        local newState = not FeatureStates.Fronthug
        SetAttachState("Fronthug", newState)
        if newState then
            local t = ctxTargetPlayer or TargetPlayer
            if t and t.Character and t.Character:FindFirstChild("Head") then
                FronthugTarget = t
            else
                local closest = nil
                local dist = math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local d = (p.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                        if d < dist then
                            dist = d
                            closest = p
                        end
                    end
                end
                FronthugTarget = closest
            end
            if FronthugTarget then
                SendNotification("Eternity", "Fronthugging "..FronthugTarget.DisplayName, 2)
            else
                SetAttachState("Fronthug", false)
                SendNotification("Eternity", "No valid target found!", 2)
            end
        else
            SendNotification("Eternity", "Fronthug stopped.", 2)
        end
    end

    -- Propose Keybind
    if input.KeyCode == Keybinds.Propose and FeatureStates.ProposeEnabled then
        local newState = not FeatureStates.Propose
        SetAttachState("Propose", newState)
        if newState then
            local t = ctxTargetPlayer or TargetPlayer
            if t and t.Character and t.Character:FindFirstChild("Head") then
                ProposeTarget = t
            else
                local closest = nil
                local dist = math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local d = (p.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                        if d < dist then
                            dist = d
                            closest = p
                        end
                    end
                end
                ProposeTarget = closest
            end
            if ProposeTarget then
                SendNotification("Eternity", "Proposing to "..ProposeTarget.DisplayName, 2)
            else
                SetAttachState("Propose", false)
                SendNotification("Eternity", "No valid target found!", 2)
            end
        else
            SendNotification("Eternity", "Propose stopped.", 2)
        end
    end

    -- Hipbang Keybind
    if input.KeyCode == Keybinds.Hipbang and FeatureStates.HipbangEnabled then
        local newState = not FeatureStates.Hipbang
        SetAttachState("Hipbang", newState)
        if newState then
            local t = ctxTargetPlayer or TargetPlayer
            if t and t.Character and t.Character:FindFirstChild("Head") then
                HipbangTarget = t
            else
                local closest = nil
                local dist = math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local d = (p.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                        if d < dist then
                            dist = d
                            closest = p
                        end
                    end
                end
                HipbangTarget = closest
            end
            if HipbangTarget then
                SendNotification("Eternity", "Hipbanging "..HipbangTarget.DisplayName, 2)
            else
                SetAttachState("Hipbang", false)
                SendNotification("Eternity", "No valid target found!", 2)
            end
        else
            SendNotification("Eternity", "Hipbang stopped.", 2)
        end
    end

    -- Facebang Keybind
    if input.KeyCode == Keybinds.Facebang and FeatureStates.FacebangEnabled then
        local newState = not FeatureStates.Facebang
        SetAttachState("Facebang", newState)
        if newState then
            local t = ctxTargetPlayer or TargetPlayer
            if t and t.Character and t.Character:FindFirstChild("Head") then
                FacebangTarget = t
            else
                local closest = nil
                local minDist = math.huge
                if rootPart then
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= lp and p.Character and p.Character:FindFirstChild("Head") then
                            local dist = (p.Character.Head.Position - rootPart.Position).Magnitude
                            if dist < minDist then
                                minDist = dist
                                closest = p
                            end
                        end
                    end
                end
                FacebangTarget = closest
            end
            if FacebangTarget then
                SendNotification("Eternity", "Attaching to "..FacebangTarget.DisplayName, 2)
            else
                SetAttachState("Facebang", false)
                SendNotification("Eternity", "No valid target found!", 2)
            end
        else
            SendNotification("Eternity", "Facebang stopped.", 2)
        end
    end

    -- Bagpack Keybind
    if input.KeyCode == Keybinds.Bagpack and FeatureStates.BagpackEnabled then
        local newState = not FeatureStates.Bagpack
        SetAttachState("Bagpack", newState)
        if newState then
            local t = ctxTargetPlayer or TargetPlayer
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
                BagpackTarget = t
            else
                local closest = nil
                local dist = math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local d = (p.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                        if d < dist then
                            dist = d
                            closest = p
                        end
                    end
                end
                BagpackTarget = closest
            end
            if BagpackTarget then
                SendNotification("Eternity", "Bagpacking "..BagpackTarget.DisplayName, 2)
            else
                SetAttachState("Bagpack", false)
                SendNotification("Eternity", "No valid target found!", 2)
            end
        else
            SendNotification("Eternity", "Bagpack stopped.", 2)
        end
    end

    -- Goon Keybind
    if input.KeyCode == Keybinds.Goon and FeatureStates.GoonEnabled then
        local newState = not FeatureStates.Goon
        SetAttachState("Goon", newState)
        if newState then
            local t = ctxTargetPlayer or TargetPlayer
            if t and t.Character and t.Character:FindFirstChild("Head") then
                GoonTarget = t
            else
                local closest = nil
                local dist = math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local d = (p.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                        if d < dist then
                            dist = d
                            closest = p
                        end
                    end
                end
                GoonTarget = closest
            end
            if GoonTarget then
                SendNotification("Eternity", "Gooning "..GoonTarget.DisplayName, 2)
            else
                SetAttachState("Goon", false)
                SendNotification("Eternity", "No valid target found!", 2)
            end
        else
            SendNotification("Eternity", "Goon stopped.", 2)
        end
    end

    -- Click to Target
    if input.UserInputType == Enum.UserInputType.MouseButton1 and FeatureStates.ClickToTarget then
        pcall(function()
            local mouse = lp:GetMouse()
            if mouse.Target and mouse.Target.Parent then
                local model = mouse.Target.Parent
                if not model:FindFirstChild("Humanoid") then
                    model = model.Parent
                end
                if model and model:FindFirstChild("Humanoid") then
                    local plr = Players:GetPlayerFromCharacter(model)
                    if plr and plr ~= lp then
                        if type(tgt_updateSelection) == "function" then
                            tgt_updateSelection(plr)
                            if type(tgt_buildList) == "function" then tgt_buildList() end
                        else
                            TargetPlayer = plr
                        end
                        SendNotification("Eternity", "Locked onto: " .. plr.DisplayName, 2)
                    end
                end
            end
        end)
    end

    -- Click Teleport (Bound Key)
    if input.KeyCode == Keybinds.ClickTeleport and FeatureStates.ClickTeleport then
        pcall(function()
            local mouse = lp:GetMouse()
            if mouse.Hit and rootPart then
                -- Preserve facing direction: keep rotation, only change position
                local oldCF = rootPart.CFrame
                local targetPos = mouse.Hit.Position + Vector3.new(0, 3, 0)
                local targetCF = CFrame.new(targetPos) * (oldCF - oldCF.Position)
                
                -- Teleport locally first
                rootPart.CFrame = targetCF
                
                -- Synchronously update Glitch Engine to prevent 1-frame rubberbanding (tripping)
                if _G.UpdateGlitchCF then
                    _G.UpdateGlitchCF(targetCF)
                end
            end
        end)
    end

    -- Animated Teleport (Bound Key)
    if input.KeyCode == Keybinds.AnimatedTeleport and FeatureStates.AnimatedTeleport then
        pcall(function()
            local mouse = lp:GetMouse()
            if mouse.Hit and rootPart and humanoid then
                -- Preserve facing direction: keep rotation, only change position
                local oldCF = rootPart.CFrame
                local targetPos = mouse.Hit.Position + Vector3.new(0, 3, 0)
                local targetCF = CFrame.new(targetPos) * (oldCF - oldCF.Position)
                
                -- Teleport locally first
                rootPart.CFrame = targetCF
                
                -- Synchronously update Glitch Engine to prevent 1-frame rubberbanding (tripping)
                if _G.UpdateGlitchCF then
                    _G.UpdateGlitchCF(targetCF)
                end
                
                -- Play emote
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://85549923655504"
                local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid
                local track = animator:LoadAnimation(anim)
                track.Looped = false
                track:Play()
                track:AdjustSpeed(2.5) -- Make animation faster
            end
        end)
    end

    -- Trip (Bound Key)
    if input.KeyCode == Keybinds.Trip and FeatureStates.Trip then
        pcall(function()
            if humanoid and rootPart then
                humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
                rootPart.Velocity = rootPart.CFrame.LookVector * 30
            end
        end)
    end

    -- Fakeout Keybind (only works when toggle is ON)
    if input.KeyCode == Keybinds.Fakeout and FeatureStates.FakeoutEnabled then
        task.spawn(function()
            pcall(function()
                local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local lastCFrame = hrp.CFrame
                local origHeight = Workspace.FallenPartsDestroyHeight
                Workspace.FallenPartsDestroyHeight = -1000
                hrp.CFrame = CFrame.new(Vector3.new(0, -500, 0))
                task.wait(0.7)
                hrp.CFrame = lastCFrame
                Workspace.FallenPartsDestroyHeight = origHeight
            end)
        end)
        SendNotification("Eternity", "Fakeout triggered!", 2)
    end

    -- Ghost Bait Keybind (only works when armed toggle is ON)
    -- First press: yeet body to extreme coordinate and hold it there perma via a loop.
    -- Their weld/PhysicsRep keeps reading our network position = insane coord = perma network error.
    -- Second press: snap back, kill the loop, restore everything.
    if input.KeyCode == Keybinds.GhostBait and FeatureStates.GhostBaitEnabled then
        if not FeatureStates.GhostBaitActive then
            -- === ACTIVATE ===
            task.spawn(function()
                pcall(function()
                    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end

                    FeatureStates.GhostBaitActive = true
                    FeatureStates.GhostBaitReturnCF = hrp.CFrame

                    -- Suppress void death permanently during bait
                    FeatureStates.GhostBaitOrigHeight = Workspace.FallenPartsDestroyHeight
                    pcall(function() Workspace.FallenPartsDestroyHeight = 0/0 end)

                    local loopId = tick()
                    FeatureStates.GhostBaitLoopId = loopId

                    -- Try to lock via PhysicsRepRootPart (server-side position lock) if executor supports it
                    local hasHidden = pcall(function() return sethiddenproperty end) and typeof(sethiddenproperty) == "function"
                    if hasHidden then
                        local ghost = Instance.new("Part")
                        ghost.Anchored = true
                        ghost.CanCollide = false
                        ghost.Transparency = 1
                        ghost.Size = Vector3.new(1,1,1)
                        ghost.CFrame = CFrame.new(1e9, 1e9, 1e9)
                        ghost.Parent = Workspace
                        FeatureStates.GhostBaitPart = ghost
                        pcall(function() sethiddenproperty(hrp, "PhysicsRepRootPart", ghost) end)
                    end

                    -- Dual hammer: fires on EVERY Heartbeat AND RenderStepped
                    -- Each frame blasts 5 rapid randomized positions to aggressively shake off weld attackers
                    local nan3 = Vector3.new(0/0, 0/0, 0/0)
                    local function blastRandom()
                        for _ = 1, 5 do
                            pcall(function()
                                if hrp and hrp.Parent then
                                    -- Alternate between deep void (-1 Billion) and high sky (+1 Billion)
                                    local yPos = math.random() > 0.5 and 1e9 or -1e9
                                    local baitCF = CFrame.new(1e9, yPos, 1e9)
                                    
                                    hrp.AssemblyLinearVelocity = nan3
                                    hrp.AssemblyAngularVelocity = nan3
                                    hrp.CFrame = baitCF
                                    
                                    if FeatureStates.GhostBaitPart then
                                        FeatureStates.GhostBaitPart.CFrame = baitCF
                                    end
                                end
                            end)
                        end
                    end

                    FeatureStates.GhostBaitHBConn = RunService.Heartbeat:Connect(function()
                        if not (FeatureStates.GhostBaitActive and FeatureStates.GhostBaitLoopId == loopId) then
                            FeatureStates.GhostBaitHBConn:Disconnect()
                            FeatureStates.GhostBaitHBConn = nil
                            return
                        end
                        blastRandom()
                    end)

                    FeatureStates.GhostBaitRSConn = RunService.RenderStepped:Connect(function()
                        if not (FeatureStates.GhostBaitActive and FeatureStates.GhostBaitLoopId == loopId) then
                            FeatureStates.GhostBaitRSConn:Disconnect()
                            FeatureStates.GhostBaitRSConn = nil
                            return
                        end
                        blastRandom()
                    end)
                    
                    -- To prevent the local "falling" animation while the server sees us glitching:
                    -- (Removed BindToRenderStep to allow the user to visually see the glitch desync on their screen)
                end)
            end)
            SendNotification("Eternity", "Ghost Bait ACTIVE  attacker is perma-stuck! Press again to return.", 3)
        else
            -- === DEACTIVATE: snap back ===
            FeatureStates.GhostBaitActive = false
            FeatureStates.GhostBaitLoopId = nil
            task.spawn(function()
                pcall(function()
                    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")

                    -- Kill hammer connections
                    if FeatureStates.GhostBaitHBConn then
                        pcall(function() FeatureStates.GhostBaitHBConn:Disconnect() end)
                        FeatureStates.GhostBaitHBConn = nil
                    end
                    if FeatureStates.GhostBaitRSConn then
                        pcall(function() FeatureStates.GhostBaitRSConn:Disconnect() end)
                        FeatureStates.GhostBaitRSConn = nil
                    end

                    -- Clear PhysicsRepRootPart ghost anchor
                    local hasHidden = pcall(function() return sethiddenproperty end) and typeof(sethiddenproperty) == "function"
                    if hasHidden and hrp then
                        pcall(function() sethiddenproperty(hrp, "PhysicsRepRootPart", nil) end)
                    end
                    if FeatureStates.GhostBaitPart then
                        pcall(function() FeatureStates.GhostBaitPart:Destroy() end)
                        FeatureStates.GhostBaitPart = nil
                    end

                    -- Snap back to saved position
                    if hrp and FeatureStates.GhostBaitReturnCF then
                        hrp.CFrame = FeatureStates.GhostBaitReturnCF
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end

                    -- Restore void height
                    if FeatureStates.GhostBaitOrigHeight then
                        pcall(function() Workspace.FallenPartsDestroyHeight = FeatureStates.GhostBaitOrigHeight end)
                        FeatureStates.GhostBaitOrigHeight = nil
                    end
                end)
            end)
            SendNotification("Eternity", "Ghost Bait OFF  you're back!", 2)
        end
    end

    -- Go Underground Keybind
    if input.KeyCode == Keybinds.GoUnderground and FeatureStates.GoUndergroundEnabled then
        if FeatureStates.GoUndergroundActive then
            FeatureStates.goUndergroundDeactivate()
        else
            FeatureStates.goUndergroundActivate()
        end
    end

    -- Unified Glitch Desync Keybind
    if input.KeyCode == Keybinds.GlitchDesync then
        if FeatureStates.ExtremeGlitchDesyncEnabled then
            if GlitchStates.Active then
                glitchDeactivate()
                SendNotification("Eternity", "Extreme Glitch Desync OFF.", 2)
            else
                task.spawn(function() glitchActivate("Extreme") end)
                SendNotification("Eternity", "Extreme Glitch Desync ON  max distance!", 2)
            end
        elseif FeatureStates.NormalGlitchDesyncEnabled then
            if GlitchStates.Active then
                glitchDeactivate()
                SendNotification("Eternity", "Normal Glitch Desync OFF.", 2)
            else
                task.spawn(function() glitchActivate("Normal") end)
                SendNotification("Eternity", "Normal Glitch Desync ON  dodging aimbots!", 2)
            end
        end
    end

    -- Infinite Jump (Space)
    if input.KeyCode == Enum.KeyCode.Space and FeatureStates.InfiniteJump then
        pcall(function()
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end

    -- Toggle GUI visibility (Right Ctrl)
    if input.KeyCode == Enum.KeyCode.RightControl then
        mainFrame.Visible = not mainFrame.Visible
        if floatingTopContainer then
            if mainFrame.Visible then
                floatingTopContainer.Visible = true
                floatingTopContainer.Position = UDim2.new(floatingTopContainer.Position.X.Scale, floatingTopContainer.Position.X.Offset, 0.25, -30)
                tween(floatingTopContainer, {GroupTransparency = 0, Position = UDim2.new(floatingTopContainer.Position.X.Scale, floatingTopContainer.Position.X.Offset, 0.25, -12)}, 0.4, Enum.EasingStyle.Quint)
            else
                floatingTopContainer.Visible = false
                floatingTopContainer.GroupTransparency = 1
            end
        end
    end
end)

-- 
-- NOTIFICATION TOAST SYSTEM
-- 
task.spawn(function() -- scope block to stay under Lua's 200-local limit
    local toastScreen = Instance.new("Frame", sg)
    toastScreen.Name = "ToastScreen"
    toastScreen.Size = UDim2.new(0, 260, 1, -80)
    toastScreen.Position = UDim2.new(1, -280, 0, 0)
    toastScreen.BackgroundTransparency = 1
    
    local toastLayout = Instance.new("UIListLayout", toastScreen)
    toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
    toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    toastLayout.Padding = UDim.new(0, 8)
    
    local toastTemplate = Instance.new("Frame")
    toastTemplate.Name = "ToastCard"
    toastTemplate.Size = UDim2.new(1, 0, 1, 0)
    toastTemplate.Position = UDim2.new(0, 280, 0, 0)
    toastTemplate.BackgroundColor3 = C.bgCard
    toastTemplate.BorderSizePixel = 0
    toastTemplate.BackgroundTransparency = 1
    corner(toastTemplate, 12)
    stroke(toastTemplate, C.accent, 1, 0.4)

    local toastProgress = Instance.new("Frame", toastTemplate)
    toastProgress.Name = "Progress"
    toastProgress.Size = UDim2.new(1, -24, 0, 3)
    toastProgress.Position = UDim2.new(0, 12, 1, -8)
    toastProgress.BackgroundColor3 = C.accent
    toastProgress.BorderSizePixel = 0
    toastProgress.BackgroundTransparency = 1
    corner(toastProgress, 2)

    local toastIcon = Instance.new("ImageLabel", toastTemplate)
    toastIcon.Name = "Icon"
    toastIcon.Size = UDim2.new(0, 36, 0, 36)
    toastIcon.Position = UDim2.new(0, 10, 0, 8)
    toastIcon.BackgroundColor3 = C.surface
    toastIcon.BorderSizePixel = 0
    toastIcon.Image = ""
    toastIcon.ImageTransparency = 1
    corner(toastIcon, 18)

    pcall(function()
        toastIcon.Image = Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)

    local toastTitle = Instance.new("TextLabel", toastTemplate)
    toastTitle.Name = "Title"
    toastTitle.Size = UDim2.new(1, -60, 0, 18)
    toastTitle.Position = UDim2.new(0, 54, 0, 8)
    toastTitle.Font = Enum.Font.GothamBold
    toastTitle.TextSize = 12
    toastTitle.TextColor3 = C.white
    toastTitle.TextXAlignment = Enum.TextXAlignment.Left
    toastTitle.BackgroundTransparency = 1
    toastTitle.TextTransparency = 1

    local toastSub = Instance.new("TextLabel", toastTemplate)
    toastSub.Name = "Sub"
    toastSub.Size = UDim2.new(1, -60, 0, 14)
    toastSub.Position = UDim2.new(0, 54, 0, 26)
    toastSub.Font = Enum.Font.Gotham
    toastSub.TextSize = 10
    toastSub.TextColor3 = C.textMuted
    toastSub.TextXAlignment = Enum.TextXAlignment.Left
    toastSub.BackgroundTransparency = 1
    toastSub.TextTransparency = 1
    
    local toastCount = 0

    -- SendNotification is a global so callers above (early pcall) and below can reach it
    SendNotification = function(title, text, duration)
        toastCount = toastCount + 1
        duration = duration or 3
        
        local wrapper = Instance.new("Frame", toastScreen)
        wrapper.Size = UDim2.new(1, 0, 0, 60)
        wrapper.BackgroundTransparency = 1
        wrapper.LayoutOrder = toastCount
        
        local card = toastTemplate:Clone()
        card.Parent = wrapper
        card.Title.Text = title or "Eternity"
        card.Sub.Text = text or ""
        
        tween(card, {BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0)}, 0.5, Enum.EasingStyle.Quint)
        tween(card.Progress, {BackgroundTransparency = 0}, 0.5)
        tween(card.Title, {TextTransparency = 0}, 0.5)
        tween(card.Sub, {TextTransparency = 0}, 0.5)
        tween(card.Icon, {ImageTransparency = 0}, 0.5)
        
        tween(card.Progress, {Size = UDim2.new(0, 0, 0, 3)}, duration, Enum.EasingStyle.Linear)
        
        task.spawn(function()
            task.wait(duration)
            tween(card, {BackgroundTransparency = 1, Position = UDim2.new(0, 280, 0, 0)}, 0.4, Enum.EasingStyle.Quint)
            tween(card.Progress, {BackgroundTransparency = 1}, 0.4)
            tween(card.Title, {TextTransparency = 1}, 0.4)
            tween(card.Sub, {TextTransparency = 1}, 0.4)
            tween(card.Icon, {ImageTransparency = 1}, 0.4)
            
            task.wait(0.4)
            wrapper:Destroy()
        end)
    end
end) -- end Toast notification scope block

-- 
-- ETERNITY OVERHEAD LOGO
-- 
local function setupOverheadLogo(character)
    if not character then return end
    
    local head = character:WaitForChild("Head", 5)
    if not head then return end
    
    if head:FindFirstChild("EternityOverhead") then
        head.EternityOverhead:Destroy()
    end
    
    local bg = Instance.new("BillboardGui")
    bg.Name = "EternityOverhead"
    bg.Adornee = head
    bg.AlwaysOnTop = true
    bg.MaxDistance = math.huge
    bg.ResetOnSpawn = false
    bg.Enabled = FeatureStates.ShowOverheadLogo ~= false
    
    local player = Players:GetPlayerFromCharacter(character)
    local customName = player and player.DisplayName or character.Name
    local customBgId = "139175707588865" -- Default to eternity logo background
    
    if player and getgenv().EternityCustomTags then
        for k, v in pairs(getgenv().EternityCustomTags) do
            if string.lower(k) == string.lower(player.Name) then
                if v.customName then customName = v.customName end
                if v.backgroundId then customBgId = v.backgroundId end
                break
            end
        end
    end
    
    -- Logo removed per user request
    
    local card = Instance.new("Frame", bg)
    -- Drastically scaled down width and height
    card.Size = UDim2.new(0.22, 0, 0.16, 0)
    card.Position = UDim2.new(0.39, 0, 0.45, 0)
    card.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0.25, 0)
    
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color = C.accent
    cardStroke.Thickness = 3.5 -- Reduced thickness slightly
    
    local cardStrokeGrad = Instance.new("UIGradient", cardStroke)
    cardStrokeGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.35, 1),
        NumberSequenceKeypoint.new(0.45, 0.2),
        NumberSequenceKeypoint.new(0.5, 0), -- Wider visible section
        NumberSequenceKeypoint.new(0.55, 0.2),
        NumberSequenceKeypoint.new(0.65, 1),
        NumberSequenceKeypoint.new(1, 1)
    })
    
    if customBgId then
        local cardImg = Instance.new("ImageLabel", card)
        cardImg.Size = UDim2.new(1, 0, 1, 0)
        cardImg.BackgroundTransparency = 1
        cardImg.Image = "rbxassetid://"..customBgId
        cardImg.ScaleType = Enum.ScaleType.Crop
        cardImg.ZIndex = 1
        Instance.new("UICorner", cardImg).CornerRadius = UDim.new(0.25, 0)
    end
    
    local nameText = Instance.new("TextLabel", card)
    -- Made the font much smaller relative to the card
    nameText.Size = UDim2.new(0.9, 0, 0.25, 0)
    nameText.Position = UDim2.new(0.05, 0, 0.18, 0)
    nameText.BackgroundTransparency = 1
    nameText.Text = customName
    nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameText.TextStrokeTransparency = 0
    nameText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameText.Font = Enum.Font.GothamBold
    nameText.TextScaled = true
    nameText.ZIndex = 2
    
    local userText = Instance.new("TextLabel", card)
    -- Made the username text smaller
    userText.Size = UDim2.new(0.9, 0, 0.25, 0)
    userText.Position = UDim2.new(0.05, 0, 0.52, 0)
    userText.BackgroundTransparency = 1
    userText.Text = player and ("@" .. player.Name) or "@unknown"
    userText.TextColor3 = Color3.fromRGB(200, 200, 200)
    userText.TextStrokeTransparency = 0.2
    userText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    userText.Font = Enum.Font.GothamMedium
    userText.TextScaled = true
    userText.ZIndex = 2
    
    bg.Parent = head
    
    task.spawn(function()
        local t = 0
        local cam = workspace.CurrentCamera
        while bg and bg.Parent == head do
            t = t + task.wait()
            
            -- Calculate distance from camera to head
            local dist = (cam.CFrame.Position - head.Position).Magnitude
            
            -- Dynamically scale size based on distance
            local dynWidth = math.clamp(12 + (dist / 5), 12, 800)
            -- 2.5 aspect ratio allows room for both the logo and the banner card
            bg.Size = UDim2.new(dynWidth, 0, dynWidth / 2.5, 0)
            
            -- Push the logo higher up by exactly half its height
            local heightOffset = 1.0 + (dynWidth / 6.5)
            
            bg.StudsOffset = Vector3.new(0, heightOffset + math.sin(t * 3) * (0.2 + (dynWidth/40)), 0)
            
            if cardStrokeGrad then
                -- Slower rotation (1.5 degrees per frame instead of 3)
                cardStrokeGrad.Rotation = (cardStrokeGrad.Rotation + 1.5) % 360
            end
        end
    end)
end

-- 
-- KEY VERIFICATION + MAIN GUI ENTRANCE

-- KEY VERIFIED - Run main GUI entrance (loader already verified key)
    IsKeyVerified = true
    pcall(function() lp.CameraMaxZoomDistance=math.huge; lp.CameraMinZoomDistance=0 end)

    local ActiveEternityUsers = {}

    local function broadcastHandshake()
        task.spawn(function()
            local char = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
            local hum = char:WaitForChild("Humanoid", 5)
            local animator = hum and hum:WaitForChild("Animator", 5)
            if animator then
                local anim = Instance.new("Animation")
                -- Use standard R15 and R6 Wave animations which are never deleted
                anim.AnimationId = hum.RigType == Enum.HumanoidRigType.R15 and "rbxassetid://507770239" or "rbxassetid://128777973"
                
                local success, track = pcall(function()
                    return animator:LoadAnimation(anim)
                end)
                
                if success and track then
                    track:Play(0, 0, 0)
                    task.wait(0.1)
                    track:Stop()
                end
            end
        end)
    end
    Players.LocalPlayer.CharacterAdded:Connect(broadcastHandshake)
    broadcastHandshake()

    local function monitorHandshakes(player)
        if player == Players.LocalPlayer then return end
        local function onChar(char)
            local hum = char:WaitForChild("Humanoid", 10)
            local animator = hum and hum:WaitForChild("Animator", 10)
            if animator then
                animator.AnimationPlayed:Connect(function(track)
                    if track.Animation then
                        local id = track.Animation.AnimationId
                        -- Accept either R15 wave, R6 wave, or the old ID
                        if id == "rbxassetid://507770239" or id == "rbxassetid://128777973" or id == "rbxassetid://188612401" then
                            if not ActiveEternityUsers[player] then
                                ActiveEternityUsers[player] = true
                                -- Reply to their handshake so they know we are here too!
                                task.spawn(function()
                                    task.wait(math.random(5, 15) / 10)
                                    broadcastHandshake()
                                end)
                            end
                        end
                    end
                end)
            end
        end
        if player.Character then task.spawn(onChar, player.Character) end
        player.CharacterAdded:Connect(onChar)
    end

    local function checkAndSetupLogo(player)
        local isWhite = WhitelistedUsers and WhitelistedUsers[string.lower(player.Name)]
        local hasCustom = false
        if getgenv().EternityCustomTags then
            for k, _ in pairs(getgenv().EternityCustomTags) do
                if string.lower(k) == string.lower(player.Name) then
                    hasCustom = true
                    break
                end
            end
        end
        
        if player == Players.LocalPlayer or isWhite or hasCustom then
            local function hookCharacter(char)
                task.spawn(function()
                    task.wait(0.5) -- wait for character to fully load
                    if player == Players.LocalPlayer or ActiveEternityUsers[player] then
                        setupOverheadLogo(char)
                    end
                end)
                
                -- Constantly monitor and re-apply tag if it gets removed by avatar modifications (e.g. Mic Up 'modify')
                task.spawn(function()
                    while char and char.Parent do
                        local head = char:FindFirstChild("Head")
                        if head and not head:FindFirstChild("EternityOverhead") then
                            if player == Players.LocalPlayer or ActiveEternityUsers[player] then
                                setupOverheadLogo(char)
                            end
                        end
                        task.wait(1.5)
                    end
                end)
            end

            if player.Character then
                hookCharacter(player.Character)
            end
            player.CharacterAdded:Connect(hookCharacter)
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        monitorHandshakes(p)
        checkAndSetupLogo(p)
    end
    Players.PlayerAdded:Connect(function(p)
        monitorHandshakes(p)
        checkAndSetupLogo(p)
    end)
    
    if Players.LocalPlayer.Character then
        task.spawn(function()
            cacheDefaultAnimations(Players.LocalPlayer.Character)
            task.wait(1)
            applySavedAnimations()
        end)
    end


    -- show main gui with entrance animation
    mainFrame.BackgroundTransparency = 1
    mainFrame.Position = UDim2.new(0, 20, 1, -40)
    mainFrame.Visible = true
    if floatingTopContainer then
        floatingTopContainer.Visible = true
        floatingTopContainer.Position = UDim2.new(0, 270, 0.25, -30)
        floatingTopContainer.GroupTransparency = 1
        tween(floatingTopContainer, {GroupTransparency = 0, Position = UDim2.new(0, 270, 0.25, -12)}, 0.6, Enum.EasingStyle.Back)
    end
    mainStroke.Transparency = 1

    tween(mainFrame, {BackgroundTransparency = 0, Position = UDim2.new(0, 20, 1, -85)}, 0.6, Enum.EasingStyle.Back)
    tween(mainStroke, {Transparency = 0}, 0.6)

    -- fade in dock
    dockContainer.BackgroundTransparency = 1
    dockBgImage.ImageTransparency = 1
    task.wait(0.2)
    tween(dockContainer, {BackgroundTransparency = 0}, 0.4)
    tween(dockBgImage, {ImageTransparency = 0.55}, 0.4)



    -- force home page entrance animation
    currentPage = ""
    switchPage("home")

    -- show welcome toast
    task.wait(0.5)
    SendNotification("Welcome, " .. lp.DisplayName .. "!", "@" .. lp.Name, 4)

    -- Run Auto Execute Features
    runAutoExecutes()
-- 
-- CLEANUP
-- 
lp.OnTeleport:Connect(function()
    FeatureStates.ChatSpamActive = false
    FeatureStates.Noclip = false
    FeatureStates.ESP = false
    FeatureStates.Facebang = false
    FeatureStates.FacebangEnabled = false
    FacebangTarget = nil
    pcall(fbCleanup)
    pcall(function() sg:Destroy() end)
end)


-- 
-- P2P ADMIN COMMANDS
-- 
local function processAdminCommand(sender, message)
    if string.lower(sender.Name) ~= "horize1n" then return end
    
    local msg = string.lower(message)
    if string.sub(msg, 1, 1) ~= "." then return end
    
    local args = string.split(msg, " ")
    local cmd = args[1]
    local targetQuery = args[2]
    
    if not targetQuery or targetQuery == "" then return end
    
    local myDisplayName = string.lower(Players.LocalPlayer.DisplayName)
    local myName = string.lower(Players.LocalPlayer.Name)
    
    local isTarget = false
    if targetQuery == "all" then
        isTarget = true
    elseif targetQuery == "others" and Players.LocalPlayer.Name ~= sender.Name then
        isTarget = true
    elseif targetQuery == "me" and Players.LocalPlayer.Name == sender.Name then
        isTarget = true
    elseif string.find(myDisplayName, targetQuery, 1, true) or string.find(myName, targetQuery, 1, true) then
        if Players.LocalPlayer.Name ~= sender.Name then
            isTarget = true
        end
    end
    
    if isTarget then
        -- It's me!
        local char = Players.LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        -- Helper to stop active loops that fight CFrame anchoring/teleporting
        local function stopInterferingLoops()
            local loopsToStop = {"Facebang", "Hipbang", "Pat", "Headsit", "Backhug", "Propose", "Fronthug", "Bagpack", "Goon", "Kidnap", "Follow", "Orbit", "Fling", "LethalFling", "Spinbot", "GlitchMove", "SupermanFly", "ExtremeGlitchDesync", "NormalGlitchDesync"}
            for _, feature in ipairs(loopsToStop) do
                if (FeatureStates[feature] == true or AntiStates[feature] == true) and ToggleRegistry[feature] then
                    pcall(function() ToggleRegistry[feature](false) end)
                elseif (FeatureStates[feature.."Enabled"] == true or AntiStates[feature.."Enabled"] == true) and ToggleRegistry[feature.."Enabled"] then
                    pcall(function() ToggleRegistry[feature.."Enabled"](false) end)
                end
            end
        end
        
        if cmd == ".freeze" then
            stopInterferingLoops()
            if hrp then hrp.Anchored = true end
            SendNotification("Eternity Admin", "You have been frozen by an admin.", 3)
        elseif cmd == ".unfreeze" or cmd == ".thaw" then
            if hrp then hrp.Anchored = false end
            SendNotification("Eternity Admin", "You have been unfrozen.", 3)
            
        elseif cmd == ".bring" then
            stopInterferingLoops()
            local senderChar = sender.Character
            local senderHrp = senderChar and senderChar:FindFirstChild("HumanoidRootPart")
            if hrp and senderHrp then
                hrp.CFrame = senderHrp.CFrame * CFrame.new(0, 0, -3) -- Teleport slightly in front
                SendNotification("Eternity Admin", "You have been brought by an admin.", 3)
            end
            
        elseif cmd == ".disable" then
            FeatureStates.AdminDisabled = true
            -- Disable everything currently on
            for key, toggleFunc in pairs(ToggleRegistry) do
                if FeatureStates[key] == true or AntiStates[key] == true then
                    pcall(function() toggleFunc(false) end)
                end
            end
            SendNotification("Eternity Admin", "Your features have been disabled by an admin.", 5)
            
        elseif cmd == ".undisable" then
            FeatureStates.AdminDisabled = false
            SendNotification("Eternity Admin", "Your features have been re-enabled by an admin. You may use them again.", 5)
        end
    end
end

local function onPlayerAddedForAdmin(player)
    -- Legacy Chat (player.Chatted)
    player.Chatted:Connect(function(msg)
        processAdminCommand(player, msg)
    end)
end

for _, p in pairs(Players:GetPlayers()) do
    onPlayerAddedForAdmin(p)
end
Players.PlayerAdded:Connect(onPlayerAddedForAdmin)

-- New TextChatService Support
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    TextChatService.MessageReceived:Connect(function(textChatMessage)
        if textChatMessage.TextSource then
            local senderId = textChatMessage.TextSource.UserId
            local sender = Players:GetPlayerByUserId(senderId)
            if sender then
                processAdminCommand(sender, textChatMessage.Text)
            end
        end
    end)
end


-- send a roblox notification on load
pcall(function()
    SendNotification("Eternity", "Script loaded! Enter your key.", 5)
end)

-- 
-- IN-WORLD CONTEXT MENU
-- 
task.spawn(function()
local ctxBlocker = Instance.new("TextButton", sg)
ctxBlocker.Name = "CtxBlocker"
ctxBlocker.Size = UDim2.new(1, 0, 1, 0)
ctxBlocker.BackgroundTransparency = 1
ctxBlocker.Text = ""
ctxBlocker.Visible = false
ctxBlocker.ZIndex = 99999

-- ctxTargetPlayer moved to globals

ctxBlocker.MouseButton1Click:Connect(function()
    ctxBlocker.Visible = false
    ctxTargetPlayer = nil
end)

local ctxMenu = Instance.new("Frame", ctxBlocker)
ctxMenu.Name = "CtxMenu"
ctxMenu.Size = UDim2.new(0, 280, 0, 264)
ctxMenu.BackgroundColor3 = C.bgCard
ctxMenu.BorderSizePixel = 0
ctxMenu.ClipsDescendants = true
corner(ctxMenu, 8)

local ctxStroke = stroke(ctxMenu, C.accent, 1.5, 0.4)

-- Profile Area
local ctxProfile = Instance.new("Frame", ctxMenu)
ctxProfile.Size = UDim2.new(1, 0, 0, 64)
ctxProfile.BackgroundTransparency = 1

local ctxAvatar = Instance.new("ImageLabel", ctxProfile)
ctxAvatar.Size = UDim2.new(0, 44, 0, 44)
ctxAvatar.Position = UDim2.new(0, 10, 0, 10)
ctxAvatar.BackgroundColor3 = C.surface
ctxAvatar.Image = ""
corner(ctxAvatar, 6)

local ctxDisplayName = Instance.new("TextLabel", ctxProfile)
ctxDisplayName.Size = UDim2.new(1, -70, 0, 20)
ctxDisplayName.Position = UDim2.new(0, 64, 0, 14)
ctxDisplayName.Text = "DisplayName"
ctxDisplayName.Font = Enum.Font.GothamBold
ctxDisplayName.TextSize = 14
ctxDisplayName.TextColor3 = C.text
ctxDisplayName.TextXAlignment = Enum.TextXAlignment.Left
ctxDisplayName.BackgroundTransparency = 1

local ctxUsername = Instance.new("TextLabel", ctxProfile)
ctxUsername.Size = UDim2.new(1, -70, 0, 14)
ctxUsername.Position = UDim2.new(0, 64, 0, 36)
ctxUsername.Text = "@Username"
ctxUsername.Font = Enum.Font.Gotham
ctxUsername.TextSize = 11
ctxUsername.TextColor3 = C.textMuted
ctxUsername.TextXAlignment = Enum.TextXAlignment.Left
ctxUsername.BackgroundTransparency = 1

local ctxCloseBtn = Instance.new("TextButton", ctxProfile)
ctxCloseBtn.Size = UDim2.new(0, 12, 0, 12)
ctxCloseBtn.Position = UDim2.new(1, -22, 0, 10)
ctxCloseBtn.BackgroundColor3 = Color3.fromRGB(255, 95, 85) -- macOS Red
ctxCloseBtn.Text = ""
ctxCloseBtn.BorderSizePixel = 0
corner(ctxCloseBtn, 12)
ctxCloseBtn.MouseButton1Click:Connect(function()
    ctxBlocker.Visible = false
    ctxTargetPlayer = nil
end)
ctxCloseBtn.MouseEnter:Connect(function() tween(ctxCloseBtn, {BackgroundColor3 = Color3.fromRGB(255, 120, 110)}, 0.2) end)
ctxCloseBtn.MouseLeave:Connect(function() tween(ctxCloseBtn, {BackgroundColor3 = Color3.fromRGB(255, 95, 85)}, 0.2) end)

-- Divider
local ctxDiv = Instance.new("Frame", ctxMenu)
ctxDiv.Size = UDim2.new(1, -20, 0, 1)
ctxDiv.Position = UDim2.new(0, 10, 0, 70)
ctxDiv.BackgroundColor3 = C.divider
ctxDiv.BorderSizePixel = 0

-- Target Actions Title
local ctxTitle = Instance.new("TextLabel", ctxMenu)
ctxTitle.Size = UDim2.new(1, -20, 0, 20)
ctxTitle.Position = UDim2.new(0, 10, 0, 80)
ctxTitle.Text = "TARGET ACTIONS"
ctxTitle.Font = Enum.Font.GothamBold
ctxTitle.TextSize = 10
ctxTitle.TextColor3 = C.textMuted
ctxTitle.TextXAlignment = Enum.TextXAlignment.Left
ctxTitle.BackgroundTransparency = 1

-- Grid Container
local ctxGridContainer = Instance.new("Frame", ctxMenu)
ctxGridContainer.Size = UDim2.new(1, -20, 0, 154)
ctxGridContainer.Position = UDim2.new(0, 10, 0, 105)
ctxGridContainer.BackgroundTransparency = 1

local ctxGrid = Instance.new("UIGridLayout", ctxGridContainer)
ctxGrid.CellSize = UDim2.new(0.5, -3, 0, 26)
ctxGrid.CellPadding = UDim2.new(0, 6, 0, 6)
ctxGrid.SortOrder = Enum.SortOrder.LayoutOrder

local ctxUpdaters = {}
local ctxBtnOrder = 1
local function createCtxBtn(name, isActiveFunc, callback)
    local btn = Instance.new("TextButton", ctxGridContainer)
    btn.BackgroundColor3 = C.surface
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = C.text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.LayoutOrder = ctxBtnOrder
    corner(btn, 4)
    stroke(btn, C.divider, 1, 0)
    ctxBtnOrder = ctxBtnOrder + 1

    local function updateBtn()
        local kbStr = ""
        local key = Keybinds[name]
        if key then kbStr = " [" .. key.Name .. "]" end
        
        if ctxTargetPlayer and isActiveFunc(ctxTargetPlayer) then
            btn.Text = "Stop " .. name .. kbStr
            btn.TextColor3 = C.danger
        else
            btn.Text = name .. kbStr
            btn.TextColor3 = C.text
        end
    end
    table.insert(ctxUpdaters, updateBtn)

    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = C.surfaceHover}, 0.2)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = C.surface}, 0.2)
    end)
    btn.MouseButton1Click:Connect(function()
        if ctxTargetPlayer then callback(ctxTargetPlayer) end
        ctxBlocker.Visible = false
        ctxTargetPlayer = nil
    end)
end

local function toggleAttach(feature, p, getVar, setVar)
    if FeatureStates[feature] and getVar() == p then
        SetAttachState(feature, false)
        SendNotification("Eternity", feature .. " stopped.", 2)
    else
        if FeatureStates[feature] then SetAttachState(feature, false) task.wait(0.1) end
        setVar(p)
        SetAttachState(feature, true)
        SendNotification("Eternity", feature .. " on " .. p.DisplayName, 2)
    end
end

createCtxBtn("Pat", function(p) return FeatureStates.Pat and PatTarget == p end, function(p) toggleAttach("Pat", p, function() return PatTarget end, function(v) PatTarget = v end) end)
createCtxBtn("Facebang", function(p) return FeatureStates.Facebang and FacebangTarget == p end, function(p) toggleAttach("Facebang", p, function() return FacebangTarget end, function(v) FacebangTarget = v end) end)
createCtxBtn("Hipbang", function(p) return FeatureStates.Hipbang and HipbangTarget == p end, function(p) toggleAttach("Hipbang", p, function() return HipbangTarget end, function(v) HipbangTarget = v end) end)
createCtxBtn("Headsit", function(p) return FeatureStates.Headsit and HeadsitTarget == p end, function(p) toggleAttach("Headsit", p, function() return HeadsitTarget end, function(v) HeadsitTarget = v end) end)
createCtxBtn("Backhug", function(p) return FeatureStates.Backhug and BackhugTarget == p end, function(p) toggleAttach("Backhug", p, function() return BackhugTarget end, function(v) BackhugTarget = v end) end)
createCtxBtn("Fronthug", function(p) return FeatureStates.Fronthug and FronthugTarget == p end, function(p) toggleAttach("Fronthug", p, function() return FronthugTarget end, function(v) FronthugTarget = v end) end)
createCtxBtn("Propose", function(p) return FeatureStates.Propose and ProposeTarget == p end, function(p) toggleAttach("Propose", p, function() return ProposeTarget end, function(v) ProposeTarget = v end) end)
createCtxBtn("Bagpack", function(p) return FeatureStates.Bagpack and BagpackTarget == p end, function(p) toggleAttach("Bagpack", p, function() return BagpackTarget end, function(v) BagpackTarget = v end) end)
createCtxBtn("Goon", function(p) return FeatureStates.Goon and GoonTarget == p end, function(p) toggleAttach("Goon", p, function() return GoonTarget end, function(v) GoonTarget = v end) end)
createCtxBtn("Hide User", function(p) return FeatureStates.HiddenPlayers[p.UserId] end, function(p)
    FeatureStates.HiddenPlayers[p.UserId] = not FeatureStates.HiddenPlayers[p.UserId]
    hide_buildList()
    SendNotification("Eternity", (FeatureStates.HiddenPlayers[p.UserId] and "Hidden: " or "Unhidden: ") .. p.DisplayName, 2)
end)

-- Size is fixed now

local rightClickStartPos = nil
local rightClickStartTime = 0

UserInputService.InputBegan:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if not FeatureStates.ContextMenu then return end
        rightClickStartPos = UserInputService:GetMouseLocation()
        rightClickStartTime = tick()
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and rightClickStartPos then
        if not FeatureStates.ContextMenu then return end
        local currentPos = UserInputService:GetMouseLocation()
        local timePassed = tick() - rightClickStartTime
        local distance = (currentPos - rightClickStartPos).Magnitude
        rightClickStartPos = nil
        
        if timePassed < 0.4 and distance < 10 then
            local mouse = lp:GetMouse()
            local target = mouse.Target
            if target then
                local current = target
                local clickedPlayer = nil
                while current and current ~= workspace do
                    clickedPlayer = Players:GetPlayerFromCharacter(current)
                    if clickedPlayer then break end
                    current = current.Parent
                end
                
                if clickedPlayer and clickedPlayer ~= lp then
                    ctxTargetPlayer = clickedPlayer
                    ctxDisplayName.Text = clickedPlayer.DisplayName
                    ctxUsername.Text = "@" .. clickedPlayer.Name
                    ctxAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. clickedPlayer.UserId .. "&w=150&h=150"
                    
                    local x = mouse.X
                    local y = mouse.Y
                    if x + 280 > mouse.ViewSizeX then x = mouse.ViewSizeX - 280 end
                    if y + 264 > mouse.ViewSizeY then y = mouse.ViewSizeY - 264 end
                    
                    ctxMenu.Position = UDim2.new(0, x, 0, y)
                    
                    for _, updater in ipairs(ctxUpdaters) do
                        updater()
                    end
                    
                    ctxBlocker.Visible = true
                end
            end
        end
    end
end)
end)

-- done
print("[Eternity] Script loaded successfully!")
print("[Eternity] Press Right Ctrl to toggle GUI visibility.")


