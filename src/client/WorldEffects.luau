-- WorldEffects: client-side juice for the tsunami and the canal.
-- The wave banner is driven by the server's WaveEvent; this module adds the
-- screen shake and the water tint while a wave is running, plus a gentle
-- bobbing pulse on the canal water so the lagoon feels alive.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local WorldEffects = {}

local player = nil
local camera = nil
local waveRunning = false
local shakeConnection = nil

-- Shake the camera while the wave runs.
local function startCameraShake()
	if shakeConnection then
		return
	end
	shakeConnection = RunService.RenderStepped:Connect(function()
		if not waveRunning then
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local offset = Vector3.new(
			(math.random() - 0.5) * 0.6,
			(math.random() - 0.5) * 0.6,
			0
		)
		cam.CFrame = cam.CFrame * CFrame.new(offset)
	end)
end

-- Stop the camera shake.
local function stopCameraShake()
	if shakeConnection then
		shakeConnection:Disconnect()
		shakeConnection = nil
	end
end

-- Pulse the canal water's transparency so it shimmers.
local function startCanalPulse()
	task.spawn(function()
		while true do
			task.wait(2)
			local world = workspace:FindFirstChild("BogWorld")
			if world then
				local water = world:FindFirstChild("CanalWater")
				if water then
					local goal = { Transparency = 0.15 + math.random() * 0.15 }
					local tween = TweenService:Create(water, TweenInfo.new(1.5, Enum.EasingStyle.Sine), goal)
					tween:Play()
				end
			end
		end
	end)
end

-- Hook the wave events: shake + blue tint on start, clear on end.
function WorldEffects.startWorldEffects(localPlayer, remotes)
	player = localPlayer
	camera = workspace.CurrentCamera

	remotes:WaitForChild("WaveEvent").OnClientEvent:Connect(function(mode)
		if mode == "start" then
			waveRunning = true
			startCameraShake()
		elseif mode == "end" then
			waveRunning = false
			stopCameraShake()
		end
	end)

	startCanalPulse()
end

return WorldEffects
