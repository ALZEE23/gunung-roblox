

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RedeemManager = {}

-- 🎁 Redeem configuration dengan model references
local REDEEM_CONFIG = {
    {
        requiredScore = 100,
        rewardName = "Starter Pack",
        modelName = "StarterOutfit", -- Nama model di workspace/ServerStorage
        description = "Basic shirt and pants",
        items = {"shirt", "pants"}
    },
    {
        requiredScore = 250,
        rewardName = "Cool Hat",
        modelName = "CoolHatOutfit",
        description = "Trendy hat accessory",
        items = {"hat"}
    },
    {
        requiredScore = 500,
        rewardName = "Complete Set",
        modelName = "CompleteOutfit",
        description = "Full outfit with accessories",
        items = {"shirt", "pants", "hat", "accessory"}
    }
}

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

-- 🎁 Process redeem request
local function processRedeem(player, rewardIndex)
    local reward = REDEEM_CONFIG[rewardIndex]
    if not reward then
        warn("[RedeemManager] Invalid reward index:", rewardIndex)
        return false
    end
    
    -- Check player score
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        warn("[RedeemManager] No leaderstats for", player.Name)
        return false
    end
    
    local score = leaderstats:FindFirstChild("💰 Score")
    if not score or score.Value < reward.requiredScore then
        warn("[RedeemManager] Insufficient score for", player.Name, "Required:", reward.requiredScore, "Current:", score and score.Value or 0)
        return false
    end
    
    -- Find outfit model
    local outfitModel = findOutfitModel(reward.modelName)
    if not outfitModel then
        return false
    end
    
    -- Extract clothing
    local clothing = extractClothingFromModel(outfitModel)
    
    -- Apply to player
    local success = applyClothingToPlayer(player, clothing)
    
    if success then
        -- Deduct score
        score.Value = score.Value - reward.requiredScore
        
        -- Send success notification
        RedeemManager.sendRedeemNotification(player, reward, true)
        print("[RedeemManager] Successfully redeemed", reward.rewardName, "for", player.Name)
        return true
    else
        RedeemManager.sendRedeemNotification(player, reward, false)
        return false
    end
end

-- 📩 Send redeem notification
function RedeemManager.sendRedeemNotification(player, reward, success)
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

-- 🎯 Create RemoteEvents
local InventoryEvents = ReplicatedStorage:WaitForChild("InventoryEvents")

local ShowRedeemModalEvent = Instance.new("RemoteEvent")
ShowRedeemModalEvent.Name = "ShowRedeemModal"
ShowRedeemModalEvent.Parent = InventoryEvents

local ProcessRedeemEvent = Instance.new("RemoteEvent")
ProcessRedeemEvent.Name = "ProcessRedeem"
ProcessRedeemEvent.Parent = InventoryEvents

-- Handle redeem request
ProcessRedeemEvent.OnServerEvent:Connect(function(player, rewardIndex)
    print("[RedeemManager] Redeem request from", player.Name, "for reward", rewardIndex)
    processRedeem(player, rewardIndex)
end)

-- 📊 Check score and show modal
local function checkScoreAndShowModal(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    
    local score = leaderstats:FindFirstChild("💰 Score")
    if not score then return end
    
    -- Check if player can redeem anything
    local availableRewards = {}
    for i, reward in ipairs(REDEEM_CONFIG) do
        if score.Value >= reward.requiredScore then
            table.insert(availableRewards, i)
        end
    end
    
    if #availableRewards > 0 then
        ShowRedeemModalEvent:FireClient(player, REDEEM_CONFIG, availableRewards)
    end
end

-- Monitor score changes
Players.PlayerAdded:Connect(function(player)
    player.ChildAdded:Connect(function(child)
        if child.Name == "leaderstats" then
            local score = child:WaitForChild("💰 Score", 5)
            if score then
                score.Changed:Connect(function()
                    wait(1) -- Delay untuk avoid spam
                    checkScoreAndShowModal(player)
                end)
            end
        end
    end)
end)

print("[RedeemManager] Redeem system initialized!")