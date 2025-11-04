
-- local Players = game:GetService("Players")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- local player = Players.LocalPlayer
-- local redeemIcon = nil
-- local currentRedeemModal = nil

-- -- 🎁 Create redeem icon button
-- local function createRedeemIcon()
--     if redeemIcon then return end
    
--     redeemIcon = Instance.new("ScreenGui")
--     redeemIcon.Name = "RedeemIcon"
--     redeemIcon.ResetOnSpawn = false
--     redeemIcon.Parent = player.PlayerGui
    
--     local iconButton = Instance.new("TextButton")
--     iconButton.Size = UDim2.new(0, 70, 0, 70)
--     iconButton.Position = UDim2.new(1, -80, 0, 120) -- Top right, below leaderboard
--     iconButton.Text = "🎁"
--     iconButton.TextColor3 = Color3.fromRGB(255, 255, 255)
--     iconButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
--     iconButton.TextScaled = true
--     iconButton.Font = Enum.Font.SourceSansBold
--     iconButton.Parent = redeemIcon
    
--     local corner = Instance.new("UICorner")
--     corner.CornerRadius = UDim.new(0, 12)
--     corner.Parent = iconButton
    
--     local stroke = Instance.new("UIStroke")
--     stroke.Color = Color3.fromRGB(255, 255, 255)
--     stroke.Thickness = 2
--     stroke.Parent = iconButton
    
--     -- 🔥 Glowing effect for available rewards
--     local shadowFrame = Instance.new("Frame")
--     shadowFrame.Size = UDim2.new(1, 6, 1, 6)
--     shadowFrame.Position = UDim2.new(0, -3, 0, -3)
--     shadowFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
--     shadowFrame.BackgroundTransparency = 0.5
--     shadowFrame.ZIndex = iconButton.ZIndex - 1
--     shadowFrame.Parent = iconButton
    
--     local shadowCorner = Instance.new("UICorner")
--     shadowCorner.CornerRadius = UDim.new(0, 15)
--     shadowCorner.Parent = shadowFrame
    
--     -- 📢 Notification badge
--     local notificationBadge = Instance.new("Frame")
--     notificationBadge.Size = UDim2.new(0, 25, 0, 25)
--     notificationBadge.Position = UDim2.new(1, -5, 0, -5)
--     notificationBadge.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
--     notificationBadge.Visible = false
--     notificationBadge.ZIndex = iconButton.ZIndex + 1
--     notificationBadge.Parent = iconButton
    
--     local badgeCorner = Instance.new("UICorner")
--     badgeCorner.CornerRadius = UDim.new(0.5, 0)
--     badgeCorner.Parent = notificationBadge
    
--     local badgeText = Instance.new("TextLabel")
--     badgeText.Size = UDim2.new(1, 0, 1, 0)
--     badgeText.Text = "!"
--     badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
--     badgeText.BackgroundTransparency = 1
--     badgeText.TextScaled = true
--     badgeText.Font = Enum.Font.SourceSansBold
--     badgeText.Parent = notificationBadge
    
--     -- 🎯 Store references
--     iconButton.Name = "RedeemButton"
--     notificationBadge.Name = "NotificationBadge"
    
--     -- Click handler
--     iconButton.Activated:Connect(function()
--         print("[RedeemIcon] Redeem icon clicked")
        
--         -- Request available rewards
--         local GetAvailableRewardsEvent = ReplicatedStorage:FindFirstChild("InventoryEvents"):FindFirstChild("GetAvailableRewards")
--         if GetAvailableRewardsEvent then
--             GetAvailableRewardsEvent:FireServer()
--         end
--     end)
    
--     print("[RedeemIcon] Redeem icon created")
-- end

-- -- 🔥 Update icon state (available rewards)
-- local function updateRedeemIcon(hasAvailableRewards, unclaimedCount)
--     if not redeemIcon then return end
    
--     local iconButton = redeemIcon:FindFirstChild("RedeemButton")
--     local notificationBadge = redeemIcon:FindFirstChild("NotificationBadge")
    
--     if iconButton and notificationBadge then
--         if hasAvailableRewards and unclaimedCount > 0 then
--             -- Show notification badge
--             notificationBadge.Visible = true
--             notificationBadge:FindFirstChild("TextLabel").Text = tostring(unclaimedCount)
            
--             -- Make icon more prominent
--             iconButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0) -- Orange glow
            
--             print("[RedeemIcon] Updated - Available rewards:", unclaimedCount)
--         else
--             -- Hide notification
--             notificationBadge.Visible = false
--             iconButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150) -- Gray (disabled)
            
--             print("[RedeemIcon] Updated - No available rewards")
--         end
--     end
-- end

-- -- 🎁 Handle modal events
-- local InventoryEvents = ReplicatedStorage:WaitForChild("InventoryEvents")

-- -- Listen for icon updates
-- local UpdateRedeemIconEvent = InventoryEvents:WaitForChild("UpdateRedeemIcon", 10)
-- if UpdateRedeemIconEvent then
--     UpdateRedeemIconEvent.OnClientEvent:Connect(function(hasAvailable, unclaimedCount)
--         updateRedeemIcon(hasAvailable, unclaimedCount)
--     end)
-- end

-- -- Listen for show modal
-- local ShowRedeemModalEvent = InventoryEvents:WaitForChild("ShowRedeemModal", 10)
-- if ShowRedeemModalEvent then
--     ShowRedeemModalEvent.OnClientEvent:Connect(function(rewardConfig, availableRewards)
--         print("[RedeemIcon] Opening redeem modal")
--         -- Use existing modal from RedeemModalHandler
--     end)
-- end

-- -- Create icon on script load
-- createRedeemIcon()

-- print("[RedeemIconHandler] Redeem icon handler initialized!")