-- StealService: stealing, carrying, slapping and dropping.
-- Pick up a brainrot from another player's UNLOCKED base and carry it home:
-- it walks to your base and becomes yours. The owner can slap you with the
-- Slap tool to make you drop it, and it walks back to its slot.

local V3 = Vector3.new
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared:WaitForChild("GameSettings"))

local StealService = {}

local playerDataService = nil
local baseService = nil
local remotes = nil
local carrying = {} -- carrying[player] = { victim, record, model }

-- Move a model toward a target at a speed. Shared walk helper (same as conveyor).
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

-- Is this player currently carrying a stolen brainrot?
function StealService.isCarrying(player)
	return carrying[player] ~= nil
end

-- Steal a brainrot off another player's base. The thief carries it home.
function StealService.stealBrainrotFromBase(thief, victim, uid)
	if not playerDataService or not baseService then
		return false, "not ready"
	end
	if thief == victim then
		return false, "your own"
	end
	if carrying[thief] then
		return false, "already carrying"
	end
	local victimState = playerDataService.getState(victim)
	if not victimState then
		return false, "no victim"
	end
	if playerDataService.isBaseLocked(victim) then
		StealService.notifyPlayer(thief, "That base is LOCKED! Come back later.")
		return false, "locked"
	end
	local record = playerDataService.findOwnedByUid(victim, uid)
	if not record or not record.model then
		return false, "gone"
	end
	local thiefState = playerDataService.getState(thief)
	if not thiefState then
		return false, "no state"
	end
	local slotIndex = playerDataService.findFreeSlot(thief)
	if not slotIndex then
		StealService.notifyPlayer(thief, "Your base is FULL! Sell something first.")
		return false, "base full"
	end
	-- Take it off the victim's base and into the thief's hands.
	playerDataService.removeOwnedByUid(victim, uid)
	record.stolenFrom = victim
	carrying[thief] = { victim = victim, record = record, slotIndex = slotIndex, model = record.model }
	thiefState.carryingUid = uid
	-- Hide the steal prompt while it is carried.
	local prompt = record.model.PrimaryPart:FindFirstChild("StealPrompt")
	if prompt then
		prompt.Enabled = false
	end
	StealService.notifyPlayer(thief, "You stole " .. record.name .. "! Run home!")
	StealService.notifyPlayer(victim, thief.Name .. " stole your " .. record.name .. "! SLAP them!")
	return true, "stolen"
end

-- Carry loop: while a player carries a brainrot, it hovers above their head.
-- When they reach their own base, the steal completes and it is placed.
function StealService.startCarryLoop()
	RunService.Heartbeat:Connect(function()
		for carrier, carry in pairs(carrying) do
			local character = carrier.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root or not carry.model.Parent then
				StealService.dropStolenBrainrot(carrier, true)
			else
				local above = root.Position + V3(0, 4.5 + GameSettings.CARRY_FOLLOW_HEIGHT, 0)
				carry.model:PivotTo(CFrame.new(above))
				-- Reached home base? The steal completes.
				local state = playerDataService.getState(carrier)
				if state and state.baseIndex ~= 0 and baseService.isPositionInsideBase(state.baseIndex, root.Position) then
					StealService.completeSteal(carrier)
				end
			end
		end
	end)
end

-- Finish a steal: the brainrot joins the thief's collection on a free slot.
function StealService.completeSteal(thief)
	local carry = carrying[thief]
	if not carry then
		return
	end
	carrying[thief] = nil
	local state = playerDataService.getState(thief)
	if not state then
		return
	end
	local record = carry.record
	record.slotIndex = carry.slotIndex
	record.stolenFrom = nil
	table.insert(state.owned, record)
	state.discovered[record.catalogId] = true
	state.carryingUid = nil
	local padPos = baseService.getSlotPadWorldPosition(state.baseIndex, record.slotIndex)
	if padPos and record.model.Parent then
		record.model:PivotTo(CFrame.new(padPos))
	end
	local prompt = record.model.PrimaryPart:FindFirstChild("StealPrompt")
	if prompt then
		prompt.Enabled = true
	end
	StealService.notifyPlayer(thief, record.name .. " is YOURS now! $" .. record.incomePerSec .. "/s")
end

-- Drop a stolen brainrot: it walks back to its owner's slot.
-- `silent` skips the slap message (used when the carrier leaves or is swept).
function StealService.dropStolenBrainrot(carrier, silent)
	local carry = carrying[carrier]
	if not carry then
		return false
	end
	carrying[carrier] = nil
	local state = playerDataService.getState(carrier)
	if state then
		state.carryingUid = nil
	end
	local victim = carry.victim
	local record = carry.record
	local victimState = playerDataService.getState(victim)
	if not victimState then
		if record.model.Parent then
			record.model:Destroy()
		end
		return true
	end
	-- Give it back to the victim on its original slot (or the first free one).
	local slotIndex = record.slotIndex
	local taken = false
	for _, owned in ipairs(victimState.owned) do
		if owned.slotIndex == slotIndex then
			taken = true
		end
	end
	if taken then
		slotIndex = playerDataService.findFreeSlot(victim) or slotIndex
	end
	record.slotIndex = slotIndex
	record.stolenFrom = nil
	table.insert(victimState.owned, record)
	local prompt = record.model.PrimaryPart:FindFirstChild("StealPrompt")
	if prompt then
		prompt.Enabled = true
	end
	if not silent then
		StealService.notifyPlayer(carrier, "You DROPPED " .. record.name .. "!")
		StealService.notifyPlayer(victim, "Your " .. record.name .. " is safe!")
	end
	-- Walk it home to the victim's base.
	task.spawn(function()
		local padPos = baseService.getSlotPadWorldPosition(victimState.baseIndex, slotIndex)
		if padPos and record.model.Parent then
			walkModelTo(record.model, padPos, 8)
			if record.model.Parent then
				record.model:PivotTo(CFrame.new(padPos))
			end
		end
	end)
	return true
end

-- Slap: knock a carried brainrot out of a nearby thief's hands.
function StealService.slapPlayer(slapper, target)
	if not playerDataService then
		return false
	end
	local state = playerDataService.getState(slapper)
	if not state then
		return false
	end
	if os.clock() - state.lastSlapAt < GameSettings.SLAP_COOLDOWN then
		return false
	end
	state.lastSlapAt = os.clock()
	local slapperRoot = slapper.Character and slapper.Character:FindFirstChild("HumanoidRootPart")
	local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not slapperRoot or not targetRoot then
		return false
	end
	if (targetRoot.Position - slapperRoot.Position).Magnitude > GameSettings.SLAP_RANGE then
		return false
	end
	-- Knockback: fling the target away from the slapper.
	local direction = (targetRoot.Position - slapperRoot.Position).Unit
	targetRoot.AssemblyLinearVelocity = direction * playerDataService.getSlapKnockback(state) * 4 + V3(0, 18, 0)
	if carrying[target] then
		StealService.dropStolenBrainrot(target, false)
		StealService.notifyPlayer(slapper, "SLAP! You saved your brainrot!")
		return true
	end
	StealService.notifyPlayer(slapper, "SLAP! (They weren't carrying anything.)")
	return true
end

-- Send a toast message to one player's screen.
function StealService.notifyPlayer(player, message)
	if not remotes then
		return
	end
	local toast = remotes:FindFirstChild("ToastEvent")
	if toast then
		toast:FireClient(player, message)
	end
end

-- Drop whatever a leaving player was carrying.
function StealService.handlePlayerLeaving(player)
	if carrying[player] then
		StealService.dropStolenBrainrot(player, true)
	end
end

-- Wire in the services this one calls (avoids require cycles).
function StealService.injectServices(services)
	playerDataService = services.PlayerDataService
	baseService = services.BaseService
	remotes = services.Remotes
end

Players.PlayerRemoving:Connect(function(player)
	StealService.handlePlayerLeaving(player)
end)

return StealService
