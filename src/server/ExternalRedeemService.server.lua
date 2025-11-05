local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local OutfitDataStore = DataStoreService:GetDataStore("PlayerOutfits")

local ExternalRedeemService = {}

-- 🌐 API Configuration (INCREASE TIMEOUT)
local API_CONFIG = {
    baseUrl = "https://script.google.com/macros/s/AKfycbxBTb-GArd2zk0nKCcAwS3wyAQ5A6Ev1SaPvtOpBO9vH_tUye6LJh0YKGqtwr3s5Mr9bA/exec?action=redeem&code=",
    maxRetries = 1 -- Add retry attempts
}

-- 🔍 Find character and humanoid
local function getPlayerCharacter(player)
    local character = player.Character
    if not character then
        warn("[ExternalRedeem] No character for player:", player.Name)
        return nil, nil
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        warn("[ExternalRedeem] No humanoid for player:", player.Name)
        return character, nil
    end
    
    return character, humanoid
end

-- 🔍 Find model in workspace or ServerStorage
local function findOutfitModel(modelName)
    local model = workspace:FindFirstChild(modelName) or game.ServerStorage:FindFirstChild(modelName)
    if model then
        print("[ExternalRedeem] Found outfit model:", modelName)
        return model
    else
        warn("[ExternalRedeem] Outfit model not found:", modelName)
        return nil
    end
end

-- 👔 Extract clothing items from model (FIXED untuk structure yang benar)
local function extractClothingFromModel(model)
    local clothing = {}
    
    print("[ExternalRedeem] 🔍 Extracting clothing from model:", model.Name)
    
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        warn("[ExternalRedeem] No Humanoid found in model:", model.Name)
        return clothing
    end
    
    local character = humanoid.Parent
    
    -- 👕 Extract Shirt
    local shirt = character:FindFirstChildOfClass("Shirt")
    if shirt then
        clothing.shirt = {
            className = "Shirt",
            shirtTemplate = shirt.ShirtTemplate
        }
        print("[ExternalRedeem] ✅ Found shirt:", shirt.ShirtTemplate)
    end
    
    -- 👖 Extract Pants
    local pants = character:FindFirstChildOfClass("Pants")
    if pants then
        clothing.pants = {
            className = "Pants",
            pantsTemplate = pants.PantsTemplate
        }
        print("[ExternalRedeem] ✅ Found pants:", pants.PantsTemplate)
    end
    
    -- 🎩 Extract Accessories (FIXED LOGIC)
    clothing.accessories = {}
    
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Accessory") then

            
            local handle = child:FindFirstChild("Handle")
            if handle then
                
                local accessoryData = {
                    name = child.Name,
                    accessoryType = child.AccessoryType
                }
                
                -- 🔧 Handle bisa jadi Part atau MeshPart
                if handle:IsA("MeshPart") then
                    -- Handle adalah MeshPart (newer style)
                    accessoryData.handleType = "MeshPart"
                    accessoryData.meshId = handle.MeshId
                    accessoryData.textureId = handle.TextureID
                    accessoryData.size = handle.Size
                    
                    
                elseif handle:IsA("Part") then
                    -- Handle adalah Part, check children untuk mesh
                    
                    
                    -- Check for SpecialMesh
                    local specialMesh = handle:FindFirstChildOfClass("SpecialMesh")
                    if specialMesh then
                        accessoryData.handleType = "PartWithSpecialMesh"
                        accessoryData.meshId = specialMesh.MeshId
                        accessoryData.textureId = specialMesh.TextureId
                        accessoryData.scale = specialMesh.Scale
                        accessoryData.meshType = specialMesh.MeshType
                        
                    end
                    
                    -- Check for MeshPart as child
                    local meshPart = handle:FindFirstChildOfClass("MeshPart")
                    if meshPart then
                        accessoryData.handleType = "PartWithMeshPart"
                        accessoryData.meshId = meshPart.MeshId
                        accessoryData.textureId = meshPart.TextureID
                        accessoryData.size = meshPart.Size
                       
                    end
                    
                    -- Store Part properties
                    accessoryData.partSize = handle.Size
                    accessoryData.partTransparency = handle.Transparency
                end
                
                -- Store attachment info
                local attachment = handle:FindFirstChild("HatAttachment") or handle:FindFirstChildOfClass("Attachment")
                if attachment then
                    accessoryData.attachmentName = attachment.Name
                    accessoryData.attachmentPosition = attachment.Position
                    accessoryData.attachmentOrientation = attachment.Orientation
                  
                end
                
                -- Only add if we found mesh data
                if accessoryData.meshId or accessoryData.handleType == "MeshPart" then
                    table.insert(clothing.accessories, accessoryData)
                    
                else
                    warn("[ExternalRedeem]   └─ No mesh data found, skipping")
                end
            else
                warn("[ExternalRedeem]   └─ No Handle found in:", child.Name)
            end
        end
    end
    
    print("[ExternalRedeem] 📊 Extraction complete - Accessories found:", #clothing.accessories)
    
    return clothing
end

-- 👤 Apply clothing to player (FIXED ACCESSORY APPLICATION)
local function applyClothingToPlayer(player, clothing)
    local character = player.Character
    if not character then
        warn("[ExternalRedeem] Player character not found:", player.Name)
        return false
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        warn("[ExternalRedeem] Player humanoid not found:", player.Name)
        return false
    end
    
    print("[ExternalRedeem] 👤 Applying clothing to player:", player.Name)
    
    -- 👕 Apply Shirt (unchanged)
    if clothing.shirt then
        local existingShirt = character:FindFirstChildOfClass("Shirt")
        if existingShirt then
            existingShirt:Destroy()
        end
        
        local newShirt = Instance.new("Shirt")
        newShirt.ShirtTemplate = clothing.shirt.shirtTemplate
        newShirt.Parent = character
    end
    
    -- 👖 Apply Pants (unchanged)
    if clothing.pants then
        local existingPants = character:FindFirstChildOfClass("Pants")
        if existingPants then
            existingPants:Destroy()
        end
        
        local newPants = Instance.new("Pants")
        newPants.PantsTemplate = clothing.pants.pantsTemplate
        newPants.Parent = character
    end
    
    -- 🎩 Apply Accessories (FIXED LOGIC)
    if clothing.accessories and #clothing.accessories > 0 then
        
        -- Remove existing accessories
        for _, accessory in pairs(character:GetChildren()) do
            if accessory:IsA("Accessory") then
                accessory:Destroy()
            end
        end
        
        -- Add new accessories
        for i, accessoryData in pairs(clothing.accessories) do
            local accessory = Instance.new("Accessory")
            accessory.Name = accessoryData.name
            accessory.AccessoryType = accessoryData.accessoryType or Enum.AccessoryType.Hat
            
            local handle
            
            -- 🔧 Create handle based on extracted type
            if accessoryData.handleType == "MeshPart" then
                -- Direct MeshPart handle
                handle = Instance.new("MeshPart")
                handle.Name = "Handle"
                handle.MeshId = accessoryData.meshId
                handle.TextureID = accessoryData.textureId or ""
                handle.Size = accessoryData.size or Vector3.new(1, 1, 1)
                handle.CanCollide = false
                handle.Massless = true
        
                
            elseif accessoryData.handleType == "PartWithMeshPart" then
                -- Part with MeshPart child
                handle = Instance.new("Part")
                handle.Name = "Handle"
                handle.Size = accessoryData.partSize or Vector3.new(1, 1, 1)
                handle.Transparency = accessoryData.partTransparency or 1
                handle.CanCollide = false
                handle.Massless = true
                
                local meshPart = Instance.new("MeshPart")
                meshPart.MeshId = accessoryData.meshId
                meshPart.TextureID = accessoryData.textureId or ""
                meshPart.Size = accessoryData.size or Vector3.new(1, 1, 1)
                meshPart.CanCollide = false
                meshPart.Massless = true
                meshPart.Parent = handle
                
                
            elseif accessoryData.handleType == "PartWithSpecialMesh" then
                -- Part with SpecialMesh
                handle = Instance.new("Part")
                handle.Name = "Handle"
                handle.Size = accessoryData.partSize or Vector3.new(1, 1, 1)
                handle.Transparency = accessoryData.partTransparency or 1
                handle.CanCollide = false
                handle.Massless = true
                
                local mesh = Instance.new("SpecialMesh")
                mesh.MeshId = accessoryData.meshId
                mesh.TextureId = accessoryData.textureId or ""
                mesh.Scale = accessoryData.scale or Vector3.new(1, 1, 1)
                if accessoryData.meshType then
                    mesh.MeshType = accessoryData.meshType
                end
                mesh.Parent = handle
                
                    
                
            else
                -- Fallback
                warn("[ExternalRedeem]   └─ Unknown handle type, using default")
                handle = Instance.new("Part")
                handle.Name = "Handle"
                handle.Size = Vector3.new(1, 1, 1)
                handle.Transparency = 1
                handle.CanCollide = false
                handle.Massless = true
            end
            
            handle.Parent = accessory
            
            -- 🔧 Add attachment
            if accessoryData.attachmentName then
                local attachment = Instance.new("Attachment")
                attachment.Name = accessoryData.attachmentName
                if accessoryData.attachmentPosition then
                    attachment.Position = accessoryData.attachmentPosition
                end
                if accessoryData.attachmentOrientation then
                    attachment.Orientation = accessoryData.attachmentOrientation
                end
                attachment.Parent = handle
                
            end
            
            -- 🔧 Add to character
            local addSuccess, addError = pcall(function()
                humanoid:AddAccessory(accessory)
            end)
            
            if addSuccess then
                print("[ExternalRedeem] ✅ Successfully added accessory:", accessoryData.name)
            else
                warn("[ExternalRedeem] ❌ Failed to add accessory:", accessoryData.name, "Error:", addError)
            end
        end
        
        print("[ExternalRedeem] ✅ Finished applying accessories")
    end
    
    return true
end

-- 👕 Apply all skins to player using outfit models
local function applyAllSkinsToPlayer(player)
    local character, humanoid = getPlayerCharacter(player)
    if not character then return false end
    
    local outfitModelsToApply = {
        "StarterOutfitModel"
    }
    
    local appliedCount = 0
    local appliedItems = {}
    
    for _, modelName in ipairs(outfitModelsToApply) do
        local outfitModel = findOutfitModel(modelName)
        if outfitModel then
            print("[ExternalRedeem] Applying outfit model:", modelName)
            
            local clothing = extractClothingFromModel(outfitModel)
            local success = applyClothingToPlayer(player, clothing)
            
            if success then
                appliedCount = appliedCount + 1
                table.insert(appliedItems, modelName)
                print("[ExternalRedeem] Successfully applied", modelName, "to", player.Name)
            else
                warn("[ExternalRedeem] Failed to apply", modelName, "to", player.Name)
            end
        else
            warn("[ExternalRedeem] Outfit model not found:", modelName)
        end
    end
    
    if appliedCount > 0 then
        print("[ExternalRedeem] Applied", appliedCount, "outfit models to", player.Name)
        return true, appliedItems
    else
        warn("[ExternalRedeem] No outfit models could be applied to", player.Name)
        return false, {}
    end
end

-- 📩 Send redeem notification
local function sendRedeemNotification(player, message, success)
    local RedeemNotification = Instance.new("ScreenGui")
    RedeemNotification.Name = "ExternalRedeemNotification"
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
    title.Text = success and "🎁 External Redeem Success!" or "❌ External Redeem Failed"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -20, 0.4, 0)
    subtitle.Position = UDim2.new(0, 10, 0.6, 0)
    subtitle.Text = message
    subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    subtitle.BackgroundTransparency = 1
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.SourceSans
    subtitle.Parent = frame
    
    game:GetService("Debris"):AddItem(RedeemNotification, 4)
end

-- 🌐 Send GET request with retry logic
local function sendRedeemRequest(code)
    local url = API_CONFIG.baseUrl .. code
    
    print("[ExternalRedeem] Sending GET request to:", url)
    
    -- Check if HttpService is enabled
    if not HttpService.HttpEnabled then
        warn("[ExternalRedeem] HttpService is not enabled!")
        return false, "HTTP requests are disabled. Please enable HttpService in game settings."
    end
    
    -- 🔄 Retry logic
    local attempts = 0
    local maxAttempts = API_CONFIG.maxRetries
    
    while attempts < maxAttempts do
        attempts = attempts + 1
        print("[ExternalRedeem] Attempt", attempts, "of", maxAttempts)
        
        local success, response = pcall(function()
            return HttpService:RequestAsync({
                Url = url,
                Method = "GET"
                -- 🔧 REMOVED: Timeout parameter - not supported!
            })
        end)
        
        if success then
            print("[ExternalRedeem] ✅ API Response Status:", response.StatusCode)
            print("[ExternalRedeem] 📝 API Response Body:", response.Body)
            
            if response.StatusCode == 200 then
                -- Success! Parse response
                local parseSuccess, responseData = pcall(function()
                    return HttpService:JSONDecode(response.Body)
                end)
                
                if parseSuccess then
                    print("[ExternalRedeem] ✅ Successfully parsed JSON response")
                    return true, responseData
                else
                    warn("[ExternalRedeem] Failed to parse JSON:", responseData)
                    if attempts >= maxAttempts then
                        return false, "Invalid server response format"
                    end
                end
            else
                warn("[ExternalRedeem] API returned status:", response.StatusCode)
                if attempts >= maxAttempts then
                    if response.StatusCode == 404 then
                        return false, "API endpoint not found"
                    elseif response.StatusCode == 500 then
                        return false, "Server internal error"
                    elseif response.StatusCode == 403 then
                        return false, "Access forbidden"
                    else
                        return false, "Server error (Status: " .. response.StatusCode .. ")"
                    end
                end
            end
        else
            warn("[ExternalRedeem] HTTP request failed (attempt " .. attempts .. "):", response)
            
            if attempts >= maxAttempts then
                if string.find(tostring(response), "Http requests are not enabled") then
                    return false, "HTTP requests disabled. Enable HttpService in Studio."
                elseif string.find(tostring(response), "ConnectFail") then
                    return false, "Cannot connect to server. Check internet connection."
                else
                    return false, "Network error: " .. tostring(response)
                end
            end
        end
        
        -- Wait before retry
        if attempts < maxAttempts then
            print("[ExternalRedeem] Waiting 1 second before retry...")
            wait(1)
        end
    end
    
    return false, "Max retry attempts exceeded"
end

-- 💾 Save outfit to DataStore
local function saveOutfit(player, clothing)
    pcall(function()
        OutfitDataStore:SetAsync(player.UserId, clothing)
        print("[ExternalRedeem] 💾 Saved outfit for", player.Name)
    end)
end

-- 📥 Load and apply saved outfit
local function loadAndApplyOutfit(player)
    spawn(function()
        wait(2)
        
        local success, clothingData = pcall(function()
            return OutfitDataStore:GetAsync(player.UserId)
        end)
        
        if success and clothingData then
            print("[ExternalRedeem] 📥 Found saved outfit for", player.Name, "- applying...")
            
            -- Decode JSON string back to table
            local clothing = HttpService:JSONDecode(clothingData)
            
            applyClothingToPlayer(player, clothing)
            print("[ExternalRedeem] ✅ Auto-applied saved outfit!")
        else
            print("[ExternalRedeem] No saved outfit for", player.Name)
        end
    end)
end

-- 🎯 Process redeem code with external API
function ExternalRedeemService.processRedeemCode(player, code)
    print("[ExternalRedeem] Processing redeem code:", code, "for player:", player.Name)
    
    local success, responseData = sendRedeemRequest(code)
    
    if not success then
        sendRedeemNotification(player, responseData, false)
        return false, responseData -- Return here, stop execution
    end
    
    if responseData.ok == true then
        print("[ExternalRedeem] API approved code:", code)
        
        local appliedSuccess, appliedItems = applyAllSkinsToPlayer(player)
        
        if appliedSuccess then
            -- 💾 Save outfit after successful apply
            local outfitModel = findOutfitModel("StarterOutfitModel")
            if outfitModel then
                local clothing = extractClothingFromModel(outfitModel)
                
                -- Fix DataStore save - convert to JSON string
                pcall(function()
                    local clothingData = HttpService:JSONEncode(clothing)
                    OutfitDataStore:SetAsync(player.UserId, clothingData)
                    print("[ExternalRedeem] 💾 Saved outfit for", player.Name)
                end)
            end
            
            local message = "Outfit applied and saved!"
            sendRedeemNotification(player, message, true)
            
            return true, message, appliedItems -- Return here, stop execution
        else
            local errorMsg = "Failed to apply outfit"
            sendRedeemNotification(player, errorMsg, false)
            return false, errorMsg -- Return here, stop execution
        end
    else
        local errorMessage = responseData.message or responseData.error or "Invalid code"
        print("[ExternalRedeem] ❌ API rejected code:", code, "reason:", errorMessage)
        sendRedeemNotification(player, errorMessage, false)
        return false, errorMessage -- Return here, stop execution
    end
end

-- 🚀 Auto-apply on player join
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        loadAndApplyOutfit(player)
    end)
end)

-- Global access
_G.ExternalRedeemService = ExternalRedeemService

print("[ExternalRedeem] External API redeem service initialized with RedeemManager logic!")
print("[ExternalRedeem] API URL:", API_CONFIG.baseUrl)
print("[ExternalRedeem] Will apply outfit models: StarterOutfit, CoolHatOutfit, CompleteOutfit")

return ExternalRedeemService