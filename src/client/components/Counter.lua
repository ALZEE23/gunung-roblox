local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local roact = require(Packages:FindFirstChild("roblox_roact@1.4.4") or Packages.Roact)
local roactRodux = require(Packages:FindFirstChild("roblox_roact-rodux@0.5.1") or Packages.RoactRodux)

local function Counter(props)
    local value = props.value or 0
    local onIncrement = props.onIncrement or function() end
    local onDecrement = props.onDecrement or function() end

    return roact.createElement("Frame", {
        Size = UDim2.new(0, 300, 0, 150),
        Position = UDim2.new(0.5, -150, 0.5, -75),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        BorderSizePixel = 0,
    }, {
        UICorner = roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, 8),
        }),
        
        Title = roact.createElement("TextLabel", {
            Text = "Counter App",
            Size = UDim2.new(1, 0, 0, 40),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            Font = Enum.Font.SourceSansBold,
        }),
        
        CountDisplay = roact.createElement("TextLabel", {
            Text = tostring(value),
            Size = UDim2.new(1, -40, 0, 40),
            Position = UDim2.new(0, 20, 0, 50),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            Font = Enum.Font.SourceSans,
        }, {
            UICorner = roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),
        }),
        
        DecrementButton = roact.createElement("TextButton", {
            Text = "-",
            Size = UDim2.new(0, 60, 0, 40),
            Position = UDim2.new(0, 20, 0, 100),
            BackgroundColor3 = Color3.fromRGB(220, 53, 69),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            Font = Enum.Font.SourceSansBold,

            [roact.Event.Activated] = onDecrement,
        }, {
            UICorner = roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),
        }),
        
        IncrementButton = roact.createElement("TextButton", {
            Text = "+",
            Size = UDim2.new(0, 60, 0, 40),
            Position = UDim2.new(1, -80, 0, 100),
            BackgroundColor3 = Color3.fromRGB(40, 167, 69),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            Font = Enum.Font.SourceSansBold,

            [roact.Event.Activated] = onIncrement,
        }, {
            UICorner = roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),
        }),
    })
end

-- Connect to Redux
local ConnectedCounter = roactRodux.connect(
    function(state)
        return {
            value = state.count,
        }
    end,
    function(dispatch)
        return {
            onIncrement = function()
                dispatch({ type = "increment" })
            end,
            onDecrement = function()
                dispatch({ type = "decrement" })
            end,
        }
    end
)(Counter)

return ConnectedCounter