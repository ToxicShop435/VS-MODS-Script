-- NONO HUB - PREFAB SPAWNER | Scan & Spawn any prefab from the game
-- Scans: ReplicatedStorage, Workspace, Lighting, ServerStorage (if accessible)
-- GUI Style: Same as NONO HUB V10
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

-- === PREFAB SOURCES ===
local prefabSources = {
    {name = "ReplicatedStorage", service = ReplicatedStorage},
    {name = "Lighting", service = Lighting},
    {name = "Workspace", service = workspace},
}

-- Try ServerStorage (usually not accessible from client, but some games expose it)
pcall(function()
    local ss = game:GetService("ServerStorage")
    if ss then
        table.insert(prefabSources, {name = "ServerStorage", service = ss})
    end
end)

-- === COLLECT ALL PREFABS ===
local function collectPrefabs(searchText)
    local results = {}
    for _, source in ipairs(prefabSources) do
        pcall(function()
            for _, child in ipairs(source.service:GetChildren()) do
                local valid = child:IsA("Model") or child:IsA("BasePart") or child:IsA("Tool") or child:IsA("Accessory") or child:IsA("Folder")
                if valid then
                    local nameMatch = true
                    if searchText and searchText ~= "" then
                        nameMatch = string.find(string.lower(child.Name), string.lower(searchText), 1, true) ~= nil
                    end
                    if nameMatch then
                        table.insert(results, {
                            name = child.Name,
                            class = child.ClassName,
                            source = source.name,
                            object = child,
                        })
                    end
                end
            end
        end)
    end
    return results
end

-- === DEEP SCAN (RECURSIVE) ===
local function collectPrefabsDeep(searchText)
    local results = {}
    local maxDepth = 5
    local maxResults = 200

    local function scan(parent, sourceName, depth)
        if depth > maxDepth or #results >= maxResults then return end
        pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                if #results >= maxResults then return end
                local valid = child:IsA("Model") or child:IsA("BasePart") or child:IsA("Tool") or child:IsA("Accessory")
                if valid then
                    local nameMatch = true
                    if searchText and searchText ~= "" then
                        nameMatch = string.find(string.lower(child.Name), string.lower(searchText), 1, true) ~= nil
                    end
                    if nameMatch then
                        table.insert(results, {
                            name = child.Name,
                            class = child.ClassName,
                            source = sourceName,
                            object = child,
                        })
                    end
                end
                if child:IsA("Folder") or child:IsA("Model") or child:IsA("Configuration") then
                    scan(child, sourceName .. "/" .. child.Name, depth + 1)
                end
            end
        end)
    end

    for _, source in ipairs(prefabSources) do
        scan(source.service, source.name, 1)
    end
    return results
end

-- === SPAWN PREFAB ===
local function spawnPrefab(prefabData)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local clone = prefabData.object:Clone()
    if not clone then return end

    -- Position the clone in front of the player
    local spawnCF = hrp.CFrame * CFrame.new(0, 0, -10)

    if clone:IsA("Model") then
        if clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(spawnCF)
        else
            -- Find a base part to position
            local part = clone:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local offset = part.Position - (clone:GetBoundingBox()).Position
                clone:TranslateBy(spawnCF.Position - (clone:GetBoundingBox()).Position)
            end
        end
        clone.Parent = workspace
    elseif clone:IsA("Tool") or clone:IsA("Accessory") then
        clone.Parent = player.Backpack
    elseif clone:IsA("BasePart") then
        clone.CFrame = spawnCF
        clone.Parent = workspace
    else
        clone.Parent = workspace
    end

    return clone
end

-- === GUI ===
spawn(function()
    wait(1)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NONOHUB_PREFAB"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui

    local function corner(obj, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 12)
        c.Parent = obj
    end

    -- SLIDE BUTTON
    local slideBtn = Instance.new("TextButton")
    slideBtn.Size = UDim2.new(0, 70, 0, 160)
    slideBtn.Position = UDim2.new(1, -70, 0.5, -80)
    slideBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 255)
    slideBtn.Text = "<"
    slideBtn.TextColor3 = Color3.new(1, 1, 1)
    slideBtn.Font = Enum.Font.GothamBold
    slideBtn.TextSize = 40
    slideBtn.Parent = screenGui
    corner(slideBtn)

    -- MAIN FRAME
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 420, 0, 550)
    mainFrame.Position = UDim2.new(1, 0, 0.5, -275)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    corner(mainFrame)

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 3
    stroke.Parent = mainFrame

    -- TITLE
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "PREFAB SPAWNER"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 26
    title.Parent = mainFrame

    -- SUBTITLE
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 20)
    subtitle.Position = UDim2.new(0, 0, 0, 45)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "NONO HUB | Scan & Spawn Prefabs"
    subtitle.TextColor3 = Color3.fromRGB(170, 170, 170)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 13
    subtitle.Parent = mainFrame

    -- SEARCH BAR
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(0.9, 0, 0, 40)
    searchFrame.Position = UDim2.new(0.05, 0, 0, 72)
    searchFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    searchFrame.Parent = mainFrame
    corner(searchFrame)

    local searchIcon = Instance.new("TextLabel")
    searchIcon.Size = UDim2.new(0, 35, 1, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextSize = 18
    searchIcon.Parent = searchFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -40, 1, 0)
    searchBox.Position = UDim2.new(0, 35, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Search prefabs..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.new(1, 1, 1)
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 16
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchFrame

    -- MODE BUTTONS (TOP LEVEL / DEEP SCAN)
    local modeFrame = Instance.new("Frame")
    modeFrame.Size = UDim2.new(0.9, 0, 0, 35)
    modeFrame.Position = UDim2.new(0.05, 0, 0, 118)
    modeFrame.BackgroundTransparency = 1
    modeFrame.Parent = mainFrame

    local deepScan = false

    local topBtn = Instance.new("TextButton")
    topBtn.Size = UDim2.new(0.48, 0, 1, 0)
    topBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    topBtn.Text = "TOP LEVEL"
    topBtn.TextColor3 = Color3.new(1, 1, 1)
    topBtn.Font = Enum.Font.GothamBold
    topBtn.TextSize = 14
    topBtn.Parent = modeFrame
    corner(topBtn, 8)

    local deepBtn = Instance.new("TextButton")
    deepBtn.Size = UDim2.new(0.48, 0, 1, 0)
    deepBtn.Position = UDim2.new(0.52, 0, 0, 0)
    deepBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    deepBtn.Text = "DEEP SCAN"
    deepBtn.TextColor3 = Color3.new(1, 1, 1)
    deepBtn.Font = Enum.Font.GothamBold
    deepBtn.TextSize = 14
    deepBtn.Parent = modeFrame
    corner(deepBtn, 8)

    -- COUNT LABEL
    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(0.9, 0, 0, 20)
    countLabel.Position = UDim2.new(0.05, 0, 0, 158)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "Found: 0 prefabs"
    countLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    countLabel.Font = Enum.Font.Gotham
    countLabel.TextSize = 13
    countLabel.TextXAlignment = Enum.TextXAlignment.Left
    countLabel.Parent = mainFrame

    -- PREFAB LIST
    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size = UDim2.new(0.9, 0, 0, 340)
    listFrame.Position = UDim2.new(0.05, 0, 0, 182)
    listFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    listFrame.ScrollBarThickness = 8
    listFrame.ScrollBarImageColor3 = Color3.fromRGB(170, 0, 255)
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    listFrame.BorderSizePixel = 0
    listFrame.Parent = mainFrame
    corner(listFrame, 8)

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = listFrame

    -- === REFRESH PREFAB LIST ===
    local function refreshList()
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end

        local prefabs
        if deepScan then
            prefabs = collectPrefabsDeep(searchBox.Text)
        else
            prefabs = collectPrefabs(searchBox.Text)
        end

        countLabel.Text = "Found: " .. #prefabs .. " prefabs"

        for i, pData in ipairs(prefabs) do
            local entry = Instance.new("Frame")
            entry.Size = UDim2.new(1, -8, 0, 50)
            entry.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            entry.BorderSizePixel = 0
            entry.LayoutOrder = i
            entry.Parent = listFrame
            corner(entry, 8)

            -- CLASS ICON
            local classIcon = Instance.new("TextLabel")
            classIcon.Size = UDim2.new(0, 35, 0, 35)
            classIcon.Position = UDim2.new(0, 8, 0.5, -17)
            classIcon.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            classIcon.Text = pData.class == "Model" and "📦" or
                             pData.class == "Tool" and "🔧" or
                             pData.class == "Accessory" and "🎩" or
                             pData.class == "BasePart" and "🧱" or
                             pData.class == "Part" and "🧱" or "📄"
            classIcon.TextSize = 18
            classIcon.Font = Enum.Font.Gotham
            classIcon.TextColor3 = Color3.new(1, 1, 1)
            classIcon.Parent = entry
            corner(classIcon, 6)

            -- NAME + SOURCE
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -120, 0, 25)
            nameLabel.Position = UDim2.new(0, 50, 0, 3)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = pData.name
            nameLabel.TextColor3 = Color3.new(1, 1, 1)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 14
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = entry

            local sourceLabel = Instance.new("TextLabel")
            sourceLabel.Size = UDim2.new(1, -120, 0, 18)
            sourceLabel.Position = UDim2.new(0, 50, 0, 27)
            sourceLabel.BackgroundTransparency = 1
            sourceLabel.Text = pData.class .. " | " .. pData.source
            sourceLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
            sourceLabel.Font = Enum.Font.Gotham
            sourceLabel.TextSize = 11
            sourceLabel.TextXAlignment = Enum.TextXAlignment.Left
            sourceLabel.Parent = entry

            -- SPAWN BUTTON
            local spawnBtn = Instance.new("TextButton")
            spawnBtn.Size = UDim2.new(0, 60, 0, 32)
            spawnBtn.Position = UDim2.new(1, -68, 0.5, -16)
            spawnBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 255)
            spawnBtn.Text = "SPAWN"
            spawnBtn.TextColor3 = Color3.new(1, 1, 1)
            spawnBtn.Font = Enum.Font.GothamBold
            spawnBtn.TextSize = 12
            spawnBtn.Parent = entry
            corner(spawnBtn, 8)

            spawnBtn.MouseButton1Click:Connect(function()
                local ok, err = pcall(function()
                    spawnPrefab(pData)
                end)
                if ok then
                    spawnBtn.Text = "OK!"
                    spawnBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
                    task.delay(1, function()
                        if spawnBtn and spawnBtn.Parent then
                            spawnBtn.Text = "SPAWN"
                            spawnBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 255)
                        end
                    end)
                else
                    spawnBtn.Text = "FAIL"
                    spawnBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                    task.delay(1.5, function()
                        if spawnBtn and spawnBtn.Parent then
                            spawnBtn.Text = "SPAWN"
                            spawnBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 255)
                        end
                    end)
                end
            end)

            -- HOVER EFFECT
            entry.MouseEnter:Connect(function()
                TweenService:Create(entry, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55, 55, 65)}):Play()
            end)
            entry.MouseLeave:Connect(function()
                TweenService:Create(entry, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
            end)
        end

        listFrame.CanvasSize = UDim2.new(0, 0, 0, #prefabs * 54 + 10)
    end

    -- === MODE TOGGLE ===
    topBtn.MouseButton1Click:Connect(function()
        deepScan = false
        topBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        deepBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        refreshList()
    end)

    deepBtn.MouseButton1Click:Connect(function()
        deepScan = true
        deepBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        topBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        refreshList()
    end)

    -- === SEARCH LIVE ===
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        refreshList()
    end)

    -- === SLIDE TOGGLE ===
    local open = false
    slideBtn.MouseButton1Click:Connect(function()
        open = not open
        local frameGoal = open and UDim2.new(1, -440, 0.5, -275) or UDim2.new(1, 0, 0.5, -275)
        local btnGoal = open and UDim2.new(1, -510, 0.5, -80) or UDim2.new(1, -70, 0.5, -80)
        TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = frameGoal}):Play()
        TweenService:Create(slideBtn, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = btnGoal}):Play()
        slideBtn.Text = open and ">" or "<"
    end)

    -- === CLOSE BUTTON ===
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 40, 0, 40)
    close.Position = UDim2.new(1, -50, 0, 5)
    close.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    close.Text = "X"
    close.TextColor3 = Color3.new(1, 1, 1)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 24
    close.Parent = mainFrame
    corner(close)
    close.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- === RGB BORDER ===
    spawn(function()
        while screenGui and screenGui.Parent do
            stroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
            task.wait()
        end
    end)

    -- === AUTO OPEN + INITIAL SCAN ===
    task.delay(0.5, function()
        if slideBtn then slideBtn.MouseButton1Click:Fire() end
    end)
    task.delay(1, function()
        refreshList()
    end)

    print("NONO HUB - PREFAB SPAWNER LOADED!")
end)
