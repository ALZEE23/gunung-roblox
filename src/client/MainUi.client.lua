local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local roact = require(Packages:FindFirstChild("roblox_roact@1.4.4") or Packages.Roact)
local roactRodux = require(Packages:FindFirstChild("roblox_roact-rodux@0.5.1") or Packages.RoactRodux)

-- Import components and store
local store = require(script.Parent.store.store)
-- local Counter = require(script.Parent.components.Counter)
local Hotbar = require(script.Parent.components.Hotbar)
local ModalTrash = require(script.Parent.components.ModalTrash)

-- Root App Component
local function App()
    return roact.createElement("ScreenGui", {
        Name = "MyApp",
        ResetOnSpawn = false,
    }, {
        -- Counter = roact.createElement(Counter)
        Hotbar = roact.createElement(Hotbar),
        ModalTrash = roact.createElement(ModalTrash)
    })
end

-- App with Provider
local app = roact.createElement(roactRodux.StoreProvider, {
    store = store
}, {
    App = roact.createElement(App)
})

-- Mount to PlayerGui
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local handle = roact.mount(app, playerGui, "MyApp")

-- Optional: Cleanup on leaving
game.Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        roact.unmount(handle)
    end
end)