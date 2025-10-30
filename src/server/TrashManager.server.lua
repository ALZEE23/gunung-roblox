local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local TrashManager = {}

-- 🔧 FIX: Use existing InventoryEvents folder
local InventoryEvents = ReplicatedStorage:WaitForChild("InventoryEvents")

-- Get existing RemoteEvents
local TrashItemEvent = InventoryEvents:WaitForChild("TrashItem")
local ShowTrashModalEvent = InventoryEvents:WaitForChild("ShowTrashModal")

print("[TrashManager] Using existing RemoteEvents")

-- Internal server communication
local ServerEvents = ReplicatedStorage:WaitForChild("ServerEvents")
local RemoveItemInternal = ServerEvents:WaitForChild("RemoveItemInternal")
local GetInventoryInternal = ServerEvents:WaitForChild("GetInventoryInternal")

-- Score system
local AddScoreInternal = Instance.new("BindableEvent")
AddScoreInternal.Name = "AddScoreInternal"
AddScoreInternal.Parent = ServerEvents

-- Trash bin configuration
local TRASH_CONFIG = {
    OrganicTrash = {
        acceptedCategory = "Organic",
        scorePerItem = 10,
        name = "Organic Trash Bin"
    },
    AnorganicTrash = {
        acceptedCategory = "Anorganic",
        scorePerItem = 15,
        name = "Anorganic Trash Bin"
    },
    MixedTrash = {
        acceptedCategory = "Campuran",
        scorePerItem = 20,
        name = "Mixed Trash Bin"
    }
}

-- 🗑️ Handle trash item request
TrashItemEvent.OnServerEvent:Connect(function(player, slot, trashBinName, quantity)
    print("[TrashManager] Player", player.Name, "wants to trash slot", slot, "in", trashBinName)
    
    -- Validate trash bin
    local trashConfig = TRASH_CONFIG[trashBinName]
    if not trashConfig then
        warn("[TrashManager] Invalid trash bin:", trashBinName)
        return
    end
    
    -- Validate slot
    if slot < 1 or slot > 3 then
        warn("[TrashManager] Invalid slot:", slot)
        return
    end
    
    quantity = quantity or 1
    if quantity < 1 then
        warn("[TrashManager] Invalid quantity:", quantity)
        return
    end
    
    -- 🔧 Get inventory via BindableFunction
    local inventory = GetInventoryInternal:Invoke(player)
    if not inventory or not inventory.hotbar.items[slot] then
        warn("[TrashManager] No item in slot", slot, "for", player.Name)
        return
    end
    
    local item = inventory.hotbar.items[slot]
    
    -- Check if item category matches trash bin
    if item.category ~= trashConfig.acceptedCategory then
        -- Send error message to client
        local ErrorNotification = Instance.new("RemoteEvent")
        ErrorNotification.Name = "TrashError"
        ErrorNotification.Parent = InventoryEvents
        ErrorNotification:FireClient(player, "Wrong trash bin! " .. item.category .. " items don't belong in " .. trashConfig.name)
        return
    end
    
    -- Calculate score
    local scoreGained = trashConfig.scorePerItem * math.min(quantity, item.quantity)
    
    -- 🔧 Remove via BindableEvent
    RemoveItemInternal:Fire(player, slot, quantity)
    
    -- Add score
    AddScoreInternal:Fire(player, scoreGained)
    
    -- 🔧 ADD: Update leaderboard
    if _G.LeaderboardManager then
        _G.LeaderboardManager.updateScore(player, scoreGained)
        _G.LeaderboardManager.updateTrashed(player, quantity or 1)
    end
    
    -- Send success feedback
    TrashManager.CreateTrashSuccessEffect(player, item.name, scoreGained, trashConfig.name)
    
    print("[TrashManager] Successfully trashed", quantity, item.name, "for", scoreGained, "points")
end)

-- 🔧 ADD: Handle show modal request
ShowTrashModalEvent.OnServerEvent:Connect(function(player, trashBinName)
    print("[TrashManager] Player", player.Name, "wants to open", trashBinName, "modal")
    
    -- Validate trash bin
    local trashConfig = TRASH_CONFIG[trashBinName]
    if not trashConfig then
        warn("[TrashManager] Invalid trash bin:", trashBinName)
        return
    end
    
    -- Send back to client to show modal
    ShowTrashModalEvent:FireClient(player, trashBinName, trashConfig)
    print("[TrashManager] Sent modal data to client")
end)

-- 🎨 Create success effect
function TrashManager.CreateTrashSuccessEffect(player, itemName, scoreGained, trashBinName)
    local SuccessNotification = Instance.new("ScreenGui")
    SuccessNotification.Name = "TrashSuccessNotification"
    SuccessNotification.Parent = player.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 80)
    frame.Position = UDim2.new(0.5, -150, 0, 100)
    frame.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    frame.Parent = SuccessNotification
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.5, 0)
    title.Text = "✅ " .. itemName .. " Trashed!"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    local score = Instance.new("TextLabel")
    score.Size = UDim2.new(1, 0, 0.5, 0)
    score.Position = UDim2.new(0, 0, 0.5, 0)
    score.Text = "+" .. scoreGained .. " points in " .. trashBinName
    score.TextColor3 = Color3.fromRGB(255, 255, 100)
    score.BackgroundTransparency = 1
    score.TextScaled = true
    score.Font = Enum.Font.SourceSans
    score.Parent = frame
    
    -- Auto cleanup
    game:GetService("Debris"):AddItem(SuccessNotification, 3)
end

print("[TrashManager] TrashManager initialized!")