-- ConveyorService: brainrots spawn at the west end of the canal and walk east
-- along the water. Players buy one with its ProximityPrompt; it then walks to
-- their base. Unsold brainrots despawn at the east end.

local V3 = Vector3.new
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared:WaitForChild("GameSettings"))
local BrainrotCatalog = require(Shared:WaitForChild("BrainrotCatalog"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

local ConveyorService = {}

local active = {} -- active[uid] = conveyor record
local uidCounter = 0
local baseService = nil -- set by init to avoid a require cycle
local playerDataService = nil

-- Move a model toward a target position at a speed, one heartbeat at a time.
-- Returns true when it arrives, false when the model is gone.
local function walkModelTo(model, targetPos, speed)
	while model.Parent do
		local current = model:GetPivot().Position
		local delta = targetPos - current
		local distance = delta.Magnitude
		if distance < 0.5 then
			return true
		end
		local step = math.min(distance, speed * 0.05)
		local newPos = current + delta.Unit * step
		model:PivotTo(CFrame.new(newPos, newPos + V3(1, 0, 0)))
		task.wait(0.05)
	end
	return false
end

-- Spawn one brainrot on the canal and let it walk east until bought or gone.
local function spawnBrainrotOnConveyor()
	if #active >= GameSettings.CONVEYOR_MAX_ACTIVE then
		return
	end
	local def, mutation = BrainrotCatalog.rollSpawn()
	local income = def.income * mutation.mult
	uidCounter += 1
	local uid = uidCounter
	local startPos = V3(GameSettings.CONVEYOR_START_X, GameSettings.CONVEYOR_Y, GameSettings.CONVEYOR_Z)
	local model = BrainrotFactory.buildBrainrotModel(def, mutation, income, startPos)
	model.Parent = workspace

	local record = {
		uid = uid,
		def = def,
		mutation = mutation,
		incomePerSec = income,
		model = model,
		bornAt = os.clock(),
		sold = false,
	}
	active[uid] = record

	-- Buy prompt: the player who triggers it buys this brainrot.
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "BUY " .. def.name
	prompt.ObjectText = def.rarity .. " " .. mutation.name .. " — $" .. income .. "/s"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 12
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		ConveyorService.buyBrainrotFromConveyor(player, uid)
	end)

	-- Walk east along the canal until bought, despawned, or at the end.
	task.spawn(function()
		local endPos = V3(GameSettings.CONVEYOR_END_X, GameSettings.CONVEYOR_Y, GameSettings.CONVEYOR_Z)
		local arrived = walkModelTo(model, endPos, GameSettings.CONVEYOR_WALK_SPEED)
		if not arrived then
			return -- bought mid-walk; the buyer owns the walk now
		end
		ConveyorService.despawnBrainrot(uid)
	end)

	-- Hard despawn timer for brainrots nobody buys.
	task.delay(GameSettings.CONVEYOR_DESPAWN_SECONDS, function()
		if active[uid] and not active[uid].sold then
			ConveyorService.despawnBrainrot(uid)
		end
	end)
end

-- Remove a conveyor brainrot from the world.
function ConveyorService.despawnBrainrot(uid)
	local record = active[uid]
	if not record then
		return
	end
	active[uid] = nil
	if record.model and record.model.Parent then
		record.model:Destroy()
	end
end

-- Buy a conveyor brainrot: pay, claim a base slot, walk it home, place it.
function ConveyorService.buyBrainrotFromConveyor(player, uid)
	local record = active[uid]
	if not record or record.sold then
		return false, "gone"
	end
	if not playerDataService then
		return false, "not ready"
	end
	local state = playerDataService.getState(player)
	if not state then
		return false, "no state"
	end
	if state.money < record.def.cost then
		return false, "not enough money"
	end
	local slotIndex = playerDataService.findFreeSlot(player)
	if not slotIndex then
		return false, "base full"
	end
	record.sold = true
	active[uid] = nil
	if not playerDataService.spendMoney(player, record.def.cost) then
		record.sold = false
		active[uid] = record
		return false, "not enough money"
	end
	local owned = playerDataService.addOwnedBrainrot(player, record.def, record.mutation, record.incomePerSec, slotIndex)
	owned.model = record.model
	-- Remove the buy prompt; it is owned now.
	local prompt = record.model.PrimaryPart:FindFirstChild("BuyPrompt")
	if prompt then
		prompt:Destroy()
	end
	-- Walk it from the canal to its slot, then hand it to BaseService.
	task.spawn(function()
		local pad = baseService.getSlotPadWorldPosition(state.baseIndex, slotIndex)
		if pad then
			walkModelTo(record.model, pad, GameSettings.CONVEYOR_WALK_SPEED * 2)
		end
		-- The buyer may have left mid-walk; only place it if they are still here.
		if record.model.Parent and playerDataService.getState(player) then
			baseService.placeBrainrotOnBase(player, owned)
		elseif record.model.Parent then
			record.model:Destroy()
		end
	end)
	return true, "bought " .. record.def.name
end

-- How many brainrots are walking the canal right now.
function ConveyorService.getActiveCount()
	local count = 0
	for _ in pairs(active) do
		count += 1
	end
	return count
end

-- Start the spawn loop. Called once from init.
function ConveyorService.startConveyorLoop()
	task.spawn(function()
		while true do
			task.wait(GameSettings.CONVEYOR_SPAWN_INTERVAL)
			local ok, err = pcall(spawnBrainrotOnConveyor)
			if not ok then
				warn("[ConveyorService] spawn failed: " .. tostring(err))
			end
		end
	end)
end

-- Wire in the services this one calls (avoids require cycles).
function ConveyorService.injectServices(services)
	baseService = services.BaseService
	playerDataService = services.PlayerDataService
end

return ConveyorService
