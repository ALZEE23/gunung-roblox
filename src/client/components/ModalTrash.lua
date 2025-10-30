local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local roact = require(Packages:FindFirstChild("roblox_roact@1.4.4") or Packages.Roact)
local roactRodux = require(Packages:FindFirstChild("roblox_roact-rodux@0.5.1") or Packages.RoactRodux)

local function ModalTrash(props)
    local isVisible = props.isVisible or false
    local trashBinName = props.trashBinName or "OrganicTrash"
    local inventory = props.inventory or {}
    local onTrashItem = props.onTrashItem or function() end
    local onClose = props.onClose or function() end
    
    if not isVisible then
        return nil
    end
    
    -- Get trash bin configuration
    local trashConfig = {
        OrganicTrash = {
            acceptedCategory = "Organic",
            color = Color3.fromRGB(76, 153, 0),
            name = "Organic Trash Bin",
            icon = "🌱"
        },
        AnorganicTrash = {
            acceptedCategory = "Anorganic",
            color = Color3.fromRGB(220, 53, 69),
            name = "Anorganic Trash Bin",
            icon = "🔧"
        },
        MixedTrash = {
            acceptedCategory = "Campuran",
            color = Color3.fromRGB(255, 193, 7),
            name = "Mixed Trash Bin",
            icon = "♻️"
        }
    }
    
    local config = trashConfig[trashBinName] or trashConfig.OrganicTrash
    local hotbarItems = inventory.hotbar and inventory.hotbar.items or {}
    
    -- Filter items yang bisa di-trash
    local validItems = {}
    for slot, item in pairs(hotbarItems) do
        if item and item.category == config.acceptedCategory then
            table.insert(validItems, {
                slot = slot,
                item = item
            })
        end
    end
    
    -- Create item slots
    local itemSlots = {}
    for i, validItem in ipairs(validItems) do
        local item = validItem.item
        local slot = validItem.slot
        
        itemSlots["Item" .. i] = roact.createElement("Frame", {
            Size = UDim2.new(1, -20, 0, 60),
            Position = UDim2.new(0, 10, 0, 80 + (i-1) * 70),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 1,
            BorderColor3 = config.color,
        }, {
            UICorner = roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, 8),
            }),
            
            ItemIcon = roact.createElement("TextLabel", {
                Size = UDim2.new(0, 50, 1, 0),
                Text = config.icon,
                TextColor3 = config.color,
                BackgroundTransparency = 1,
                TextScaled = true,
                Font = Enum.Font.SourceSansBold,
            }),
            
            ItemInfo = roact.createElement("Frame", {
                Size = UDim2.new(1, -110, 1, 0),
                Position = UDim2.new(0, 55, 0, 0),
                BackgroundTransparency = 1,
            }, {
                ItemName = roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0.6, 0),
                    Text = item.name or item.id,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 1,
                    TextScaled = true,
                    Font = Enum.Font.SourceSansBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),
                
                ItemQuantity = roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0.4, 0),
                    Position = UDim2.new(0, 0, 0.6, 0),
                    Text = "Quantity: " .. (item.quantity or 1),
                    TextColor3 = Color3.fromRGB(200, 200, 200),
                    BackgroundTransparency = 1,
                    TextScaled = true,
                    Font = Enum.Font.SourceSans,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),
            }),
            
            TrashButton = roact.createElement("TextButton", {
                Size = UDim2.new(0, 50, 0, 40),
                Position = UDim2.new(1, -55, 0.5, -20),
                Text = "🗑️",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                TextScaled = true,
                Font = Enum.Font.SourceSansBold,
                
                [roact.Event.Activated] = function()
                    onTrashItem(slot, trashBinName, 1)
                end,
            }, {
                UICorner = roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                }),
            }),
        })
    end
    
    return roact.createElement("ScreenGui", {
        Name = "TrashModal",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, {
        Background = roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.5,
            
            [roact.Event.Activated] = function()
                onClose()
            end,
        }),
        
        Modal = roact.createElement("Frame", {
            Size = UDim2.new(0, 400, 0, 300 + #validItems * 70),
            Position = UDim2.new(0.5, -200, 0.5, -150 - #validItems * 35),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            BorderSizePixel = 2,
            BorderColor3 = config.color,
        }, {
            UICorner = roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, 12),
            }),
            
            Title = roact.createElement("TextLabel", {
                Size = UDim2.new(1, -20, 0, 40),
                Position = UDim2.new(0, 10, 0, 10),
                Text = config.icon .. " " .. config.name,
                TextColor3 = config.color,
                BackgroundTransparency = 1,
                TextScaled = true,
                Font = Enum.Font.SourceSansBold,
            }),
            
            Subtitle = roact.createElement("TextLabel", {
                Size = UDim2.new(1, -20, 0, 30),
                Position = UDim2.new(0, 10, 0, 50),
                Text = "Select items to trash:",
                TextColor3 = Color3.fromRGB(200, 200, 200),
                BackgroundTransparency = 1,
                TextScaled = true,
                Font = Enum.Font.SourceSans,
            }),
            
            CloseButton = roact.createElement("TextButton", {
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(1, -40, 0, 10),
                Text = "✕",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                TextScaled = true,
                Font = Enum.Font.SourceSansBold,
                
                [roact.Event.Activated] = function()
                    onClose()
                end,
            }, {
                UICorner = roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                }),
            }),
            
            NoItemsMessage = (#validItems == 0) and roact.createElement("TextLabel", {
                Size = UDim2.new(1, -20, 0, 60),
                Position = UDim2.new(0, 10, 0, 100),
                Text = "No " .. config.acceptedCategory .. " items in your inventory",
                TextColor3 = Color3.fromRGB(150, 150, 150),
                BackgroundTransparency = 1,
                TextScaled = true,
                Font = Enum.Font.SourceSansItalic,
            }) or nil,
            
            unpack(itemSlots)
        })
    })
end

-- Connect to Redux store
local ConnectedModalTrash = roactRodux.connect(
    function(state)
        return {
            isVisible = state.trash and state.trash.modalVisible or false,
            trashBinName = state.trash and state.trash.currentTrashBin or "OrganicTrash",
            inventory = state.inventory or {},
        }
    end,
    function(dispatch)
        return {
            onTrashItem = function(slot, trashBinName, quantity)
                -- Fire to server
                local TrashItemEvent = ReplicatedStorage:FindFirstChild("InventoryEvents"):FindFirstChild("TrashItem")
                if TrashItemEvent then
                    TrashItemEvent:FireServer(slot, trashBinName, quantity)
                end
                
                -- Close modal
                dispatch({
                    type = "HIDE_TRASH_MODAL"
                })
            end,
            
            onClose = function()
                dispatch({
                    type = "HIDE_TRASH_MODAL"
                })
            end,
        }
    end
)(ModalTrash)

return ConnectedModalTrash