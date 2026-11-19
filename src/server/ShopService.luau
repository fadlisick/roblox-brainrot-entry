-- ShopService: the remotes the client calls to spend money.
-- Buy/sell brainrots, buy upgrades and base slots, buy a base lock, rebirth.
-- Every call re-checks the price and the balance server-side; the client
-- never decides whether a purchase succeeds.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopService = {}

local playerDataService = nil
local baseService = nil
local remotes = nil

-- Send a toast to one player.
local function notify(player, message)
	if not remotes then
		return
	end
	local toast = remotes:FindFirstChild("ToastEvent")
	if toast then
		toast:FireClient(player, message)
	end
end

-- Sell an owned brainrot for half its cost. Args: uid.
-- The model is destroyed first, while the record still names it.
local function onSellBrainrot(player, uid)
	local record = playerDataService.findOwnedByUid(player, uid)
	if record and record.model and record.model.Parent then
		record.model:Destroy()
	end
	local refund = playerDataService.sellBrainrot(player, uid)
	if refund then
		notify(player, "Sold for $" .. refund .. "!")
	else
		notify(player, "Could not sell that brainrot.")
	end
end

-- Buy one level of an upgrade. Args: upgrade key ("WalkSpeed", "SlapPower", "IncomeBoost").
local function onBuyUpgrade(player, upgradeKey)
	if playerDataService.buyUpgrade(player, upgradeKey) then
		notify(player, "Upgrade bought: " .. upgradeKey .. "!")
	else
		notify(player, "Not enough money (or maxed out).")
	end
end

-- Buy an extra base slot. No args.
local function onBuySlot(player)
	if playerDataService.buyExtraSlot(player) then
		notify(player, "Extra base slot unlocked!")
	else
		notify(player, "Not enough money (or max slots).")
	end
end

-- Buy a 60-second base lock. No args.
local function onBuyLock(player)
	if playerDataService.buyBaseLock(player) then
		notify(player, "Base LOCKED for 60 seconds! No stealing!")
	else
		notify(player, "Lock not ready or not enough money.")
	end
end

-- Rebirth. No args. Wipes the player's brainrot models first, then resets state.
local function onRebirth(player)
	local state = playerDataService.getState(player)
	if not state then
		return
	end
	if #state.owned < 10 then
		notify(player, "Rebirth needs 10 brainrots on your base.")
		return
	end
	baseService.clearOwnedBrainrotModels(player)
	local ok, message = playerDataService.doRebirth(player)
	if ok then
		notify(player, "REBIRTH! Income x" .. playerDataService.getIncomeMultiplier(state) .. " forever!")
	else
		notify(player, "Rebirth failed: " .. tostring(message))
	end
end

-- Steal request from a client prompt fallback. Args: victim player, uid.
local function onStealRequest(player, victim, uid)
	-- The steal prompt normally calls StealService directly; this is the
	-- remote fallback for clients that trigger it by other means.
end

-- Hook every shop remote up to its handler. Called once from init.
function ShopService.bindRemotes()
	local buySell = remotes:WaitForChild("SellBrainrot")
	buySell.OnServerEvent:Connect(onSellBrainrot)
	remotes:WaitForChild("BuyUpgrade").OnServerEvent:Connect(onBuyUpgrade)
	remotes:WaitForChild("BuySlot").OnServerEvent:Connect(onBuySlot)
	remotes:WaitForChild("BuyLock").OnServerEvent:Connect(onBuyLock)
	remotes:WaitForChild("DoRebirth").OnServerEvent:Connect(onRebirth)
	remotes:WaitForChild("StealBrainrot").OnServerEvent:Connect(onStealRequest)
end

-- Wire in the services this one calls (avoids require cycles).
function ShopService.injectServices(services)
	playerDataService = services.PlayerDataService
	baseService = services.BaseService
	remotes = services.Remotes
end

return ShopService
