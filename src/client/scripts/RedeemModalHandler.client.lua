
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local currentRedeemModal = nil

-- 🎁 Create redeem modal
local function createRedeemModal(rewardConfig, availableRewards)
    if currentRedeemModal then
        currentRedeemModal:Destroy()
    end
    
    print("[RedeemModal] Creating modal with", #availableRewards, "available rewards")
    
    -- Create modal GUI
    currentRedeemModal = Instance.new("ScreenGui")
    currentRedeemModal.Name = "RedeemModal"
    currentRedeemModal.Parent = player.PlayerGui
    
    -- Background
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.Parent = currentRedeemModal
    
    -- Modal frame
    local modalHeight = 150 + #availableRewards * 100
    local modal = Instance.new("Frame")
    modal.Size = UDim2.new(0, 450, 0, modalHeight)
    modal.Position = UDim2.new(0.5, -225, 0.5, -modalHeight/2)
    modal.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    modal.BorderSizePixel = 2
    modal.BorderColor3 = Color3.fromRGB(255, 215, 0) -- Gold border
    modal.Parent = background
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = modal
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 50)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.Text = "🎁 REWARD STORE 🎁"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.BackgroundTransparency = 1
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = modal
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 35, 0, 35)
    closeButton.Position = UDim2.new(1, -45, 0, 10)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = modal
    
    closeButton.Activated:Connect(function()
        if currentRedeemModal then
            currentRedeemModal:Destroy()
            currentRedeemModal = nil
        end
    end)
    
    -- Rewards list
    for i, rewardIndex in ipairs(availableRewards) do
        local reward = rewardConfig[rewardIndex]
        
        local rewardFrame = Instance.new("Frame")
        rewardFrame.Size = UDim2.new(1, -20, 0, 80)
        rewardFrame.Position = UDim2.new(0, 10, 0, 70 + (i-1) * 90)
        rewardFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        rewardFrame.BorderSizePixel = 1
        rewardFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
        rewardFrame.Parent = modal
        
        local rewardCorner = Instance.new("UICorner")
        rewardCorner.CornerRadius = UDim.new(0, 10)
        rewardCorner.Parent = rewardFrame
        
        -- Reward name
        local rewardName = Instance.new("TextLabel")
        rewardName.Size = UDim2.new(0.6, 0, 0.5, 0)
        rewardName.Position = UDim2.new(0, 15, 0, 5)
        rewardName.Text = reward.rewardName
        rewardName.TextColor3 = Color3.fromRGB(255, 215, 0)
        rewardName.BackgroundTransparency = 1
        rewardName.TextScaled = true
        rewardName.Font = Enum.Font.SourceSansBold
        rewardName.TextXAlignment = Enum.TextXAlignment.Left
        rewardName.Parent = rewardFrame
        
        -- Description
        local description = Instance.new("TextLabel")
        description.Size = UDim2.new(0.6, 0, 0.5, 0)
        description.Position = UDim2.new(0, 15, 0.5, 0)
        description.Text = reward.description .. " (Cost: " .. reward.requiredScore .. " points)"
        description.TextColor3 = Color3.fromRGB(200, 200, 200)
        description.BackgroundTransparency = 1
        description.TextScaled = true
        description.Font = Enum.Font.SourceSans
        description.TextXAlignment = Enum.TextXAlignment.Left
        description.Parent = rewardFrame
        
        -- Redeem button
        local redeemButton = Instance.new("TextButton")
        redeemButton.Size = UDim2.new(0, 100, 0, 50)
        redeemButton.Position = UDim2.new(1, -110, 0.5, -25)
        redeemButton.Text = "🎁 REDEEM"
        redeemButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        redeemButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        redeemButton.TextScaled = true
        redeemButton.Font = Enum.Font.SourceSansBold
        redeemButton.Parent = rewardFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = redeemButton
        
        redeemButton.Activated:Connect(function()
            print("[RedeemModal] Redeeming reward:", reward.rewardName)
            
            -- Fire redeem event
            local ProcessRedeemEvent = ReplicatedStorage:FindFirstChild("InventoryEvents"):FindFirstChild("ProcessRedeem")
            if ProcessRedeemEvent then
                ProcessRedeemEvent:FireServer(rewardIndex)
            end
            
            -- Close modal
            if currentRedeemModal then
                currentRedeemModal:Destroy()
                currentRedeemModal = nil
            end
        end)
    end
    
    -- Close on background click
    background.Activated:Connect(function()
        if currentRedeemModal then
            currentRedeemModal:Destroy()
            currentRedeemModal = nil
        end
    end)
    
    print("[RedeemModal] Modal created with", #availableRewards, "redeemable rewards")
end

-- Listen for show redeem modal
local InventoryEvents = ReplicatedStorage:WaitForChild("InventoryEvents")
local ShowRedeemModalEvent = InventoryEvents:WaitForChild("ShowRedeemModal")

ShowRedeemModalEvent.OnClientEvent:Connect(function(rewardConfig, availableRewards)
    print("[RedeemModal] Received show modal event with", #availableRewards, "rewards")
    createRedeemModal(rewardConfig, availableRewards)
end)

print("[RedeemModalHandler] Redeem modal handler initialized!")