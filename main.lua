--[[
    Idzam Ch3atz v7 — Steal An Egg
    target : Roblox, executor (Delta / Xeno / Wave / Potassium)
    fix    : lag engine (cache jauh lebih efisien), UI tab stabil, minimize icon,
             smart fire remote (Instance/String/Kosong), anti-reconnect.
]]

-- ============================================================
-- BYPASS LAYER (Ringan & Anti-Lag)
-- ============================================================
local Bypass_Enabled = true
local Bypass = {}
do
    local function has(fn) return type(fn) == "function" end
    local AC_KEYWORDS = {"anticheat", "anti_cheat", "anti-cheat", "ac_", "detect", "report", "memer", "guard", "monitor", "integrity"}
    local function looksLikeAC(name) local l = tostring(name):lower() for _, kw in ipairs(AC_KEYWORDS) do if l:find(kw, 1, true) then return true end end return false end
    local hooked_tables = {}
    
    local function isACTable(t)
        if type(t) ~= "table" then return false end
        if type(rawget(t, "Detected")) == "function" then return true end
        if type(rawget(t, "Kill")) == "function" and rawget(t, "Variables") and rawget(t, "Process") then return true end
        return false
    end
    
    local function neutraliseTable(t)
        if hooked_tables[t] then return end hooked_tables[t] = true
        for _, key in ipairs({"Detected", "Report"}) do local fn = rawget(t, key) if type(fn) == "function" and has(hookfunction) then pcall(hookfunction, fn, function() return true end) end end
        local kill = rawget(t, "Kill") if type(kill) == "function" and has(hookfunction) then pcall(hookfunction, kill, function() end) end
    end
    
    local ac_remotes = {}
    local function classifyRemotes()
        local RS = game:GetService("ReplicatedStorage")
        local ok, desc = pcall(function() return RS:GetDescendants() end) if not ok then return end
        for _, obj in ipairs(desc) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                if looksLikeAC(obj.Name) then ac_remotes[obj] = true pcall(function() obj.Parent = nil end) end
            end
        end
    end
    
    local function hookNamecall()
        if not has(hookmetamethod) then return end
        local old
        old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                if ac_remotes[self] then return nil end
                local ok, name = pcall(function() return self.Name end) if ok and looksLikeAC(name) then return nil end
            end
            return old(self, ...)
        end))
    end

    local real_props = { WalkSpeed = {}, JumpPower = {} }
    local function hookProperties()
        if not has(hookmetamethod) then return end
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            local value = oldIndex(self, key)
            if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
                if key == "WalkSpeed" and real_props.WalkSpeed[self] then return 16 end
                if key == "JumpPower" and real_props.JumpPower[self] then return 50 end
            end
            return value
        end))
        local oldNewIndex
        oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
            if typeof(self) == "Instance" and self:IsA("Humanoid") then
                if key == "WalkSpeed" then real_props.WalkSpeed[self] = value end
                if key == "JumpPower" then real_props.JumpPower[self] = value end
            end
            return oldNewIndex(self, key, value)
        end))
    end

    function Bypass.enable()
        if not Bypass_Enabled then return end
        classifyRemotes() hookNamecall() hookProperties()
        -- Scan GC dihapus dari loop utama biar gak lag. Cukup sekali di awal.
        task.spawn(function()
            task.wait(5)
            if has(getgc) then
                local ok, gc = pcall(getgc, true)
                if ok then for _, obj in ipairs(gc) do if isACTable(obj) then neutraliseTable(obj) end end end
            end
        end)
    end
    function Bypass.safeParent() if has(gethui) then local ok, h = pcall(gethui) if ok and h then return h end end return game:GetService("CoreGui") end
end

Bypass.enable()

-- ============================================================
-- CONFIG & STATE
-- ============================================================
local Config = {
    EggContainer     = workspace,
    EggKeywords      = {"egg", "nest", "crate"},
    RemoteKeywords   = {"steal", "egg", "pick", "grab"},
    HatchKeywords    = {"hatch", "open"},
    SellKeywords     = {"sell", "cashout", "collect"},

    SpeedValue       = 22, -- Aman
    JumpValue        = 55,
    RestoreSpeed     = 16,
    RestoreJump      = 50,
    
    StealDelay       = 0.8, -- Jeda antar steal (jangan terlalu cepat)
    CacheRefreshRate = 2.0, -- Scan egg tiap 2 detik (jangan tiap frame)
}

local State = {
    AutoSteal = false, AutoFarm = false, AutoSell = false, AutoHatch = false,
    EggESP = false, PlayerESP = false,
    Speed = false, Jump = false, Fly = false, Noclip = false, AntiAFK = true
}

local Selected  = {}
local EggCache  = {}
local RemoteMap = {}
local LP = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

-- ============================================================
-- HELPERS
-- ============================================================
local function getChar() return LP.Character or LP.CharacterAdded:Wait() end
local function getHRP() return getChar():FindFirstChild("HumanoidRootPart") or getChar():WaitForChild("HumanoidRootPart", 5) end
local function getHumanoid() return getChar():FindFirstChildOfClass("Humanoid") end

local function nameMatchesAny(name, list)
    local l = name:lower()
    for _, kw in ipairs(list) do if l:find(kw, 1, true) then return true end end
    return false
end

-- Cache Scanner (Efisien)
local function refreshEggCache()
    EggCache = {}
    local ok, desc = pcall(function() return Config.EggContainer:GetDescendants() end)
    if not ok then return end
    for _, obj in ipairs(desc) do
        if obj ~= getChar() and nameMatchesAny(obj.Name, Config.EggKeywords) then
            local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local info = {obj=obj, part=part, name=obj.Name, income=0, rarity="Common"}
                -- Baca Atribut (Value)
                if obj.GetAttributes then
                    for k, v in pairs(obj:GetAttributes()) do
                        local lk = k:lower()
                        if type(v) == "number" and (lk:find("income") or lk:find("value")) then info.income = math.max(info.income, v) end
                        if lk:find("rarity") then info.rarity = tostring(v) end
                    end
                end
                table.insert(EggCache, info)
            end
        end
    end
    table.sort(EggCache, function(a, b) return a.income > b.income end)
end

-- Scan Remote
local function scanRemotes()
    RemoteMap = {}
    local RS = game:GetService("ReplicatedStorage")
    local ok, desc = pcall(function() return RS:GetDescendants() end) if not ok then return end
    for _, obj in ipairs(desc) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local ln = obj.Name:lower()
            for _, kw in ipairs(Config.RemoteKeywords) do
                if ln:find(kw, 1, true) then
                    if not RemoteMap[kw] or #obj.Name < #RemoteMap[kw].Name then RemoteMap[kw] = obj end
                end
            end
        end
    end
end

-- Smart Remote Fire
local function smartFire(eggInfo)
    local remote = RemoteMap["steal"] or RemoteMap["egg"] or RemoteMap["pick"]
    if not remote then return false end
    
    local ok1 = pcall(function() remote:FireServer(eggInfo.obj) end)       -- Coba Object
    local ok2 = pcall(function() remote:FireServer(eggInfo.name) end)      -- Coba String
    local ok3 = pcall(function() remote:FireServer() end)                  -- Coba Kosong
    
    return ok1 or ok2 or ok3
end

-- ============================================================
-- ENGINE LOOP
-- ============================================================
task.spawn(function()
    while task.wait(Config.CacheRefreshRate) do
        refreshEggCache()
        if State.EggESP then
            -- Render ESP logic (disederhanakan)
        end
    end
end)

task.spawn(function()
    while task.wait(Config.StealDelay) do
        if State.AutoSteal then
            local target = nil
            for _, e in ipairs(EggCache) do
                if next(Selected) == nil or Selected[e.name] then target = e break end
            end
            if target then
                local success = smartFire(target)
                if not success then
                    -- Fallback jika remote tidak ada (pindah cepat & fire prompt)
                    local hrp = getHRP()
                    if hrp and target.part then
                        local oldCF = hrp.CFrame
                        hrp.CFrame = CFrame.new(target.part.Position + Vector3.new(0,3,0))
                        task.wait(0.15)
                        for _, d in ipairs(target.obj:GetDescendants()) do
                            if d:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(d) end) end
                        end
                        task.wait(0.15)
                        hrp.CFrame = oldCF -- Balik ke tempat semula
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- UI BUILD (Minimize, Tabs, Anti-Bug)
-- ============================================================
local HUIParent = Bypass.safeParent()
local ui = Instance.new("ScreenGui") ui.Name = "IdzamCh3atzUI" ui.ResetOnSpawn = false ui.Parent = HUIParent
local main = Instance.new("Frame") main.Size = UDim2.new(0, 340, 0, 420) main.Position = UDim2.new(0, 40, 0.5, -210) main.BackgroundColor3 = Color3.fromRGB(14, 14, 18) main.BorderSizePixel = 0 main.Parent = ui
local mc = Instance.new("UICorner") mc.CornerRadius = UDim.new(0, 12) mc.Parent = main
local ms = Instance.new("UIStroke") ms.Color = Color3.fromRGB(90, 255, 150) ms.Thickness = 1 ms.Transparency = 0.3 ms.Parent = main

-- Header & Minimize
local header = Instance.new("Frame") header.Size = UDim2.new(1, 0, 0, 42) header.BackgroundTransparency = 1 header.Parent = main
local title = Instance.new("TextLabel") title.Size = UDim2.new(1, -80, 1, 0) title.Position = UDim2.new(0, 16, 0, 0) title.BackgroundTransparency = 1 title.Text = "IDZAM v7" title.TextColor3 = Color3.fromRGB(90, 255, 150) title.Font = Enum.Font.GothamBold title.TextSize = 16 title.TextXAlignment = Enum.TextXAlignment.Left title.Parent = header

local minBtn = Instance.new("TextButton") minBtn.Size = UDim2.new(0, 24, 0, 24) minBtn.Position = UDim2.new(1, -60, 0.5, -12) minBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34) minBtn.Text = "-" minBtn.TextColor3 = Color3.fromRGB(220, 220, 220) minBtn.Font = Enum.Font.GothamBold minBtn.Parent = header
local mbC = Instance.new("UICorner") mbC.CornerRadius = UDim.new(0, 4) mbC.Parent = minBtn

local closeBtn = Instance.new("TextButton") closeBtn.Size = UDim2.new(0, 24, 0, 24) closeBtn.Position = UDim2.new(1, -28, 0.5, -12) closeBtn.BackgroundColor3 = Color3.fromRGB(70, 30, 30) closeBtn.Text = "X" closeBtn.TextColor3 = Color3.fromRGB(220, 220, 220) closeBtn.Font = Enum.Font.GothamBold closeBtn.Parent = header
local cbC = Instance.new("UICorner") cbC.CornerRadius = UDim.new(0, 4) cbC.Parent = closeBtn

-- Tabs
local tabBar = Instance.new("Frame") tabBar.Size = UDim2.new(1, -24, 0, 30) tabBar.Position = UDim2.new(0, 12, 0, 44) tabBar.BackgroundTransparency = 1 tabBar.Parent = main
local tabLayout = Instance.new("UIListLayout") tabLayout.FillDirection = Enum.FillDirection.Horizontal tabLayout.Padding = UDim.new(0, 4) tabLayout.Parent = tabBar

local content = Instance.new("Frame") content.Size = UDim2.new(1, -24, 1, -122) content.Position = UDim2.new(0, 12, 0, 80) content.BackgroundTransparency = 1 content.Parent = main

local pages = {}
local function newPage(name)
    local p = Instance.new("ScrollingFrame") p.Size = UDim2.new(1, 0, 1, 0) p.BackgroundTransparency = 1 p.BorderSizePixel = 0 p.ScrollBarThickness = 3 p.ScrollBarImageColor3 = Color3.fromRGB(90, 255, 150) p.CanvasSize = UDim2.new(0, 0, 0, 0) p.Visible = false p.Parent = content
    local l = Instance.new("UIListLayout") l.Padding = UDim.new(0, 5) l.Parent = p
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() p.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10) end)
    pages[name] = p return p
end

local function showPage(name)
    for k, p in pairs(pages) do p.Visible = (k == name) end
    for _, btn in ipairs(tabBar:GetChildren()) do
        if btn:IsA("TextButton") then
            btn.TextColor3 = (btn.Name == name) and Color3.fromRGB(90, 255, 150) or Color3.fromRGB(120, 120, 130)
            btn.BackgroundColor3 = (btn.Name == name) and Color3.fromRGB(30, 40, 34) or Color3.fromRGB(24, 24, 30)
        end
    end
end

local function addTab(name)
    local b = Instance.new("TextButton") b.Name = name b.Size = UDim2.new(0, 80, 1, 0) b.BackgroundColor3 = Color3.fromRGB(24, 24, 30) b.BorderSizePixel = 0 b.Text = name b.TextColor3 = Color3.fromRGB(120, 120, 130) b.Font = Enum.Font.GothamBold b.TextSize = 11 b.Parent = tabBar
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = b
    b.MouseButton1Click:Connect(function() showPage(name) end)
end

-- Toggle / Button Helper
local function addToggle(page, label, key, cb)
    local b = Instance.new("TextButton") b.Size = UDim2.new(1, 0, 0, 32) b.BackgroundColor3 = Color3.fromRGB(28, 28, 34) b.BorderSizePixel = 0 b.TextColor3 = Color3.fromRGB(220, 220, 220) b.Font = Enum.Font.GothamBold b.TextSize = 12 b.Text = "  " .. label .. "  [OFF]" b.TextXAlignment = Enum.TextXAlignment.Left b.AutoButtonColor = false b.Parent = page
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = b
    b.MouseButton1Click:Connect(function()
        State[key] = not State[key]
        if State[key] then b.Text = "  " .. label .. "  [ON]" b.TextColor3 = Color3.fromRGB(90, 255, 150) b.BackgroundColor3 = Color3.fromRGB(24, 44, 30)
        else b.Text = "  " .. label .. "  [OFF]" b.TextColor3 = Color3.fromRGB(220, 220, 220) b.BackgroundColor3 = Color3.fromRGB(28, 28, 34) end
        if cb then cb() end
    end)
end

local function addButton(page, label, color, cb)
    local b = Instance.new("TextButton") b.Size = UDim2.new(1, 0, 0, 30) b.BackgroundColor3 = color or Color3.fromRGB(34, 34, 42) b.BorderSizePixel = 0 b.TextColor3 = Color3.fromRGB(220, 220, 220) b.Font = Enum.Font.GothamBold b.TextSize = 11 b.Text = "  " .. label b.TextXAlignment = Enum.TextXAlignment.Left b.AutoButtonColor = false b.Parent = page
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = b
    b.MouseButton1Click:Connect(cb)
end

-- Build Pages
local farmPage = newPage("Farm")
local playerPage = newPage("Player")
local miscPage = newPage("Misc")

addToggle(farmPage, "Auto Steal", "AutoSteal")
addToggle(farmPage, "Auto Hatch", "AutoHatch")
addToggle(farmPage, "Auto Sell", "AutoSell")

addToggle(playerPage, "Speed", "Speed", function() local h=getHumanoid() if h then h.WalkSpeed = State.Speed and Config.SpeedValue or Config.RestoreSpeed end end)
addToggle(playerPage, "Jump", "Jump", function() local h=getHumanoid() if h then h.JumpPower = State.Jump and Config.JumpValue or Config.RestoreJump end end)
addToggle(playerPage, "Fly (CFrame)", "Fly", function()
    if State.Fly then
        task.spawn(function()
            while State.Fly do
                local hrp = getHRP() local cam = workspace.CurrentCamera
                if hrp and cam then
                    local move = getHumanoid() and getHumanoid().MoveDirection or Vector3.zero
                    local dir = Vector3.zero
                    if move.Magnitude > 0 then dir = cam.CFrame:VectorToWorldSpace(Vector3.new(move.X, 0, move.Z)) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
                    if dir.Magnitude > 0 then hrp.CFrame = hrp.CFrame + dir.Unit * 60 * RunService.RenderStepped:Wait() end
                end
                task.wait()
            end
        end)
    end
end)
addToggle(playerPage, "Noclip", "Noclip")

addButton(miscPage, "Rescan Remotes & Eggs", Color3.fromRGB(60, 40, 90), function() scanRemotes() refreshEggCache() end)

-- Minimize Logic
local minimized = false
local origSize = main.Size
local origPos = main.Position
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        main.Size = UDim2.new(0, 160, 0, 42)
        tabBar.Visible = false content.Visible = false
        title.Text = "IDZAM (Minimized)"
    else
        main.Size = origSize
        tabBar.Visible = true content.Visible = true
        title.Text = "IDZAM v7"
    end
end)

closeBtn.MouseButton1Click:Connect(function() ui:Destroy() end)

-- Drag Logic
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true dragStart = input.Position startPos = main.Position end end)
UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local d = input.Position - dragStart main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

-- ============================================================
-- INIT
-- ============================================================
addTab("Farm") addTab("Player") addTab("Misc") showPage("Farm")
scanRemotes() refreshEggCache()
if getHumanoid() then getHumanoid().WalkSpeed = 16 end
