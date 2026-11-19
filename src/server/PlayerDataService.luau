-- PlayerDataService: the single source of truth for player state.
-- Money, owned brainrots, rebirths, upgrades, base assignment, index progress.
-- Every other service reads and writes state through here, never its own copy.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared:WaitForChild("GameSettings"))
local BrainrotCatalog = require(Shared:WaitForChild("BrainrotCatalog"))

local PlayerDataService = {}

local states = {} -- states[player] = state table
local uidCounter = 0

-- Create a fresh state for a joining player.
local function newState(player)
	return {
		player = player,
		money = GameSettings.START_MONEY,
		rebirths = 0,
		baseIndex = 0, -- assigned by BaseService
		slots = GameSettings.BASE_START_SLOTS,
		slotsBought = 0,
		locksBought = 0,
		lockUntil = 0,
		lockCooldownUntil = 0,
		upgrades = { WalkSpeed = 0, SlapPower = 0, IncomeBoost = 0 },
		owned = {}, -- list of owned brainrot records
		discovered = {}, -- discovered[catalogId] = true (Index progress, kept on rebirth)
		carryingUid = nil,
		lastSlapAt = 0,
	}
end

-- Income multiplier from rebirths and the IncomeBoost upgrade.
function PlayerDataService.getIncomeMultiplier(state)
	local mult = GameSettings.REBIRTH_MONEY_MULTIPLIER ^ state.rebirths
	mult *= 1 + 0.25 * state.upgrades.IncomeBoost
	return mult
end

-- Total $/sec across all owned brainrots, after multipliers.
function PlayerDataService.getIncomePerSec(state)
	local total = 0
	for _, record in ipairs(state.owned) do
		total += record.incomePerSec
	end
	return total * PlayerDataService.getIncomeMultiplier(state)
end

-- Walk speed multiplier from the WalkSpeed upgrade.
function PlayerDataService.getWalkSpeedMultiplier(state)
	return 1 + 0.15 * state.upgrades.WalkSpeed
end

-- Slap knockback distance from the SlapPower upgrade.
function PlayerDataService.getSlapKnockback(state)
	return 8 + 6 * state.upgrades.SlapPower
end

-- Rebirth price for this state.
function PlayerDataService.getRebirthCost(state)
	return GameSettings.REBIRTH_BASE_COST * (2 ^ state.rebirths)
end

-- Next extra-slot price for this state.
function PlayerDataService.getNextSlotCost(state)
	return GameSettings.BASE_SLOT_COST * (2 ^ state.slotsBought)
end

-- Next base-lock price for this state.
function PlayerDataService.getNextLockCost(state)
	return GameSettings.BASE_LOCK_COST * (2 ^ state.locksBought)
end

-- Upgrade price for the next level of an upgrade.
function PlayerDataService.getUpgradeCost(upgradeKey, currentLevel)
	local def = GameSettings.UPGRADES[upgradeKey]
	if not def then
		return nil
	end
	return def.baseCost * (2 ^ currentLevel)
end

-- Register a player when they join. Returns their state.
function PlayerDataService.registerPlayer(player)
	local state = newState(player)
	states[player] = state
	return state
end

-- Drop a player's state when they leave (their base is freed by BaseService).
function PlayerDataService.removePlayer(player)
	states[player] = nil
end

-- Get a player's state, or nil if they are not registered.
function PlayerDataService.getState(player)
	return states[player]
end

-- Add money (income ticks, sales). Returns the new balance.
function PlayerDataService.addMoney(player, amount)
	local state = states[player]
	if not state then
		return 0
	end
	state.money += amount
	return state.money
end

-- Spend money if the player can afford it. Returns true on success.
function PlayerDataService.spendMoney(player, amount)
	local state = states[player]
	if not state or state.money < amount then
		return false
	end
	state.money -= amount
	return true
end

-- Record a newly bought brainrot. Returns the owned record.
function PlayerDataService.addOwnedBrainrot(player, def, mutation, incomePerSec, slotIndex)
	local state = states[player]
	if not state then
		return nil
	end
	uidCounter += 1
	local record = {
		uid = uidCounter,
		catalogId = def.id,
		name = def.name,
		rarity = def.rarity,
		mutation = mutation.name,
		incomePerSec = incomePerSec,
		cost = def.cost,
		slotIndex = slotIndex,
		model = nil, -- set by BaseService once placed
		stolenFrom = nil, -- set by StealService while carried
	}
	table.insert(state.owned, record)
	state.discovered[def.id] = true
	return record
end

-- Find an owned record by uid.
function PlayerDataService.findOwnedByUid(player, uid)
	local state = states[player]
	if not state then
		return nil
	end
	for _, record in ipairs(state.owned) do
		if record.uid == uid then
			return record
		end
	end
	return nil
end

-- Remove an owned record by uid (sell or rebirth). Returns the record.
function PlayerDataService.removeOwnedByUid(player, uid)
	local state = states[player]
	if not state then
		return nil
	end
	for i, record in ipairs(state.owned) do
		if record.uid == uid then
			table.remove(state.owned, i)
			return record
		end
	end
	return nil
end

-- How many brainrots this player owns.
function PlayerDataService.getOwnedCount(player)
	local state = states[player]
	if not state then
		return 0
	end
	return #state.owned
end

-- First free slot index on this player's base, or nil when full.
function PlayerDataService.findFreeSlot(player)
	local state = states[player]
	if not state then
		return nil
	end
	local used = {}
	for _, record in ipairs(state.owned) do
		used[record.slotIndex] = true
	end
	for slot = 1, state.slots do
		if not used[slot] then
			return slot
		end
	end
	return nil
end

-- Is this player's base locked right now?
function PlayerDataService.isBaseLocked(player)
	local state = states[player]
	if not state then
		return false
	end
	return os.time() < state.lockUntil
end

-- Seconds left on the base lock (0 when unlocked).
function PlayerDataService.getLockSecondsLeft(player)
	local state = states[player]
	if not state then
		return 0
	end
	return math.max(0, state.lockUntil - os.time())
end

-- Buy a base lock. Returns true on success.
function PlayerDataService.buyBaseLock(player)
	local state = states[player]
	if not state then
		return false
	end
	if os.time() < state.lockCooldownUntil then
		return false
	end
	local cost = PlayerDataService.getNextLockCost(state)
	if not PlayerDataService.spendMoney(player, cost) then
		return false
	end
	state.lockUntil = os.time() + GameSettings.BASE_LOCK_DURATION
	state.lockCooldownUntil = state.lockUntil + GameSettings.BASE_LOCK_COOLDOWN
	state.locksBought += 1
	return true
end

-- Buy an extra base slot. Returns true on success.
function PlayerDataService.buyExtraSlot(player)
	local state = states[player]
	if not state then
		return false
	end
	if state.slots >= GameSettings.BASE_MAX_SLOTS then
		return false
	end
	local cost = PlayerDataService.getNextSlotCost(state)
	if not PlayerDataService.spendMoney(player, cost) then
		return false
	end
	state.slots += 1
	state.slotsBought += 1
	return true
end

-- Buy one level of an upgrade. Returns true on success.
function PlayerDataService.buyUpgrade(player, upgradeKey)
	local state = states[player]
	local def = GameSettings.UPGRADES[upgradeKey]
	if not state or not def then
		return false
	end
	local level = state.upgrades[upgradeKey] or 0
	if level >= def.maxLevel then
		return false
	end
	local cost = PlayerDataService.getUpgradeCost(upgradeKey, level)
	if not PlayerDataService.spendMoney(player, cost) then
		return false
	end
	state.upgrades[upgradeKey] = level + 1
	return true
end

-- Rebirth: spend money + owned count, reset money and brainrots, +1 rebirth.
-- Keeps the Index (discovered) and upgrades. Returns true on success.
function PlayerDataService.doRebirth(player)
	local state = states[player]
	if not state then
		return false, "no state"
	end
	if #state.owned < GameSettings.REBIRTH_MIN_BRAINROTS then
		return false, "need " .. GameSettings.REBIRTH_MIN_BRAINROTS .. " brainrots"
	end
	local cost = PlayerDataService.getRebirthCost(state)
	if state.money < cost then
		return false, "need " .. cost
	end
	state.money = GameSettings.START_MONEY
	state.rebirths += 1
	state.owned = {}
	state.carryingUid = nil
	return true, "rebirth " .. state.rebirths
end

-- Sell an owned brainrot for half its cost. Returns the refund or nil.
function PlayerDataService.sellBrainrot(player, uid)
	local state = states[player]
	if not state then
		return nil
	end
	local record = PlayerDataService.findOwnedByUid(player, uid)
	if not record then
		return nil
	end
	PlayerDataService.removeOwnedByUid(player, uid)
	local refund = math.floor(record.cost * GameSettings.SELL_FRACTION)
	state.money += refund
	return refund
end

-- A snapshot of one player's state for the client HUD (no models, no functions).
function PlayerDataService.buildClientSnapshot(player)
	local state = states[player]
	if not state then
		return nil
	end
	local ownedSummary = {}
	for _, record in ipairs(state.owned) do
		table.insert(ownedSummary, {
			uid = record.uid,
			catalogId = record.catalogId,
			name = record.name,
			rarity = record.rarity,
			mutation = record.mutation,
			incomePerSec = record.incomePerSec,
			cost = record.cost,
			slotIndex = record.slotIndex,
		})
	end
	return {
		money = math.floor(state.money),
		incomePerSec = math.floor(PlayerDataService.getIncomePerSec(state)),
		rebirths = state.rebirths,
		rebirthCost = PlayerDataService.getRebirthCost(state),
		rebirthMultiplier = PlayerDataService.getIncomeMultiplier(state),
		baseIndex = state.baseIndex,
		slots = state.slots,
		slotsBought = state.slotsBought,
		nextSlotCost = PlayerDataService.getNextSlotCost(state),
		lockSecondsLeft = PlayerDataService.getLockSecondsLeft(state),
		lockCooldownLeft = math.max(0, state.lockCooldownUntil - os.time()),
		nextLockCost = PlayerDataService.getNextLockCost(state),
		upgrades = {
			WalkSpeed = state.upgrades.WalkSpeed,
			SlapPower = state.upgrades.SlapPower,
			IncomeBoost = state.upgrades.IncomeBoost,
		},
		owned = ownedSummary,
		discovered = state.discovered,
		carryingUid = state.carryingUid,
	}
end

-- Richest players, for the leaderboard board. Returns up to `count` entries.
function PlayerDataService.getRichestPlayers(count)
	local ranked = {}
	for player, state in pairs(states) do
		table.insert(ranked, { name = player.Name, money = math.floor(state.money), rebirths = state.rebirths })
	end
	table.sort(ranked, function(a, b)
		return a.money > b.money
	end)
	local top = {}
	for i = 1, math.min(count, #ranked) do
		table.insert(top, ranked[i])
	end
	return top
end

Players.PlayerRemoving:Connect(function(player)
	PlayerDataService.removePlayer(player)
end)

return PlayerDataService
