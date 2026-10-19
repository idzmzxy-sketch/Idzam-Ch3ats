-- Idzam ch3atz — intro gate + Slate loader
-- original base: pulsehub.gg / discord.gg/pulsezone
local HUB_NAME = "Idzam ch3atz"
local SLATE_URL = "https://raw.githubusercontent.com/PulseZax/Slate/refs/heads/main/.lua"

-- ============ INTRO GATE ============
local function show_intro()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Name = "IdzamIntro"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Parent = player:WaitForChild("PlayerGui")

    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.35
    backdrop.BorderSizePixel = 0
    backdrop.Parent = gui

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromOffset(500, 280)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
    panel.BorderSizePixel = 0
    panel.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(78, 80, 92)
    stroke.Thickness = 1
    stroke.Parent = panel

    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.fromScale(0.5, 0.5)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.45
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = -1
    shadow.Parent = panel

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = Color3.fromRGB(40, 42, 50)
    header.BorderSizePixel = 0
    header.Parent = panel

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header

    local headerCover = Instance.new("Frame")
    headerCover.Size = UDim2.new(1, 0, 0, 22)
    headerCover.Position = UDim2.fromOffset(0, 22)
    headerCover.BackgroundColor3 = Color3.fromRGB(40, 42, 50)
    headerCover.BorderSizePixel = 0
    headerCover.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -24, 1, 0)
    title.Position = UDim2.fromOffset(16, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(235, 235, 240)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "💬 " .. HUB_NAME
    title.Parent = header

    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -48, 0, 150)
    body.Position = UDim2.fromOffset(24, 64)
    body.BackgroundTransparency = 1
    body.Font = Enum.Font.Gotham
    body.TextSize = 15
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.LineHeight = 1.15
    body.TextColor3 = Color3.fromRGB(224, 224, 230)
    body.Text = "Script ini Milik Idzam mungkin akan ada masalah atau apa karena ga ngurusin ini kalo ada masalah bisa chat ke tele @idzmzxy "
    body.Parent = panel

    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(200, 48)
    button.Position = UDim2.new(0.5, 0, 1, -24)
    button.AnchorPoint = Vector2.new(0.5, 1)
    button.BackgroundColor3 = Color3.fromRGB(214, 68, 88)
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Font = Enum.Font.GothamBold
    button.TextSize = 18
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = "ayo mulai 😈"
    button.Parent = panel

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = button

    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(232, 82, 102)
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(214, 68, 88)
    end)

    local done = false
    button.MouseButton1Click:Connect(function()
        if done then return end
        done = true
        gui:Destroy()
    end)

    while not done do
        task.wait(0.1)
    end
end

show_intro()

-- ============ SLATE LOAD ============
local Slate
if type(_G.__IdzamSlate) == "table" and _G.__IdzamSlate.CreateWindow then
    Slate = _G.__IdzamSlate
else
    local ok, lib = pcall(function()
        return loadstring(game:HttpGetAsync(SLATE_URL), "@IdzamSlate")()
    end)
    if not ok or type(lib) ~= "table" then
        warn(HUB_NAME .. ": gagal muat Slate UI")
        return
    end
    Slate = lib
    _G.__IdzamSlate = Slate
end

-- ============ KATALOG ============
local CATALOG = {
    {
        Key = "mm2",
        Name = "Murder Mystery 2",
        Places = { 142823291 },
        Universe = 66654135,
        Loader = "https://api.luarmor.net/files/v4/loaders/5857a6cfae3b902eb3c2dff7cdbf173b.lua",
        Listed = true,
        Tone = Color3.fromRGB(214, 68, 88),
    },
    {
        Key = "speed",
        Name = "+1 Speed Keyboard Escape",
        Places = { 95082159892680, 118941584817777, 93411036959889 },
        Universe = 9584852943,
        Loader = "https://api.luarmor.net/files/v4/loaders/385c6d8937bfc4ef284dc8c27b50e1c5.lua",
        Listed = false,
        Tone = Color3.fromRGB(236, 176, 72),
    },
    {
        Key = "gag",
        Name = "Grow A Garden 2",
        Places = { 97598239454123 },
        Universe = 10200395747,
        Loader = "https://api.luarmor.net/files/v4/loaders/abd74919679fad90b027ed4e177cea66.lua",
        Listed = true,
        Tone = Color3.fromRGB(76, 175, 92),
    },
    {
        Key = "sandiego",
        Name = "San Diego Border Roleplay",
        Places = { 136020512003847 },
        Universe = 9855761734,
        Loader = "https://api.luarmor.net/files/v4/loaders/16e8365b42517b9a82b7e0a9f4120d3c.lua",
        Listed = true,
        Tone = Color3.fromRGB(72, 132, 220),
    },
    {
        Key = "stealegg",
        Name = "Steal An Egg",
        Places = { 107778070777162 },
        Universe = 10563114921,
        Loader = "https://api.luarmor.net/files/v4/loaders/9eaf6021130040db2646aa9b094427ef.lua",
        Listed = true,
        Tone = Color3.fromRGB(226, 168, 62),
    },
    {
        Key = "rivals",
        Name = "RIVALS",
        Places = { 17625359962, 71874690745115, 117398147513099, 129604661913557, 133215910299950, 18126510175 },
        Universe = 6035872082,
        Loader = "https://api.luarmor.net/files/v4/loaders/8ea20a4f7e9fb8343eec902723cf66f6.lua",
        Listed = true,
        Tone = Color3.fromRGB(90, 169, 255),
    },
    {
        Key = "bloxstrike",
        Name = "BloxStrike",
        Places = { 114234929420007, 108194354348181, 135434213652028, 101836176558619 },
        Universe = 7633926880,
        Loader = "https://api.luarmor.net/files/v4/loaders/107fbc36b735fcffe3b85e3eb7b84eb5.lua",
        Listed = true,
        Tone = Color3.fromRGB(217, 164, 65),
    },
    {
        Key = "kukirin",
        Name = "Drive A Kukirin!",
        Places = { 71704434889758 },
        Universe = 10634461028,
        Loader = "https://raw.githubusercontent.com/PulseZax/driveakukirin/refs/heads/main/.lua",
        Listed = true,
        Tone = Color3.fromRGB(242, 140, 46),
    },
}

local Players = game:GetService("Players")

local function thumb(placeId)
    return string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", placeId)
end

local function launch(entry)
    local ok, chunk = pcall(function()
        return loadstring(game:HttpGetAsync(entry.Loader), "@" .. entry.Key)
    end)
    if not ok or not chunk then
        return false, chunk
    end
    local ok2, err = pcall(chunk)
    return ok2, err
end

local function arm(element, action)
    if type(element) ~= "table" then return end
    local last = 0
    for _, part in ipairs({ element.button, element.card, element.hitbox }) do
        if typeof(part) == "Instance" then
            part.Active = true
            part.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1
                    and input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end
                if os.clock() - last < 0.5 then return end
                last = os.clock()
                action()
            end)
        end
    end
end

local function matchPlace(placeId, universeId)
    for _, entry in ipairs(CATALOG) do
        if entry.Universe == universeId then return entry end
    end
    for _, entry in ipairs(CATALOG) do
        for _, id in ipairs(entry.Places) do
            if id == placeId then return entry end
        end
    end
    return nil
end

local supported = matchPlace(game.PlaceId, game.GameId)
if supported then
    local ok, err = launch(supported)
    if not ok then
        warn(HUB_NAME .. ": " .. supported.Name .. " gagal — " .. tostring(err))
    end
    return
end

if type(_G.IdzamHubLoader) == "table" then
    pcall(function() _G.IdzamHubLoader.Window:Destroy() end)
end
_G.IdzamHubLoader = {}

pcall(function() Slate.Cleanup() end)
pcall(function()
    Slate:PreloadIcons({ "zap", "play", "x", "triangle-alert", "circle-check", "gamepad-2", "layout-grid" })
end)

local Window = Slate:CreateWindow({
    Name = HUB_NAME,
    Subtitle = "script loader",
    Icon = "zap",
    Logo = true,
    Size = UDim2.fromOffset(700, 500),
    ToggleKey = Enum.KeyCode.LeftControl,
})

pcall(function() Slate.Theme.Preset("Ash") end)
pcall(function() Slate:SetFontFamily("JosefinSans") end)

pcall(function()
    local corner = Window.root:FindFirstChildOfClass("UICorner")
    if corner then corner.CornerRadius = UDim.new(0, 6) end
    local stroke = Window.root:FindFirstChildOfClass("UIStroke")
    if stroke then stroke.Thickness = 0 end
end)

_G.IdzamHubLoader.Window = Window

local Tab = Window:CreateTab({ Name = "Scripts", Icon = "layout-grid" })

local placeName = "this game"
pcall(function()
    local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    if info and info.Name then placeName = info.Name end
end)

do
    local notice = Tab:CreateSection({ Name = "Unsupported game" })
    notice:Paragraph({
        Name = "No script for " .. placeName,
        Description = "Every script below reads its own game data on start and will stall here.",
    })
end

do
    local list = Tab:CreateSection({ Name = "Available scripts" })
    local grid = list:Grid({ Columns = 2, Height = 206, MinWidth = 196 })

    for _, entry in ipairs(CATALOG) do
        if entry.Listed then
            local start = function()
                Slate:Notify({
                    Title = HUB_NAME,
                    Description = "Starting " .. entry.Name,
                    Icon = "play",
                    Duration = 5,
                })
                task.spawn(function()
                    local finished, ok, err = false, nil, nil
                    task.spawn(function()
                        ok, err = launch(entry)
                        finished = true
                    end)
                    local waited = 0
                    while not finished and waited < 6 do
                        task.wait(0.25)
                        waited += 0.25
                    end
                    if not finished then
                        Slate:Notify({
                            Title = HUB_NAME,
                            Description = entry.Name .. " is stuck waiting for its own game data",
                            Icon = "triangle-alert",
                            Tone = "Warning",
                            Duration = 10,
                        })
                    elseif not ok then
                        Slate:Notify({
                            Title = HUB_NAME,
                            Description = entry.Name .. " failed: " .. tostring(err),
                            Icon = "circle-alert",
                            Tone = "Danger",
                            Duration = 10,
                        })
                    else
                        Slate:Notify({
                            Title = HUB_NAME,
                            Description = entry.Name .. " started",
                            Icon = "circle-check",
                            Tone = "Success",
                            Duration = 8,
                        })
                    end
                end)
            end
            local card = grid:Invite({
                Name = entry.Name,
                Icon = thumb(entry.Places[1]),
                Stats = { { Text = "Place " .. tostring(entry.Places[1]), Dot = entry.Tone } },
                Game = "ROBLOX",
                GameIcon = "gamepad-2",
                Tone = entry.Tone,
                Glyph = "play",
                ButtonText = "Run",
                ButtonColor = entry.Tone,
                CopiedText = "Starting",
                Callback = start,
            })
            arm(card, start)
        end
    end
end

do
    local close = Tab:CreateSection({ Name = "Menu" })
    close:Button({
        Name = "Close menu",
        Icon = "x",
        Callback = function()
            pcall(function() Window:Destroy() end)
            _G.IdzamHubLoader = nil
        end,
    })
end

Slate:Notify({
    Title = HUB_NAME,
    Description = "No script for " .. placeName .. ". Pick one below to run it anyway.",
    Icon = "triangle-alert",
    Tone = "Warning",
    Duration = 10,
})
