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
    currentRedeemModal.ResetOnSpawn = false
    currentRedeemModal.Parent = player.PlayerGui
    
    -- Background
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.3 -- 🔧 More transparent
    background.BorderSizePixel = 0
    background.Parent = currentRedeemModal
    
    -- Modal frame
    local modalHeight = math.max(200, 150 + #availableRewards * 100)
    local modal = Instance.new("Frame")
    modal.Size = UDim2.new(0, 500, 0, modalHeight)
    modal.Position = UDim2.new(0.5, -250, 0.5, -modalHeight/2)
    modal.BackgroundColor3 = Color3.fromRGB(35, 35, 35) -- 🔧 Darker background
    modal.BorderSizePixel = 0
    modal.Parent = background
    
    -- 🔧 ADD: Better styling
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = modal
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 215, 0) -- Gold border
    stroke.Thickness = 3
    stroke.Parent = modal
    
    -- 🔧 ADD: Drop shadow
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.Position = UDim2.new(0, -5, 0, -5)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.ZIndex = modal.ZIndex - 1
    shadow.BorderSizePixel = 0
    shadow.Parent = background
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 20)
    shadowCorner.Parent = shadow
    
    -- Title background
    local titleBg = Instance.new("Frame")
    titleBg.Size = UDim2.new(1, 0, 0, 60)
    titleBg.Position = UDim2.new(0, 0, 0, 0)
    titleBg.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    titleBg.BorderSizePixel = 0
    titleBg.Parent = modal
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 15)
    titleCorner.Parent = titleBg
    
    -- Fix title corner (only top corners)
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 15)
    titleFix.Position = UDim2.new(0, 0, 1, -15)
    titleFix.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBg
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.Text = "🎁 REWARD STORE 🎁"
    title.TextColor3 = Color3.fromRGB(0, 0, 0) -- 🔧 Black text on gold
    title.BackgroundTransparency = 1
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = titleBg
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 10)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = modal
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0.5, 0)
    closeCorner.Parent = closeButton
    
    closeButton.Activated:Connect(function()
        if currentRedeemModal then
            currentRedeemModal:Destroy()
            currentRedeemModal = nil
        end
    end)
    
    -- 🔧 ADD: ScrollingFrame for rewards
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -40, 1, -80)
    scrollFrame.Position = UDim2.new(0, 20, 0, 70)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
    scrollFrame.Parent = modal
    
    -- Calculate content size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #availableRewards * 100 + 20)
    
    -- Rewards list
    for i, rewardIndex in ipairs(availableRewards) do
        local reward = rewardConfig[rewardIndex]
        
        local rewardFrame = Instance.new("Frame")
        rewardFrame.Size = UDim2.new(1, -20, 0, 90)
        rewardFrame.Position = UDim2.new(0, 10, 0, (i-1) * 100 + 10)
        rewardFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- 🔧 Darker gray
        rewardFrame.BorderSizePixel = 0
        rewardFrame.Parent = scrollFrame
        
        local rewardCorner = Instance.new("UICorner")
        rewardCorner.CornerRadius = UDim.new(0, 12)
        rewardCorner.Parent = rewardFrame
        
        local rewardStroke = Instance.new("UIStroke")
        rewardStroke.Color = Color3.fromRGB(100, 100, 100)
        rewardStroke.Thickness = 1
        rewardStroke.Parent = rewardFrame
        
        -- 🔧 ADD: Reward icon
        local rewardIcon = Instance.new("TextLabel")
        rewardIcon.Size = UDim2.new(0, 60, 0, 60)
        rewardIcon.Position = UDim2.new(0, 15, 0.5, -30)
        rewardIcon.Text = "🎁"
        rewardIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
        rewardIcon.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        rewardIcon.TextScaled = true
        rewardIcon.Font = Enum.Font.SourceSansBold
        rewardIcon.Parent = rewardFrame
        
        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(0, 10)
        iconCorner.Parent = rewardIcon
        
        -- Reward name
        local rewardName = Instance.new("TextLabel")
        rewardName.Size = UDim2.new(0.5, -90, 0, 30)
        rewardName.Position = UDim2.new(0, 85, 0, 10)
        rewardName.Text = reward.rewardName
        rewardName.TextColor3 = Color3.fromRGB(255, 215, 0)
        rewardName.BackgroundTransparency = 1
        rewardName.TextScaled = true
        rewardName.Font = Enum.Font.SourceSansBold
        rewardName.TextXAlignment = Enum.TextXAlignment.Left
        rewardName.Parent = rewardFrame
        
        -- Description
        local description = Instance.new("TextLabel")
        description.Size = UDim2.new(0.5, -90, 0, 25)
        description.Position = UDim2.new(0, 85, 0, 40)
        description.Text = reward.description
        description.TextColor3 = Color3.fromRGB(200, 200, 200)
        description.BackgroundTransparency = 1
        description.TextScaled = true
        description.Font = Enum.Font.SourceSans
        description.TextXAlignment = Enum.TextXAlignment.Left
        description.Parent = rewardFrame
        
        -- Cost label
        local costLabel = Instance.new("TextLabel")
        costLabel.Size = UDim2.new(0.5, -90, 0, 20)
        costLabel.Position = UDim2.new(0, 85, 0, 65)
        costLabel.Text = "Cost: " .. reward.requiredScore .. " points"
        costLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        costLabel.BackgroundTransparency = 1
        costLabel.TextScaled = true
        costLabel.Font = Enum.Font.SourceSansItalic
        costLabel.TextXAlignment = Enum.TextXAlignment.Left
        costLabel.Parent = rewardFrame
        
        -- Redeem button
        local redeemButton = Instance.new("TextButton")
        redeemButton.Size = UDim2.new(0, 120, 0, 60)
        redeemButton.Position = UDim2.new(1, -135, 0.5, -30)
        redeemButton.Text = "🎁 REDEEM"
        redeemButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        redeemButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        redeemButton.TextScaled = true
        redeemButton.Font = Enum.Font.SourceSansBold
        redeemButton.BorderSizePixel = 0
        redeemButton.Parent = rewardFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 10)
        buttonCorner.Parent = redeemButton
        
        -- 🔧 ADD: Button hover effect
        redeemButton.MouseEnter:Connect(function()
            redeemButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
        end)
        
        redeemButton.MouseLeave:Connect(function()
            redeemButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        end)
        
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
    
    -- 🔧 ADD: Empty state jika gak ada rewards
    if #availableRewards == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, 0, 0, 100)
        emptyLabel.Position = UDim2.new(0, 0, 0.5, -50)
        emptyLabel.Text = "🎁\n\nNo rewards available yet!\nEarn more points to unlock rewards."
        emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.TextScaled = true
        emptyLabel.Font = Enum.Font.SourceSans
        emptyLabel.Parent = scrollFrame
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