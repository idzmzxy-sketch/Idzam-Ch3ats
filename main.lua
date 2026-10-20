--[[
    Idzam Ch3atz v3 — Steal An Egg
    target : Roblox, executor (Delta / Xeno / Wave / Solara / Krnl)
    source : mekanik game dari wiki + script publik (bypass.tools, delta-scripts, scriptverse)
    note   : remote name di-derive otomatis dari ReplicatedStorage. kalau gagal, fallback ke ProximityPrompt.
]]

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    -- workspace
    EggContainer     = workspace,
    PenFolder        = workspace,
    TreadmillFolder  = workspace,

    -- scan
    EggKeywords      = {"egg", "nest", "crate"},
    PromptKeywords   = {"egg", "steal", "pickup", "take"},
    RemoteKeywords   = {"egg", "steal", "pick", "grab", "hatch", "place", "sell", "treadmill", "buy"},
    SellKeywords     = {"sell", "cashout", "collect"},
    HatchKeywords    = {"hatch", "open"},
    PlaceKeywords    = {"place", "equip"},

    -- behavior
    StealDelay       = 0.15,
    FarmCycleDelay   = 0.3,
    MinValueFilter   = 0,        -- $/s minimum, 0 = semua
    SpeedValue       = 28,
    JumpValue        = 60,
    RestoreSpeed     = 16,
    RestoreJump      = 50,
    AutoReturnBase   = true,
    BaseCFrame       = nil,      -- di-set pas startup / tombol "Set Base"

    -- visual
    AccentColor      = Color3.fromRGB(90, 255, 150),
    BgColor          = Color3.fromRGB(14, 14, 18),
    PanelColor       = Color3.fromRGB(22, 22, 28),
    TextColor        = Color3.fromRGB(220, 220, 225),
}

-- ============================================================
-- SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser      = game:GetService("VirtualUser")
local CoreGui          = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

-- ============================================================
-- STATE
-- ============================================================
local State = {
    AutoSteal      = false,
    AutoFarm       = false,
    AutoFarmIndex  = false,
    AutoHatch      = false,
    AutoPlace      = false,
    AutoSell       = false,
    AutoTreadmill  = false,
    EggESP         = false,
    PlayerESP      = false,
    Speed          = false,
    Jump           = false,
    Fly            = false,
    Noclip         = false,
    AntiAFK        = true,
    InstantPrompt  = true,
}

local Selected   = {}      -- egg name -> true
local EggCache   = {}      -- list of {obj, part, name, rarity, income, value, content}
local StolenSet  = {}
local RemoteMap  = {}      -- keyword -> RemoteEvent/RemoteFunction
local FarmIndex  = 0

-- ============================================================
-- HELPERS
-- ============================================================
local function getChar() return LP.Character or LP.CharacterAdded:Wait() end
local function getHRP()
    return getChar():FindFirstChild("HumanoidRootPart")
        or getChar():WaitForChild("HumanoidRootPart", 5)
end
local function getHumanoid() return getChar():FindFirstChildOfClass("Humanoid") end

local function nameMatchesAny(name, list)
    local l = name:lower()
    for _, kw in ipairs(list) do
        if l:find(kw, 1, true) then return true end
    end
    return false
end

local function isEgg(obj)
    if obj == getChar() then return false end
    if obj:IsA("BasePart") or obj:IsA("Model") then
        return nameMatchesAny(obj.Name, Config.EggKeywords)
    end
    return false
end

local function getEggPart(obj)
    if obj:IsA("BasePart") then return obj end
    return obj.PrimaryPart
        or obj:FindFirstChild("HumanoidRootPart")
        or obj:FindFirstChildWhichIsA("BasePart")
end

-- ============================================================
-- DEEP REMOTE SCANNER
-- ============================================================
local function scanRemotes()
    RemoteMap = {}
    local ok, desc = pcall(function()
        return ReplicatedStorage:GetDescendants()
    end)
    if not ok then return end
    for _, obj in ipairs(desc) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local ln = obj.Name:lower()
            for _, kw in ipairs(Config.RemoteKeywords) do
                if ln:find(kw, 1, true) then
                    -- simpan yang pertama ketemu per keyword, prioritaskan nama pendek
                    if not RemoteMap[kw] or #obj.Name < #RemoteMap[kw].Name then
                        RemoteMap[kw] = obj
                    end
                end
            end
        end
    end
end

local function callRemote(keyword, ...)
    local r = RemoteMap[keyword]
    if not r then return false end
    local args = {...}
    local ok = pcall(function()
        if r:IsA("RemoteFunction") then
            r:InvokeServer(unpack(args))
        else
            r:FireServer(unpack(args))
        end
    end)
    return ok
end

-- ============================================================
-- EGG INFO — rarity + income dari attribute/child
-- ============================================================
local ValueKeys = {"income", "value", "worth", "price", "cash", "money", "persecond", "per_second"}
local RarityKeys = {"rarity", "tier", "rank", "grade", "class"}
local ContentKeys = {"content", "pet", "reward", "inside", "hatch", "contains"}

local function readEggInfo(obj)
    local info = {
        obj = obj, name = obj.Name, rarity = "Common",
        income = 0, content = "?", part = getEggPart(obj),
    }
    -- attributes
    if obj.GetAttributes then
        for k, v in pairs(obj:GetAttributes()) do
            local lk = k:lower()
            if type(v) == "number" and nameMatchesAny(lk, ValueKeys) then
                info.income = math.max(info.income, v)
            end
            if nameMatchesAny(lk, RarityKeys) then info.rarity = tostring(v) end
            if nameMatchesAny(lk, ContentKeys) then info.content = tostring(v) end
        end
    end
    -- children
    for _, c in ipairs(obj:GetDescendants()) do
        if c:IsA("NumberValue") or c:IsA("IntValue") then
            local ln = c.Name:lower()
            if nameMatchesAny(ln, ValueKeys) then info.income = math.max(info.income, c.Value) end
        elseif c:IsA("StringValue") then
            local ln = c.Name:lower()
            if nameMatchesAny(ln, RarityKeys) then info.rarity = c.Value end
            if nameMatchesAny(ln, ContentKeys) then info.content = c.Value end
        end
    end
    info.value = info.income
    return info
end

local function refreshEggCache()
    EggCache = {}
    local ok, desc = pcall(function() return Config.EggContainer:GetDescendants() end)
    if not ok then return end
    for _, obj in ipairs(desc) do
        if isEgg(obj) then
            local part = getEggPart(obj)
            if part then table.insert(EggCache, readEggInfo(obj)) end
        end
    end
    table.sort(EggCache, function(a, b) return a.income > b.income end)
end

-- ============================================================
-- NOTIF
-- ============================================================
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "IdzamNotif"
notifGui.ResetOnSpawn = false
notifGui.Parent = CoreGui

local function notify(text)
    local box = Instance.new("TextLabel")
    box.Size = UDim2.new(0, 300, 0, 36)
    box.Position = UDim2.new(0.5, -150, 0, 30)
    box.BackgroundColor3 = Config.PanelColor
    box.BackgroundTransparency = 0.1
    box.BorderSizePixel = 0
    box.TextColor3 = Config.AccentColor
    box.Font = Enum.Font.GothamBold
    box.TextSize = 13
    box.Text = "Idzam Ch3atz — " .. text
    box.Parent = notifGui
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = box
    local s = Instance.new("UIStroke") s.Color = Config.AccentColor s.Transparency = 0.6 s.Parent = box
    task.delay(2.5, function()
        local tw = TweenService:Create(box, TweenInfo.new(0.4),
            { BackgroundTransparency = 1, TextTransparency = 1 })
        tw:Play()
        tw.Completed:Wait()
        box:Destroy()
    end)
end

-- ============================================================
-- ESP
-- ============================================================
local eggEspFolder    = Instance.new("Folder")
local playerEspFolder = Instance.new("Folder")
eggEspFolder.Name    = "IdzamEggESP"
playerEspFolder.Name = "IdzamPlayerESP"
eggEspFolder.Parent    = CoreGui
playerEspFolder.Parent = CoreGui

local function clearFolder(f)
    for _, c in ipairs(f:GetChildren()) do c:Destroy() end
end

local function makeBillboard(parent, adornee, text, color, subtext)
    local bb = Instance.new("BillboardGui")
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 260, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.55
    frame.BorderSizePixel = 0
    frame.Parent = bb
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 6) fc.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0.6, 0)
    lbl.Position = UDim2.new(0, 4, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color
    lbl.TextStrokeTransparency = 0.4
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    if subtext then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -8, 0.35, 0)
        sub.Position = UDim2.new(0, 4, 0.62, 0)
        sub.BackgroundTransparency = 1
        sub.Text = subtext
        sub.TextColor3 = Color3.fromRGB(180, 180, 185)
        sub.TextScaled = true
        sub.Font = Enum.Font.Gotham
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = frame
    end
    return bb
end

local function renderEggESP()
    clearFolder(eggEspFolder)
    if not State.EggESP then return end
    for _, e in ipairs(EggCache) do
        if e.part and e.part.Parent then
            local txt = string.format("%s  [%s]", e.name, e.rarity)
            local sub = string.format("$%d/s  |  %s", e.income, e.content)
            makeBillboard(eggEspFolder, e.part, txt, Config.AccentColor, sub)
        end
    end
end

local function renderPlayerESP()
    clearFolder(playerEspFolder)
    if not State.PlayerESP then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head then makeBillboard(playerEspFolder, head, plr.Name, Color3.fromRGB(255, 90, 90)) end
        end
    end
end

task.spawn(function()
    while task.wait(1) do
        refreshEggCache()
        if State.EggESP then renderEggESP() end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if State.PlayerESP then renderPlayerESP() end
    end
end)

-- ============================================================
-- TELEPORT / INTERACT
-- ============================================================
local function tpTo(pos, instant)
    local hrp = getHRP()
    if not hrp then return end
    local cf = CFrame.new(pos + Vector3.new(0, 3, 0))
    if instant then hrp.CFrame = cf
    else
        TweenService:Create(hrp,
            TweenInfo.new(0.12, Enum.EasingStyle.Linear),
            { CFrame = cf }):Play()
    end
end

local function firePrompts(obj)
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            if Config.InstantPrompt and type(fireproximityprompt) == "function" then
                pcall(fireproximityprompt, d)
            else
                pcall(function()
                    d:InputHoldBegin()
                    task.wait(math.max(d.HoldDuration or 0.1, 0.1))
                    d:InputHoldEnd()
                end)
            end
        end
    end
end

-- ============================================================
-- STEAL ENGINE — prompt dulu, remote sebagai fallback
-- ============================================================
local function eggAllowed(info)
    if info.income < Config.MinValueFilter then return false end
    local anySelected = next(Selected) ~= nil
    if anySelected then return Selected[info.name] == true end
    return true
end

local function nearestAllowedEgg()
    local hrp = getHRP()
    if not hrp then return nil end
    local best, bestDist
    for _, e in ipairs(EggCache) do
        if e.part and e.part.Parent and eggAllowed(e) then
            local d = (e.part.Position - hrp.Position).Magnitude
            if not bestDist or d < bestDist then best, bestDist = e, d end
        end
    end
    return best, bestDist
end

local function stealEgg(info)
    if not info or not info.part or not info.part.Parent then return false end
    tpTo(info.part.Position, true)
    task.wait(0.08)
    firePrompts(info.obj)
    -- fallback remote
    if not info.obj:FindFirstChildWhichIsA("ProximityPrompt", true) then
        for _, kw in ipairs({"steal", "egg", "pick"}) do
            if RemoteMap[kw] then
                callRemote(kw, info.name)
                break
            end
        end
    end
    StolenSet[info.name] = (StolenSet[info.name] or 0) + 1
    return true
end

-- ============================================================
-- AUTO LOOPS
-- ============================================================
task.spawn(function()
    while task.wait(Config.StealDelay) do
        if State.AutoSteal then
            refreshEggCache()
            local e = nearestAllowedEgg()
            if e then stealEgg(e) end
        end
    end
end)

task.spawn(function()
    while task.wait(Config.FarmCycleDelay) do
        if State.AutoFarm then
            refreshEggCache()
            local e = nearestAllowedEgg()
            if e then stealEgg(e) end
        end
    end
end)

task.spawn(function()
    while task.wait(Config.FarmCycleDelay) do
        if State.AutoFarmIndex then
            refreshEggCache()
            local picked
            for i = FarmIndex + 1, #EggCache do
                local e = EggCache[i]
                if e.part and e.part.Parent and eggAllowed(e) then
                    picked = e
                    FarmIndex = i
                    break
                end
            end
            if picked then stealEgg(picked) else FarmIndex = 0 end
        end
    end
end)

-- ============================================================
-- HATCH / PLACE / SELL / TREADMILL
-- ============================================================
local function tryHatch()
    for _, kw in ipairs({"hatch", "open"}) do
        if RemoteMap[kw] then callRemote(kw); return true end
    end
    -- prompt di pen
    for _, d in ipairs(Config.PenFolder:GetDescendants()) do
        if d:IsA("ProximityPrompt") and nameMatchesAny(d.Name, Config.HatchKeywords) then
            pcall(function()
                if type(fireproximityprompt) == "function" then fireproximityprompt(d) end
            end)
            return true
        end
    end
    return false
end

local function tryPlace()
    for _, kw in ipairs({"place", "equip"}) do
        if RemoteMap[kw] then callRemote(kw); return true end
    end
    return false
end

local function trySell()
    for _, kw in ipairs({"sell", "cashout", "collect"}) do
        if RemoteMap[kw] then callRemote(kw, "all"); return true end
    end
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and nameMatchesAny(d.Name, Config.SellKeywords) then
            pcall(function()
                if type(fireproximityprompt) == "function" then fireproximityprompt(d) end
            end)
            return true
        end
    end
    return false
end

local function tryTreadmill()
    for _, kw in ipairs({"treadmill"}) do
        if RemoteMap[kw] then callRemote(kw); return true end
    end
    return false
end

task.spawn(function() while task.wait(2) do if State.AutoHatch then tryHatch() end end end)
task.spawn(function() while task.wait(2) do if State.AutoPlace then tryPlace() end end end)
task.spawn(function() while task.wait(3) do if State.AutoSell then trySell() end end end)
task.spawn(function() while task.wait(2) do if State.AutoTreadmill then tryTreadmill() end end end)

-- ============================================================
-- MOVEMENT
-- ============================================================
local function applySpeed()
    local h = getHumanoid()
    if h then h.WalkSpeed = State.Speed and Config.SpeedValue or Config.RestoreSpeed end
end
local function applyJump()
    local h = getHumanoid()
    if h then
        h.UseJumpPower = true
        h.JumpPower = State.Jump and Config.JumpValue or Config.RestoreJump
    end
end

LP.CharacterAdded:Connect(function()
    task.wait(1)
    applySpeed() applyJump()
end)

-- fly
local flyBV, flyBG
local function setFly(on)
    local hrp = getHRP()
    if not hrp then return end
    if on then
        if not flyBV then
            flyBV = Instance.new("BodyVelocity")
            flyBV.Velocity = Vector3.zero
            flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flyBV.Parent = hrp
        end
        if not flyBG then
            flyBG = Instance.new("BodyGyro")
            flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            flyBG.P = 1000 flyBG.D = 50
            flyBG.CFrame = hrp.CFrame
            flyBG.Parent = hrp
        end
        task.spawn(function()
            while State.Fly and flyBV and flyBV.Parent do
                local cam = workspace.CurrentCamera
                local move = getHumanoid() and getHumanoid().MoveDirection or Vector3.zero
                local dir = Vector3.zero
                if move.Magnitude > 0 then
                    dir = cam.CFrame:VectorToWorldSpace(Vector3.new(move.X, 0, move.Z)) * 60
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 60, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 60, 0) end
                flyBV.Velocity = dir
                flyBG.CFrame = cam.CFrame
                task.wait()
            end
        end)
    else
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyBG then flyBG:Destroy() flyBG = nil end
    end
end

-- noclip
task.spawn(function()
    while task.wait(0.2) do
        if State.Noclip then
            local char = LP.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                end
            end
        end
    end
end)

-- anti afk
LP.Idled:Connect(function()
    if State.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end
end)

-- ============================================================
-- BASE
-- ============================================================
local function setBase()
    local hrp = getHRP()
    if hrp then
        Config.BaseCFrame = hrp.CFrame
        notify("base di-set")
    end
end

local function tpBase()
    if Config.BaseCFrame then
        local hrp = getHRP()
        if hrp then hrp.CFrame = Config.BaseCFrame + Vector3.new(0, 3, 0) end
    else
        notify("base belum di-set")
    end
end

-- ============================================================
-- UI — TAB-BASED DARK GLASS
-- ============================================================
local ui = Instance.new("ScreenGui")
ui.Name = "IdzamCh3atzUI"
ui.ResetOnSpawn = false
ui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 340, 0, 500)
main.Position = UDim2.new(0, 40, 0.5, -250)
main.BackgroundColor3 = Config.BgColor
main.BackgroundTransparency = 0.05
main.BorderSizePixel = 0
main.Parent = ui
local mc = Instance.new("UICorner") mc.CornerRadius = UDim.new(0, 12) mc.Parent = main
local ms = Instance.new("UIStroke") ms.Color = Config.AccentColor ms.Thickness = 1 ms.Transparency = 0.3 ms.Parent = main

-- header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundTransparency = 1
header.Parent = main
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Text = "IDZAM CH3ATZ"
title.TextColor3 = Config.AccentColor
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- tab bar
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -24, 0, 30)
tabBar.Position = UDim2.new(0, 12, 0, 44)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main
local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabBar

-- content
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -24, 1, -122)
content.Position = UDim2.new(0, 12, 0, 80)
content.BackgroundTransparency = 1
content.Parent = main

local pages = {}
local currentPage

local function newPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Config.AccentColor
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = content
    local pl = Instance.new("UIListLayout")
    pl.Padding = UDim.new(0, 5)
    pl.SortOrder = Enum.SortOrder.LayoutOrder
    pl.Parent = page
    pl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pl.AbsoluteContentSize.Y + 10)
    end)
    pages[name] = page
    return page
end

local function showPage(name)
    for _, p in pairs(pages) do p.Visible = false end
    if pages[name] then pages[name].Visible = true end
    currentPage = name
    -- update tab highlight
    for _, btn in ipairs(tabBar:GetChildren()) do
        if btn:IsA("TextButton") then
            btn.TextColor3 = (btn.Name == name) and Config.AccentColor or Color3.fromRGB(120, 120, 130)
            btn.BackgroundColor3 = (btn.Name == name) and Color3.fromRGB(30, 40, 34) or Color3.fromRGB(24, 24, 30)
        end
    end
end

local function addTab(name)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 78, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(120, 120, 130)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = tabBar
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = btn
    btn.MouseButton1Click:Connect(function() showPage(name) end)
    return btn
end

local function addToggle(page, label, key, onChanged)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Config.TextColor
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = "  " .. label .. "  [OFF]"
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.Parent = page
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = btn
    btn.MouseButton1Click:Connect(function()
        State[key] = not State[key]
        if State[key] then
            btn.Text = "  " .. label .. "  [ON]"
            btn.TextColor3 = Config.AccentColor
            btn.BackgroundColor3 = Color3.fromRGB(24, 44, 30)
        else
            btn.Text = "  " .. label .. "  [OFF]"
            btn.TextColor3 = Config.TextColor
            btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
        end
        if onChanged then onChanged() end
    end)
    return btn
end

local function addButton(page, label, color, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = color or Color3.fromRGB(34, 34, 42)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Config.TextColor
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Text = "  " .. label
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.Parent = page
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = btn
    btn.MouseButton1Click:Connect(onClick)
    return btn
end

-- ============================================================
-- PAGES
-- ============================================================
local farmPage = newPage("Farm")
local eggPage  = newPage("Eggs")
local playerPage = newPage("Player")
local miscPage = newPage("Misc")

addToggle(farmPage, "Auto Steal", "AutoSteal")
addToggle(farmPage, "Auto Farm (loop)", "AutoFarm")
addToggle(farmPage, "Auto Farm Index (value desc)", "AutoFarmIndex", function() FarmIndex = 0 end)
addToggle(farmPage, "Auto Hatch", "AutoHatch")
addToggle(farmPage, "Auto Place", "AutoPlace")
addToggle(farmPage, "Auto Sell", "AutoSell")
addToggle(farmPage, "Auto Treadmill", "AutoTreadmill")

addButton(farmPage, "Set Base (current pos)", Color3.fromRGB(40, 60, 90), setBase)
addButton(farmPage, "Teleport to Base", Color3.fromRGB(40, 60, 90), tpBase)

-- egg page
local scanBtn = addButton(eggPage, "Scan Eggs (deep)", Color3.fromRGB(60, 40, 90), function()
    refreshEggCache()
    notify(string.format("%d egg | %d remote ketemu", #EggCache, (function()
        local n = 0 for _ in pairs(RemoteMap) do n = n + 1 end return n
    end)()))
    buildEggList()
end)

local eggListFrame = Instance.new("Frame")
eggListFrame.Size = UDim2.new(1, 0, 0, 220)
eggListFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
eggListFrame.BorderSizePixel = 0
eggListFrame.Parent = eggPage
local elfc = Instance.new("UICorner") elfc.CornerRadius = UDim.new(0, 6) elfc.Parent = eggListFrame

local eggScroll = Instance.new("ScrollingFrame")
eggScroll.Size = UDim2.new(1, -8, 1, -8)
eggScroll.Position = UDim2.new(0, 4, 0, 4)
eggScroll.BackgroundTransparency = 1
eggScroll.BorderSizePixel = 0
eggScroll.ScrollBarThickness = 3
eggScroll.ScrollBarImageColor3 = Config.AccentColor
eggScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
eggScroll.Parent = eggListFrame
local eggLayout = Instance.new("UIListLayout")
eggLayout.Padding = UDim.new(0, 4)
eggLayout.Parent = eggScroll

function buildEggList()
    for _, c in ipairs(eggScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for _, e in ipairs(EggCache) do
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = Selected[e.name] and Color3.fromRGB(26, 50, 34) or Color3.fromRGB(26, 26, 32)
        row.BorderSizePixel = 0
        row.TextColor3 = Selected[e.name] and Config.AccentColor or Color3.fromRGB(200, 200, 205)
        row.Font = Enum.Font.Gotham
        row.TextSize = 10
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.Text = string.format("  %s  ·  %s  ·  $%d/s", e.name, e.rarity, e.income)
        row.AutoButtonColor = false
        row.Parent = eggScroll
        local rc = Instance.new("UICorner") rc.CornerRadius = UDim.new(0, 4) rc.Parent = row
        row.MouseButton1Click:Connect(function()
            Selected[e.name] = not Selected[e.name] or nil
            row.BackgroundColor3 = Selected[e.name] and Color3.fromRGB(26, 50, 34) or Color3.fromRGB(26, 26, 32)
            row.TextColor3 = Selected[e.name] and Config.AccentColor or Color3.fromRGB(200, 200, 205)
        end)
    end
    eggScroll.CanvasSize = UDim2.new(0, 0, 0, eggLayout.AbsoluteContentSize.Y + 6)
end

addButton(eggPage, "Clear Selection", Color3.fromRGB(70, 30, 30), function()
    Selected = {}
    buildEggList()
    notify("selection cleared")
end)

-- min value input
local minFrame = Instance.new("Frame")
minFrame.Size = UDim2.new(1, 0, 0, 32)
minFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
minFrame.BorderSizePixel = 0
minFrame.Parent = eggPage
local mfc = Instance.new("UICorner") mfc.CornerRadius = UDim.new(0, 6) mfc.Parent = minFrame

local minBox = Instance.new("TextBox")
minBox.Size = UDim2.new(1, -8, 1, -4)
minBox.Position = UDim2.new(0, 4, 0, 2)
minBox.BackgroundTransparency = 1
minBox.TextColor3 = Config.TextColor
minBox.Font = Enum.Font.Gotham
minBox.TextSize = 11
minBox.PlaceholderText = "min income $/s (0 = semua)"
minBox.Text = "0"
minBox.Parent = minFrame
minBox.FocusLost:Connect(function()
    Config.MinValueFilter = math.max(0, tonumber(minBox.Text) or 0)
    notify("min income = $" .. Config.MinValueFilter .. "/s")
end)

-- player page
addToggle(playerPage, "Speed", "Speed", applySpeed)
addToggle(playerPage, "Jump", "Jump", applyJump)
addToggle(playerPage, "Fly", "Fly", function() setFly(State.Fly) end)
addToggle(playerPage, "Noclip", "Noclip")
addToggle(playerPage, "Anti-AFK", "AntiAFK")
addToggle(playerPage, "Instant Prompt", "InstantPrompt")
addToggle(playerPage, "Egg ESP", "EggESP", function() renderEggESP() end)
addToggle(playerPage, "Player ESP", "PlayerESP", function() renderPlayerESP() end)

-- misc
addButton(miscPage, "Rescan Remotes", Color3.fromRGB(50, 50, 70), function()
    scanRemotes()
    local n = 0 for _ in pairs(RemoteMap) do n = n + 1 end
    notify(string.format("%d remote ke-map", n))
end)
addButton(miscPage, "Server Hop", Color3.fromRGB(50, 50, 70), function()
    local ok, res = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    end)
    if not ok then notify("hop gagal") return end
    local ok2, data = pcall(function() return game:GetService("HttpService"):JSONDecode(res) end)
    if not ok2 then notify("hop gagal") return end
    for _, s in ipairs(data.data or {}) do
        if s.id ~= game.JobId and s.playing < s.maxPlayers then
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id) end)
            return
        end
    end
    notify("server penuh / gagal")
end)

-- ============================================================
-- TABS
-- ============================================================
addTab("Farm") addTab("Eggs") addTab("Player") addTab("Misc")
showPage("Farm")

-- drag
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true dragStart = input.Position startPos = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                  startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- ============================================================
-- INIT
-- ============================================================
scanRemotes()
refreshEggCache()
buildEggList()
applySpeed() applyJump()
notify(string.format("v3 loaded — %d egg | %d remote", #EggCache, (function()
    local n = 0 for _ in pairs(RemoteMap) do n = n + 1 end return n
end)()))
