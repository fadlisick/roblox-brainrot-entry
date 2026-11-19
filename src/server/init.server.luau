-- init.server: boots Brainrot Bog. Creates the remotes, builds the world,
-- wires every service together, claims bases for joining players, hands out
-- the Slap tool, and starts the conveyor, income and tsunami loops.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared:WaitForChild("GameSettings"))

local WorldBuilder = require(script:WaitForChild("WorldBuilder"))
local BrainrotFactory = require(script:WaitForChild("BrainrotFactory"))
local PlayerDataService = require(script:WaitForChild("PlayerDataService"))
local BaseService = require(script:WaitForChild("BaseService"))
local ConveyorService = require(script:WaitForChild("ConveyorService"))
local IncomeService = require(script:WaitForChild("IncomeService"))
local StealService = require(script:WaitForChild("StealService"))
local WaveService = require(script:WaitForChild("WaveService"))
local ShopService = require(script:WaitForChild("ShopService"))

print("[Brainrot Bog] Booting the bog...")

-- Remotes folder: every RemoteEvent the client and server share.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local remoteNames = {
	"BuyBrainrot", "SellBrainrot", "BuyUpgrade", "BuySlot", "BuyLock",
	"DoRebirth", "StealBrainrot", "SlapHit", "ClientSync", "WaveEvent", "ToastEvent",
}
for _, name in ipairs(remoteNames) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
end

-- Build the 3D world first: island, canal, bases, trees, signs.
WorldBuilder.buildWorld()
print("[Brainrot Bog] World built: 8 bases around the canal.")

-- Wire services together (each inject avoids a require cycle).
local services = {
	PlayerDataService = PlayerDataService,
	BaseService = BaseService,
	ConveyorService = ConveyorService,
	IncomeService = IncomeService,
	StealService = StealService,
	WaveService = WaveService,
	ShopService = ShopService,
	Remotes = remotes,
}
BaseService.injectServices(services)
ConveyorService.injectServices(services)
IncomeService.injectServices(services)
StealService.injectServices(services)
WaveService.injectServices(services)
ShopService.injectServices(services)

ShopService.bindRemotes()

-- Slap tool: every player gets one, so owners can defend their base.
local function giveSlapTool(player)
	local tool = Instance.new("Tool")
	tool.Name = "Slap"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 0.4, 3)
	handle.Color = Color3.fromRGB(255, 220, 90)
	handle.Material = Enum.Material.SmoothPlastic
	handle.Parent = tool
	tool.Activated:Connect(function()
		-- Slap the nearest other player in range.
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local nearest = nil
		local nearestDistance = GameSettings.SLAP_RANGE
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				local otherRoot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
				if otherRoot then
					local distance = (otherRoot.Position - root.Position).Magnitude
					if distance <= nearestDistance then
						nearest = other
						nearestDistance = distance
					end
				end
			end
		end
		if nearest then
			StealService.slapPlayer(player, nearest)
		end
	end)
	tool.Parent = player:WaitForChild("Backpack")
end

-- Register a joining player: state, base, spawn point, slap tool.
local function onPlayerAdded(player)
	PlayerDataService.registerPlayer(player)
	local baseIndex = BaseService.claimBaseForPlayer(player)
	print("[Brainrot Bog] " .. player.Name .. " joined, base " .. baseIndex)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		giveSlapTool(player)
		local root = character:WaitForChild("HumanoidRootPart")
		root.CFrame = CFrame.new(GameSettings.SPAWN_POSITION)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Start the loops: conveyor spawns, income ticks, tsunami timer, carry loop.
ConveyorService.startConveyorLoop()
IncomeService.startIncomeLoop()
WaveService.startWaveLoop()
StealService.startCarryLoop()

print("[Brainrot Bog] Ready! 48 brainrots, 8 bases, tsunami every "
	.. GameSettings.WAVE_INTERVAL .. "s. Welcome to the bog.")
