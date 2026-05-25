-- NONO HUB - PREFAB SPAWNER | Spawn prefabs from TS module
-- Source: ts.ts (auto-detect TS ModuleScript/Folder across game services)
-- GUI Style: NONO HUB V10
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

-- === FIND TS MODULE ===
local tsSource = nil
local tsData = nil
local tsSourceName = "unknown"

local function findTS()
    local searchLocations = {
        {service = ReplicatedStorage, name = "ReplicatedStorage"},
        {service = Lighting, name = "Lighting"},
        {service = workspace, name = "Workspace"},
    }
    pcall(function()
        local ss = game:GetService("ServerStorage")
        if ss then
            table.insert(searchLocations, {service = ss, name = "ServerStorage"})
        end
    end)

    for _, loc in ipairs(searchLocations) do
        pcall(function()
            local ts = loc.service:FindFirstChild("TS") or loc.service:FindFirstChild("ts")
            if ts then
                tsSource = ts
                tsSourceName = loc.name .. "/TS"

                if ts:IsA("ModuleScript") then
                    local ok, data = pcall(require, ts)
                    if ok and type(data) == "table" then
                        tsData = data
                    end
                end

                local tsChild = ts:FindFirstChild("TS") or ts:FindFirstChild("ts")
                if tsChild then
                    tsSource = tsChild
                    tsSourceName = loc.name .. "/TS/TS"
                    if tsChild:IsA("ModuleScript") then
                        local ok, data = pcall(require, tsChild)
                        if ok and type(data) == "table" then
                            tsData = data
                        end
                    end
                end
            end
        end)
        if tsSource then break end
    end

    if not tsSource then
        for _, loc in ipairs(searchLocations) do
            pcall(function()
                for _, child in ipairs(loc.service:GetDescendants()) do
                    if not tsSource and (child.Name == "TS" or child.Name == "ts") then
                        tsSource = child
                        tsSourceName = loc.name .. "/.../" .. child.Name
                        if child:IsA("ModuleScript") then
                            local ok, data = pcall(require, child)
                            if ok and type(data) == "table" then
                                tsData = data
                            end
                        end
                    end
                end
            end)
            if tsSource then break end
        end
    end
end

-- === COLLECT PREFABS FROM TS ===
local function collectPrefabsFromTS(searchText)
    local results = {}

    if tsData and type(tsData) == "table" then
        for key, value in pairs(tsData) do
            local entryName = tostring(key)
            local nameMatch = true
            if searchText and searchText ~= "" then
                nameMatch = string.find(string.lower(entryName), string.lower(searchText), 1, true) ~= nil
            end
            if nameMatch then
                if type(value) == "userdata" and typeof(value) == "Instance" then
                    table.insert(results, {
                        name = entryName,
                        class = value.ClassName,
                        source = tsSourceName .. " [table]",
                        object = value,
                        isInstance = true,
                    })
                elseif type(value) == "table" then
                    local prefabRef = value.Prefab or value.prefab or value.Model or value.model or value.Object or value.object
                    if prefabRef and type(prefabRef) == "userdata" and typeof(prefabRef) == "Instance" then
                        table.insert(results, {
                            name = entryName,
                            class = prefabRef.ClassName,
                            source = tsSourceName .. " [table]",
                            object = prefabRef,
                            isInstance = true,
                        })
                    else
                        table.insert(results, {
                            name = entryName,
                            class = "TableEntry",
                            source = tsSourceName .. " [data]",
                            object = value,
                            isInstance = false,
                        })
                    end
                end
            end
        end
    end

    if tsSource and typeof(tsSource) == "Instance" then
        local function scanChildren(parent, parentPath)
            pcall(function()
                for _, child in ipairs(parent:GetChildren()) do
                    local valid = child:IsA("Model") or child:IsA("BasePart") or child:IsA("Tool")
                        or child:IsA("Accessory") or child:IsA("MeshPart") or child:IsA("UnionOperation")
                        or child:IsA("Decal") or child:IsA("SurfaceGui")
                    if valid then
                        local nameMatch = true
                        if searchText and searchText ~= "" then
                            nameMatch = string.find(string.lower(child.Name), string.lower(searchText), 1, true) ~= nil
                        end
                        if nameMatch then
                            table.insert(results, {
                                name = child.Name,
                                class = child.ClassName,
                                source = parentPath,
                                object = child,
                                isInstance = true,
                            })
                        end
                    end
                    if child:IsA("Folder") or child:IsA("Model") or child:IsA("Configuration") then
                        scanChildren(child, parentPath .. "/" .. child.Name)
                    end
                end
            end)
        end
        scanChildren(tsSource, tsSourceName)
    end

    return results
end

-- === COLLECT ALL PREFABS (FALLBACK - FULL GAME SCAN) ===
local function collectAllPrefabs(searchText)
    local results = {}
    local maxResults = 300
    local searchLocations = {
        {service = ReplicatedStorage, name = "ReplicatedStorage"},
        {service = Lighting, name = "Lighting"},
        {service = workspace, name = "Workspace"},
    }
    pcall(function()
        local ss = game:GetService("ServerStorage")
        if ss then
            table.insert(searchLocations, {service = ss, name = "ServerStorage"})
        end
    end)

    local function scan(parent, sourceName, depth)
        if depth > 5 or #results >= maxResults then return end
        pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                if #results >= maxResults then return end
                local valid = child:IsA("Model") or child:IsA("BasePart") or child:IsA("Tool")
                    or child:IsA("Accessory") or child:IsA("MeshPart") or child:IsA("UnionOperation")
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
                            isInstance = true,
                        })
                    end
                end
                if child:IsA("Folder") or child:IsA("Model") or child:IsA("Configuration") then
                    scan(child, sourceName .. "/" .. child.Name, depth + 1)
                end
            end
        end)
    end

    for _, loc in ipairs(searchLocations) do
        scan(loc.service, loc.name, 1)
    end
    return results
end

-- === SPAWN PREFAB ===
local function spawnPrefab(prefabData)
    local char = player.Character
    if not char then return false, "No character" end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, "No HumanoidRootPart" end

    if not prefabData.isInstance then
        return false, "Not a spawnable instance"
    end

    local clone = prefabData.object:Clone()
    if not clone then return false, "Clone failed" end

    local spawnCF = hrp.CFrame * CFrame.new(0, 0, -10)

    if clone:IsA("Model") then
        if clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(spawnCF)
        else
            local part = clone:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local cf, _ = clone:GetBoundingBox()
                clone:TranslateBy(spawnCF.Position - cf.Position)
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

    return true
end

-- === GUI ===
spawn(function()
    wait(1)

    findTS()

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NONOHUB_PREFAB_TS"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui

    local function corner(obj, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 12)
        c.Parent = obj
    end

    -- SLIDE BUTTON (right side, purple)
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
    mainFrame.Size = UDim2.new(0, 420, 0, 560)
    mainFrame.Position = UDim2.new(1, 0, 0.5, -280)
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

    -- SUBTITLE (source info)
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 20)
    subtitle.Position = UDim2.new(0, 0, 0, 45)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = tsSource and ("NONO HUB | Source: " .. tsSourceName) or "NONO HUB | TS not found - Full Scan"
    subtitle.TextColor3 = Color3.fromRGB(170, 170, 170)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 12
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
    searchIcon.Text = "?"
    searchIcon.TextColor3 = Color3.fromRGB(170, 170, 170)
    searchIcon.Font = Enum.Font.GothamBold
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

    -- MODE BUTTONS (TS SOURCE / FULL SCAN)
    local modeFrame = Instance.new("Frame")
    modeFrame.Size = UDim2.new(0.9, 0, 0, 35)
    modeFrame.Position = UDim2.new(0.05, 0, 0, 118)
    modeFrame.BackgroundTransparency = 1
    modeFrame.Parent = mainFrame

    local useFullScan = (tsSource == nil)

    local tsBtn = Instance.new("TextButton")
    tsBtn.Size = UDim2.new(0.48, 0, 1, 0)
    tsBtn.BackgroundColor3 = tsSource and Color3.fromRGB(170, 0, 255) or Color3.fromRGB(50, 50, 60)
    tsBtn.Text = "TS PREFABS"
    tsBtn.TextColor3 = Color3.new(1, 1, 1)
    tsBtn.Font = Enum.Font.GothamBold
    tsBtn.TextSize = 14
    tsBtn.Parent = modeFrame
    corner(tsBtn, 8)

    local fullBtn = Instance.new("TextButton")
    fullBtn.Size = UDim2.new(0.48, 0, 1, 0)
    fullBtn.Position = UDim2.new(0.52, 0, 0, 0)
    fullBtn.BackgroundColor3 = tsSource and Color3.fromRGB(50, 50, 60) or Color3.fromRGB(170, 0, 255)
    fullBtn.Text = "FULL SCAN"
    fullBtn.TextColor3 = Color3.new(1, 1, 1)
    fullBtn.Font = Enum.Font.GothamBold
    fullBtn.TextSize = 14
    fullBtn.Parent = modeFrame
    corner(fullBtn, 8)

    -- COUNT + REFRESH
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(0.9, 0, 0, 25)
    infoFrame.Position = UDim2.new(0.05, 0, 0, 158)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = mainFrame

    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(0.7, 0, 1, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "Found: 0 prefabs"
    countLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    countLabel.Font = Enum.Font.Gotham
    countLabel.TextSize = 13
    countLabel.TextXAlignment = Enum.TextXAlignment.Left
    countLabel.Parent = infoFrame

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0.28, 0, 1, 0)
    refreshBtn.Position = UDim2.new(0.72, 0, 0, 0)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    refreshBtn.Text = "REFRESH"
    refreshBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 12
    refreshBtn.Parent = infoFrame
    corner(refreshBtn, 6)

    -- PREFAB LIST
    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size = UDim2.new(0.9, 0, 0, 350)
    listFrame.Position = UDim2.new(0.05, 0, 0, 188)
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

    -- === CLASS ICON MAP ===
    local function getClassLabel(className)
        if className == "Model" then return "[M]"
        elseif className == "Tool" then return "[T]"
        elseif className == "Accessory" then return "[A]"
        elseif className == "Part" or className == "BasePart" then return "[P]"
        elseif className == "MeshPart" then return "[MP]"
        elseif className == "UnionOperation" then return "[U]"
        elseif className == "TableEntry" then return "[D]"
        else return "[?]"
        end
    end

    local function getClassColor(className)
        if className == "Model" then return Color3.fromRGB(0, 170, 255)
        elseif className == "Tool" then return Color3.fromRGB(255, 170, 0)
        elseif className == "Accessory" then return Color3.fromRGB(255, 100, 200)
        elseif className == "Part" or className == "BasePart" then return Color3.fromRGB(100, 255, 100)
        elseif className == "MeshPart" then return Color3.fromRGB(100, 200, 255)
        elseif className == "UnionOperation" then return Color3.fromRGB(200, 200, 100)
        elseif className == "TableEntry" then return Color3.fromRGB(170, 170, 170)
        else return Color3.fromRGB(200, 200, 200)
        end
    end

    -- === REFRESH LIST ===
    local function refreshList()
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end

        local prefabs
        if useFullScan then
            prefabs = collectAllPrefabs(searchBox.Text)
        else
            prefabs = collectPrefabsFromTS(searchBox.Text)
        end

        countLabel.Text = "Found: " .. #prefabs .. " prefabs"

        if #prefabs == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, -8, 0, 60)
            empty.BackgroundTransparency = 1
            empty.Text = useFullScan and "No prefabs found in game" or "No prefabs found in TS\nTry FULL SCAN mode"
            empty.TextColor3 = Color3.fromRGB(120, 120, 120)
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 14
            empty.TextWrapped = true
            empty.Parent = listFrame
        end

        for i, pData in ipairs(prefabs) do
            local entry = Instance.new("Frame")
            entry.Size = UDim2.new(1, -8, 0, 54)
            entry.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            entry.BorderSizePixel = 0
            entry.LayoutOrder = i
            entry.Parent = listFrame
            corner(entry, 8)

            -- CLASS ICON
            local classIcon = Instance.new("TextLabel")
            classIcon.Size = UDim2.new(0, 38, 0, 38)
            classIcon.Position = UDim2.new(0, 8, 0.5, -19)
            classIcon.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            classIcon.Text = getClassLabel(pData.class)
            classIcon.TextSize = 13
            classIcon.Font = Enum.Font.GothamBold
            classIcon.TextColor3 = getClassColor(pData.class)
            classIcon.Parent = entry
            corner(classIcon, 6)

            -- NAME
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -125, 0, 25)
            nameLabel.Position = UDim2.new(0, 52, 0, 4)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = pData.name
            nameLabel.TextColor3 = Color3.new(1, 1, 1)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 14
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = entry

            -- SOURCE
            local sourceLabel = Instance.new("TextLabel")
            sourceLabel.Size = UDim2.new(1, -125, 0, 18)
            sourceLabel.Position = UDim2.new(0, 52, 0, 28)
            sourceLabel.BackgroundTransparency = 1
            sourceLabel.Text = pData.class .. " | " .. pData.source
            sourceLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
            sourceLabel.Font = Enum.Font.Gotham
            sourceLabel.TextSize = 11
            sourceLabel.TextXAlignment = Enum.TextXAlignment.Left
            sourceLabel.TextTruncate = Enum.TextTruncate.AtEnd
            sourceLabel.Parent = entry

            -- SPAWN BUTTON
            local spawnBtn = Instance.new("TextButton")
            spawnBtn.Size = UDim2.new(0, 65, 0, 34)
            spawnBtn.Position = UDim2.new(1, -73, 0.5, -17)
            spawnBtn.BackgroundColor3 = pData.isInstance and Color3.fromRGB(170, 0, 255) or Color3.fromRGB(80, 80, 90)
            spawnBtn.Text = pData.isInstance and "SPAWN" or "DATA"
            spawnBtn.TextColor3 = Color3.new(1, 1, 1)
            spawnBtn.Font = Enum.Font.GothamBold
            spawnBtn.TextSize = 12
            spawnBtn.Parent = entry
            corner(spawnBtn, 8)

            if pData.isInstance then
                spawnBtn.MouseButton1Click:Connect(function()
                    local ok, err = pcall(function()
                        local success, msg = spawnPrefab(pData)
                        if not success then error(msg) end
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
            end

            -- HOVER
            entry.MouseEnter:Connect(function()
                TweenService:Create(entry, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(55, 55, 65)}):Play()
            end)
            entry.MouseLeave:Connect(function()
                TweenService:Create(entry, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
            end)
        end

        listFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(#prefabs * 58 + 10, 60))
    end

    -- === MODE TOGGLE ===
    tsBtn.MouseButton1Click:Connect(function()
        if not tsSource then return end
        useFullScan = false
        tsBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 255)
        fullBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        refreshList()
    end)

    fullBtn.MouseButton1Click:Connect(function()
        useFullScan = true
        fullBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 255)
        tsBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        refreshList()
    end)

    -- REFRESH BUTTON
    refreshBtn.MouseButton1Click:Connect(function()
        refreshBtn.Text = "..."
        findTS()
        subtitle.Text = tsSource and ("NONO HUB | Source: " .. tsSourceName) or "NONO HUB | TS not found - Full Scan"
        refreshList()
        task.delay(0.5, function()
            if refreshBtn and refreshBtn.Parent then
                refreshBtn.Text = "REFRESH"
            end
        end)
    end)

    -- LIVE SEARCH
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        refreshList()
    end)

    -- SLIDE TOGGLE
    local open = false
    slideBtn.MouseButton1Click:Connect(function()
        open = not open
        local frameGoal = open and UDim2.new(1, -440, 0.5, -280) or UDim2.new(1, 0, 0.5, -280)
        local btnGoal = open and UDim2.new(1, -510, 0.5, -80) or UDim2.new(1, -70, 0.5, -80)
        TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = frameGoal}):Play()
        TweenService:Create(slideBtn, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = btnGoal}):Play()
        slideBtn.Text = open and ">" or "<"
    end)

    -- CLOSE BUTTON
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

    -- RGB BORDER
    spawn(function()
        while screenGui and screenGui.Parent do
            stroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
            task.wait()
        end
    end)

    -- AUTO OPEN + INITIAL SCAN
    task.delay(0.5, function()
        if slideBtn then slideBtn.MouseButton1Click:Fire() end
    end)
    task.delay(1, function()
        refreshList()
    end)

    print("NONO HUB - PREFAB SPAWNER (TS) LOADED!")
end)
