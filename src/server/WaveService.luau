-- WaveService: the tsunami. Every few minutes a warning banner goes out,
-- then a giant wave wall sweeps the map west to east. Anyone outside their
-- own base is swept back to spawn and drops any carried brainrot.
-- triggerTsunamiForTour is the TOUR.json entry point for reviewers.

local C = Color3.fromRGB
local V3 = Vector3.new
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared:WaitForChild("GameSettings"))

local WaveService = {}

local playerDataService = nil
local baseService = nil
local stealService = nil
local remotes = nil
local waveWall = nil
local waveActive = false

-- Broadcast a wave event to every client (warning / start / end).
local function broadcastWave(mode, secondsLeft)
	if not remotes then
		return
	end
	local waveEvent = remotes:FindFirstChild("WaveEvent")
	if waveEvent then
		waveEvent:FireAllClients(mode, secondsLeft)
	end
end

-- Build the wave wall once: a huge translucent blue wall at the west end.
local function buildWaveWall()
	waveWall = Instance.new("Part")
	waveWall.Name = "TsunamiWall"
	waveWall.Size = V3(6, GameSettings.WAVE_HEIGHT, 150)
	waveWall.Position = V3(-130, GameSettings.WAVE_HEIGHT / 2, 0)
	waveWall.Color = C(40, 140, 255)
	waveWall.Material = Enum.Material.Water
	waveWall.Transparency = 0.25
	waveWall.Anchored = true
	waveWall.CanCollide = false
	waveWall.Parent = workspace
end

-- Sweep the wall across the map, washing away everyone caught outside.
local function sweepWaveAcrossMap()
	local startX = -130
	local endX = 130
	local steps = 100
	for step = 1, steps do
		if not waveWall then
			return
		end
		local x = startX + (endX - startX) * (step / steps)
		waveWall.Position = V3(x, GameSettings.WAVE_HEIGHT / 2, 0)
		-- Anyone near the wall front who is outside their base gets swept.
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local state = playerDataService.getState(player)
				local insideBase = false
				if state and state.baseIndex ~= 0 then
					insideBase = baseService.isPositionInsideBase(state.baseIndex, root.Position)
				end
				if not insideBase and math.abs(root.Position.X - x) < 5 then
					WaveService.sweepPlayerToSpawn(player)
				end
			end
		end
		task.wait(GameSettings.WAVE_SWEEP_SECONDS / steps)
	end
end

-- Sweep one player back to the spawn pad and make them drop what they carry.
function WaveService.sweepPlayerToSpawn(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	if stealService and stealService.isCarrying(player) then
		stealService.dropStolenBrainrot(player, true)
	end
	root.CFrame = CFrame.new(GameSettings.SPAWN_POSITION)
	if stealService then
		stealService.notifyPlayer(player, "The TSUNAMI swept you back to spawn!")
	end
end

-- Run one full tsunami: warning, then the sweep, then the all-clear.
function WaveService.runTsunami()
	if waveActive then
		return false
	end
	waveActive = true
	if not waveWall then
		buildWaveWall()
	end
	broadcastWave("warning", GameSettings.WAVE_WARNING_SECONDS)
	task.wait(GameSettings.WAVE_WARNING_SECONDS)
	broadcastWave("start", 0)
	sweepWaveAcrossMap()
	broadcastWave("end", 0)
	if waveWall then
		waveWall.Position = V3(-130, GameSettings.WAVE_HEIGHT / 2, 0)
	end
	waveActive = false
	return true
end

-- TOUR.json entry point: reviewers can trigger the tsunami from Studio.
-- Called on the Server with one argument (ignored, any string or number).
function WaveService.triggerTsunamiForTour(_arg)
	task.spawn(function()
		WaveService.runTsunami()
	end)
	return "tsunami triggered"
end

-- Start the repeating tsunami loop. Called once from init.
function WaveService.startWaveLoop()
	task.spawn(function()
		while true do
			task.wait(GameSettings.WAVE_INTERVAL)
			local ok, err = pcall(WaveService.runTsunami)
			if not ok then
				warn("[WaveService] tsunami failed: " .. tostring(err))
			end
		end
	end)
end

-- Wire in the services this one calls (avoids require cycles).
function WaveService.injectServices(services)
	playerDataService = services.PlayerDataService
	baseService = services.BaseService
	stealService = services.StealService
	remotes = services.Remotes
end

return WaveService
