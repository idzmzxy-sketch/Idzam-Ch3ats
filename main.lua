-- Language: Luau | File: IdzamCh3atz.lua | Target: Roblox Studio LocalScript
-- Idzam Ch3atz UI v2.0 — responsive GUI, working toggles, drag, and minimize-to-icon.
-- Gameplay actions that affect shared game state must be implemented and validated by your own server.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Clean up a previous copy without destroying unrelated ScreenGuis.
local previous = playerGui:FindFirstChild("IdzamCh3atz")
if previous then
    previous:Destroy()
end

local COLORS = {
    background = Color3.fromRGB(15, 16, 23),
    panel = Color3.fromRGB(23, 25, 36),
    panelRaised = Color3.fromRGB(30, 32, 46),
    text = Color3.fromRGB(238, 238, 248),
    muted = Color3.fromRGB(155, 158, 180),
    accent = Color3.fromRGB(130, 95, 255),
    accentSoft = Color3.fromRGB(56, 45, 94),
    enabled = Color3.fromRGB(48, 145, 105),
    disabled = Color3.fromRGB(48, 51, 68),
    danger = Color3.fromRGB(188, 67, 87),
}

local gui = Instance.new("ScreenGui")
gui.Name = "IdzamCh3atz"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function round(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 9),
    }, parent)
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or COLORS.accent,
        Transparency = transparency or 0.25,
        Thickness = thickness or 1,
    }, parent)
end

local main = create("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0.94, 0, 0.70, 0),
    BackgroundColor3 = COLORS.background,
    BorderSizePixel = 0,
    ClipsDescendants = false,
}, gui)
round(main, 13)
local mainStroke = stroke(main, COLORS.accent, 0.12, 1.5)
create("UISizeConstraint", {
    MinSize = Vector2.new(300, 300),
    MaxSize = Vector2.new(720, 540),
}, main)

local top = create("Frame", {
    Name = "TopBar",
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
    Active = true,
}, main)
round(top, 13)

-- The lower overlay squares off the bottom corners of the top bar.
create("Frame", {
    Position = UDim2.new(0, 0, 1, -12),
    Size = UDim2.new(1, 0, 0, 12),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
}, top)

create("TextLabel", {
    Name = "Brand",
    Position = UDim2.fromOffset(15, 0),
    Size = UDim2.new(1, -115, 1, 0),
    BackgroundTransparency = 1,
    Text = "IDZAM CH3ATZ",
    TextColor3 = COLORS.text,
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, top)

create("TextLabel", {
    Name = "Version",
    Position = UDim2.new(0, 15, 0, 28),
    Size = UDim2.new(1, -125, 0, 14),
    BackgroundTransparency = 1,
    Text = "UI V2.0  •  STUDIO EDITION",
    TextColor3 = COLORS.muted,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, top)

local minimizeButton = create("TextButton", {
    Name = "MinimizeButton",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.fromOffset(32, 30),
    BackgroundColor3 = COLORS.danger,
    BorderSizePixel = 0,
    Text = "×",
    TextColor3 = COLORS.text,
    Font = Enum.Font.GothamBold,
    TextSize = 22,
    AutoButtonColor = true,
}, top)
round(minimizeButton, 8)

local sidebar = create("ScrollingFrame", {
    Name = "Sidebar",
    Position = UDim2.fromOffset(10, 58),
    Size = UDim2.new(0, 112, 1, -70),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = COLORS.accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, main)
round(sidebar, 9)
create("UIPadding", {
    PaddingTop = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 7),
    PaddingRight = UDim.new(0, 7),
}, sidebar)
create("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, sidebar)

local content = create("Frame", {
    Name = "Content",
    Position = UDim2.new(0, 132, 0, 58),
    Size = UDim2.new(1, -142, 1, -86),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
}, main)
round(content, 9)

local statusLabel = create("TextLabel", {
    Name = "Status",
    Position = UDim2.new(0, 135, 1, -23),
    Size = UDim2.new(1, -145, 0, 15),
    BackgroundTransparency = 1,
    Text = "Ready • RightShift hides/shows the panel",
    TextColor3 = COLORS.muted,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, main)

local toastSequence = 0
local function notify(message)
    toastSequence += 1
    local thisToast = toastSequence
    statusLabel.Text = tostring(message)
    statusLabel.TextColor3 = COLORS.text
    task.delay(3, function()
        if gui.Parent and toastSequence == thisToast then
            statusLabel.Text = "Ready • RightShift hides/shows the panel"
            statusLabel.TextColor3 = COLORS.muted
        end
    end)
end

-- Minimize becomes a floating restore icon. It does not destroy the GUI.
local restoreIcon = create("TextButton", {
    Name = "RestoreIcon",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -18, 1, -70),
    Size = UDim2.fromOffset(54, 54),
    BackgroundColor3 = COLORS.accent,
    BorderSizePixel = 0,
    Text = "IC",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBlack,
    TextSize = 17,
    Visible = false,
    AutoButtonColor = true,
}, gui)
round(restoreIcon, 18)
stroke(restoreIcon, Color3.fromRGB(211, 199, 255), 0.05, 1.5)

local minimized = false
local function minimize()
    minimized = true
    main.Visible = false
    restoreIcon.Visible = true
    notify("Menu minimized • Tap the IC icon to restore")
end

local function restore()
    minimized = false
    main.Visible = true
    restoreIcon.Visible = false
    notify("Idzam Ch3atz restored")
end

minimizeButton.Activated:Connect(minimize)
restoreIcon.Activated:Connect(restore)

local pages = {}
local navButtons = {}
local toggleStates = {}
local accentOptions = {
    Color3.fromRGB(130, 95, 255),
    Color3.fromRGB(42, 160, 220),
    Color3.fromRGB(224, 90, 155),
    Color3.fromRGB(70, 180, 125),
}
local accentIndex = 1

local function makePage(name)
    local page = create("ScrollingFrame", {
        Name = name .. "Page",
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 1, -16),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, content)
    create("UIPadding", {
        PaddingBottom = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 4),
    }, page)
    create("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    pages[name] = page
    return page
end

local function makeHeader(page, text)
    return create("TextLabel", {
        Name = "Header",
        Size = UDim2.new(1, -3, 0, 29),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = COLORS.accent,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, page)
end

local function makeInfo(page, text, height)
    local label = create("TextLabel", {
        Size = UDim2.new(1, -3, 0, height or 38),
        BackgroundColor3 = COLORS.panelRaised,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = COLORS.muted,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, page)
    round(label, 7)
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 8),
    }, label)
    return label
end

local function makeButton(page, text, callback)
    local button = create("TextButton", {
        Size = UDim2.new(1, -3, 0, 36),
        BackgroundColor3 = COLORS.panelRaised,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = COLORS.text,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextWrapped = true,
        AutoButtonColor = false,
    }, page)
    round(button, 7)
    stroke(button, COLORS.accent, 0.82, 1)

    button.Activated:Connect(function(inputObject)
        if callback then
            local ok, err = pcall(callback, inputObject)
            if not ok then
                warn("Idzam Ch3atz button error:", err)
                notify("Action error • see Output for details")
            end
        end
    end)

    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12), {
            BackgroundColor3 = COLORS.accentSoft,
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        local targetColor = COLORS.panelRaised
        TweenService:Create(button, TweenInfo.new(0.12), {
            BackgroundColor3 = targetColor,
        }):Play()
    end)
    return button
end

-- Create the button before connecting its callback; this avoids the old local-scope bug.
local function makeToggle(page, key, label, defaultValue, callback)
    local enabled = defaultValue == true
    toggleStates[key] = enabled

    local button = create("TextButton", {
        Name = key .. "Toggle",
        Size = UDim2.new(1, -3, 0, 38),
        BackgroundColor3 = enabled and COLORS.enabled or COLORS.disabled,
        BorderSizePixel = 0,
        Text = "",
        TextColor3 = COLORS.text,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        AutoButtonColor = false,
    }, page)
    round(button, 7)
    stroke(button, enabled and COLORS.enabled or COLORS.accent, 0.65, 1)

    local title = create("TextLabel", {
        Name = "ToggleLabel",
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -63, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = COLORS.text,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, button)

    local state = create("TextLabel", {
        Name = "State",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -7, 0.5, 0),
        Size = UDim2.fromOffset(44, 23),
        BackgroundColor3 = enabled and COLORS.enabled or COLORS.disabled,
        BorderSizePixel = 0,
        Text = enabled and "ON" or "OFF",
        TextColor3 = COLORS.text,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
    }, button)
    round(state, 6)

    local function render()
        button.BackgroundColor3 = enabled and Color3.fromRGB(34, 80, 68) or COLORS.panelRaised
        state.BackgroundColor3 = enabled and COLORS.enabled or COLORS.disabled
        state.Text = enabled and "ON" or "OFF"
    end

    button.Activated:Connect(function()
        enabled = not enabled
        toggleStates[key] = enabled
        render()
        notify(label .. (enabled and " enabled" or " disabled"))
        if callback then
            local ok, err = pcall(callback, enabled)
            if not ok then
                warn("Idzam Ch3atz toggle error (" .. key .. "):", err)
                notify("Toggle error • see Output for details")
            end
        end
    end)

    return {
        button = button,
        get = function() return enabled end,
        set = function(value)
            enabled = value == true
            toggleStates[key] = enabled
            render()
            if callback then callback(enabled) end
        end,
    }
end

local function makeNav(name, order)
    local button = create("TextButton", {
        Name = name .. "Tab",
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 33),
        BackgroundColor3 = COLORS.panelRaised,
        BorderSizePixel = 0,
        Text = name,
        TextColor3 = COLORS.muted,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        AutoButtonColor = false,
    }, sidebar)
    round(button, 7)
    navButtons[name] = button
    button.Activated:Connect(function()
        for pageName, page in pairs(pages) do
            page.Visible = pageName == name
        end
        for navName, nav in pairs(navButtons) do
            nav.BackgroundColor3 = navName == name and COLORS.accentSoft or COLORS.panelRaised
            nav.TextColor3 = navName == name and COLORS.text or COLORS.muted
        end
        notify(name .. " tab")
    end)
    return button
end

local home = makePage("Home")
local steal = makePage("Steal")
local egg = makePage("Egg")
local playerPage = makePage("Player")
local visual = makePage("Visual")
local world = makePage("World")
local misc = makePage("Misc")
local settings = makePage("Settings")
local info = makePage("Info")

-- HOME
makeHeader(home, "DASHBOARD")
local welcomeLabel = makeInfo(home, "Welcome, " .. player.DisplayName .. "!", 43)
local playerInfo = makeInfo(home, "Player: " .. player.Name .. "\nUserId: " .. tostring(player.UserId), 52)
local worldInfo = makeInfo(home, "PlaceId: " .. tostring(game.PlaceId) .. "\nSession: loading...", 52)
local liveInfo = makeInfo(home, "Ping: reading...  •  FPS: reading...", 36)

makeButton(home, "Refresh dashboard", function()
    welcomeLabel.Text = "Welcome, " .. player.DisplayName .. "!"
    playerInfo.Text = "Player: " .. player.Name .. "\nUserId: " .. tostring(player.UserId)
    worldInfo.Text = "PlaceId: " .. tostring(game.PlaceId) .. "\nSession: " .. math.floor(workspace.DistributedGameTime) .. "s"
    notify("Dashboard refreshed")
end)
makeButton(home, "Copy-friendly player info to Output", function()
    print("[Idzam Ch3atz] Player:", player.Name, "UserId:", player.UserId, "PlaceId:", game.PlaceId)
    notify("Player info printed to Output")
end)

-- STEAL: UI preferences only. A real steal interaction belongs in a game you own.
makeHeader(steal, "STEAL TOOLS")
makeInfo(steal, "These switches save UI preferences. They do not trigger actions in another creator's game.", 54)
makeToggle(steal, "auto_steal_ui", "Auto Steal • Studio hook", false, function(on)
    if on then
        notify("Auto Steal preference ON • connect your own server mechanic")
    else
        notify("Auto Steal preference OFF")
    end
end)
makeToggle(steal, "steal_alerts", "Steal action notifications", true, function(on)
    notify("Steal notifications " .. (on and "ON" or "OFF"))
end)
makeToggle(steal, "steal_prompt_helper", "Prompt helper • Studio", false, function(on)
    notify("Prompt helper preference " .. (on and "ON" or "OFF"))
end)
makeButton(steal, "Show integration status", function()
    notify("No game-owned server handler is connected")
end)

-- EGG
makeHeader(egg, "EGG TOOLS")
makeInfo(egg, "Egg catalog actions can be connected to data from your own Roblox experience.", 48)
makeToggle(egg, "egg_notifications", "Egg notifications", true, function(on)
    notify("Egg notifications " .. (on and "ON" or "OFF"))
end)
makeToggle(egg, "egg_catalog_ui", "Show egg catalog panel", false, function(on)
    notify("Egg catalog panel preference " .. (on and "ON" or "OFF"))
end)
makeButton(egg, "List SpawnLocation objects", function()
    local count = 0
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("SpawnLocation") then
            count += 1
            print("[Idzam Ch3atz] SpawnLocation:", object:GetFullName())
        end
    end
    notify("Found " .. count .. " SpawnLocation object(s); names printed to Output")
end)

-- PLAYER
makeHeader(playerPage, "PLAYER INFO")
local characterInfo = makeInfo(playerPage, "Character: waiting for character...", 52)
local humanoidInfo = makeInfo(playerPage, "Humanoid: not found", 52)
local function refreshCharacterInfo()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    characterInfo.Text = "Character: " .. (character and character.Name or "not spawned")
    if humanoid then
        humanoidInfo.Text = string.format("Health: %.0f / %.0f\nWalkSpeed: %.1f • JumpPower: %.1f", humanoid.Health, humanoid.MaxHealth, humanoid.WalkSpeed, humanoid.JumpPower)
    else
        humanoidInfo.Text = "Humanoid: not found"
    end
end
makeButton(playerPage, "Refresh character info", function()
    refreshCharacterInfo()
    notify("Character info refreshed")
end)
makeInfo(playerPage, "This panel reports your character values. It does not force movement changes in public games.", 52)

-- VISUAL
makeHeader(visual, "VISUAL PREFERENCES")
makeInfo(visual, "These switches are working UI preferences. Add visual effects through your own game's systems.", 52)
makeToggle(visual, "visual_player_labels", "Player label preference", false, function(on)
    notify("Player label preference " .. (on and "ON" or "OFF"))
end)
makeToggle(visual, "visual_egg_markers", "Egg marker preference", false, function(on)
    notify("Egg marker preference " .. (on and "ON" or "OFF"))
end)
makeToggle(visual, "visual_effects", "Extra UI effects", true, function(on)
    notify("Extra UI effects " .. (on and "ON" or "OFF"))
end)

-- WORLD
makeHeader(world, "WORLD INSPECTOR")
makeInfo(world, "Inspect selected object types in your Studio experience. Results go to the Output window.", 52)
makeButton(world, "Count parts in Workspace", function()
    local count = 0
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("BasePart") then
            count += 1
        end
    end
    notify("Workspace contains " .. count .. " BasePart object(s)")
end)
makeButton(world, "List tagged SpawnLocations", function()
    local count = 0
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("SpawnLocation") then
            count += 1
            print(string.format("[Idzam Ch3atz] Spawn #%d: %s", count, object:GetFullName()))
        end
    end
    notify("Listed " .. count .. " spawn object(s) in Output")
end)
makeButton(world, "Print Workspace model names", function()
    local count = 0
    for _, object in ipairs(workspace:GetChildren()) do
        if object:IsA("Model") then
            count += 1
            print("[Idzam Ch3atz] Model:", object.Name)
        end
    end
    notify("Printed " .. count .. " top-level model name(s)")
end)

-- MISC
makeHeader(misc, "EXTRA TOOLS")
makeToggle(misc, "misc_status_messages", "Status messages", true, function(on)
    statusLabel.Visible = on
    if not on then
        statusLabel.Visible = false
    else
        notify("Status messages ON")
    end
end)
makeToggle(misc, "misc_hotkey", "RightShift hotkey", true, function(on)
    notify("RightShift hotkey " .. (on and "ON" or "OFF"))
end)
makeButton(misc, "Print enabled preferences", function()
    for key, value in pairs(toggleStates) do
        print("[Idzam Ch3atz]", key, value and "ON" or "OFF")
    end
    notify("Preferences printed to Output")
end)

-- SETTINGS
makeHeader(settings, "SETTINGS")
makeToggle(settings, "settings_compact", "Compact window", false, function(on)
    main.Size = on and UDim2.new(0.88, 0, 0.60, 0) or UDim2.new(0.94, 0, 0.70, 0)
    notify("Compact window " .. (on and "ON" or "OFF"))
end)
makeButton(settings, "Change accent color", function()
    accentIndex = (accentIndex % #accentOptions) + 1
    COLORS.accent = accentOptions[accentIndex]
    mainStroke.Color = COLORS.accent
    restoreIcon.BackgroundColor3 = COLORS.accent
    statusLabel.TextColor3 = COLORS.accent
    for _, descendant in ipairs(gui:GetDescendants()) do
        if descendant:IsA("UIStroke") then
            descendant.Color = COLORS.accent
        elseif descendant:IsA("TextLabel") and descendant.Name == "Header" then
            descendant.TextColor3 = COLORS.accent
        end
    end
    notify("Accent color changed")
end)
makeButton(settings, "Center window", function()
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    notify("Window centered")
end)
makeButton(settings, "Minimize to IC icon", minimize)
makeButton(settings, "Restore panel", restore)

-- INFO
makeHeader(info, "ABOUT IDZAM CH3ATZ")
makeInfo(info, "Version: 2.0\nInterface: dark-purple / responsive\nInput: mouse + touch + keyboard", 66)
makeInfo(info, "RightShift toggles the panel. The × button minimizes to the IC icon. Tap IC to restore.", 58)
makeInfo(info, "For shared gameplay mechanics, use a server-side script in your own Roblox experience and validate every request.", 68)

local tabNames = {"Home", "Steal", "Egg", "Player", "Visual", "World", "Misc", "Settings", "Info"}
for index, name in ipairs(tabNames) do
    makeNav(name, index)
end
pages.Home.Visible = true
navButtons.Home.BackgroundColor3 = COLORS.accentSoft
navButtons.Home.TextColor3 = COLORS.text

-- Draggable title bar; supports mouse and touch input.
local dragging = false
local dragStart = nil
local startPosition = nil

top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and dragStart and startPosition then
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift and toggleStates.misc_hotkey ~= false then
        if minimized or not main.Visible then
            restore()
        else
            minimize()
        end
    end
end)

-- Lightweight dashboard refresh; this loop stops automatically when the GUI is destroyed.
task.spawn(function()
    local frameCount = 0
    local lastFpsSample = os.clock()
    local currentFps = 0
    local frameConnection
    frameConnection = RunService.RenderStepped:Connect(function()
        if not gui.Parent then
            frameConnection:Disconnect()
            return
        end
        frameCount += 1
        local now = os.clock()
        if now - lastFpsSample >= 1 then
            currentFps = frameCount
            frameCount = 0
            lastFpsSample = now
            local pingText = "N/A"
            local ok, result = pcall(function()
                return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
            end)
            if ok and result then
                pingText = result
            end
            liveInfo.Text = "Ping: " .. pingText .. "  •  FPS: " .. tostring(currentFps)
            worldInfo.Text = "PlaceId: " .. tostring(game.PlaceId) .. "\nSession: " .. math.floor(workspace.DistributedGameTime) .. "s"
            refreshCharacterInfo()
        end
    end)
end)

player.CharacterAdded:Connect(function()
    task.wait(0.5)
    if gui.Parent then
        refreshCharacterInfo()
    end
end)

notify("Idzam Ch3atz V2.0 ready")
print("[Idzam Ch3atz] V2.0 loaded. UI-only switches need your own game logic to perform gameplay actions.")
