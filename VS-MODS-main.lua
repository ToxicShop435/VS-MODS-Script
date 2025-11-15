local UserInputService = game:GetService("UserInputService")
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local window = library.CreateLib("Auto Clicker", "DarkTheme")
local tab = window:NewTab("Main")
local section = tab:NewSection("Main")

local autoClickActive = false
local clicking = false

local mouse = game.Players.LocalPlayer:GetMouse()
local clickConnection
local inputConnection

section:NewButton("Auto Click", "Active/Désactive l'auto click", function()
    autoClickActive = not autoClickActive
    if autoClickActive then
        print("Auto Click activé. Presse J pour spam, K pour stop.")

        inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if not autoClickActive then return end

            if input.KeyCode == Enum.KeyCode.J and not clicking then
                clicking = true
                -- Lance la boucle de clic rapide dans un thread séparé
                spawn(function()
                    while clicking do
                        mouse1click()
                        task.wait(0.001) -- 1000 clics par seconde théoriquement
                    end
                end)
            elseif input.KeyCode == Enum.KeyCode.K and clicking then
                clicking = false
            end
        end)
    else
        clicking = false
        if inputConnection then
            inputConnection:Disconnect()
            inputConnection = nil
        end
        print("Auto Click désactivé.")
    end
end)
