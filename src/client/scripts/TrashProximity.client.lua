local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local roact = require(Packages:FindFirstChild("roblox_roact@1.4.4") or Packages.Roact)
local rodux = require(Packages:FindFirstChild("roblox_rodux@3.0.0") or Packages.Rodux)

local player = Players.LocalPlayer
local character = player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local PROXIMITY_DISTANCE = 10 -- studs
local currentTrashBin = nil
local proximityGui = nil

-- Create proximity GUI
local function createProximityGui(trashBinName)
    local trashConfig = {
        OrganicTrash = { name = "Organic Trash Bin", icon = "🌱" },
        AnorganicTrash = { name = "Anorganic Trash Bin", icon = "🔧" },
        MixedTrash = { name = "Mixed Trash Bin", icon = "♻️" }
    }
    
    local config = trashConfig[trashBinName] or trashConfig.OrganicTrash
    
    proximityGui = Instance.new("ScreenGui")
    proximityGui.Name = "TrashProximityGui"
    proximityGui.Parent = player.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 60)
    frame.Position = UDim2.new(0.5, -100, 0.8, -30)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BackgroundTransparency = 0.2
    frame.Parent = proximityGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = config.icon .. " Press E to open " .. config.name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = frame
end

-- Remove proximity GUI
local function removeProximityGui()
    if proximityGui then
        proximityGui:Destroy()
        proximityGui = nil
    end
end

-- Check proximity to trash bins
local function checkProximity()
    local newTrashBin = nil
    local closestDistance = PROXIMITY_DISTANCE
    
    -- Find all trash bins in workspace
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "OrganicTrash" or obj.Name == "AnorganicTrash" or obj.Name == "MixedTrash" then
            local trashPosition = nil
            
            -- 🔧 FIX: Handle both Part and Model cases
            if obj:IsA("Part") then
                trashPosition = obj.Position
            elseif obj:IsA("Model") then
                -- Try PrimaryPart first
                if obj.PrimaryPart then
                    trashPosition = obj.PrimaryPart.Position
                else
                    -- Find first Part in model
                    local firstPart = obj:FindFirstChildOfClass("Part") or obj:FindFirstChildOfClass("MeshPart")
                    if firstPart then
                        trashPosition = firstPart.Position
                    else
                        -- warn("[TrashProximity] No parts found in model:", obj.Name)
                        continue -- Skip this object
                    end
                end
            end
            
            if trashPosition then
                local distance = (humanoidRootPart.Position - trashPosition).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    newTrashBin = obj.Name
                end
            end
        end
    end
    
    -- Update GUI based on proximity
    if newTrashBin ~= currentTrashBin then
        removeProximityGui()
        currentTrashBin = newTrashBin
        
        if currentTrashBin then
            createProximityGui(currentTrashBin)
        end
    end
end

-- Handle E key press
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.E and currentTrashBin then
        print("[TrashProximity] E pressed for trash bin:", currentTrashBin)
        
        -- 🔧 FIX: Fire RemoteEvent langsung ke server untuk show modal
        local ShowTrashModalEvent = ReplicatedStorage:FindFirstChild("InventoryEvents"):FindFirstChild("ShowTrashModal")
        if ShowTrashModalEvent then
            ShowTrashModalEvent:FireServer(currentTrashBin)
            print("[TrashProximity] Fired ShowTrashModal event")
        else
            warn("[TrashProximity] ShowTrashModal RemoteEvent not found!")
        end
        
        removeProximityGui()
        currentTrashBin = nil
    end
end)

-- Run proximity check
game:GetService("RunService").Heartbeat:Connect(checkProximity)

print("[TrashProximity] Proximity detection initialized!")