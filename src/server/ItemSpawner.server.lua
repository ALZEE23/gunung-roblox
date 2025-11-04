local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Import ItemManager
local ItemManager = require(script.Parent.ItemManager)

local ItemSpawner = {}

-- Configuration
local SPAWN_CONFIG = {
    maxItems = 50,           -- Max items di map
    spawnRate = 5,           -- Spawn 1 item setiap 5 detik
    spawnRadius = 500,       -- Radius spawn dari center map
    minDistanceBetweenItems = 20, -- Jarak minimum antar items
    despawnTime = 120,       -- Item hilang setelah 2 menit
}

-- Storage for spawned items
local spawnedItems = {}
local lastSpawnTime = 0

-- Function untuk cari posisi spawn yang valid
local function findValidSpawnPosition()
    local attempts = 0
    local maxAttempts = 20
    
    while attempts < maxAttempts do
        attempts = attempts + 1
        
        -- Random position dalam radius
        local angle = math.random() * math.pi * 2
        local distance = math.random(50, SPAWN_CONFIG.spawnRadius)
        
        local x = math.cos(angle) * distance
        local z = math.sin(angle) * distance
        local y = 1000 -- Start dari atas
        
        -- 🔧 FIX: Raycast ke bawah untuk cari ground
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        
        -- 🔧 FIX: Collect all character models to ignore
        local charactersToIgnore = {}
        local Players = game:GetService("Players")
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                table.insert(charactersToIgnore, player.Character)
            end
        end
        
        raycastParams.FilterDescendantsInstances = charactersToIgnore
        
        local raycastResult = workspace:Raycast(Vector3.new(x, y, z), Vector3.new(0, -2000, 0), raycastParams)
        
        if raycastResult then
            local groundPos = raycastResult.Position
            local spawnPos = groundPos + Vector3.new(0, 2, 0) -- Spawn 2 studs di atas ground
            
            -- Check jarak dengan items lain
            local tooClose = false
            for _, itemData in pairs(spawnedItems) do
                if itemData.model and itemData.model.Parent then
                    local otherPrimaryPart
                    if itemData.model:IsA("Model") then
                        otherPrimaryPart = itemData.model.PrimaryPart
                    else
                        otherPrimaryPart = itemData.model
                    end
                    
                    if otherPrimaryPart then
                        local distance = (spawnPos - otherPrimaryPart.Position).Magnitude
                        if distance < SPAWN_CONFIG.minDistanceBetweenItems then
                            tooClose = true
                            break
                        end
                    end
                end
            end
            
            if not tooClose then
                return spawnPos
            end
        end
    end
    
    return nil -- Gak ketemu posisi valid
end

-- Function untuk spawn item
function ItemSpawner.spawnRandomItem()
    if #spawnedItems >= SPAWN_CONFIG.maxItems then
        return -- Map sudah full
    end
    
    local spawnPos = findValidSpawnPosition()
    if not spawnPos then
        return -- Gak ketemu posisi valid
    end
    
    -- 🔍 DEBUG: Check ItemManager
    -- print("[ItemSpawner] Checking ItemManager...")
    -- print("[ItemSpawner] ItemManager:", ItemManager)
    
    if ItemManager.getAllItems then
        -- print("[ItemSpawner] getAllItems function exists")
        local allItems = ItemManager.getAllItems()
        -- print("[ItemSpawner] getAllItems returned:", allItems)
        
        for itemId, itemData in pairs(allItems) do
            -- print("[ItemSpawner] Found item:", itemId, itemData)
        end
    else
        -- print("[ItemSpawner] ERROR: getAllItems function missing!")
        
        -- 🔧 FALLBACK: Load items directly dari ReplicatedStorage
        local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
        if itemsFolder then
            -- print("[ItemSpawner] Found Items folder, loading directly...")
            
            local categories = {"Organic", "Anorganic", "Campuran"}
            for _, category in pairs(categories) do
                local categoryFolder = itemsFolder:FindFirstChild(category)
                if categoryFolder then
                    -- print("[ItemSpawner] Found category:", category)
                    for _, item in pairs(categoryFolder:GetChildren()) do
                        if item:IsA("MeshPart") then
                            -- print("[ItemSpawner] Found meshpart:", item.Name)

                            -- Spawn dummy item langsung
                            local spawnedItem = item:Clone()
                            spawnedItem.Name = item.Name .. "_Spawned"
                            spawnedItem.Position = spawnPos
                            spawnedItem.Parent = workspace
                            
                            -- print("[ItemSpawner] Spawned dummy:", item.Name, "at", spawnPos)
                            return -- Exit after spawning 1 item
                        end
                    end
                end
            end
        else
            -- print("[ItemSpawner] ERROR: Items folder not found in ReplicatedStorage!")
        end
        return
    end
    
    -- Pilih item random
    local allItems = ItemManager.getAllItems()
    local itemKeys = {}
    for itemId, _ in pairs(allItems) do
        table.insert(itemKeys, itemId)
    end
    
    if #itemKeys == 0 then
        warn("[ItemSpawner] No items available to spawn!")
        return
    end
    
    local randomItemId = itemKeys[math.random(1, #itemKeys)]
    local itemData = allItems[randomItemId]
    
    -- Clone item model
    local itemModel = itemData.model:Clone()
    
    -- 🔧 FIX: Handle MeshPart vs Model differently
    local primaryPart
    if itemModel:IsA("Model") then
        if not itemModel.PrimaryPart then
            itemModel.PrimaryPart = itemModel:FindFirstChildOfClass("Part") or itemModel:FindFirstChildOfClass("MeshPart")
        end
        primaryPart = itemModel.PrimaryPart
    else
        -- For MeshPart/Part, the item itself is the primary part
        primaryPart = itemModel
    end
    
    if not primaryPart then
        warn("[ItemSpawner] Item has no valid primary part:", randomItemId)
        return
    end
    
    -- Setup model
    itemModel.Name = randomItemId .. "_Spawned"
    
    -- 🔧 FIX: Position based on type
    if itemModel:IsA("Model") then
        itemModel:SetPrimaryPartCFrame(CFrame.new(spawnPos))
    else
        -- For MeshPart/Part
        itemModel.Position = spawnPos
        itemModel.Anchored = true  -- 🔧 FIX: Keep items floating, don't let them fall
        itemModel.CanCollide = false -- Optional: prevent collision
    end
    
    itemModel.Parent = workspace
    
    -- 🔧 FIX: Animation using correct part (relative positioning)
    local originalPosition = primaryPart.Position
    local floatTween = TweenService:Create(
        primaryPart,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = originalPosition + Vector3.new(0, 1, 0)}
    )
    floatTween:Play()
    
    -- 🔧 FIX: Rotation using CFrame instead of Rotation
    local rotateTween = TweenService:Create(
        primaryPart,
        TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        {CFrame = primaryPart.CFrame * CFrame.Angles(0, math.rad(360), 0)}
    )
    rotateTween:Play()
    
    -- 🔧 FIX: Detector position
    local detector = Instance.new("Part")
    detector.Name = "PickupDetector"
    detector.Size = Vector3.new(8, 8, 8)
    detector.Position = primaryPart.Position
    detector.Anchored = true
    detector.CanCollide = false
    detector.Transparency = 1
    detector.Parent = itemModel
    
    -- Pickup connection
    local pickupConnection
    pickupConnection = detector.Touched:Connect(function(hit)
        local humanoid = hit.Parent:FindFirstChild("Humanoid")
        if humanoid then
            local player = game.Players:GetPlayerFromCharacter(hit.Parent)
            if player then
                -- 🔧 FIX: Use RemoteEvent instead of requiring InventoryManager
                local InventoryEvents = ReplicatedStorage:FindFirstChild("InventoryEvents")
                if InventoryEvents then
                    local AddItemEvent = InventoryEvents:FindFirstChild("AddItem")
                    if AddItemEvent then
                        -- Fire to InventoryManager (server script akan handle ini)
                        -- Tapi ini pickup dari server, jadi kita simulate player action
                        
                        -- 🔧 SIMPLE SOLUTION: Call InventoryManager function via BindableEvent
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
                        
                        -- Fire internal event yang InventoryManager bisa listen
                        AddItemInternal:Fire(player, randomItemId, 1)
                        
                        -- print("[ItemSpawner] Player", player.Name, "picked up", randomItemId)
                        
                        -- Remove from spawned items
                        for i, spawned in pairs(spawnedItems) do
                            if spawned.model == itemModel then
                                spawned.cleanup()
                                table.remove(spawnedItems, i)
                                break
                            end
                        end
                        
                        -- Cleanup
                        pickupConnection:Disconnect()
                        floatTween:Cancel()
                        rotateTween:Cancel()
                        itemModel:Destroy()
                    end
                end
            end
        end
    end)
    
    -- Store spawned item data
    local spawnedItemData = {
        model = itemModel,
        itemId = randomItemId,
        spawnTime = tick(),
        cleanup = function()
            if pickupConnection then
                pickupConnection:Disconnect()
            end
            floatTween:Cancel()
            rotateTween:Cancel()
            if itemModel and itemModel.Parent then
                itemModel:Destroy()
            end
        end
    }
    
    table.insert(spawnedItems, spawnedItemData)
    -- print("[ItemSpawner] Spawned", randomItemId, "at", spawnPos)
end

-- Function untuk cleanup expired items
function ItemSpawner.cleanupExpiredItems()
    local currentTime = tick()
    
    for i = #spawnedItems, 1, -1 do
        local itemData = spawnedItems[i]
        if currentTime - itemData.spawnTime > SPAWN_CONFIG.despawnTime then
            -- print("[ItemSpawner] Despawning expired item:", itemData.itemId)
            itemData.cleanup()
            table.remove(spawnedItems, i)
        end
    end
end

-- Main spawn loop
local function onHeartbeat()
    local currentTime = tick()
    
    -- Spawn new items
    if currentTime - lastSpawnTime >= SPAWN_CONFIG.spawnRate then
        lastSpawnTime = currentTime
        ItemSpawner.spawnRandomItem()
    end
    
    -- Cleanup expired items
    ItemSpawner.cleanupExpiredItems()
end

-- Start spawning
RunService.Heartbeat:Connect(onHeartbeat)

-- Initial spawn burst
for i = 1, 10 do
    ItemSpawner.spawnRandomItem()
end

print("[ItemSpawner] Item spawner initialized!")

return ItemSpawner