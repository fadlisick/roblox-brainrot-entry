-- BaseService: claims a base for each player, places brainrots on its slots,
-- owns the base lock, and frees the base when a player leaves.
-- A base is one of the 8 coloured plots WorldBuilder built around the canal.

local V3 = Vector3.new
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared:WaitForChild("GameSettings"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local BaseService = {}

local claimedBases = {} -- claimedBases[baseIndex] = player
local playerDataService = nil
local stealService = nil

-- Give a joining player the first free base. Returns the base index (0 = none).
function BaseService.claimBaseForPlayer(player)
	for i = 1, GameSettings.BASE_COUNT do
		if not claimedBases[i] then
			claimedBases[i] = player
			local state = playerDataService.getState(player)
			if state then
				state.baseIndex = i
			end
			BaseService.refreshBaseSign(i)
			return i
		end
	end
	return 0
end

-- Free a player's base when they leave; their brainrots go with them.
function BaseService.releaseBaseForPlayer(player)
	local state = playerDataService.getState(player)
	local baseIndex = state and state.baseIndex or 0
	if baseIndex == 0 then
		for i, owner in pairs(claimedBases) do
			if owner == player then
				baseIndex = i
			end
		end
	end
	if baseIndex ~= 0 then
		claimedBases[baseIndex] = nil
		BaseService.refreshBaseSign(baseIndex)
	end
end

-- Which player owns a base (nil when empty).
function BaseService.getBaseOwner(baseIndex)
	return claimedBases[baseIndex]
end

-- World position of a slot pad on a base, raised so a brainrot stands on it.
function BaseService.getSlotPadWorldPosition(baseIndex, slotIndex)
	local pad = WorldBuilder.getSlotPad(baseIndex, slotIndex)
	if not pad then
		return nil
	end
	return pad.Position + V3(0, 2.2, 0)
end

-- Place an owned brainrot on its slot: park it, add the steal prompt.
function BaseService.placeBrainrotOnBase(player, ownedRecord)
	local state = playerDataService.getState(player)
	if not state or not ownedRecord.model then
		return
	end
	local padPos = BaseService.getSlotPadWorldPosition(state.baseIndex, ownedRecord.slotIndex)
	if padPos then
		ownedRecord.model:PivotTo(CFrame.new(padPos))
	end
	-- Steal prompt: other players can pick this brainrot up when unlocked.
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "STEAL " .. ownedRecord.name
	prompt.ObjectText = ownedRecord.rarity .. " — $" .. ownedRecord.incomePerSec .. "/s"
	prompt.HoldDuration = 0.8
	prompt.MaxActivationDistance = 10
	prompt.Parent = ownedRecord.model.PrimaryPart
	prompt.Triggered:Connect(function(thief)
		if thief ~= player and stealService then
			stealService.stealBrainrotFromBase(thief, player, ownedRecord.uid)
		end
	end)
end

-- Re-park every owned brainrot after a rebirth wipe or a return.
function BaseService.reparkOwnedBrainrots(player)
	local state = playerDataService.getState(player)
	if not state then
		return
	end
	for _, record in ipairs(state.owned) do
		if record.model and record.model.Parent then
			local padPos = BaseService.getSlotPadWorldPosition(state.baseIndex, record.slotIndex)
			if padPos then
				record.model:PivotTo(CFrame.new(padPos))
			end
		end
	end
end

-- Destroy all of a player's placed brainrot models (rebirth reset).
function BaseService.clearOwnedBrainrotModels(player)
	local state = playerDataService.getState(player)
	if not state then
		return
	end
	for _, record in ipairs(state.owned) do
		if record.model and record.model.Parent then
			record.model:Destroy()
		end
		record.model = nil
	end
end

-- Refresh the owner sign over a base: owner name or EMPTY.
function BaseService.refreshBaseSign(baseIndex)
	local folder = WorldBuilder.getBaseModel(baseIndex)
	if not folder then
		return
	end
	local sign = folder:FindFirstChild("OwnerSign")
	if not sign then
		return
	end
	local gui = sign:FindFirstChildOfClass("SurfaceGui")
	if not gui then
		return
	end
	local label = gui:FindFirstChildOfClass("TextLabel")
	if not label then
		return
	end
	local owner = claimedBases[baseIndex]
	if owner then
		label.Text = "BASE " .. baseIndex .. " — " .. owner.Name:upper()
	else
		label.Text = "BASE " .. baseIndex .. " — EMPTY"
	end
end

-- Is a world position inside a given base's plot (for wave safety)?
function BaseService.isPositionInsideBase(baseIndex, position)
	local centre = GameSettings.BASE_POSITIONS[baseIndex]
	if not centre then
		return false
	end
	return math.abs(position.X - centre.X) <= 15 and math.abs(position.Z - centre.Z) <= 13
end

-- Wire in the services this one calls (avoids require cycles).
function BaseService.injectServices(services)
	playerDataService = services.PlayerDataService
	stealService = services.StealService
end

Players.PlayerRemoving:Connect(function(player)
	BaseService.releaseBaseForPlayer(player)
end)

return BaseService
