local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local roact = require(Packages:FindFirstChild("roblox_roact@1.4.4") or Packages.Roact)
local roactRodux = require(Packages:FindFirstChild("roblox_roact-rodux@0.5.1") or Packages.RoactRodux)

local function Hotbar(props)
    local selectedSlot = props.selectedSlot or 1
    local items = props.items or {}
    local onSlotClick = props.onSlotClick or function() end
    
    -- Create 3 slots - SELALU ada, tidak peduli ada item atau tidak
    local slots = {}
    
    for i = 1, 3 do
        local item = items[i]
        local isSelected = selectedSlot == i
        
        -- Default slot color (abu-abu) atau category color jika ada item
        local slotColor = Color3.fromRGB(60, 60, 60) -- Default gray
        if item then
            if item.category == "Organic" then
                slotColor = Color3.fromRGB(76, 153, 0) -- Green
            elseif item.category == "Anorganic" then 
                slotColor = Color3.fromRGB(220, 53, 69) -- Red
            elseif item.category == "Campuran" then
                slotColor = Color3.fromRGB(255, 193, 7) -- Yellow
            end
        end
        
        slots["Slot" .. i] = roact.createElement("TextButton", {
            Text = "", -- Kosong karena pakai viewport
            Size = UDim2.new(0, 80, 0, 80),
            BackgroundColor3 = isSelected and Color3.fromRGB(100, 150, 255) or slotColor,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.SourceSans,
            ClipsDescendants = true, -- 🔑 KEY: Clip children to slot bounds
            
            -- 🔧 ADD: Debug border untuk lihat slot bounds
            BorderSizePixel = 1,
            BorderColor3 = Color3.fromRGB(255, 255, 255),

            [roact.Event.Activated] = function()
                onSlotClick(i)
            end,
            
            -- 🔑 Add ref for viewport setup
            [roact.Ref] = function(rbx)
                if rbx and item then
                    -- Setup 3D model in viewport dengan delay
                    spawn(function()
                        wait(0.1) -- Small delay untuk ensure viewport ready
                        local viewport = rbx:FindFirstChild("ItemViewport")
                        if viewport then
                            setupItemViewport(viewport, item)
                        end
                    end)
                end
            end,
        }, {
            UICorner = roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8),
            }),
            
            UIStroke = roact.createElement("UIStroke", {
                Color = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120),
                Thickness = isSelected and 3 or 1,
            }),
            
            -- Slot number - lebih kecil
            SlotNumber = roact.createElement("TextLabel", {
                Text = tostring(i),
                Size = UDim2.new(0, 14, 0, 14), -- 🔧 SMALLER: 14x14
                Position = UDim2.new(0, 1, 0, 1), -- 🔧 SMALLER: Corner position
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.2, -- Less transparent untuk visibility
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 25, -- 🔧 HIGHER: Above viewport
            }, {
                UICorner = roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 2),
                }),
            }),
            
            -- Quantity label - lebih kecil
            QuantityLabel = (item and item.quantity and item.quantity > 1) and roact.createElement("TextLabel", {
                Text = "x" .. tostring(item.quantity),
                Size = UDim2.new(0, 22, 0, 12), -- 🔧 SMALLER: 22x12
                Position = UDim2.new(1, -23, 1, -13), -- 🔧 SMALLER: Bottom-right
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.2, -- Less transparent
                TextColor3 = Color3.fromRGB(255, 255, 0),
                TextScaled = true,
                Font = Enum.Font.SourceSansBold,
                ZIndex = 25, -- 🔧 HIGHER: Above viewport
            }, {
                UICorner = roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 2),
                }),
                
                UIStroke = roact.createElement("UIStroke", {
                    Color = Color3.fromRGB(255, 255, 0),
                    Thickness = 1,
                }),
            }) or nil,

            -- Category indicator - hanya jika ada item
            CategoryIndicator = item and roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 2),
                Position = UDim2.new(0, 0, 1, -2),
                BackgroundColor3 = slotColor,
                BorderSizePixel = 0,
                ZIndex = 20,
            }) or nil,
            
            -- 🔧 FIX: Add ViewportFrame directly instead of unpack
            -- Maksimal viewport (hampir full slot):

            -- 🔧 BIGGER: Maksimal ViewportFrame
            ItemViewport = item and roact.createElement("ViewportFrame", {
                Size = UDim2.new(1, -6, 1, -20), -- 🔧 BIGGER: Cuma margin 6px dan 20px
                Position = UDim2.new(0, 3, 0, 3),  -- 🔧 BIGGER: Minimal padding
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                ZIndex = 1,
            }, {
                -- Camera
                Camera = roact.createElement("Camera"),
                
                -- 3D Item Model (akan diupdate via refs)
                ItemModel = roact.createElement("Folder"),
            }) or nil,
            
            -- 🔧 FIX: Empty placeholder directly
            EmptyPlaceholder = (not item) and roact.createElement("TextLabel", {
                Text = "Empty",
                Size = UDim2.new(1, -20, 1, -40),
                Position = UDim2.new(0, 10, 0, 30),
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(150, 150, 150),
                TextScaled = true,
                Font = Enum.Font.SourceSansItalic,
                ZIndex = 1,
            }) or nil,
        })
    end

    return roact.createElement("Frame", {
        Size = UDim2.new(0, 290, 0, 100),
        Position = UDim2.new(0.5, -145, 1, -120),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
    }, {
        UICorner = roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, 12),
        }),
        
        UIPadding = roact.createElement("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        }),
        
        UIListLayout = roact.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.Name,
        }),
        
        Slot1 = slots["Slot1"],
        Slot2 = slots["Slot2"],
        Slot3 = slots["Slot3"],
    })
end

-- 🎨 Function untuk setup 3D model di viewport
function setupItemViewport(viewport, item)
    -- Clear existing content
    viewport:ClearAllChildren()
    
    -- Get item model dari ReplicatedStorage
    local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
    if not itemsFolder then 
        print("[Hotbar] Items folder not found")
        return 
    end
    
    local categoryFolder = itemsFolder:FindFirstChild(item.category)
    if not categoryFolder then 
        print("[Hotbar] Category folder not found:", item.category)
        return 
    end
    
    local originalModel = categoryFolder:FindFirstChild(item.id)
    if not originalModel then 
        print("[Hotbar] Item model not found:", item.id)
        return 
    end
    
    -- Clone dan setup model
    local model = originalModel:Clone()
    model.Parent = viewport
    
    -- 🔧 FIX: Ensure model fits in viewport
    if model:IsA("MeshPart") then
        -- Scale down if needed
        local maxSize = math.max(model.Size.X, model.Size.Y, model.Size.Z)
        if maxSize > 3 then
            local scale = 3 / maxSize
            model.Size = model.Size * scale
        end
        model.Position = Vector3.new(0, 0, 0)
    end

    -- 🎯 EXTREME SCALE UP: Make mesh HUGE
    if model:IsA("MeshPart") then
        local currentSize = math.max(model.Size.X, model.Size.Y, model.Size.Z)
        local targetSize = 8 -- 🔥 HUGE target size
        local scale = targetSize / currentSize
        
        model.Size = model.Size * scale
        model.Position = Vector3.new(0, 0, 0)
        
        print("[Hotbar] HUGE scaled mesh from", currentSize, "to", math.max(model.Size.X, model.Size.Y, model.Size.Z))
    end
    
    -- Create camera
    local camera = Instance.new("Camera")
    camera.Parent = viewport
    viewport.CurrentCamera = camera
    
    -- 🔥 VERY CLOSE CAMERA
    local modelSize = 8 -- Use huge scaled size
    if model:IsA("MeshPart") then
        modelSize = math.max(model.Size.X, model.Size.Y, model.Size.Z)
    end
    
    -- 🎯 SUPER CLOSE: Fill entire viewport
    local distance = modelSize * 0.6 -- Super close!
    
    camera.CFrame = CFrame.lookAt(
        Vector3.new(distance * 0.5, distance * 0.2, distance * 0.5), -- Fill viewport
        Vector3.new(0, 0, 0)
    )
    
    -- 🔧 FIX: Better camera positioning
    local modelSize = 2 -- Default size
    if model:IsA("MeshPart") then
        modelSize = math.max(model.Size.X, model.Size.Y, model.Size.Z)
    end
    
    local distance = math.max(modelSize * 1.5, 3) -- Ensure minimum distance
    
    camera.CFrame = CFrame.lookAt(
        Vector3.new(distance * 0.7, distance * 0.5, distance * 0.7), -- Angled view
        Vector3.new(0, 0, 0) -- Look at center
    )
    
    -- 🔧 FIX: Slower rotation animation
    local TweenService = game:GetService("TweenService")
    local rotateTween = TweenService:Create(
        model,
        TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), -- Slower rotation
        {CFrame = model.CFrame * CFrame.Angles(0, math.rad(360), 0)}
    )
    rotateTween:Play()
    
    print("[Hotbar] Setup viewport for item:", item.id)
end

local ConnectedHotbar = roactRodux.connect(
    function(state)
        return {
            selectedSlot = state.hotbar and state.hotbar.selectedSlot or 1,
            items = state.hotbar and state.hotbar.items or {},
        }
    end,
    function(dispatch)
        return {
            onSlotClick = function(slot)
                dispatch({ 
                    type = "SELECT_SLOT", 
                    slot = slot 
                })
            end,
        }
    end
)(Hotbar)

return ConnectedHotbar