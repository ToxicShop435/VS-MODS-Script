-- NONO HUB V10 - TP LIST SHOWS EVERYONE (INCLUDING DEAD) | NAME + HEALTH ESP
-- TP LIST: ALL PLAYERS (alive + dead) | ESP: Name + Health Bar + [DEAD] | 100% WORKING
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

-- === VARIABLES ===
local flying = false
local noclipping = false
local infiniteJumpEnabled = false
local speedBoostValue = 16
local bodyVelocity, bodyGyro
local noclipLoop, jumpLoop
local screenGui, mainFrame, slideBtn, flyStatus
local espBoxes = {}
local espNames = {}
local espHealths = {}

-- === SAFE LOAD ===
spawn(function()
    wait(1)

    -- === GET CHARACTER ===
    local function getChar()
        if not player.Character then player.CharacterAdded:Wait() end
        local char = player.Character
        char:WaitForChild("HumanoidRootPart", 5)
        char:WaitForChild("Humanoid", 5)
        return char
    end

    -- === ESP (NAME + HEALTH BAR + DEAD STATUS) ===
    local function updateESP(plr)
        if plr == player then return end
        
        -- CLEAN OLD ESP
        if espBoxes[plr] then espBoxes[plr]:Destroy() espBoxes[plr] = nil end
        if espNames[plr] then espNames[plr]:Destroy() espNames[plr] = nil end
        if espHealths[plr] then espHealths[plr]:Destroy() espHealths[plr] = nil end

        -- FIND TARGET PART (ALIVE OR DEAD)
        local targetPart = nil
        local char = plr.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            targetPart = char.HumanoidRootPart
        elseif char then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    targetPart = part
                    break
                end
            end
        end

        if not targetPart or not char then return end

        local hum = char:FindFirstChild("Humanoid")
        local isDead = not hum or hum.Health <= 0
        local healthPercent = hum and math.clamp(hum.Health / hum.MaxHealth, 0, 1) or 0

        -- BOX (RED/GREEN)
        local box = Instance.new("BoxHandleAdornment")
        box.Size = char:GetExtentsSize() + Vector3.new(0, 2, 0)
        box.Adornee = char
        box.Color3 = isDead and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
        box.Transparency = 0.5
        box.AlwaysOnTop = true
        box.ZIndex = 10
        box.Parent = CoreGui
        espBoxes[plr] = box

        -- NAME + HEALTH TEXT
        local nameTag = Instance.new("BillboardGui")
        nameTag.Adornee = targetPart
        nameTag.Size = UDim2.new(0, 160, 0, 40)
        nameTag.StudsOffset = Vector3.new(0, 6, 0)
        nameTag.AlwaysOnTop = true
        nameTag.Parent = CoreGui

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = plr.Name .. (isDead and " [DEAD]" or "")
        nameLabel.TextColor3 = isDead and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(0, 255, 0)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.new(0,0,0)
        nameLabel.TextSize = 18
        nameLabel.Parent = nameTag
        espNames[plr] = nameTag

        -- HEALTH BAR
        local healthFrame = Instance.new("BillboardGui")
        healthFrame.Adornee = targetPart
        healthFrame.Size = UDim2.new(0, 160, 0, 8)
        healthFrame.StudsOffset = Vector3.new(0, 4, 0)
        healthFrame.AlwaysOnTop = true
        healthFrame.Parent = CoreGui

        local healthBg = Instance.new("Frame")
        healthBg.Size = UDim2.new(1, 0, 1, 0)
        healthBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        healthBg.BorderSizePixel = 0
        healthBg.Parent = healthFrame
        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(0, 4)
        bgCorner.Parent = healthBg

        local healthBar = Instance.new("Frame")
        healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
        healthBar.BackgroundColor3 = isDead and Color3.fromRGB(100, 0, 0) or Color3.fromRGB(0, 255, 0)
        healthBar.BorderSizePixel = 0
        healthBar.Parent = healthBg
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 4)
        barCorner.Parent = healthBar

        espHealths[plr] = healthFrame
    end

    -- === ESP REFRESH LOOP (0.5s) ===
    spawn(function()
        while true do
            for _, plr in pairs(Players:GetPlayers()) do
                pcall(updateESP, plr)
            end
            task.wait(0.5)
        end
    end)

    -- === FLY (PRESS E) ===
    local function startFly()
        if flying then return end
        local char = getChar()
        local hrp = char.HumanoidRootPart
        local hum = char.Humanoid
        flying = true
        hum.PlatformStand = true
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bodyVelocity.Velocity = Vector3.new(0,0,0)
        bodyVelocity.Parent = hrp
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        bodyGyro.P = 30000
        bodyGyro.CFrame = hrp.CFrame
        bodyGyro.Parent = hrp
        spawn(function()
            while flying and hrp and hrp.Parent do
                local cam = workspace.CurrentCamera
                local move = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
                bodyVelocity.Velocity = move * 100
                bodyGyro.CFrame = cam.CFrame
                task.wait()
            end
        end)
    end

    local function stopFly()
        if not flying then return end
        flying = false
        local char = player.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = false end
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
    end

    UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.E then
            if flying then stopFly() else startFly() end
            if flyStatus then
                flyStatus.Text = "FLY: " .. (flying and "ON" or "OFF") .. " (E)"
                flyStatus.BackgroundColor3 = flying and Color3.fromRGB(0,200,0) or Color3.fromRGB(50,50,60)
            end
        end
    end)

    -- === TP TO PLAYER (WORKS ON DEAD BODIES TOO) ===
    local function tpToPlayer(name)
        local target = Players:FindFirstChild(name)
        if not target then return end
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local targetPart = nil
        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            targetPart = target.Character.HumanoidRootPart
        elseif target.Character then
            for _, part in pairs(target.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    targetPart = part
                    break
                end
            end
        end
        
        if targetPart then
            hrp.CFrame = targetPart.CFrame + Vector3.new(0, 5, 0)
        end
    end

    -- === GUI ===
    local function createGui()
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "NONOHUB_FULLTP"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = CoreGui

        local function corner(obj)
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 12)
            c.Parent = obj
        end

        slideBtn = Instance.new("TextButton")
        slideBtn.Size = UDim2.new(0, 70, 0, 160)
        slideBtn.Position = UDim2.new(0, 0, 0.5, -80)
        slideBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
        slideBtn.Text = ">"
        slideBtn.TextColor3 = Color3.new(1,1,1)
        slideBtn.Font = Enum.Font.GothamBold
        slideBtn.TextSize = 40
        slideBtn.Parent = screenGui
        corner(slideBtn)

        mainFrame = Instance.new("Frame")
        mainFrame.Size = UDim2.new(0, 380, 0, 480)
        mainFrame.Position = UDim2.new(0, -380, 0.5, -240)
        mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        mainFrame.Active = true
        mainFrame.Draggable = true
        mainFrame.Parent = screenGui
        corner(mainFrame)

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 3
        stroke.Parent = mainFrame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 60)
        title.BackgroundTransparency = 1
        title.Text = "NONO HUB V10"
        title.TextColor3 = Color3.new(1,1,1)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 28
        title.Parent = mainFrame

        flyStatus = Instance.new("TextLabel")
        flyStatus.Size = UDim2.new(0.9, 0, 0, 45)
        flyStatus.Position = UDim2.new(0.05, 0, 0.12, 0)
        flyStatus.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        flyStatus.Text = "FLY: OFF (Press E)"
        flyStatus.TextColor3 = Color3.fromRGB(255, 255, 0)
        flyStatus.Font = Enum.Font.GothamBold
        flyStatus.TextSize = 18
        flyStatus.Parent = mainFrame
        corner(flyStatus)

        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = UDim2.new(0.9, 0, 0.7, 0)
        scrollFrame.Position = UDim2.new(0.05, 0, 0.23, 0)
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.ScrollBarThickness = 8
        scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.Parent = mainFrame

        local open = false
        slideBtn.MouseButton1Click:Connect(function()
            open = not open
            local goal = open and UDim2.new(0, 20, 0.5, -240) or UDim2.new(0, -380, 0.5, -240)
            TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = goal}):Play()
            slideBtn.Text = open and "<" or ">"
        end)

        local y = 0
        local function addBtn(name, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 40)
            btn.Position = UDim2.new(0, 5, 0, y)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            btn.Text = name .. ": OFF"
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.GothamSemibold
            btn.TextSize = 16
            btn.Parent = scrollFrame
            corner(btn)
            btn:SetAttribute("on", false)
            btn.MouseButton1Click:Connect(function()
                local on = not btn:GetAttribute("on")
                btn:SetAttribute("on", on)
                btn.Text = name .. ": " .. (on and "ON" or "OFF")
                btn.BackgroundColor3 = on and Color3.fromRGB(0,200,0) or Color3.fromRGB(50,50,60)
                callback(on)
            end)
            y = y + 50
            return btn
        end

        addBtn("NOCLIP", function(on)
            noclipping = on
            if on then
                noclipLoop = RunService.RenderStepped:Connect(function()
                    local char = player.Character
                    if char then
                        for _, v in pairs(char:GetDescendants()) do
                            if v:IsA("BasePart") then v.CanCollide = false end
                        end
                    end
                end)
            else
                if noclipLoop then noclipLoop:Disconnect() end
            end
        end)

        addBtn("INFINITE JUMP", function(on)
            infiniteJumpEnabled = on
            if on then
                local hum = player.Character and player.Character:FindFirstChild("Humanoid")
                if hum then hum.JumpPower = 100 end
                jumpLoop = UserInputService.JumpRequest:Connect(function()
                    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end)
            else
                if jumpLoop then jumpLoop:Disconnect() end
                local hum = player.Character and player.Character:FindFirstChild("Humanoid")
                if hum then hum.JumpPower = 50 end
            end
        end)

        -- SPEED SLIDER
        local speedLabel = Instance.new("TextLabel")
        speedLabel.Size = UDim2.new(1, -10, 0, 40)
        speedLabel.Position = UDim2.new(0, 5, 0, y)
        speedLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        speedLabel.Text = "Speed: 16"
        speedLabel.TextColor3 = Color3.new(1,1,1)
        speedLabel.Font = Enum.Font.GothamSemibold
        speedLabel.TextSize = 18
        speedLabel.Parent = scrollFrame
        corner(speedLabel)

        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, -10, 0, 10)
        slider.Position = UDim2.new(0, 5, 0, y + 45)
        slider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        slider.Parent = scrollFrame
        corner(slider)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 20, 1, 4)
        knob.Position = UDim2.new(0, -10, 0, 0)
        knob.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        knob.Parent = slider
        corner(knob)

        local dragging = false
        knob.InputBegan:Connect(function(i) 
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end 
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = math.clamp((i.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
                speedBoostValue = math.floor(rel * 100 + 16)
                knob.Position = UDim2.new(rel, -10, 0, 0)
                speedLabel.Text = "Speed: " .. speedBoostValue
                local hum = player.Character and player.Character:FindFirstChild("Humanoid")
                if hum then hum.WalkSpeed = speedBoostValue end
            end
        end)
        UserInputService.InputEnded:Connect(function(i) 
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end 
        end)
        y = y + 80

        -- TP LIST - SHOWS EVERYONE (ALIVE + DEAD)
        local tpContainer = Instance.new("Frame")
        tpContainer.Size = UDim2.new(1, -10, 0, 180)
        tpContainer.Position = UDim2.new(0, 5, 0, y)
        tpContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        tpContainer.Parent = scrollFrame
        corner(tpContainer)

        local tpTitle = Instance.new("TextLabel")
        tpTitle.Size = UDim2.new(1, 0, 0, 30)
        tpTitle.BackgroundTransparency = 1
        tpTitle.Text = "TELEPORT TO ANYONE (ALL PLAYERS)"
        tpTitle.TextColor3 = Color3.fromRGB(0, 170, 255)
        tpTitle.Font = Enum.Font.GothamBold
        tpTitle.TextSize = 16
        tpTitle.Parent = tpContainer

        local tpList = Instance.new("ScrollingFrame")
        tpList.Size = UDim2.new(1, -10, 1, -35)
        tpList.Position = UDim2.new(0, 5, 0, 30)
        tpList.BackgroundTransparency = 1
        tpList.ScrollBarThickness = 6
        tpList.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255)
        tpList.CanvasSize = UDim2.new(0, 0, 0, 0)
        tpList.Parent = tpContainer

        spawn(function()
            while screenGui and screenGui.Parent do
                tpList:ClearAllChildren()
                local ty = 0
                for _, p in pairs(Players:GetPlayers()) do
                    -- SHOW ALL PLAYERS (EVEN DEAD)
                    local hum = p.Character and p.Character:FindFirstChild("Humanoid")
                    local isDead = hum and hum.Health <= 0
                    local status = isDead and " [DEAD]" or (hum and " [ALIVE]" or " [NO BODY]")

                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1, 0, 0, 30)
                    btn.Position = UDim2.new(0, 0, 0, ty)
                    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                    btn.Text = p.Name .. status
                    btn.TextColor3 = isDead and Color3.fromRGB(255, 100, 100) or Color3.new(1,1,1)
                    btn.Font = Enum.Font.Gotham
                    btn.TextSize = 14
                    btn.Parent = tpList
                    corner(btn)
                    btn.MouseButton1Click:Connect(function() tpToPlayer(p.Name) end)
                    ty = ty + 35
                end
                tpList.CanvasSize = UDim2.new(0, 0, 0, ty)
                task.wait(1)
            end
        end)

        y = y + 200
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, y)

        -- CLOSE BUTTON
        local close = Instance.new("TextButton")
        close.Size = UDim2.new(0, 40, 0, 40)
        close.Position = UDim2.new(1, -50, 0, 10)
        close.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        close.Text = "X"
        close.TextColor3 = Color3.new(1,1,1)
        close.Font = Enum.Font.GothamBold
        close.TextSize = 24
        close.Parent = mainFrame
        corner(close)
        close.MouseButton1Click:Connect(function()
            stopFly()
            if noclipLoop then noclipLoop:Disconnect() end
            if jumpLoop then jumpLoop:Disconnect() end
            for _, v in pairs(espBoxes) do if v then v:Destroy() end end
            for _, v in pairs(espNames) do if v then v:Destroy() end end
            for _, v in pairs(espHealths) do if v then v:Destroy() end end
            screenGui:Destroy()
        end)

        -- RGB BORDER
        spawn(function()
            while screenGui and screenGui.Parent do
                stroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                task.wait()
            end
        end)

        -- AUTO OPEN
        task.delay(1, function()
            if slideBtn then slideBtn.MouseButton1Click:Fire() end
        end)
    end

    createGui()
    print("NONO HUB V10 - TP LIST SHOWS EVERYONE (ALIVE + DEAD) - LOADED!")
end)
