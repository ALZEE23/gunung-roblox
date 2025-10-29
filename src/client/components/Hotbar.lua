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
            Text = item and item.name or "", -- Kosong jika no item
            Size = UDim2.new(0, 80, 0, 80), -- Size tetap untuk grid
            BackgroundColor3 = isSelected and Color3.fromRGB(100, 150, 255) or slotColor,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            Font = Enum.Font.SourceSans,

            [roact.Event.Activated] = function()
                onSlotClick(i)
            end,
        }, {
            UICorner = roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8),
            }),
            
            UIStroke = roact.createElement("UIStroke", {
                Color = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120),
                Thickness = isSelected and 3 or 1,
            }),
            
            -- Slot number - SELALU ada
            SlotNumber = roact.createElement("TextLabel", {
                Text = tostring(i),
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0, 5, 0, 5),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.3,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                Font = Enum.Font.SourceSansBold,
            }, {
                UICorner = roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                }),
            }),
            
            -- Empty slot placeholder - tampil jika kosong
            EmptyPlaceholder = (not item) and roact.createElement("TextLabel", {
                Text = "Empty",
                Size = UDim2.new(1, -10, 1, -30),
                Position = UDim2.new(0, 5, 0, 25),
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(150, 150, 150),
                TextScaled = true,
                Font = Enum.Font.SourceSansItalic,
            }) or nil,
            
            -- Show quantity jika item exists
            QuantityLabel = (item and item.quantity) and roact.createElement("TextLabel", {
                Text = "x" .. tostring(item.quantity),
                Size = UDim2.new(0, 25, 0, 15),
                Position = UDim2.new(1, -30, 1, -20),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.3,
                TextColor3 = Color3.fromRGB(255, 255, 0),
                TextScaled = true,
                Font = Enum.Font.SourceSans,
            }, {
                UICorner = roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 3),
                }),
            }) or nil,

            -- Category indicator - hanya jika ada item
            CategoryIndicator = item and roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 3),
                Position = UDim2.new(0, 0, 1, -3),
                BackgroundColor3 = slotColor,
                BorderSizePixel = 0,
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
        
        -- 🎯 UIListLayout - lebih simple untuk horizontal layout
        UIListLayout = roact.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 10), -- Jarak antar slot
            SortOrder = Enum.SortOrder.Name,
        }),
        
        -- Slots akan diatur otomatis oleh UIGridLayout
        Slot1 = slots["Slot1"],
        Slot2 = slots["Slot2"],
        Slot3 = slots["Slot3"],
    })
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