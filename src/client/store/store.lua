local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local rodux = require(Packages:FindFirstChild("roblox_rodux@4.0.0-rc.0") or Packages.Rodux)

local function reducer(state, action)
    state = state or { count = 0 }

    if action.type == "increment" then
        return { count = state.count + 1 }
    elseif action.type == "decrement" then
        return { count = state.count - 1 }
    else
        return state
    end
end

local store = rodux.Store.new(reducer)

return store