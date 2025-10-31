local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")

local itemsFolder = ReplicatedStorage:FindFirstChild("Items")

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local window = library.CreateLib("VS MODS TEST - Steal A Brainrot", "DarkTheme")
local tab = window:NewTab("Main")
local section = tab:NewSection("Main")

-- Bouton Give All Items
section:NewButton("Give All Items (Client Sidded cool to fake live)", "Clone tout le contenu de ReplicatedStorage.Items dans ton Backpack", function()
    if not itemsFolder then
        game.StarterGui:SetCore("SendNotification", {
            Title = "Erreur",
            Text = "Le dossier Items n'existe pas dans ReplicatedStorage",
            Duration = 4,
        })
        return
    end

    local count = 0
    for _, item in ipairs(itemsFolder:GetChildren()) do
        if item:IsA("Tool") then
            local clone = item:Clone()
            clone.Parent = backpack
            count += 1
        end
    end

    game.StarterGui:SetCore("SendNotification", {
        Title = "Items clonés",
        Text = "Ajouté " .. tostring(count) .. " items dans ton Backpack",
        Duration = 4,
    })
end)

-- Bouton Give Cash (client-sided visual only)
section:NewButton("Give Cash (Visual only)", "Met ton Cash à 'infinite' localement", function()
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        game.StarterGui:SetCore("SendNotification", {
            Title = "Erreur",
            Text = "Pas de leaderstats trouvé",
            Duration = 4,
        })
        return
    end

    local cash = leaderstats:FindFirstChild("Cash")
    if not cash then
        game.StarterGui:SetCore("SendNotification", {
            Title = "Erreur",
            Text = "Pas de Cash trouvé dans leaderstats",
            Duration = 4,
        })
        return
    end

    cash.Value = 1e9

    game.StarterGui:SetCore("SendNotification", {
        Title = "1B added on the leaderbord",
        Text = "Ton Cash est maintenant 'infinite' localement !",
        Duration = 4,
    })
end)

-- Bouton No Laser (client-sided)
section:NewButton("No Laser", "Supprime tous les lasers dans workspace.Plots", function()
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then
        game.StarterGui:SetCore("SendNotification", {
            Title = "Erreur",
            Text = "Pas de dossier Plots trouvé dans Workspace",
            Duration = 4,
        })
        return
    end

    local count = 0
    for _, obj in ipairs(plotsFolder:GetDescendants()) do
        if obj.Name:lower():find("laser") then
            obj:Destroy()
            count += 1
        end
    end

    game.StarterGui:SetCore("SendNotification", {
        Title = "No Laser",
        Text = "Supprimé " .. tostring(count) .. " lasers",
        Duration = 4,
    })
end)

-- Bouton No Base Wall (client-sided)
section:NewButton("No Base Wall", "Supprime toutes les décorations dans workspace.Plots", function()
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then
        game.StarterGui:SetCore("SendNotification", {
            Title = "Erreur",
            Text = "Pas de dossier Plots trouvé dans Workspace",
            Duration = 4,
        })
        return
    end

    local count = 0
    for _, base in ipairs(plotsFolder:GetChildren()) do
        local decorations = base:FindFirstChild("Decorations")
        if decorations then
            for _, obj in ipairs(decorations:GetChildren()) do
                obj:Destroy()
                count += 1
            end
        end
    end

    game.StarterGui:SetCore("SendNotification", {
        Title = "No Base Wall",
        Text = "Supprimé " .. tostring(count) .. " décorations",
        Duration = 4,
    })
end)
