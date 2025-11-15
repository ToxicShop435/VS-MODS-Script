-- NONO HUB V3 - ESP + PERFECT AIMBOT + TRIGGERBOT (Auto-Shoots Murderer!)
-- Blue = Hero  Red = Villain  Sheriff Aimbot + Triggerbot

local Players = gameGetService(Players)
local Workspace = gameGetService(Workspace)
local RunService = gameGetService(RunService)
local UserInputService = gameGetService(UserInputService)
local LocalPlayer = Players.LocalPlayer

-- === ESP & AIMBOT & TRIGGERBOT ===
local ESP = { Enabled = true, Boxes = {} }
local AIMBOT = { Enabled = false, Target = nil }
local TRIGGERBOT = { Enabled = false }
local GUI_VISIBLE = true

-- === CONFIG ===
local REFRESH_TIME = 1.0
local BOX_SIZE_OFFSET = Vector2.new(4, 6)
local BOX_THICKNESS = 4
local AIMBOT_SMOOTHNESS = 0.12
local AIM_FOV = 300
local TRIGGER_FOV = 80  -- Triggerbot crosshair distance
local SHERIFF_COLOR = Color3.fromRGB(50, 150, 255)
local MURDERER_COLOR = Color3.fromRGB(255, 50, 50)

-- === RGB ===
local function getRainbowColor()
    local time = tick() % 3
    local r = math.floor(math.sin(time  2)  127 + 128)
    local g = math.floor(math.sin(time  2 + 2)  127 + 128)
    local b = math.floor(math.sin(time  2 + 4)  127 + 128)
    return Color3.fromRGB(r, g, b)
end

-- === BOX FUNCTIONS ===
local function createBox()
    local box = Drawing.new(Square)
    box.Visible = false
    box.Filled = false
    box.Thickness = BOX_THICKNESS
    box.Transparency = 0.8
    return box
end

local function getRole(player)
    local backpack = playerFindFirstChild(Backpack)
    local char = player.Character
    if not (backpack and char) then return nil end
    if backpackFindFirstChild(Knife) or charFindFirstChild(Knife) then
        return Villain
    elseif backpackFindFirstChild(Gun) or charFindFirstChild(Gun) then
        return Hero
    end
    return nil
end

local function updateBox(player, box)
    local char = player.Character
    if not (char and charFindFirstChild(HumanoidRootPart) and charFindFirstChild(Head)) then
        box.Visible = false
        return
    end
    local root = char.HumanoidRootPart
    local head = char.Head
    local camera = Workspace.CurrentCamera
    local screenPos, onScreen = cameraWorldToViewportPoint(root.Position)
    if not onScreen then
        box.Visible = false
        return
    end
    local headPos = cameraWorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local legPos = cameraWorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
    local height = math.abs(headPos.Y - legPos.Y)
    local width = height  0.6
    box.Size = Vector2.new(width, height) + BOX_SIZE_OFFSET
    box.Position = Vector2.new(screenPos.X - width2, screenPos.Y - height2)
    box.Visible = true
end

local function clearBoxes()
    for _, box in pairs(ESP.Boxes) do
        if box then boxRemove() end
    end
    ESP.Boxes = {}
end

-- === AIMBOT (unchanged - working perfectly) ===
local function isSheriff()
    local char = LocalPlayer.Character
    if not char then return false end
    local backpack = LocalPlayerFindFirstChild(Backpack)
    return (backpack and backpackFindFirstChild(Gun)) or charFindFirstChild(Gun)
end

local function findMurdererTarget()
    if not isSheriff() then return nil end
    
    local camera = Workspace.CurrentCamera
    local closest, shortestDist = nil, math.huge
    
    for _, player in ipairs(PlayersGetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.CharacterFindFirstChild(HumanoidRootPart) then
            local role = getRole(player)
            if role == Villain then
                local rootPos = player.Character.HumanoidRootPart.Position
                local screenPos, onScreen = cameraWorldToViewportPoint(rootPos)
                
                if onScreen then
                    local screenCenter = Vector2.new(camera.ViewportSize.X2, camera.ViewportSize.Y2)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    
                    if dist  AIM_FOV and dist  shortestDist then
                        shortestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

-- === NEW TRIGGERBOT - AUTO SHOOT MURDERER ===
local function triggerbotCheck()
    if not TRIGGERBOT.Enabled or not isSheriff() then return end
    
    local camera = Workspace.CurrentCamera
    local screenCenter = Vector2.new(camera.ViewportSize.X2, camera.ViewportSize.Y2)
    
    for _, player in ipairs(PlayersGetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.CharacterFindFirstChild(Head) then
            local role = getRole(player)
            if role == Villain then  -- Murderer!
                local headPos3D = player.Character.Head.Position
                local screenPos, onScreen = cameraWorldToViewportPoint(headPos3D)
                
                if onScreen then
                    local crosshairDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if crosshairDist  TRIGGER_FOV then  -- Head in crosshair!
                        -- AUTO SHOOT (simulate mouse click)
                        mouse1press()
                        wait(0.05)
                        mouse1release()
                        return
                    end
                end
            end
        end
    end
end

-- === AIMBOT LOOP ===
RunService.RenderSteppedConnect(function()
    if not AIMBOT.Enabled then return end
    
    local target = findMurdererTarget()
    AIMBOT.Target = target
    
    if target and target.Character and target.CharacterFindFirstChild(Head) then
        local camera = Workspace.CurrentCamera
        local headPos = target.Character.Head.Position
        
        local targetCFrame = CFrame.lookAt(camera.CFrame.Position, headPos)
        local currentCFrame = camera.CFrame
        
        local smoothedCFrame = currentCFrameLerp(targetCFrame, AIMBOT_SMOOTHNESS)
        camera.CFrame = smoothedCFrame
    end
    
    -- Triggerbot runs here too
    triggerbotCheck()
end)

-- === GUI (added Triggerbot button) ===
local Gui = Instance.new(ScreenGui)
Gui.Name = NonoHubV3_Triggerbot
Gui.Parent = LocalPlayerWaitForChild(PlayerGui)
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 1000

local Frame = Instance.new(Frame)
Frame.Size = UDim2.new(0, 480, 0, 280)  -- Wider for 4 buttons
Frame.Position = UDim2.new(0, 20, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Frame.BorderSizePixel = 0
Frame.Parent = Gui

local Corner = Instance.new(UICorner)
Corner.CornerRadius = UDim.new(0, 16)
Corner.Parent = Frame

local Shadow = Instance.new(ImageLabel)
Shadow.Size = UDim2.new(1, 24, 1, 24)
Shadow.Position = UDim2.new(0, -12, 0, -12)
Shadow.BackgroundTransparency = 1
Shadow.Image = rbxassetid6014261993
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.5
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(30, 30, 270, 270)
Shadow.Parent = Frame

-- Title
local Title = Instance.new(TextLabel)
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = NONO HUB V3 - PERFECT COMBO
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 34
Title.Parent = Frame

-- Subtitle
local Subtitle = Instance.new(TextLabel)
Subtitle.Size = UDim2.new(1, 0, 0, 30)
Subtitle.Position = UDim2.new(0, 0, 0, 50)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = ESP + Aimbot + Triggerbot = UNSTOPPABLE!
Subtitle.TextColor3 = Color3.fromRGB(255, 100, 100)
Subtitle.Font = Enum.Font.GothamBold
Subtitle.TextSize = 24
Subtitle.Parent = Frame

-- Status
local Status = Instance.new(TextLabel)
Status.Size = UDim2.new(1, -30, 0, 35)
Status.Position = UDim2.new(0, 15, 0, 85)
Status.BackgroundTransparency = 1
Status.Text = Loading...
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.Font = Enum.Font.GothamBold
Status.TextSize = 26
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Frame

-- Target Label
local TargetLabel = Instance.new(TextLabel)
TargetLabel.Size = UDim2.new(1, -30, 0, 30)
TargetLabel.Position = UDim2.new(0, 15, 0, 125)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = Target None
TargetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
TargetLabel.Font = Enum.Font.Gotham
TargetLabel.TextSize = 22
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Parent = Frame

-- 4 BUTTONS
local ToggleBtn = Instance.new(TextButton)
ToggleBtn.Size = UDim2.new(0, 105, 0, 45)
ToggleBtn.Position = UDim2.new(0, 15, 1, -60)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
ToggleBtn.Text = ESP ON
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.TextSize = 18
ToggleBtn.Parent = Frame

local AimbotBtn = Instance.new(TextButton)
AimbotBtn.Size = UDim2.new(0, 105, 0, 45)
AimbotBtn.Position = UDim2.new(0, 130, 1, -60)
AimbotBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
AimbotBtn.Text = AIMBOT OFF
AimbotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AimbotBtn.Font = Enum.Font.GothamBlack
AimbotBtn.TextSize = 18
AimbotBtn.Parent = Frame

local TriggerBtn = Instance.new(TextButton)  -- NEW!
TriggerBtn.Size = UDim2.new(0, 105, 0, 45)
TriggerBtn.Position = UDim2.new(0, 245, 1, -60)
TriggerBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
TriggerBtn.Text = TRIGGER OFF
TriggerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TriggerBtn.Font = Enum.Font.GothamBlack
TriggerBtn.TextSize = 18
TriggerBtn.Parent = Frame

local HideBtn = Instance.new(TextButton)
HideBtn.Size = UDim2.new(0, 105, 0, 45)
HideBtn.Position = UDim2.new(1, -120, 1, -60)
HideBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
HideBtn.Text = HIDE
HideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HideBtn.Font = Enum.Font.GothamBlack
HideBtn.TextSize = 18
HideBtn.Parent = Frame

-- Corners
for _, btn in pairs({ToggleBtn, AimbotBtn, TriggerBtn, HideBtn}) do
    local btnCorner = Instance.new(UICorner)
    btnCorner.CornerRadius = UDim.new(0, 12)
    btnCorner.Parent = btn
end

-- Floating SHOW
local FloatBtn = Instance.new(TextButton)
FloatBtn.Size = UDim2.new(0, 80, 0, 40)
FloatBtn.Position = UDim2.new(1, -100, 1, -60)
FloatBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
FloatBtn.Text = SHOW
FloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = 20
FloatBtn.Visible = false
FloatBtn.Parent = Gui

local FloatCorner = Instance.new(UICorner)
FloatCorner.CornerRadius = UDim.new(0, 10)
FloatCorner.Parent = FloatBtn

-- === BUTTON LOGIC ===
HideBtn.MouseButton1ClickConnect(function()
    GUI_VISIBLE = false
    Frame.Visible = false
    Shadow.Visible = false
    HideBtn.Visible = false
    FloatBtn.Visible = true
end)

FloatBtn.MouseButton1ClickConnect(function()
    GUI_VISIBLE = true
    Frame.Visible = true
    Shadow.Visible = true
    HideBtn.Visible = true
    FloatBtn.Visible = false
end)

ToggleBtn.MouseButton1ClickConnect(function()
    ESP.Enabled = not ESP.Enabled
    ToggleBtn.Text = ESP.Enabled and ESP ON or ESP OFF
    ToggleBtn.BackgroundColor3 = ESP.Enabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(255, 60, 60)
    if not ESP.Enabled then clearBoxes() end
end)

AimbotBtn.MouseButton1ClickConnect(function()
    AIMBOT.Enabled = not AIMBOT.Enabled
    AimbotBtn.Text = AIMBOT.Enabled and AIMBOT ON or AIMBOT OFF
    AimbotBtn.BackgroundColor3 = AIMBOT.Enabled and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(100, 100, 100)
end)

TriggerBtn.MouseButton1ClickConnect(function()
    TRIGGERBOT.Enabled = not TRIGGERBOT.Enabled
    TriggerBtn.Text = TRIGGERBOT.Enabled and TRIGGER ON or TRIGGER OFF
    TriggerBtn.BackgroundColor3 = TRIGGERBOT.Enabled and Color3.fromRGB(255, 150, 0) or Color3.fromRGB(100, 100, 100)
end)

-- === RGB TITLE ===
spawn(function()
    while wait(0.05) do
        Title.TextColor3 = getRainbowColor()
    end
end)

-- === MAIN LOOP ===
spawn(function()
    while wait(REFRESH_TIME) do
        if not ESP.Enabled then continue end
        
        local heroCount = 0
        local villainCount = 0
        clearBoxes()

        for _, player in ipairs(PlayersGetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local role = getRole(player)
                if role then
                    local box = createBox()
                    ESP.Boxes[player] = box
                    box.Color = (role == Hero) and SHERIFF_COLOR or MURDERER_COLOR
                    if role == Hero then heroCount += 1 else villainCount += 1 end
                end
            end
        end

        local myRole = getRole(LocalPlayer)
        local targetName = AIMBOT.Target and AIMBOT.Target.Name or None
        Status.Text = string.format(You %s  Heroes %d  Villains %d, myRole or , heroCount, villainCount)
        TargetLabel.Text = string.format(Target %s, targetName)
        TargetLabel.TextColor3 = AIMBOT.Target and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(150, 150, 150)
    end
end)

-- === BOX RENDER ===
RunService.RenderSteppedConnect(function()
    if not ESP.Enabled then return end
    for player, box in pairs(ESP.Boxes) do
        if player and player.Character then
            updateBox(player, box)
        else
            box.Visible = false
        end
    end
end)

-- === RESET ===
LocalPlayer.CharacterAddedConnect(function()
    wait(3)
    clearBoxes()
    AIMBOT.Target = nil
end)

-- === DRAG ===
local dragging = false
local dragStart, startPos
Frame.InputBeganConnect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and GUI_VISIBLE then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)
Frame.InputChangedConnect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
Frame.InputEndedConnect(function()
    dragging = false
end)

print(✅ NONO HUB V3 - TRIGGERBOT ADDED!)
print(🔫 TRIGGERBOT Auto-shoots when Murderer head is in crosshair!)
print(🎯 Enable AIMBOT + TRIGGER = INSTANT KILLS!)