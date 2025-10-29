local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local rodux = require(Packages:FindFirstChild("roblox_rodux@4.0.0-rc.0") or Packages.Rodux)

-- Wait for inventory events
local InventoryEvents = ReplicatedStorage:WaitForChild("InventoryEvents")
local UpdateInventoryEvent = InventoryEvents:WaitForChild("UpdateInventory")

-- Function untuk load items dari ReplicatedStorage
local function loadItemsFromStorage()
    local itemsData = {}
    
    -- Wait for Items folder
    local ItemsFolder = ReplicatedStorage:WaitForChild("Items", 5)
    if not ItemsFolder then
        warn("Items folder not found in ReplicatedStorage!")
        return itemsData
    end
    
    -- Categories yang tersedia
    local categories = {"Organic", "Anorganic", "Campuran"}
    
    for _, categoryName in ipairs(categories) do
        local categoryFolder = ItemsFolder:FindFirstChild(categoryName)
        if categoryFolder then
            print("Loading items from category:", categoryName)
            
            for _, itemModel in ipairs(categoryFolder:GetChildren()) do
                if itemModel:IsA("Model") then
                    -- Extract item data dari model
                    local itemData = {
                        id = itemModel.Name,
                        name = itemModel.Name,
                        category = categoryName,
                        model = itemModel,
                        -- Bisa ambil data lain dari StringValue/IntValue di dalam model
                        value = itemModel:FindFirstChild("Value") and itemModel.Value.Value or 0,
                        description = itemModel:FindFirstChild("Description") and itemModel.Description.Value or "",
                    }
                    
                    itemsData[itemModel.Name] = itemData
                    print("  Loaded item:", itemModel.Name, "Category:", categoryName)
                end
            end
        else
            warn("Category folder not found:", categoryName)
        end
    end
    
    return itemsData
end

-- Load items saat store initialize
local itemsDatabase = loadItemsFromStorage()

local function reducer(state, action)
    state = state or { 
        count = 0,
        itemsDatabase = itemsDatabase,
        hotbar = {
            selectedSlot = 1,
            items = {
                [1] = nil,  -- Empty slot
                [2] = nil,  -- Empty slot  
                [3] = nil,  -- Empty slot
            }
        },
        inventory = {
            storage = {},
            coins = 0
        }
    }

    if action.type == "increment" then
        return {
            count = state.count + 1,
            itemsDatabase = state.itemsDatabase,
            hotbar = state.hotbar,
            inventory = state.inventory
        }
    elseif action.type == "decrement" then
        return {
            count = state.count - 1,
            itemsDatabase = state.itemsDatabase,
            hotbar = state.hotbar,
            inventory = state.inventory
        }
    elseif action.type == "UPDATE_INVENTORY_FROM_SERVER" then
        return {
            count = state.count,
            itemsDatabase = state.itemsDatabase,
            hotbar = action.data.hotbar,
            inventory = {
                storage = action.data.storage,
                coins = action.data.coins
            }
        }
    elseif action.type == "SELECT_SLOT" then
        return {
            count = state.count,
            itemsDatabase = state.itemsDatabase,
            hotbar = {
                selectedSlot = action.slot,
                items = state.hotbar.items
            },
            inventory = state.inventory
        }
    elseif action.type == "ADD_ITEM_TO_HOTBAR" then
        local newItems = {}
        for i, item in pairs(state.hotbar.items) do
            newItems[i] = item
        end
        
        -- Find empty slot atau stack existing item
        for i = 1, 3 do
            if not newItems[i] then
                newItems[i] = {
                    id = action.itemId,
                    name = state.itemsDatabase[action.itemId].name,
                    quantity = action.quantity or 1,
                    category = state.itemsDatabase[action.itemId].category
                }
                break
            elseif newItems[i].id == action.itemId then
                newItems[i].quantity = newItems[i].quantity + (action.quantity or 1)
                break
            end
        end
        
        return {
            count = state.count,
            itemsDatabase = state.itemsDatabase,
            hotbar = {
                selectedSlot = state.hotbar.selectedSlot,
                items = newItems
            },
            inventory = state.inventory
        }
    elseif action.type == "RELOAD_ITEMS" then
        -- Reload items dari ReplicatedStorage
        local newItemsDatabase = loadItemsFromStorage()
        return {
            count = state.count,
            itemsDatabase = newItemsDatabase,
            hotbar = state.hotbar,
            inventory = state.inventory
        }
    elseif action.type == "PICKUP_ITEM" then
        -- Cari slot kosong pertama
        local newItems = {}
        for i, item in pairs(state.hotbar.items) do
            newItems[i] = item
        end
        
        -- Add ke slot kosong
        for i = 1, 3 do
            if not newItems[i] then
                newItems[i] = {
                    id = action.itemId,
                    name = action.itemId, -- Atau dari database
                    quantity = action.quantity
                }
                break
            end
        end
        
        return { 
            count = state.count,
            itemsDatabase = state.itemsDatabase,
            hotbar = {
                selectedSlot = state.hotbar.selectedSlot,
                items = newItems
            },
            inventory = state.inventory
        }
    else
        return state
    end
end

local store = rodux.Store.new(reducer)

-- Listen untuk server updates
UpdateInventoryEvent.OnClientEvent:Connect(function(inventoryData)
    store:dispatch({
        type = "UPDATE_INVENTORY_FROM_SERVER",
        data = inventoryData
    })
end)

return store