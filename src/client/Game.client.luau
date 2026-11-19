-- Game.client: boots the Brainrot Bog client. Waits for the shared modules
-- and the remotes, then starts the interface controller and the world effects.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Client = script.Parent

-- Wait for the server to publish its remotes before touching the UI.
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local InterfaceController = require(Client:WaitForChild("InterfaceController"))
local WorldEffects = require(Client:WaitForChild("WorldEffects"))

InterfaceController.startInterfaceController(player, playerGui, remotes)
WorldEffects.startWorldEffects(player, remotes)

print("[Brainrot Bog] Client ready for " .. player.Name)
