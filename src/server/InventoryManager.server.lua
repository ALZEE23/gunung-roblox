local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import ItemManager
local ItemManager = require(script.Parent.ItemManager)

-- DataStore setup
local inventoryStore = DataStoreService:GetDataStore("PlayerInventory")

-- RemoteEvents
local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "InventoryEvents"
remoteEvents.Parent = ReplicatedStorage

local UpdateInventoryEvent = Instance.new("RemoteEvent")
UpdateInventoryEvent.Name = "UpdateInventory"
UpdateInventoryEvent.Parent = remoteEvents

local AddItemEvent = Instance.new("RemoteEvent")
AddItemEvent.Name = "AddItem"
AddItemEvent.Parent = remoteEvents

local GetInventoryFunction = Instance.new("RemoteFunction")
GetInventoryFunction.Name = "GetInventory"
GetInventoryFunction.Parent = remoteEvents

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
    
    -- Try add to specific hotbar slot first
    if targetSlot and targetSlot >= 1 and targetSlot <= 3 then
        local existingItem = inventory.hotbar.items[targetSlot]
        if not existingItem then
            -- Empty slot
            inventory.hotbar.items[targetSlot] = {
                id = itemId,
                name = itemData.name,
                category = itemData.category,
                quantity = quantity
            }
            UpdateInventoryEvent:FireClient(player, inventory)
            print("[InventoryManager] Added", itemData.name, "to hotbar slot", targetSlot)
            return true
        elseif existingItem.id == itemId then
            -- Stack same item
            existingItem.quantity = existingItem.quantity + quantity
            UpdateInventoryEvent:FireClient(player, inventory)
            print("[InventoryManager] Stacked", quantity, itemData.name, "in slot", targetSlot)
            return true
        end
    end
    
    -- Try add to any empty hotbar slot
    for slot = 1, 3 do
        local item = inventory.hotbar.items[slot]
        if not item then
            inventory.hotbar.items[slot] = {
                id = itemId,
                name = itemData.name,
                category = itemData.category,
                quantity = quantity
            }
            UpdateInventoryEvent:FireClient(player, inventory)
            print("[InventoryManager] Added", itemData.name, "to hotbar slot", slot)
            return true
        elseif item.id == itemId then
            item.quantity = item.quantity + quantity
            UpdateInventoryEvent:FireClient(player, inventory)
            print("[InventoryManager] Stacked", quantity, itemData.name, "in slot", slot)
            return true
        end
    end
    
    -- Add to storage if hotbar full
    table.insert(inventory.storage, {
        id = itemId,
        name = itemData.name,
        category = itemData.category,
        quantity = quantity
    })
    
    UpdateInventoryEvent:FireClient(player, inventory)
    print("[InventoryManager] Added", itemData.name, "to storage")
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
GetInventoryFunction.OnServerInvoke = function(player)
    return InventoryManager.GetInventory(player)
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

return InventoryManager
