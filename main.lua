--[[
    Idzam Ch3atz v6 — Remote Sniper
    target : Roblox, executor (Delta / Xeno / Wave / Solara / Potassium)
    metode : membuang TP. Menembak RemoteEvent 'Steal' langsung dari jarak jauh.
    note   : script ini JAUH lebih aman dari anti-cheat BACA-6516 karena
             karakter lu gak pernah bergerak secara ilegal.
]]

-- ============================================================
-- BYPASS LAYER (Sama seperti v5.1, tetap dipake buat jaga-jaga)
-- ============================================================
local Bypass_Enabled = true
local Bypass = {}
do
    local function has(fn) return type(fn) == "function" end
    local function safe_call(fn, ...) local ok, res = pcall(fn, ...) if ok then return res end return nil end
    local AC_KEYWORDS = {"anticheat", "anti_cheat", "anti-cheat", "ac_", "_ac", "detect", "report", "memer", "guard", "monitor", "integrity", "byfron", "hyperion", "iac", "adonis", "watchdog"}
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
        for _, key in ipairs({"Detected", "Report"}) do local fn = rawget(t, key) if type(fn) == "function" and has(hookfunction) then safe_call(hookfunction, fn, function() return true end) end end
        local kill = rawget(t, "Kill") if type(kill) == "function" and has(hookfunction) then safe_call(hookfunction, kill, function() end) end
    end
    local disabled_threads = 0
    local function scanGC() if not has(getgc) then return end local ok, gc = pcall(getgc, true) if not ok then return end for _, obj in ipairs(gc) do if isACTable(obj) then neutraliseTable(obj) disabled_threads = disabled_threads + 1 end end end
    local function killACThreads() if not has(getgc) then return end local ok, gc = pcall(getgc, true) if not ok then return end for _, thread in ipairs(gc) do if type(thread) == "thread" and coroutine.status(thread) ~= "dead" then local info = safe_call(debug.info, thread, "s") if type(info) == "string" and looksLikeAC(info) then safe_call(coroutine.close, thread) disabled_threads = disabled_threads + 1 end end end end
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
    local function disableDetectionConnections()
        if not has(getconnections) then return end
        local LP = game:GetService("Players").LocalPlayer
        local function disableSignal(signal)
            if not signal then return end
            local ok, conns = pcall(getconnections, signal) if not ok then return end
            for _, conn in ipairs(conns) do
                local fn = conn.Function
                if fn then local info = safe_call(debug.info, fn, "s") if type(info) == "string" and looksLikeAC(info) then safe_call(function() conn:Disable() end) end end
            end
        end
        local char = LP.Character or LP.CharacterAdded:Wait()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then disableSignal(hum:GetPropertyChangedSignal("WalkSpeed")) disableSignal(hum:GetPropertyChangedSignal("JumpPower")) end
    end
    function Bypass.enable()
        if not Bypass_Enabled then return 0, 0 end
        scanGC() killACThreads() classifyRemotes() hookNamecall() hookProperties() disableDetectionConnections()
        task.spawn(function() while task.wait(3) do scanGC() killACThreads() classifyRemotes() end end)
        return disabled_threads, (function() local n = 0 for _ in pairs(ac_remotes) do n = n + 1 end return n end)()
    end
    function Bypass.safeParent()
        if has(gethui) then local ok, h = pcall(gethui) if ok and h then return h end end
        return game:GetService("CoreGui")
    end
end

local acThreads, acRemotes = Bypass.enable()

-- ============================================================
-- CONFIG & STATE
-- ============================================================
local Config = {
    EggContainer     = workspace,
    EggKeywords      = {"egg", "nest", "crate"},
    RemoteKeywords   = {"steal", "egg", "pick", "grab"},
    HatchKeywords    = {"hatch", "open"},
    PlaceKeywords    = {"place", "equip"},
    SellKeywords     = {"sell", "cashout", "collect"},

    SpeedValue       = 18,
    JumpValue        = 52,
    RestoreSpeed     = 16,
    RestoreJump      = 50,

    -- Delay buat instant steal (jangan terlalu cepat biar gak rate-limited)
    StealDelay       = 0.5,
    MinValueFilter   = 0,

    AccentColor      = Color3.fromRGB(90, 255, 150),
    BgColor          = Color3.fromRGB(14, 14, 18),
    PanelColor       = Color3.fromRGB(22, 22, 28),
    TextColor        = Color3.fromRGB(220, 220, 225),
}

local State = {
    AutoSteal = false, AutoHatch = false, AutoPlace = false, AutoSell = false,
    EggESP = false, PlayerESP = false,
    Speed = false, Jump = false, Fly = false, Noclip = false,
    AntiAFK = true, InstantPrompt = true,
}

local Selected  = {}
local EggCache  = {}
local RemoteMap = {} -- Ini kunci utamanya. Map keyword -> RemoteEvent
local LP = game:GetService("Players").LocalPlayer

-- ============================================================
-- HELPERS & SCAN REMOTE
-- ============================================================
local function getChar() return LP.Character or LP.CharacterAdded:Wait() end
local function getHRP() return getChar():FindFirstChild("HumanoidRootPart") or getChar():WaitForChild("HumanoidRootPart", 5) end
local function getHumanoid() return getChar():FindFirstChildOfClass("Humanoid") end

local function nameMatchesAny(name, list)
    local l = name:lower()
    for _, kw in ipairs(list) do if l:find(kw, 1, true) then return true end end
    return false
end

-- Fungsi ini yang bakal nyari remote 'Steal' asli dari game
local function scanRemotes()
    RemoteMap = {}
    local RS = game:GetService("ReplicatedStorage")
    local ok, desc = pcall(function() return RS:GetDescendants() end)
    if not ok then return end
    for _, obj in ipairs(desc) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local ln = obj.Name:lower()
            for _, kw in ipairs(Config.RemoteKeywords) do
                if ln:find(kw, 1, true) then
                    -- Prioritaskan nama yang paling pendek (biasanya yang utama)
                    if not RemoteMap[kw] or #obj.Name < #RemoteMap[kw].Name then
                        RemoteMap[kw] = obj
                    end
                end
            end
        end
    end
end

-- Tembak remote tanpa deket egg
local function fireStealRemote(eggName)
    -- Coba keyword 'steal' dulu, kalau gak ada coba 'egg'
    local remote = RemoteMap["steal"] or RemoteMap["egg"] or RemoteMap["pick"]
    if not remote then return false end
    
    local ok = pcall(function()
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(eggName)
        else
            remote:FireServer(eggName)
        end
    end)
    return ok
end

-- Fallback kalau remote gak ketemu (pake prompt terdekat)
local function firePromptNearby()
    local hrp = getHRP()
    if not hrp then return end
    for _, obj in ipairs(Config.EggContainer:GetDescendants()) do
        if nameMatchesAny(obj.Name, Config.EggKeywords) then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part and (part.Position - hrp.Position).Magnitude < 30 then
                for _, d in ipairs(obj:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then
                        pcall(function() fireproximityprompt(d) end)
                    end
                end
            end
        end
    end
end

-- ============================================================
-- EGG INFO (Sama kayak sebelumnya)
-- ============================================================
local ValueKeys  = {"income", "value", "worth", "price", "cash", "money"}
local RarityKeys = {"rarity", "tier", "rank", "grade"}
local ContentKeys = {"content", "pet", "reward", "inside"}

local function readEggInfo(obj)
    local info = {obj=obj, name=obj.Name, rarity="Common", income=0, content="?"}
    if obj.GetAttributes then
        for k, v in pairs(obj:GetAttributes()) do
            local lk = k:lower()
            if type(v) == "number" and nameMatchesAny(lk, ValueKeys) then info.income = math.max(info.income, v) end
            if nameMatchesAny(lk, RarityKeys) then info.rarity = tostring(v) end
            if nameMatchesAny(lk, ContentKeys) then info.content = tostring(v) end
        end
    end
    for _, c in ipairs(obj:GetDescendants()) do
        if c:IsA("NumberValue") or c:IsA("IntValue") then
            if nameMatchesAny(c.Name:lower(), ValueKeys) then info.income = math.max(info.income, c.Value) end
        elseif c:IsA("StringValue") then
            local ln = c.Name:lower()
            if nameMatchesAny(ln, RarityKeys) then info.rarity = c.Value end
            if nameMatchesAny(ln, ContentKeys) then info.content = c.Value end
        end
    end
    return info
end

local function refreshEggCache()
    EggCache = {}
    local ok, desc = pcall(function() return Config.EggContainer:GetDescendants() end)
    if not ok then return end
    for _, obj in ipairs(desc) do
        if nameMatchesAny(obj.Name, Config.EggKeywords) and obj ~= getChar() then
            local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then table.insert(EggCache, readEggInfo(obj)) end
        end
    end
    table.sort(EggCache, function(a, b) return a.income > b.income end)
end

-- ============================================================
-- UI (Bypass Parent)
-- ============================================================
local HUIParent = Bypass.safeParent()
local notifGui = Instance.new("ScreenGui") notifGui.Name = "IdzamNotif" notifGui.ResetOnSpawn = false notifGui.Parent = HUIParent
local function notify(text)
    local box = Instance.new("TextLabel")
    box.Size = UDim2.new(0, 300, 0, 36) box.Position = UDim2.new(0.5, -150, 0, 30)
    box.BackgroundColor3 = Config.PanelColor box.BackgroundTransparency = 0.1 box.BorderSizePixel = 0
    box.TextColor3 = Config.AccentColor box.Font = Enum.Font.GothamBold box.TextSize = 13
    box.Text = "Idzam Ch3atz — " .. text box.Parent = notifGui
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = box
    local s = Instance.new("UIStroke") s.Color = Config.AccentColor s.Transparency = 0.6 s.Parent = box
    task.delay(2.5, function()
        local tw = TweenService:Create(box, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 })
        tw:Play() tw.Completed:Wait() box:Destroy()
    end)
end

local eggEspFolder = Instance.new("Folder") eggEspFolder.Name = "IdzamEggESP" eggEspFolder.Parent = HUIParent
local function clearFolder(f) for _, c in ipairs(f:GetChildren()) do c:Destroy() end end
local function makeBillboard(parent, adornee, text, color, subtext)
    local bb = Instance.new("BillboardGui") bb.Adornee = adornee bb.Size = UDim2.new(0, 260, 0, 50) bb.StudsOffset = Vector3.new(0, 3, 0) bb.AlwaysOnTop = true bb.Parent = parent
    local frame = Instance.new("Frame") frame.Size = UDim2.new(1, 0, 1, 0) frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) frame.BackgroundTransparency = 0.55 frame.BorderSizePixel = 0 frame.Parent = bb
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 6) fc.Parent = frame
    local lbl = Instance.new("TextLabel") lbl.Size = UDim2.new(1, -8, 0.6, 0) lbl.Position = UDim2.new(0, 4, 0, 2) lbl.BackgroundTransparency = 1 lbl.Text = text lbl.TextColor3 = color lbl.TextStrokeTransparency = 0.4 lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) lbl.TextScaled = true lbl.Font = Enum.Font.GothamBold lbl.TextXAlignment = Enum.TextXAlignment.Left lbl.Parent = frame
    if subtext then
        local sub = Instance.new("TextLabel") sub.Size = UDim2.new(1, -8, 0.35, 0) sub.Position = UDim2.new(0, 4, 0.62, 0) sub.BackgroundTransparency = 1 sub.Text = subtext sub.TextColor3 = Color3.fromRGB(180, 180, 185) sub.TextScaled = true sub.Font = Enum.Font.Gotham sub.TextXAlignment = Enum.TextXAlignment.Left sub.Parent = frame
    end
end

local function renderEggESP()
    clearFolder(eggEspFolder)
    if not State.EggESP then return end
    for _, e in ipairs(EggCache) do
        local part = e.obj:IsA("BasePart") and e.obj or e.obj.PrimaryPart or e.obj:FindFirstChildWhichIsA("BasePart")
        if part and part.Parent then makeBillboard(eggEspFolder, part, string.format("%s [%s]", e.name, e.rarity), Config.AccentColor, string.format("$%d/s", e.income)) end
    end
end

task.spawn(function() while task.wait(1) do refreshEggCache() if State.EggESP then renderEggESP() end end end)

-- ============================================================
-- STEAL ENGINE (Remote Sniper)
-- ============================================================
local function eggAllowed(info)
    if info.income < Config.MinValueFilter then return false end
    if next(Selected) ~= nil then return Selected[info.name] == true end
    return true
end

local function snipeBestEgg()
    refreshEggCache()
    local bestEgg
    for _, e in ipairs(EggCache) do
        if eggAllowed(e) then bestEgg = e break end -- Ambil yang paling tinggi (udah disortir)
    end
    if not bestEgg then return end

    -- Tembak remote langsung tanpa gerak
    local success = fireStealRemote(bestEgg.name)
    if not success then
        -- Kalau remote gak ada, coba fire prompt yang ada di deket (tapi gak TP)
        firePromptNearby()
    end
end

task.spawn(function()
    while task.wait(Config.StealDelay) do
        if State.AutoSteal then
            snipeBestEgg()
        end
    end
end)

-- ============================================================
-- MOVEMENT & MISC
-- ============================================================
local function applySpeed() local h = getHumanoid() if h then h.WalkSpeed = State.Speed and Config.SpeedValue or Config.RestoreSpeed end end
local function applyJump() local h = getHumanoid() if h then h.UseJumpPower = true h.JumpPower = State.Jump and Config.JumpValue or Config.RestoreJump end end
LP.CharacterAdded:Connect(function() task.wait(1) applySpeed() applyJump() end)

local flyConn
local function setFly(on)
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if not on then return end
    flyConn = RunService.RenderStepped:Connect(function(dt)
        if not State.Fly then return end
        local hrp = getHRP() if not hrp then return end
        local cam = workspace.CurrentCamera
        local move = getHumanoid() and getHumanoid().MoveDirection or Vector3.zero
        local dir = Vector3.zero
        if move.Magnitude > 0 then dir = cam.CFrame:VectorToWorldSpace(Vector3.new(move.X, 0, move.Z)) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then hrp.CFrame = hrp.CFrame + dir.Unit * 60 * dt end
    end)
end

task.spawn(function() while task.wait(0.2) do
    if State.Noclip then local char = LP.Character if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end end end
end end)

LP.Idled:Connect(function()
    if State.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end
end)

-- ============================================================
-- UI BUILD
-- ============================================================
local ui = Instance.new("ScreenGui") ui.Name = "IdzamCh3atzUI" ui.ResetOnSpawn = false ui.Parent = HUIParent
local main = Instance.new("Frame") main.Size = UDim2.new(0, 320, 0, 380) main.Position = UDim2.new(0, 40, 0.5, -190) main.BackgroundColor3 = Config.BgColor main.BackgroundTransparency = 0.05 main.BorderSizePixel = 0 main.Parent = ui
local mc = Instance.new("UICorner") mc.CornerRadius = UDim.new(0, 12) mc.Parent = main
local ms = Instance.new("UIStroke") ms.Color = Config.AccentColor ms.Thickness = 1 ms.Transparency = 0.3 ms.Parent = main

local header = Instance.new("Frame") header.Size = UDim2.new(1, 0, 0, 42) header.BackgroundTransparency = 1 header.Parent = main
local title = Instance.new("TextLabel") title.Size = UDim2.new(1, -24, 1, 0) title.Position = UDim2.new(0, 16, 0, 0) title.BackgroundTransparency = 1 title.Text = "IDZAM SNIPER v6" title.TextColor3 = Config.AccentColor title.Font = Enum.Font.GothamBold title.TextSize = 16 title.TextXAlignment = Enum.TextXAlignment.Left title.Parent = header

local content = Instance.new("ScrollingFrame") content.Size = UDim2.new(1, -24, 1, -60) content.Position = UDim2.new(0, 12, 0, 50) content.BackgroundTransparency = 1 content.BorderSizePixel = 0 content.ScrollBarThickness = 3 content.ScrollBarImageColor3 = Config.AccentColor content.CanvasSize = UDim2.new(0, 0, 0, 0) content.Parent = main
local cl = Instance.new("UIListLayout") cl.Padding = UDim.new(0, 6) cl.Parent = content
cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() content.CanvasSize = UDim2.new(0, 0, 0, cl.AbsoluteContentSize.Y + 10) end)

local function addToggle(label, key, onChanged)
    local btn = Instance.new("TextButton") btn.Size = UDim2.new(1, 0, 0, 34) btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34) btn.BorderSizePixel = 0 btn.TextColor3 = Config.TextColor btn.Font = Enum.Font.GothamBold btn.TextSize = 12 btn.Text = "  " .. label .. "  [OFF]" btn.TextXAlignment = Enum.TextXAlignment.Left btn.AutoButtonColor = false btn.Parent = content
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = btn
    btn.MouseButton1Click:Connect(function()
        State[key] = not State[key]
        if State[key] then btn.Text = "  " .. label .. "  [ON]" btn.TextColor3 = Config.AccentColor btn.BackgroundColor3 = Color3.fromRGB(24, 44, 30)
        else btn.Text = "  " .. label .. "  [OFF]" btn.TextColor3 = Config.TextColor btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34) end
        if onChanged then onChanged() end
    end)
    return btn
end

local function addButton(label, color, onClick)
    local btn = Instance.new("TextButton") btn.Size = UDim2.new(1, 0, 0, 32) btn.BackgroundColor3 = color or Color3.fromRGB(34, 34, 42) btn.BorderSizePixel = 0 btn.TextColor3 = Config.TextColor btn.Font = Enum.Font.GothamBold btn.TextSize = 11 btn.Text = "  " .. label btn.TextXAlignment = Enum.TextXAlignment.Left btn.AutoButtonColor = false btn.Parent = content
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = btn
    btn.MouseButton1Click:Connect(onClick)
end

addToggle("Auto Steal (Remote Sniper)", "AutoSteal")
addToggle("Speed", "Speed", applySpeed)
addToggle("Jump", "Jump", applyJump)
addToggle("Fly (CFrame)", "Fly", function() setFly(State.Fly) end)
addToggle("Noclip", "Noclip")
addToggle("Egg ESP", "EggESP", function() renderEggESP() end)

addButton("Scan & Map Remotes", Color3.fromRGB(60, 40, 90), function()
    scanRemotes()
    local n = 0 for _ in pairs(RemoteMap) do n = n + 1 end
    notify(string.format("%d remote steal ketemu", n))
end)

addButton("Rescan Eggs", Color3.fromRGB(40, 60, 90), function()
    refreshEggCache()
    notify(string.format("%d egg di-scan", #EggCache))
end)

local dragging, dragStart, startPos
header.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true dragStart = input.Position startPos = main.Position end end)
UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local d = input.Position - dragStart main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

scanRemotes()
refreshEggCache()
applySpeed() applyJump()
local n = 0 for _ in pairs(RemoteMap) do n = n + 1 end
notify(string.format("v6 Sniper — %d remote | %d egg", n, #EggCache))
