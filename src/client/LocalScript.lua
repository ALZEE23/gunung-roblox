local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local roact = require(Packages:WaitForChild("roact"))
local rodux = require(Packages:WaitForChild("rodux"))

local App = require(script.Parent.ui.App)

local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local handle = roact.mount(roact.createElement(App), playerGui, "MainUI")
