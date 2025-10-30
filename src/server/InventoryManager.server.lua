local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 🔧 FIX: Create InventoryEvents folder dan RemoteEvents
local InventoryEvents = ReplicatedStorage:FindFirstChild("InventoryEvents")
if not InventoryEvents then
    InventoryEvents = Instance.new("Folder")
    InventoryEvents.Name = "InventoryEvents"
    InventoryEvents.Parent = ReplicatedStorage
end

-- Create required RemoteEvents/Functions
local GetInventoryFunction = InventoryEvents:FindFirstChild("GetInventory")
if not GetInventoryFunction then
    GetInventoryFunction = Instance.new("RemoteFunction")
    GetInventoryFunction.Name = "GetInventory"
    GetInventoryFunction.Parent = InventoryEvents
end

local AddItemEvent = InventoryEvents:FindFirstChild("AddItem")
if not AddItemEvent then
    AddItemEvent = Instance.new("RemoteEvent")
    AddItemEvent.Name = "AddItem"
    AddItemEvent.Parent = InventoryEvents
end

local UpdateInventoryEvent = InventoryEvents:FindFirstChild("UpdateInventory")
if not UpdateInventoryEvent then
    UpdateInventoryEvent = Instance.new("RemoteEvent")
    UpdateInventoryEvent.Name = "UpdateInventory"
    UpdateInventoryEvent.Parent = InventoryEvents
end

-- 🔧 FIX: Create TrashItem event for TrashManager
local TrashItemEvent = InventoryEvents:FindFirstChild("TrashItem")
if not TrashItemEvent then
    TrashItemEvent = Instance.new("RemoteEvent")
    TrashItemEvent.Name = "TrashItem"
    TrashItemEvent.Parent = InventoryEvents
end

-- 🔧 FIX: Create ShowTrashModal event
local ShowTrashModalEvent = InventoryEvents:FindFirstChild("ShowTrashModal")
if not ShowTrashModalEvent then
    ShowTrashModalEvent = Instance.new("RemoteEvent")
    ShowTrashModalEvent.Name = "ShowTrashModal"
    ShowTrashModalEvent.Parent = InventoryEvents
end

print("[InventoryManager] Created RemoteEvents:", InventoryEvents:GetChildren())

-- Import ItemManager
local ItemManager = require(script.Parent.ItemManager)

-- DataStore setup
local inventoryStore = DataStoreService:GetDataStore("PlayerInventory")

-- Storage
local inventories = {}
local InventoryManager = {}

-- Default hotbar structure
local function createDefaultHotbar()
    return {
        selectedSlot = 1,
        items = {
            [1] = nil,
            [2] = nil,
            [3] = nil,
        }
    }
end

-- 🔧 UPDATE: Create pickup notification function dengan better text
local function createPickupNotification(player, item, success, reason)
    local PickupNotification = Instance.new("ScreenGui")
    PickupNotification.Name = "PickupNotification"
    PickupNotification.Parent = player.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 70)
    frame.Position = UDim2.new(0.5, -150, 0, 50)
    frame.Parent = PickupNotification
    
    if success then
        frame.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    else
        frame.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    end
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 50, 1, 0)
    icon.Text = success and "📦" or "📦"  -- Always show pickup icon
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.BackgroundTransparency = 1
    icon.TextScaled = true
    icon.Font = Enum.Font.SourceSansBold
    icon.Parent = frame
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -60, 0.6, 0)
    text.Position = UDim2.new(0, 55, 0, 5)
    
    -- 🔧 FIXED: Better text based on success and reason
    if success then
        text.Text = "Picked up: " .. (item.name or item.id)
    else
        if reason == "storage" then
            text.Text = "Hotbar full → Storage: " .. (item.name or item.id)
        else
            text.Text = "Picked up: " .. (item.name or item.id)
        end
    end
    
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.BackgroundTransparency = 1
    text.TextScaled = true
    text.Font = Enum.Font.SourceSansBold
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = frame
    
    -- 🔧 FIXED: Better subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -60, 0.4, 0)
    subtitle.Position = UDim2.new(0, 55, 0.6, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.SourceSans
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = frame
    
    if success then
        if reason == "stacked" then
            subtitle.Text = "Stacked in hotbar"
            subtitle.TextColor3 = Color3.fromRGB(200, 255, 200)
        elseif reason == "new" then
            subtitle.Text = "Added to hotbar"
            subtitle.TextColor3 = Color3.fromRGB(200, 255, 200)
        else
            subtitle.Text = "Quantity: " .. (item.quantity or 1)
            subtitle.TextColor3 = Color3.fromRGB(200, 255, 200)
        end
    else
        if reason == "storage" then
            subtitle.Text = "Check storage later!"
            subtitle.TextColor3 = Color3.fromRGB(255, 255, 150)
        else
            subtitle.Text = "Truly inventory full!"
            subtitle.TextColor3 = Color3.fromRGB(255, 200, 200)
        end
    end
    
    -- Auto cleanup
    game:GetService("Debris"):AddItem(PickupNotification, 3)
    print("[InventoryManager] Created pickup notification for:", item.name, "success:", success, "reason:", reason)
end

-- 🧩 Load data player saat masuk
function InventoryManager.InitPlayer(player)
    local success, savedData = pcall(function()
        return inventoryStore:GetAsync(player.UserId)
    end)

    if success and savedData then
        inventories[player.UserId] = savedData
        -- Validate items masih ada di ItemManager
        InventoryManager.ValidateInventory(player)
        print("[InventoryManager] Loaded inventory for", player.Name)
    else
        -- Create default inventory structure
        inventories[player.UserId] = {
            hotbar = createDefaultHotbar(),
            storage = {},
            coins = 0
        }
        print("[InventoryManager] Created new inventory for", player.Name)
    end

    -- Send ke client
    UpdateInventoryEvent:FireClient(player, inventories[player.UserId])
end

-- 🔍 Validate inventory items dengan ItemManager
function InventoryManager.ValidateInventory(player)
    local inventory = inventories[player.UserId]
    if not inventory then return end

    -- Validate hotbar items
    for slot, item in pairs(inventory.hotbar.items) do
        if item then
            local itemData = ItemManager.getItemData(item.id)
            if not itemData then
                -- Item tidak ada lagi, remove dari inventory
                inventory.hotbar.items[slot] = nil
                print("[InventoryManager] Removed invalid item:", item.id)
            else
                -- Update item data dengan data terbaru
                item.name = itemData.name
                item.category = itemData.category
            end
        end
    end

    -- Validate storage items
    for i, item in pairs(inventory.storage) do
        if item then
            local itemData = ItemManager.getItemData(item.id)
            if not itemData then
                inventory.storage[i] = nil
                print("[InventoryManager] Removed invalid storage item:", item.id)
            else
                item.name = itemData.name
                item.category = itemData.category
            end
        end
    end
end

-- 🪄 Tambahkan item ke inventory (dengan structure baru)
function InventoryManager.AddItem(player, itemId, quantity, targetSlot)
    local inventory = inventories[player.UserId]
    if not inventory then
        InventoryManager.InitPlayer(player)
        inventory = inventories[player.UserId]
    end
    
    -- Validate item exists di ItemManager
    local itemData = ItemManager.getItemData(itemId)
    if not itemData then
        warn("[InventoryManager] Invalid item ID:", itemId)
        return false
    end
    
    quantity = quantity or 1
    
    -- 🔍 FIRST: Check if item already exists in any slot (untuk stacking)
    for slot = 1, 3 do
        local existingItem = inventory.hotbar.items[slot]
        if existingItem and existingItem.id == itemId then
            -- Stack dengan item yang sama
            existingItem.quantity = existingItem.quantity + quantity
            UpdateInventoryEvent:FireClient(player, inventory)
            createPickupNotification(player, itemData, true, "stacked") -- 🔧 ADD notification
            print("[InventoryManager] Stacked", quantity, itemData.name, "in slot", slot, "Total:", existingItem.quantity)
            return true
        end
    end
    
    -- 🔍 SECOND: Find empty slot jika item belum ada
    for slot = 1, 3 do
        local existingItem = inventory.hotbar.items[slot]
        if not existingItem then
            inventory.hotbar.items[slot] = {
                id = itemId,
                name = itemData.name,
                category = itemData.category,
                quantity = quantity
            }
            UpdateInventoryEvent:FireClient(player, inventory)
            createPickupNotification(player, itemData, true, "new") -- 🔧 ADD notification
            print("[InventoryManager] Added new", itemData.name, "to hotbar slot", slot)
            return true
        end
    end
    
    -- 🔍 THIRD: Hotbar full, add to storage
    table.insert(inventory.storage, {
        id = itemId,
        name = itemData.name,
        category = itemData.category,
        quantity = quantity
    })
    
    UpdateInventoryEvent:FireClient(player, inventory)
    createPickupNotification(player, itemData, false, "storage") -- 🔧 ADD notification
    print("[InventoryManager] Hotbar full! Added", itemData.name, "to storage")
    return true
end

-- 🗑️ Remove item dari inventory
function InventoryManager.RemoveItem(player, slot, quantity)
    local inventory = inventories[player.UserId]
    if not inventory then return false end
    
    quantity = quantity or 1
    local item = inventory.hotbar.items[slot]
    if not item then return false end
    
    item.quantity = item.quantity - quantity
    if item.quantity <= 0 then
        inventory.hotbar.items[slot] = nil
    end
    
    UpdateInventoryEvent:FireClient(player, inventory)
    return true
end

-- 🔄 Move item between slots
function InventoryManager.MoveItem(player, fromSlot, toSlot)
    local inventory = inventories[player.UserId]
    if not inventory then return false end
    
    local fromItem = inventory.hotbar.items[fromSlot]
    local toItem = inventory.hotbar.items[toSlot]
    
    -- Swap items
    inventory.hotbar.items[fromSlot] = toItem
    inventory.hotbar.items[toSlot] = fromItem
    
    UpdateInventoryEvent:FireClient(player, inventory)
    return true
end

-- 📦 Get inventory data
function InventoryManager.GetInventory(player)
    return inventories[player.UserId] or nil
end

-- 💾 Save player data
function InventoryManager.SavePlayerData(player)
    local data = inventories[player.UserId]
    if not data then return end

    local success, err = pcall(function()
        inventoryStore:SetAsync(player.UserId, data)
    end)

    if success then
        print("[InventoryManager] Saved inventory for", player.Name)
    else
        warn("[InventoryManager] Failed to save data for", player.Name, err)
    end
end

-- 🧹 Remove player data
function InventoryManager.RemovePlayer(player)
    InventoryManager.SavePlayerData(player)
    inventories[player.UserId] = nil
end

-- RemoteEvent handlers
-- Handle GetInventory RemoteFunction
GetInventoryFunction.OnServerInvoke = function(player)
    local inventory = InventoryManager.GetInventory(player)
    print("[InventoryManager] Sent inventory to client for", player.Name)
    return inventory
end

AddItemEvent.OnServerEvent:Connect(function(player, itemId, quantity, slot)
    InventoryManager.AddItem(player, itemId, quantity, slot)
end)

-- Player events
Players.PlayerAdded:Connect(function(player)
    InventoryManager.InitPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    InventoryManager.RemovePlayer(player)
end)

-- 🔧 LISTEN untuk pickup dari ItemSpawner
local ServerEvents = ReplicatedStorage:FindFirstChild("ServerEvents")
if not ServerEvents then
    ServerEvents = Instance.new("Folder")
    ServerEvents.Name = "ServerEvents"
    ServerEvents.Parent = ReplicatedStorage
end

local AddItemInternal = ServerEvents:FindFirstChild("AddItemInternal")
if not AddItemInternal then
    AddItemInternal = Instance.new("BindableEvent")
    AddItemInternal.Name = "AddItemInternal"
    AddItemInternal.Parent = ServerEvents
end

local RemoveItemInternal = Instance.new("BindableEvent")
RemoveItemInternal.Name = "RemoveItemInternal"
RemoveItemInternal.Parent = ServerEvents

local GetInventoryInternal = Instance.new("BindableFunction")
GetInventoryInternal.Name = "GetInventoryInternal"
GetInventoryInternal.Parent = ServerEvents

-- Listen untuk internal server pickup events
AddItemInternal.Event:Connect(function(player, itemId, quantity)
    print("[InventoryManager] Received internal pickup:", player.Name, itemId, quantity)
    local success = InventoryManager.AddItem(player, itemId, quantity)
    if success then
        print("[InventoryManager] Successfully added", itemId, "to", player.Name, "inventory")
    end
end)

RemoveItemInternal.Event:Connect(function(player, slot, quantity)
    return InventoryManager.RemoveItem(player, slot, quantity)
end)

GetInventoryInternal.OnInvoke = function(player)
    return InventoryManager.GetInventory(player)
end

print("[InventoryManager] Setup internal event listeners")
print("[InventoryManager] InventoryManager ready with internal communication!")

return InventoryManager
