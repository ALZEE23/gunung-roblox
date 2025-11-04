local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local redeemCodeButton = nil
local currentInputModal = nil

-- 🚨 Show error message
local function showErrorMessage(message)
    local errorGui = Instance.new("ScreenGui")
    errorGui.Name = "ErrorMessage"
    errorGui.Parent = player.PlayerGui
    
    local errorFrame = Instance.new("Frame")
    errorFrame.Size = UDim2.new(0, 300, 0, 80)
    errorFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
    errorFrame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    errorFrame.BorderSizePixel = 0
    errorFrame.Parent = errorGui
    
    local errorCorner = Instance.new("UICorner")
    errorCorner.CornerRadius = UDim.new(0, 12)
    errorCorner.Parent = errorFrame
    
    local errorText = Instance.new("TextLabel")
    errorText.Size = UDim2.new(1, -20, 1, -20)
    errorText.Position = UDim2.new(0, 10, 0, 10)
    errorText.Text = "❌ " .. message
    errorText.TextColor3 = Color3.fromRGB(255, 255, 255)
    errorText.BackgroundTransparency = 1
    errorText.TextScaled = true
    errorText.Font = Enum.Font.SourceSansBold
    errorText.Parent = errorFrame
    
    -- Auto cleanup
    game:GetService("Debris"):AddItem(errorGui, 3)
end

-- ✅ Show success message
local function showSuccessMessage(message)
    local successGui = Instance.new("ScreenGui")
    successGui.Name = "SuccessMessage"
    successGui.Parent = player.PlayerGui
    
    local successFrame = Instance.new("Frame")
    successFrame.Size = UDim2.new(0, 300, 0, 80)
    successFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
    successFrame.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    successFrame.BorderSizePixel = 0
    successFrame.Parent = successGui
    
    local successCorner = Instance.new("UICorner")
    successCorner.CornerRadius = UDim.new(0, 12)
    successCorner.Parent = successFrame
    
    local successText = Instance.new("TextLabel")
    successText.Size = UDim2.new(1, -20, 1, -20)
    successText.Position = UDim2.new(0, 10, 0, 10)
    successText.Text = "✅ " .. message
    successText.TextColor3 = Color3.fromRGB(255, 255, 255)
    successText.BackgroundTransparency = 1
    successText.TextScaled = true
    successText.Font = Enum.Font.SourceSansBold
    successText.Parent = successFrame
    
    -- Auto cleanup
    game:GetService("Debris"):AddItem(successGui, 4)
    
    -- Close input modal on success
    if currentInputModal then
        currentInputModal:Destroy()
        currentInputModal = nil
    end
end

-- 📝 Create input modal
local function createInputModal()
    if currentInputModal then
        currentInputModal:Destroy()
    end
    
    print("[InputRedeem] Creating input modal")
    
    -- Create modal GUI
    currentInputModal = Instance.new("ScreenGui")
    currentInputModal.Name = "RedeemCodeModal"
    currentInputModal.ResetOnSpawn = false
    currentInputModal.Parent = player.PlayerGui
    
    -- Background overlay
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.4
    background.BorderSizePixel = 0
    background.Parent = currentInputModal
    
    -- Modal frame
    local modal = Instance.new("Frame")
    modal.Size = UDim2.new(0, 450, 0, 300)
    modal.Position = UDim2.new(0.5, -225, 0.5, -150)
    modal.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    modal.BorderSizePixel = 0
    modal.Parent = background
    
    local modalCorner = Instance.new("UICorner")
    modalCorner.CornerRadius = UDim.new(0, 15)
    modalCorner.Parent = modal
    
    local modalStroke = Instance.new("UIStroke")
    modalStroke.Color = Color3.fromRGB(100, 50, 200)
    modalStroke.Thickness = 3
    modalStroke.Parent = modal
    
    -- Title background
    local titleBg = Instance.new("Frame")
    titleBg.Size = UDim2.new(1, 0, 0, 60)
    titleBg.Position = UDim2.new(0, 0, 0, 0)
    titleBg.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
    titleBg.BorderSizePixel = 0
    titleBg.Parent = modal
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 15)
    titleCorner.Parent = titleBg
    
    -- Fix title corner (only top)
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 15)
    titleFix.Position = UDim2.new(0, 0, 1, -15)
    titleFix.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBg
    
    -- Title text
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.Text = "📝 ENTER REDEEM CODE"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
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
        print("[InputRedeem] Close button clicked")
        if currentInputModal then
            currentInputModal:Destroy()
            currentInputModal = nil
        end
    end)
    
    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Size = UDim2.new(1, -40, 0, 50)
    instructions.Position = UDim2.new(0, 20, 0, 80)
    instructions.Text = "Enter your redeem code below to claim rewards!"
    instructions.TextColor3 = Color3.fromRGB(200, 200, 200)
    instructions.BackgroundTransparency = 1
    instructions.TextScaled = true
    instructions.Font = Enum.Font.SourceSans
    instructions.TextWrapped = true
    instructions.Parent = modal
    
    -- Input frame
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, -40, 0, 60)
    inputFrame.Position = UDim2.new(0, 20, 0, 140)
    inputFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = modal
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 10)
    inputCorner.Parent = inputFrame
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromRGB(100, 100, 100)
    inputStroke.Thickness = 2
    inputStroke.Parent = inputFrame
    
    -- Text input box
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 1, -20)
    textBox.Position = UDim2.new(0, 10, 0, 10)
    textBox.BackgroundTransparency = 1
    textBox.Text = ""
    textBox.PlaceholderText = "Enter redeem code here..."
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    textBox.TextScaled = true
    textBox.Font = Enum.Font.SourceSans
    textBox.ClearTextOnFocus = false
    textBox.Parent = inputFrame
    
    -- 🔧 Focus effect
    textBox.Focused:Connect(function()
        inputStroke.Color = Color3.fromRGB(100, 50, 200)
        inputStroke.Thickness = 3
    end)
    
    textBox.FocusLost:Connect(function()
        inputStroke.Color = Color3.fromRGB(100, 100, 100)
        inputStroke.Thickness = 2
    end)
    
    -- Submit button
    local submitButton = Instance.new("TextButton")
    submitButton.Size = UDim2.new(0, 150, 0, 50)
    submitButton.Position = UDim2.new(0.5, -75, 0, 220)
    submitButton.Text = "🎁 REDEEM"
    submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    submitButton.TextScaled = true
    submitButton.Font = Enum.Font.SourceSansBold
    submitButton.BorderSizePixel = 0
    submitButton.Parent = modal
    
    local submitCorner = Instance.new("UICorner")
    submitCorner.CornerRadius = UDim.new(0, 12)
    submitCorner.Parent = submitButton
    
    -- 🔧 Submit button states
    local function updateSubmitButton()
        local code = textBox.Text:gsub("%s+", "") -- Remove spaces
        if #code > 0 then
            submitButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            submitButton.Text = "🎁 REDEEM"
        else
            submitButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            submitButton.Text = "Enter Code"
        end
    end
    
    textBox:GetPropertyChangedSignal("Text"):Connect(updateSubmitButton)
    updateSubmitButton() -- Initial state
    
    -- Submit functionality (UPDATE dengan enhanced debugging)
    local function submitCode()
        local code = textBox.Text:gsub("%s+", ""):upper() -- Clean and uppercase
        
        if #code == 0 then
            showErrorMessage("Please enter a redeem code!")
            return
        end
        
        print("[InputRedeem] 🚀 Submitting code:", code)
        
        -- Disable button temporarily
        submitButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        submitButton.Text = "Processing..."
        
        -- 🔍 DEBUG: Check if InventoryEvents exists
        local InventoryEvents = ReplicatedStorage:FindFirstChild("InventoryEvents")
        if not InventoryEvents then
            warn("[InputRedeem] ❌ InventoryEvents not found in ReplicatedStorage!")
            showErrorMessage("System error - InventoryEvents missing!")
            wait(1)
            updateSubmitButton()
            return
        end
        
        print("[InputRedeem] ✅ Found InventoryEvents")
        
        -- 🔍 DEBUG: Check if RedeemCode event exists
        local RedeemCodeEvent = InventoryEvents:FindFirstChild("RedeemCode")
        if not RedeemCodeEvent then
            warn("[InputRedeem] ❌ RedeemCode event not found!")
            showErrorMessage("System error - RedeemCode event missing!")
            wait(1)
            updateSubmitButton()
            return
        end
        
        print("[InputRedeem] ✅ Found RedeemCode event")
        print("[InputRedeem] 📡 Firing RedeemCode event with code:", code)
        
        -- Send to server
        local success = pcall(function()
            RedeemCodeEvent:FireServer(code)
        end)
        
        if success then
            print("[InputRedeem] ✅ Successfully fired RedeemCode event")
        else
            warn("[InputRedeem] ❌ Failed to fire RedeemCode event")
            showErrorMessage("Failed to send request to server!")
            wait(1)
            updateSubmitButton()
        end
    end
    
    -- 🔧 Submit on button click
    submitButton.Activated:Connect(submitCode)
    
    -- 🔧 Submit on Enter key
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            submitCode()
        end
    end)
    
    -- Auto-focus text box
    spawn(function() -- 🔧 FIX: Use spawn instead of wait
        wait(0.1)
        textBox:CaptureFocus()
    end)
    
    -- Close on background click
    background.Activated:Connect(function()
        print("[InputRedeem] Background clicked - closing modal")
        if currentInputModal then
            currentInputModal:Destroy()
            currentInputModal = nil
        end
    end)
    
    print("[InputRedeem] Input modal created")
end

-- 🎁 Create redeem code button
local function createRedeemCodeButton()
    if redeemCodeButton then return end
    
    redeemCodeButton = Instance.new("ScreenGui")
    redeemCodeButton.Name = "RedeemCodeButton"
    redeemCodeButton.ResetOnSpawn = false
    redeemCodeButton.Parent = player.PlayerGui
    
    local buttonFrame = Instance.new("TextButton")
    buttonFrame.Size = UDim2.new(0, 140, 0, 40)
    buttonFrame.Position = UDim2.new(1, -150, 0, 200) -- Below redeem icon
    buttonFrame.Text = "📝 Redeem Code"
    buttonFrame.TextColor3 = Color3.fromRGB(255, 255, 255)
    buttonFrame.BackgroundColor3 = Color3.fromRGB(100, 50, 200) -- Purple
    buttonFrame.TextScaled = true
    buttonFrame.Font = Enum.Font.SourceSansBold
    buttonFrame.BorderSizePixel = 0
    buttonFrame.Parent = redeemCodeButton
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = buttonFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Parent = buttonFrame
    
    -- 🎯 Click handler
    buttonFrame.Activated:Connect(function()
        print("[InputRedeem] Code button clicked")
        createInputModal() -- 🔧 NOW WORKS - function is defined above
    end)
    
    -- 🔧 Hover effects
    buttonFrame.MouseEnter:Connect(function()
        buttonFrame.BackgroundColor3 = Color3.fromRGB(120, 70, 220)
    end)
    
    buttonFrame.MouseLeave:Connect(function()
        buttonFrame.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
    end)
    
    print("[InputRedeem] Redeem code button created")
end

-- 📡 Listen for server responses
local InventoryEvents = ReplicatedStorage:WaitForChild("InventoryEvents")

-- Create redeem code response event
local RedeemCodeResponseEvent = InventoryEvents:WaitForChild("RedeemCodeResponse", 10)
if not RedeemCodeResponseEvent then
    RedeemCodeResponseEvent = Instance.new("RemoteEvent")
    RedeemCodeResponseEvent.Name = "RedeemCodeResponse"
    RedeemCodeResponseEvent.Parent = InventoryEvents
end

RedeemCodeResponseEvent.OnClientEvent:Connect(function(success, message, rewards)
    print("[InputRedeem] Received response - Success:", success, "Message:", message)
    
    if success then
        local fullMessage = message
        if rewards and #rewards > 0 then
            fullMessage = fullMessage .. "\nRewards: " .. table.concat(rewards, ", ")
        end
        showSuccessMessage(fullMessage)
    else
        showErrorMessage(message or "Unknown error occurred!")
        
        -- Re-enable submit button in modal if it's open
        if currentInputModal then
            local modal = currentInputModal:FindFirstChild("RedeemCodeModal")
            if modal then
                local submitButton = modal:FindFirstChild("TextButton") -- 🔧 FIX: Better path
                if submitButton then
                    spawn(function() -- 🔧 FIX: Use spawn
                        wait(1)
                        submitButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
                        submitButton.Text = "🎁 REDEEM"
                    end)
                end
            end
        end
    end
end)

-- 🚀 Initialize
createRedeemCodeButton()

print("[InputRedeemHandler] Redeem code input system initialized!")