
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local guideModal = nil
local guideButton = nil

-- 📖 Guide content (Goals & Instructions)
local GUIDE_CONTENT = {
    title = "Petunjuk Game",
    sections = {
        {
            icon = "🎯",
            title = "Tujuan Utama",
            description = "Ayo cari, kumpulkan dan buang semua sampah! Jadilah penyelamat dunia!"
        },
        {
            icon = "🗑️",
            title = "Cara Bermain",
            description = [[
• Jelajahi untuk menemukan barang-barang sampah
• Sentuh barang untuk mengambilnya
• Barang masuk ke hotbar Anda (3 slot)
• Barang dengan jenis yang sama akan menumpuk bersama
• Jenis yang berbeda memerlukan slot kosong
            ]]
        },
        {
            icon = "📦",
            title = "Sistem Hotbar",
            description = [[
• 3 slot untuk jenis barang yang berbeda
• Penyimpanan tersedia untuk barang tambahan
            ]]
        },
        {
            icon = "💰",
            title = "Rewards",
            description = [[
• Dapatkan koin untuk mengumpulkan barang
• Naikkan peringkat di papan peringkat
• Tukarkan kode spesial
• Dapatkan pakaian eksklusif!
            ]]
        },
        {
            icon = "🎁",
            title = "Redeem Codes",
            description = [[
• Klik tombol "Redeem Code"
• Masukkan kode yang valid
• Dapatkan hadiah spesial
• Kode hanya dapat digunakan sekali!
            ]]
        }
    }
}

-- 🎨 Create Guide Button (Top-right corner)
local function createGuideButton()
    if guideButton then return end
    
    guideButton = Instance.new("ScreenGui")
    guideButton.Name = "GuideButton"
    guideButton.ResetOnSpawn = false
    guideButton.IgnoreGuiInset = true
    guideButton.Parent = playerGui
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 50, 0, 50)
    button.Position = UDim2.new(1, -60, 0, 70) -- Below redeem button
    button.Text = "❓"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.BackgroundColor3 = Color3.fromRGB(50, 150, 250)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold
    button.BorderSizePixel = 0
    button.Parent = guideButton
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0) -- Circular
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Parent = button
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(70, 170, 255)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(50, 150, 250)
        }):Play()
    end)
    
    -- Click to open guide
    button.MouseButton1Click:Connect(function()
        showGuideModal()
    end)
    
    print("[GuideModal] Guide button created")
end

-- 📖 Create Guide Modal
local function createGuideModal()
    if guideModal then
        guideModal:Destroy()
    end
    
    guideModal = Instance.new("ScreenGui")
    guideModal.Name = "GuideModal"
    guideModal.ResetOnSpawn = false
    guideModal.IgnoreGuiInset = true
    guideModal.Enabled = false
    guideModal.Parent = playerGui
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Parent = guideModal
    
    -- Main modal container
    local modal = Instance.new("Frame")
    modal.Name = "GuideModalContainer"
    modal.Size = UDim2.new(0, 600, 0, 500)
    modal.Position = UDim2.new(0.5, -300, 0.5, -250)
    modal.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    modal.BorderSizePixel = 0
    modal.Parent = guideModal
    
    local modalCorner = Instance.new("UICorner")
    modalCorner.CornerRadius = UDim.new(0, 15)
    modalCorner.Parent = modal
    
    local modalStroke = Instance.new("UIStroke")
    modalStroke.Color = Color3.fromRGB(100, 100, 255)
    modalStroke.Thickness = 3
    modalStroke.Parent = modal
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
    header.BorderSizePixel = 0
    header.Parent = modal
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 15)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.Text = GUIDE_CONTENT.title
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
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
    closeButton.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0.5, 0)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        hideGuideModal()
    end)
    
    -- Content scroll frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -80)
    scrollFrame.Position = UDim2.new(0, 10, 0, 70)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 255)
    scrollFrame.Parent = modal
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 15)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    -- Add guide sections
    local totalHeight = 0
    
    for i, section in ipairs(GUIDE_CONTENT.sections) do
        local sectionFrame = Instance.new("Frame")
        sectionFrame.Size = UDim2.new(1, -20, 0, 120)
        sectionFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        sectionFrame.BorderSizePixel = 0
        sectionFrame.LayoutOrder = i
        sectionFrame.Parent = scrollFrame
        
        local sectionCorner = Instance.new("UICorner")
        sectionCorner.CornerRadius = UDim.new(0, 10)
        sectionCorner.Parent = sectionFrame
        
        -- Icon
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 40, 0, 40)
        icon.Position = UDim2.new(0, 10, 0, 10)
        icon.Text = section.icon
        icon.TextColor3 = Color3.fromRGB(255, 255, 255)
        icon.BackgroundTransparency = 1
        icon.TextScaled = true
        icon.Font = Enum.Font.SourceSansBold
        icon.Parent = sectionFrame
        
        -- Section title
        local sectionTitle = Instance.new("TextLabel")
        sectionTitle.Size = UDim2.new(1, -70, 0, 30)
        sectionTitle.Position = UDim2.new(0, 60, 0, 10)
        sectionTitle.Text = section.title
        sectionTitle.TextColor3 = Color3.fromRGB(255, 255, 100)
        sectionTitle.BackgroundTransparency = 1
        sectionTitle.TextScaled = true
        sectionTitle.Font = Enum.Font.SourceSansBold
        sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
        sectionTitle.Parent = sectionFrame
        
        -- Description
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -70, 1, -50)
        desc.Position = UDim2.new(0, 60, 0, 45)
        desc.Text = section.description
        desc.TextColor3 = Color3.fromRGB(200, 200, 200)
        desc.BackgroundTransparency = 1
        desc.TextSize = 20
        desc.Font = Enum.Font.SourceSans
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top
        desc.TextWrapped = true
        desc.Parent = sectionFrame
        
        totalHeight = totalHeight + 135
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    
    print("[GuideModal] Guide modal created")
end

-- 🎬 Show modal with animation
function showGuideModal()
    if not guideModal then
        createGuideModal()
    end
    
    guideModal.Enabled = true
    
    local modal = guideModal:FindFirstChild("GuideModalContainer")
    if modal then
        -- Start small
        modal.Size = UDim2.new(0, 0, 0, 0)
        
        -- Animate to full size
        local tween = TweenService:Create(modal, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 600, 0, 500)
        })
        tween:Play()
    end
    
    print("[GuideModal] Guide modal opened")
end

-- 🎬 Hide modal with animation
function hideGuideModal()
    if not guideModal then return end
    
    local modal = guideModal:FindFirstChild("GuideModalContainer")
    if modal then
        local tween = TweenService:Create(modal, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        
        tween.Completed:Connect(function()
            guideModal.Enabled = false
        end)
        
        tween:Play()
    end
    
    print("[GuideModal] Guide modal closed")
end

-- 🚀 Auto-show on first join
local function checkFirstTimePlayer()
    -- Check if player is new (you can save this to DataStore)
    local hasSeenGuide = false -- Replace with DataStore check
    
    if not hasSeenGuide then
        wait(2) -- Wait 2 seconds after join
        showGuideModal()
    end
end

-- 📖 Initialize
createGuideButton()
createGuideModal()
checkFirstTimePlayer()

-- ⌨️ Close modal with ESC key
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Escape then
        if guideModal and guideModal.Enabled then
            hideGuideModal()
        end
    end
end)

print("[GuideModal] Guide modal system initialized!")