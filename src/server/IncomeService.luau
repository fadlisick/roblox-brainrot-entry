-- IncomeService: ticks every owned brainrot's $/sec into its owner's money,
-- once a second, server-side. Also pushes a fresh client snapshot and keeps
-- the richest-player leaderboard board up to date.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IncomeService = {}

local playerDataService = nil
local remotes = nil
local boardBodyLabel = nil

-- One tick: pay every registered player their income for this second.
local function tickIncome()
	for _, player in ipairs(Players:GetPlayers()) do
		local state = playerDataService.getState(player)
		if state then
			local income = playerDataService.getIncomePerSec(state)
			if income > 0 then
				playerDataService.addMoney(player, income)
			end
		end
	end
end

-- Push a fresh HUD snapshot to every player.
local function pushSnapshots()
	if not remotes then
		return
	end
	local sync = remotes:FindFirstChild("ClientSync")
	if not sync then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local snapshot = playerDataService.buildClientSnapshot(player)
		if snapshot then
			sync:FireClient(player, snapshot)
		end
	end
end

-- Rewrite the in-world leaderboard board with the richest players.
local function refreshLeaderboardBoard()
	if not boardBodyLabel then
		return
	end
	local top = playerDataService.getRichestPlayers(5)
	if #top == 0 then
		boardBodyLabel.Text = "No players yet..."
		return
	end
	local lines = {}
	for i, entry in ipairs(top) do
		table.insert(lines, i .. ". " .. entry.name .. " — $" .. entry.money)
	end
	boardBodyLabel.Text = table.concat(lines, "\n")
end

-- Find the board's body label once the world exists.
local function findBoardLabel()
	local world = workspace:FindFirstChild("BogWorld")
	if not world then
		return
	end
	local board = world:FindFirstChild("LeaderboardBoard")
	if not board then
		return
	end
	local gui = board:FindFirstChildOfClass("SurfaceGui")
	if not gui then
		return
	end
	boardBodyLabel = gui:FindFirstChild("BoardBody")
end

-- Start the 1-second income loop and the 5-second board refresh.
function IncomeService.startIncomeLoop()
	findBoardLabel()
	task.spawn(function()
		while true do
			task.wait(1)
			local ok, err = pcall(function()
				tickIncome()
				pushSnapshots()
			end)
			if not ok then
				warn("[IncomeService] tick failed: " .. tostring(err))
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(5)
			pcall(refreshLeaderboardBoard)
		end
	end)
end

-- Wire in the services this one calls (avoids require cycles).
function IncomeService.injectServices(services)
	playerDataService = services.PlayerDataService
	remotes = services.Remotes
end

return IncomeService
