local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local currentModal = nil

-- Create simple modal GUI
local function createTrashModal(trashBinName, trashConfig)
    if currentModal then
        currentModal:Destroy()
    end
    
    print("[TrashModal] Creating modal for:", trashBinName)
    
    -- Get inventory from server
    local GetInventoryFunction = ReplicatedStorage:FindFirstChild("InventoryEvents"):FindFirstChild("GetInventory")
    local inventory = {}
    
    if GetInventoryFunction then
        local success, result = pcall(function()
            return GetInventoryFunction:InvokeServer()
        end)
        if success and result then
            inventory = result
            print("[TrashModal] Got inventory with", result.hotbar and #result.hotbar.items or 0, "items")
        else
            warn("[TrashModal] Failed to get inventory")
        end
    end
    
    local hotbarItems = inventory.hotbar and inventory.hotbar.items or {}
    
    -- Filter items yang bisa di-trash
    local validItems = {}
    for slot, item in pairs(hotbarItems) do
        if item and item.category == trashConfig.acceptedCategory then
            table.insert(validItems, {
                slot = slot,
                item = item
            })
        end
    end
    
    print("[TrashModal] Found", #validItems, "valid items for", trashConfig.acceptedCategory)
    
    -- Create modal GUI
    currentModal = Instance.new("ScreenGui")
    currentModal.Name = "TrashModal"
    currentModal.Parent = player.PlayerGui
    currentModal.IgnoreGuiInset = true
    
    -- Background
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.Parent = currentModal
    
    -- Modal frame
    local modalHeight = 200 + math.max(1, #validItems) * 80
    local modal = Instance.new("Frame")
    modal.Size = UDim2.new(0, 400, 0, modalHeight)
    modal.Position = UDim2.new(0.5, -200, 0.5, -modalHeight/2)
    modal.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    modal.BorderSizePixel = 2
    modal.BorderColor3 = Color3.fromRGB(255, 255, 255)
    modal.Parent = background
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = modal
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.Text = trashConfig.name
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = modal
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -20, 0, 30)
    subtitle.Position = UDim2.new(0, 10, 0, 50)
    subtitle.Text = "Select items to trash (Category: " .. trashConfig.acceptedCategory .. ")"
    subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    subtitle.BackgroundTransparency = 1
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.SourceSans
    subtitle.Parent = modal
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = modal
    
    closeButton.Activated:Connect(function()
        print("[TrashModal] Close button clicked")
        if currentModal then
            currentModal:Destroy()
            currentModal = nil
        end
    end)
    
    -- Items list or no items message
    if #validItems == 0 then
        local noItems = Instance.new("TextLabel")
        noItems.Size = UDim2.new(1, -20, 0, 60)
        noItems.Position = UDim2.new(0, 10, 0, 90)
        noItems.Text = "No " .. trashConfig.acceptedCategory .. " items in your inventory"
        noItems.TextColor3 = Color3.fromRGB(150, 150, 150)
        noItems.BackgroundTransparency = 1
        noItems.TextScaled = true
        noItems.Font = Enum.Font.SourceSansItalic
        noItems.Parent = modal
    else
        for i, validItem in ipairs(validItems) do
            local item = validItem.item
            local slot = validItem.slot
            
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, -20, 0, 70)
            itemFrame.Position = UDim2.new(0, 10, 0, 90 + (i-1) * 80)
            itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            itemFrame.BorderSizePixel = 1
            itemFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
            itemFrame.Parent = modal
            
            local itemCorner = Instance.new("UICorner")
            itemCorner.CornerRadius = UDim.new(0, 8)
            itemCorner.Parent = itemFrame
            
            -- Item name
            local itemName = Instance.new("TextLabel")
            itemName.Size = UDim2.new(0.6, 0, 0.6, 0)
            itemName.Position = UDim2.new(0, 10, 0, 5)
            itemName.Text = (item.name or item.id) .. " (Slot " .. slot .. ")"
            itemName.TextColor3 = Color3.fromRGB(255, 255, 255)
            itemName.BackgroundTransparency = 1
            itemName.TextScaled = true
            itemName.Font = Enum.Font.SourceSansBold
            itemName.TextXAlignment = Enum.TextXAlignment.Left
            itemName.Parent = itemFrame
            
            -- Item quantity
            local itemQuantity = Instance.new("TextLabel")
            itemQuantity.Size = UDim2.new(0.6, 0, 0.4, 0)
            itemQuantity.Position = UDim2.new(0, 10, 0.6, 0)
            itemQuantity.Text = "Qty: " .. (item.quantity or 1) .. " | Category: " .. item.category
            itemQuantity.TextColor3 = Color3.fromRGB(200, 200, 200)
            itemQuantity.BackgroundTransparency = 1
            itemQuantity.TextScaled = true
            itemQuantity.Font = Enum.Font.SourceSans
            itemQuantity.TextXAlignment = Enum.TextXAlignment.Left
            itemQuantity.Parent = itemFrame
            
            -- Trash button
            local trashButton = Instance.new("TextButton")
            trashButton.Size = UDim2.new(0, 80, 0, 40)
            trashButton.Position = UDim2.new(1, -90, 0.5, -20)
            trashButton.Text = "🗑️ Trash"
            trashButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            trashButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            trashButton.TextScaled = true
            trashButton.Font = Enum.Font.SourceSansBold
            trashButton.Parent = itemFrame
            
            local trashCorner = Instance.new("UICorner")
            trashCorner.CornerRadius = UDim.new(0, 6)
            trashCorner.Parent = trashButton
            
            trashButton.Activated:Connect(function()
                print("[TrashModal] Trashing item:", item.name, "from slot:", slot)
                
                -- Fire trash event
                local TrashItemEvent = ReplicatedStorage:FindFirstChild("InventoryEvents"):FindFirstChild("TrashItem")
                if TrashItemEvent then
                    TrashItemEvent:FireServer(slot, trashBinName, 1)
                    print("[TrashModal] Fired TrashItem event")
                end

                if item.quantity and item.quantity > 1 then
                    item.quantity = item.quantity - 1
                    itemQuantity.Text = "Qty: " .. item.quantity .. " | Category: " .. item.category
                else
                    itemFrame:Destroy()
                end
                
                -- Close modal
                -- if currentModal then
                --     currentModal:Destroy()
                --     currentModal = nil
                -- end
            end)
        end
    end
    
    -- Close on background click
    background.Activated:Connect(function()
        print("[TrashModal] Background clicked")
        if currentModal then
            currentModal:Destroy()
            currentModal = nil
        end
    end)
    
    print("[TrashModal] Modal created successfully!")
end

-- Listen for show modal event from server
local InventoryEvents = ReplicatedStorage:WaitForChild("InventoryEvents")
local ShowTrashModalEvent = InventoryEvents:WaitForChild("ShowTrashModal")

ShowTrashModalEvent.OnClientEvent:Connect(function(trashBinName, trashConfig)
    print("[TrashModal] Received show modal event:", trashBinName)
    createTrashModal(trashBinName, trashConfig)
end)

print("[TrashModalHandler] Modal handler initialized!")