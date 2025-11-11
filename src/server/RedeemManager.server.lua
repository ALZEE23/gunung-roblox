local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

print("[RedeemManager] 🚀 RedeemManager starting...")

-- Prevent double initialization
if _G.RedeemManagerInitialized then
    warn("[RedeemManager] ⚠️ Already initialized, skipping...")
    return
end
_G.RedeemManagerInitialized = true

local RedeemManager = {}

-- 💾 DataStore untuk tracking redeem
local redeemStore = DataStoreService:GetDataStore("PlayerRedeems")

-- Player redeem data (in-memory)
local playerRedeemData = {}

-- 🎁 Redeem configuration
local REDEEM_CONFIG = {
    {
        id = "starter_pack",
        requiredScore = 100,
        rewardName = "Starter Pack",
        modelName = "StarterOutfit",
        description = "Basic shirt and pants",
        items = {"shirt", "pants"}
    },
    {
        id = "cool_hat",
        requiredScore = 250,
        rewardName = "Cool Hat",
        modelName = "CoolHatOutfit",
        description = "Trendy hat accessory",
        items = {"hat"}
    },
    {
        id = "complete_set",
        requiredScore = 500,
        rewardName = "Complete Set",
        modelName = "CompleteOutfit",
        description = "Full outfit with accessories",
        items = {"shirt", "pants", "hat", "accessory"}
    }
}

-- 🎯 Create RemoteEvents first
local InventoryEvents = ReplicatedStorage:FindFirstChild("InventoryEvents")
if not InventoryEvents then
    InventoryEvents = Instance.new("Folder")
    InventoryEvents.Name = "InventoryEvents"
    InventoryEvents.Parent = ReplicatedStorage
end

local UpdateRedeemIconEvent = Instance.new("RemoteEvent")
UpdateRedeemIconEvent.Name = "UpdateRedeemIcon"
UpdateRedeemIconEvent.Parent = InventoryEvents

local GetAvailableRewardsEvent = Instance.new("RemoteEvent")
GetAvailableRewardsEvent.Name = "GetAvailableRewards"
GetAvailableRewardsEvent.Parent = InventoryEvents

local ProcessRedeemEvent = Instance.new("RemoteEvent")
ProcessRedeemEvent.Name = "ProcessRedeem"
ProcessRedeemEvent.Parent = InventoryEvents

local ShowRedeemModalEvent = Instance.new("RemoteEvent")
ShowRedeemModalEvent.Name = "ShowRedeemModal"
ShowRedeemModalEvent.Parent = InventoryEvents

-- 🔧 ADD: Create RedeemCode event for external API
local RedeemCodeEvent = InventoryEvents:FindFirstChild("RedeemCode")
if not RedeemCodeEvent then
    RedeemCodeEvent = Instance.new("RemoteEvent")
    RedeemCodeEvent.Name = "RedeemCode"
    RedeemCodeEvent.Parent = InventoryEvents
else
    -- Clear existing connections to prevent double firing
    RedeemCodeEvent:Destroy()
    RedeemCodeEvent = Instance.new("RemoteEvent")
    RedeemCodeEvent.Name = "RedeemCode"
    RedeemCodeEvent.Parent = InventoryEvents
end

local RedeemCodeResponseEvent = InventoryEvents:FindFirstChild("RedeemCodeResponse")
if not RedeemCodeResponseEvent then
    RedeemCodeResponseEvent = Instance.new("RemoteEvent")
    RedeemCodeResponseEvent.Name = "RedeemCodeResponse"
    RedeemCodeResponseEvent.Parent = InventoryEvents
else
    RedeemCodeResponseEvent:Destroy()
    RedeemCodeResponseEvent = Instance.new("RemoteEvent")
    RedeemCodeResponseEvent.Name = "RedeemCodeResponse"
    RedeemCodeResponseEvent.Parent = InventoryEvents
end

print("[RedeemManager] ✅ Events created")

-- Wait for ExternalRedeemService
print("[RedeemManager] ⏳ Waiting for ExternalRedeemService...")
local ExternalRedeemService = nil
local maxWait = 0
while not ExternalRedeemService and maxWait < 50 do
    ExternalRedeemService = _G.ExternalRedeemService
    if ExternalRedeemService then
        print("[RedeemManager] ✅ Found ExternalRedeemService!")
        break
    end
    wait(0.1)
    maxWait = maxWait + 1
end

if not ExternalRedeemService then
    warn("[RedeemManager] ❌ ExternalRedeemService NOT FOUND after 5 seconds!")
    warn("[RedeemManager] ❌ Check if ExternalRedeemService.server.lua is running!")
end

-- 🔧 SINGLE CONNECTION - Handle external redeem code input
RedeemCodeEvent.OnServerEvent:Connect(function(player, code)
    print("[RedeemManager] 📨 External redeem request from", player.Name, "for code:", code)
    
    -- Use ExternalRedeemService if available
    if ExternalRedeemService and ExternalRedeemService.processRedeemCode then
        print("[RedeemManager] 🚀 Calling ExternalRedeemService.processRedeemCode...")
        
        local success, result = pcall(function()
            return ExternalRedeemService.processRedeemCode(player, code)
        end)
        
        if success then
            local redeemSuccess, message, rewards = result, nil, {}
            
            -- Handle multiple return values
            if type(result) == "boolean" then
                redeemSuccess = result
            end
            
            print("[RedeemManager] 📊 Redeem result - Success:", redeemSuccess)
            
            -- Send response back to client (ONLY ONCE!)
            RedeemCodeResponseEvent:FireClient(player, redeemSuccess, message or "Processed", rewards or {})
            
            print("[RedeemManager] ✅ Sent response to", player.Name)
        else
            warn("[RedeemManager] ❌ Error calling processRedeemCode:", result)
            RedeemCodeResponseEvent:FireClient(player, false, "Error: " .. tostring(result))
        end
    else
        warn("[RedeemManager] ❌ ExternalRedeemService not available!")
        RedeemCodeResponseEvent:FireClient(player, false, "External redeem service not available")
    end
end)

print("[RedeemManager] ✅ RedeemManager initialized with SINGLE connection")

-- 🔍 Find model in workspace or ServerStorage
local function findOutfitModel(modelName)
    local model = workspace:FindFirstChild(modelName) or game.ServerStorage:FindFirstChild(modelName)
    if model then
        print("[RedeemManager] Found outfit model:", modelName)
        return model
    else
        warn("[RedeemManager] Outfit model not found:", modelName)
        return nil
    end
end

-- 👔 Extract clothing items dari model
local function extractClothingFromModel(model)
    local clothing = {}
    
    -- Find humanoid di model
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        warn("[RedeemManager] No Humanoid found in model:", model.Name)
        return clothing
    end
    
    -- Find body parts
    local character = humanoid.Parent
    
    -- 👕 Extract Shirt
    local shirt = character:FindFirstChildOfClass("Shirt")
    if shirt then
        clothing.shirt = {
            className = "Shirt",
            shirtTemplate = shirt.ShirtTemplate
        }
        print("[RedeemManager] Found shirt:", shirt.ShirtTemplate)
    end
    
    -- 👖 Extract Pants
    local pants = character:FindFirstChildOfClass("Pants")
    if pants then
        clothing.pants = {
            className = "Pants",
            pantsTemplate = pants.PantsTemplate
        }
        print("[RedeemManager] Found pants:", pants.PantsTemplate)
    end
    
    -- 🎩 Extract Accessories (hats, etc.)
    clothing.accessories = {}
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Accessory") then
            local handle = child:FindFirstChild("Handle")
            if handle then
                local mesh = handle:FindFirstChildOfClass("SpecialMesh") or handle:FindFirstChildOfClass("MeshPart")
                if mesh then
                    table.insert(clothing.accessories, {
                        name = child.Name,
                        meshId = mesh:IsA("SpecialMesh") and mesh.MeshId or "",
                        textureId = mesh:IsA("SpecialMesh") and mesh.TextureId or "",
                        meshPart = mesh:IsA("MeshPart") and mesh.MeshId or "",
                        accessoryType = child.AccessoryType
                    })
                    print("[RedeemManager] Found accessory:", child.Name)
                end
            end
        end
    end
    
    return clothing
end

-- 👤 Apply clothing ke player
local function applyClothingToPlayer(player, clothing)
    local character = player.Character
    if not character then
        warn("[RedeemManager] Player character not found:", player.Name)
        return false
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        warn("[RedeemManager] Player humanoid not found:", player.Name)
        return false
    end
    
    -- 👕 Apply Shirt
    if clothing.shirt then
        local existingShirt = character:FindFirstChildOfClass("Shirt")
        if existingShirt then
            existingShirt:Destroy()
        end
        
        local newShirt = Instance.new("Shirt")
        newShirt.ShirtTemplate = clothing.shirt.shirtTemplate
        newShirt.Parent = character
        print("[RedeemManager] Applied shirt to", player.Name)
    end
    
    -- 👖 Apply Pants
    if clothing.pants then
        local existingPants = character:FindFirstChildOfClass("Pants")
        if existingPants then
            existingPants:Destroy()
        end
        
        local newPants = Instance.new("Pants")
        newPants.PantsTemplate = clothing.pants.pantsTemplate
        newPants.Parent = character
        print("[RedeemManager] Applied pants to", player.Name)
    end
    
    -- 🎩 Apply Accessories
    if clothing.accessories then
        -- Remove existing accessories (optional)
        for _, accessory in pairs(character:GetChildren()) do
            if accessory:IsA("Accessory") then
                accessory:Destroy()
            end
        end
        
        -- Add new accessories
        for _, accessoryData in pairs(clothing.accessories) do
            local accessory = Instance.new("Accessory")
            accessory.Name = accessoryData.name
            accessory.AccessoryType = accessoryData.accessoryType or Enum.AccessoryType.Hat
            
            local handle = Instance.new("Part")
            handle.Name = "Handle"
            handle.Size = Vector3.new(1, 1, 1)
            handle.Transparency = 1
            handle.CanCollide = false
            handle.Parent = accessory
            
            if accessoryData.meshId ~= "" then
                local mesh = Instance.new("SpecialMesh")
                mesh.MeshId = accessoryData.meshId
                mesh.TextureId = accessoryData.textureId
                mesh.Parent = handle
            end
            
            -- Add to character
            humanoid:AddAccessory(accessory)
            print("[RedeemManager] Applied accessory:", accessoryData.name, "to", player.Name)
        end
    end
    
    return true
end

-- 📩 Send redeem notification
local function sendRedeemNotification(player, reward, success)
    local RedeemNotification = Instance.new("ScreenGui")
    RedeemNotification.Name = "RedeemNotification"
    RedeemNotification.Parent = player.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 100)
    frame.Position = UDim2.new(0.5, -175, 0.5, -50)
    frame.BackgroundColor3 = success and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
    frame.Parent = RedeemNotification
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0.6, 0)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.Text = success and ("🎁 Redeemed: " .. reward.rewardName) or ("❌ Redeem Failed")
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -20, 0.4, 0)
    subtitle.Position = UDim2.new(0, 10, 0.6, 0)
    subtitle.Text = success and reward.description or ("Need " .. reward.requiredScore .. " points")
    subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    subtitle.BackgroundTransparency = 1
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.SourceSans
    subtitle.Parent = frame
    
    -- Auto cleanup
    game:GetService("Debris"):AddItem(RedeemNotification, 4)
end

-- 💾 Load player redeem data
local function loadPlayerRedeemData(player)
    local success, data = pcall(function()
        return redeemStore:GetAsync(player.UserId)
    end)
    
    if success and data then
        playerRedeemData[player.UserId] = data
        print("[RedeemManager] Loaded redeem data for", player.Name, "- Claimed:", #data.claimedRewards, "Available:", #data.availableRewards)
    else
        playerRedeemData[player.UserId] = {
            claimedRewards = {}, -- Array of claimed reward IDs
            availableRewards = {}, -- Array of available but unclaimed reward indices
            lastScoreCheck = 0
        }
        print("[RedeemManager] Created new redeem data for", player.Name)
    end
end

-- 💾 Save player redeem data
local function savePlayerRedeemData(player)
    local data = playerRedeemData[player.UserId]
    if not data then return end
    
    local success, err = pcall(function()
        redeemStore:SetAsync(player.UserId, data)
    end)
    
    if success then
        print("[RedeemManager] Saved redeem data for", player.Name)
    else
        warn("[RedeemManager] Failed to save redeem data for", player.Name, ":", err)
    end
end

-- 📱 Update client redeem icon
local function updateClientRedeemIcon(player)
    local data = playerRedeemData[player.UserId]
    if not data then return end
    
    local hasAvailable = #data.availableRewards > 0
    local unclaimedCount = #data.availableRewards
    
    -- Send to client
    UpdateRedeemIconEvent:FireClient(player, hasAvailable, unclaimedCount)
    print("[RedeemManager] Updated icon for", player.Name, "- Available:", unclaimedCount)
end

-- 🔔 Show new reward notification
local function showNewRewardNotification(player, newRewardIndices)
    local NewRewardNotification = Instance.new("ScreenGui")
    NewRewardNotification.Name = "NewRewardNotification"
    NewRewardNotification.Parent = player.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 80)
    frame.Position = UDim2.new(0.5, -150, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    frame.Parent = NewRewardNotification
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0.6, 0)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.Text = "🎁 NEW REWARD AVAILABLE!"
    title.TextColor3 = Color3.fromRGB(0, 0, 0)
    title.BackgroundTransparency = 1
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -20, 0.4, 0)
    subtitle.Position = UDim2.new(0, 10, 0.6, 0)
    
    if #newRewardIndices == 1 then
        local reward = REDEEM_CONFIG[newRewardIndices[1]]
        subtitle.Text = reward.rewardName .. " - Click gift icon to redeem!"
    else
        subtitle.Text = #newRewardIndices .. " new rewards - Click gift icon!"
    end
    
    subtitle.TextColor3 = Color3.fromRGB(50, 50, 50)
    subtitle.BackgroundTransparency = 1
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.SourceSans
    subtitle.Parent = frame
    
    -- Auto cleanup
    game:GetService("Debris"):AddItem(NewRewardNotification, 5)
    
    print("[RedeemManager] Showed new reward notification for", player.Name)
end

-- 🔍 Check for new available rewards
local function checkAvailableRewards(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    
    local score = leaderstats:FindFirstChild("💰 Score")
    if not score then return end
    
    local data = playerRedeemData[player.UserId]
    if not data then return end
    
    local currentScore = score.Value
    local previousScore = data.lastScoreCheck
    
    print("[RedeemManager] Checking rewards for", player.Name, "- Current:", currentScore, "Previous:", previousScore)
    
    -- Check for newly available rewards (even on first check)
    local newRewards = {}
    for i, reward in ipairs(REDEEM_CONFIG) do
        -- Check if reward is available, not claimed, and not already in available list
        if currentScore >= reward.requiredScore and
           not table.find(data.claimedRewards, reward.id) and
           not table.find(data.availableRewards, i) then
            
            table.insert(newRewards, i)
            table.insert(data.availableRewards, i)
            print("[RedeemManager] New reward available for", player.Name, ":", reward.rewardName)
        end
    end
    
    -- Update last score check
    data.lastScoreCheck = currentScore
    
    -- Save data
    savePlayerRedeemData(player)
    
    -- Update client icon
    updateClientRedeemIcon(player)
    
    -- Show notification for new rewards (only if score actually increased)
    if #newRewards > 0 and currentScore > previousScore then
        showNewRewardNotification(player, newRewards)
    end
end

-- 🎁 Process redeem request
local function processRedeem(player, rewardIndex)
    local reward = REDEEM_CONFIG[rewardIndex]
    if not reward then
        warn("[RedeemManager] Invalid reward index:", rewardIndex)
        return false
    end
    
    local data = playerRedeemData[player.UserId]
    if not data then
        warn("[RedeemManager] No redeem data for", player.Name)
        return false
    end
    
    -- Check if reward is available to claim
    if not table.find(data.availableRewards, rewardIndex) then
        warn("[RedeemManager] Reward not available for", player.Name)
        return false
    end
    
    -- Check if already claimed
    if table.find(data.claimedRewards, reward.id) then
        warn("[RedeemManager] Reward already claimed by", player.Name)
        return false
    end
    
    -- Find outfit model and apply
    local outfitModel = findOutfitModel(reward.modelName)
    if not outfitModel then 
        sendRedeemNotification(player, reward, false)
        return false 
    end
    
    local clothing = extractClothingFromModel(outfitModel)
    local success = applyClothingToPlayer(player, clothing)
    
    if success then
        -- Mark as claimed
        table.insert(data.claimedRewards, reward.id)
        
        -- Remove from available
        local availableIndex = table.find(data.availableRewards, rewardIndex)
        if availableIndex then
            table.remove(data.availableRewards, availableIndex)
        end
        
        -- Save data
        savePlayerRedeemData(player)
        
        -- Update client icon
        updateClientRedeemIcon(player)
        
        -- Send success notification
        sendRedeemNotification(player, reward, true)
        print("[RedeemManager] Successfully redeemed", reward.rewardName, "for", player.Name)
        return true
    else
        sendRedeemNotification(player, reward, false)
        return false
    end
end

-- 📊 Get available rewards for player
local function getAvailableRewards(player)
    local data = playerRedeemData[player.UserId]
    if not data then return {} end
    
    local availableRewards = {}
    for _, rewardIndex in ipairs(data.availableRewards) do
        table.insert(availableRewards, rewardIndex)
    end
    
    return availableRewards
end

-- Event handlers
GetAvailableRewardsEvent.OnServerEvent:Connect(function(player)
    local availableRewards = getAvailableRewards(player)
    if #availableRewards > 0 then
        ShowRedeemModalEvent:FireClient(player, REDEEM_CONFIG, availableRewards)
        print("[RedeemManager] Sent modal to", player.Name, "with", #availableRewards, "rewards")
    else
        print("[RedeemManager] No available rewards for", player.Name)
    end
end)

ProcessRedeemEvent.OnServerEvent:Connect(function(player, rewardIndex)
    print("[RedeemManager] Redeem request from", player.Name, "for reward", rewardIndex)
    processRedeem(player, rewardIndex)
end)

-- Player events
Players.PlayerAdded:Connect(function(player)
    -- Load redeem data first
    loadPlayerRedeemData(player)
    
    -- Wait for leaderstats then set up monitoring
    player.ChildAdded:Connect(function(child)
        if child.Name == "leaderstats" then
            local score = child:WaitForChild("💰 Score", 5)
            if score then
                -- Wait a bit then do initial check
                wait(2)
                checkAvailableRewards(player)
                
                -- Monitor score changes
                score.Changed:Connect(function()
                    wait(1) -- Delay to avoid spam
                    checkAvailableRewards(player)
                end)
            end
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    savePlayerRedeemData(player)
    playerRedeemData[player.UserId] = nil
end)

print("[RedeemManager] Enhanced redeem system with persistence initialized!")