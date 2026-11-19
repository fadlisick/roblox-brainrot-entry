-- InterfaceController: every ScreenGui element of Brainrot Bog.
-- Top bar (money, $/sec, rebirth) centred so it stays clear of the Roblox
-- menu buttons in the top-left corner; Shop / Index / Lock / Rebirth buttons;
-- the tsunami warning banner; toast messages; the Index grid of all 48
-- brainrots with owned/discovered state; the shop panel with upgrades, extra
-- slots and selling. All money comes from the server's ClientSync snapshots.

local C = Color3.fromRGB
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotCatalog = require(Shared:WaitForChild("BrainrotCatalog"))
local FormatMoney = require(Shared:WaitForChild("FormatMoney"))
local GameSettings = require(Shared:WaitForChild("GameSettings"))

local InterfaceController = {}

local player = nil
local remotes = nil
local gui = nil
local moneyLabel = nil
local incomeLabel = nil
local rebirthLabel = nil
local lockLabel = nil
local waveBanner = nil
local waveBannerLabel = nil
local toastLabel = nil
local toastUntil = 0
local indexPanel = nil
local shopPanel = nil
local indexGrid = nil
local shopList = nil
local latestSnapshot = nil

-- Small helper: a TextLabel with the house font.
local function makeLabel(name, parent, text, size, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = size
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.Parent = parent
	return label
end

-- Small helper: a rounded button.
local function makeButton(name, parent, text, size, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = C(35, 35, 55)
	button.Text = text
	button.TextColor3 = C(255, 255, 255)
	button.TextSize = 20
	button.Font = Enum.Font.GothamBold
	button.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	button.Parent = parent
	return button
end

-- Show a short toast message at the bottom of the screen for 4 seconds.
local function showToast(message)
	toastLabel.Text = message
	toastLabel.Visible = true
	toastUntil = os.clock() + 4
end

-- Build the top bar: money, income, rebirth — centred, clear of the menu.
local function buildTopBar()
	local bar = Instance.new("Frame")
	bar.Name = "TopBar"
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 52)
	bar.Size = UDim2.fromOffset(560, 56)
	bar.BackgroundColor3 = C(20, 20, 32)
	bar.BackgroundTransparency = 0.15
	bar.BorderSizePixel = 0
	bar.Parent = gui

	moneyLabel = makeLabel("MoneyLabel", bar, "$100", 28, C(120, 255, 140))
	moneyLabel.Position = UDim2.new(0.03, 0, 0, 0)
	moneyLabel.Size = UDim2.new(0.4, 0, 1, 0)
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left

	incomeLabel = makeLabel("IncomeLabel", bar, "$0/s", 22, C(255, 220, 90))
	incomeLabel.Position = UDim2.new(0.43, 0, 0, 0)
	incomeLabel.Size = UDim2.new(0.3, 0, 1, 0)
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Left

	rebirthLabel = makeLabel("RebirthLabel", bar, "Rebirth 0 (x1)", 22, C(150, 220, 255))
	rebirthLabel.Position = UDim2.new(0.73, 0, 0, 0)
	rebirthLabel.Size = UDim2.new(0.24, 0, 1, 0)
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Right
end

-- Build the row of action buttons under the top bar.
local function buildActionButtons()
	local row = Instance.new("Frame")
	row.Name = "ActionRow"
	row.AnchorPoint = Vector2.new(0.5, 0)
	row.Position = UDim2.new(0.5, 0, 0, 118)
	row.Size = UDim2.fromOffset(560, 44)
	row.BackgroundTransparency = 1
	row.Parent = gui

	local shopButton = makeButton("ShopButton", row, "SHOP", UDim2.new(0.24, 0, 1, 0), UDim2.new(0, 0, 0, 0))
	local indexButton = makeButton("IndexButton", row, "INDEX (48)", UDim2.new(0.24, 0, 1, 0), UDim2.new(0.253, 0, 0, 0))
	local lockButton = makeButton("LockButton", row, "LOCK BASE", UDim2.new(0.24, 0, 1, 0), UDim2.new(0.506, 0, 0, 0))
	local rebirthButton = makeButton("RebirthButton", row, "REBIRTH", UDim2.new(0.24, 0, 1, 0), UDim2.new(0.759, 0, 0, 0))

	shopButton.MouseButton1Click:Connect(function()
		shopPanel.Visible = not shopPanel.Visible
		indexPanel.Visible = false
		InterfaceController.refreshShopPanel()
	end)
	indexButton.MouseButton1Click:Connect(function()
		indexPanel.Visible = not indexPanel.Visible
		shopPanel.Visible = false
		InterfaceController.refreshIndexPanel()
	end)
	lockButton.MouseButton1Click:Connect(function()
		remotes:WaitForChild("BuyLock"):FireServer()
	end)
	rebirthButton.MouseButton1Click:Connect(function()
		remotes:WaitForChild("DoRebirth"):FireServer()
	end)
end

-- Build the base-lock status label under the buttons.
local function buildLockLabel()
	lockLabel = makeLabel("LockLabel", gui, "", 18, C(255, 140, 140))
	lockLabel.AnchorPoint = Vector2.new(0.5, 0)
	lockLabel.Position = UDim2.new(0.5, 0, 0, 168)
	lockLabel.Size = UDim2.fromOffset(560, 24)
	lockLabel.TextXAlignment = Enum.TextXAlignment.Center
end

-- Build the tsunami warning banner (hidden until a wave is coming).
local function buildWaveBanner()
	waveBanner = Instance.new("Frame")
	waveBanner.Name = "WaveBanner"
	waveBanner.AnchorPoint = Vector2.new(0.5, 0)
	waveBanner.Position = UDim2.new(0.5, 0, 0, 200)
	waveBanner.Size = UDim2.fromOffset(640, 64)
	waveBanner.BackgroundColor3 = C(20, 80, 180)
	waveBanner.BackgroundTransparency = 0.1
	waveBanner.BorderSizePixel = 0
	waveBanner.Visible = false
	waveBanner.Parent = gui

	waveBannerLabel = makeLabel("WaveBannerLabel", waveBanner, "TSUNAMI INCOMING!", 30, C(255, 255, 255))
	waveBannerLabel.Size = UDim2.fromScale(1, 1)
	waveBannerLabel.Font = Enum.Font.GothamBlack
end

-- Build the toast label at the bottom of the screen.
local function buildToast()
	toastLabel = makeLabel("ToastLabel", gui, "", 20, C(255, 255, 255))
	toastLabel.AnchorPoint = Vector2.new(0.5, 1)
	toastLabel.Position = UDim2.new(0.5, 0, 1, -24)
	toastLabel.Size = UDim2.fromOffset(700, 32)
	toastLabel.BackgroundColor3 = C(20, 20, 32)
	toastLabel.BackgroundTransparency = 0.2
	toastLabel.Visible = false
end

-- Build the Index panel: a scrolling grid of all 48 brainrots.
local function buildIndexPanel()
	indexPanel = Instance.new("Frame")
	indexPanel.Name = "IndexPanel"
	indexPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	indexPanel.Position = UDim2.fromScale(0.5, 0.5)
	indexPanel.Size = UDim2.fromOffset(640, 460)
	indexPanel.BackgroundColor3 = C(25, 25, 40)
	indexPanel.Visible = false
	indexPanel.Parent = gui

	local title = makeLabel("IndexTitle", indexPanel, "BRAINROT INDEX — 48 CHARACTERS", 24, C(255, 255, 255))
	title.Position = UDim2.new(0, 0, 0, 8)
	title.Size = UDim2.new(1, 0, 0, 32)

	local closeButton = makeButton("CloseIndex", indexPanel, "X", UDim2.fromOffset(40, 32), UDim2.new(1, -48, 0, 8))
	closeButton.MouseButton1Click:Connect(function()
		indexPanel.Visible = false
	end)

	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "IndexScroller"
	scroller.Position = UDim2.new(0, 8, 0, 48)
	scroller.Size = UDim2.new(1, -16, 1, -56)
	scroller.BackgroundTransparency = 1
	scroller.ScrollBarThickness = 6
	scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.Parent = indexPanel

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(145, 86)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.Parent = scroller
	indexGrid = scroller
end

-- Build the Shop panel: upgrades, extra slots, owned brainrots to sell.
local function buildShopPanel()
	shopPanel = Instance.new("Frame")
	shopPanel.Name = "ShopPanel"
	shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	shopPanel.Position = UDim2.fromScale(0.5, 0.5)
	shopPanel.Size = UDim2.fromOffset(640, 460)
	shopPanel.BackgroundColor3 = C(25, 25, 40)
	shopPanel.Visible = false
	shopPanel.Parent = gui

	local title = makeLabel("ShopTitle", shopPanel, "SHOP — UPGRADES & SELL", 24, C(255, 255, 255))
	title.Position = UDim2.new(0, 0, 0, 8)
	title.Size = UDim2.new(1, 0, 0, 32)

	local closeButton = makeButton("CloseShop", shopPanel, "X", UDim2.fromOffset(40, 32), UDim2.new(1, -48, 0, 8))
	closeButton.MouseButton1Click:Connect(function()
		shopPanel.Visible = false
	end)

	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "ShopScroller"
	scroller.Position = UDim2.new(0, 8, 0, 48)
	scroller.Size = UDim2.new(1, -16, 1, -56)
	scroller.BackgroundTransparency = 1
	scroller.ScrollBarThickness = 6
	scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.Parent = shopPanel

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.Parent = scroller
	shopList = scroller
end

-- One row in the shop panel: label on the left, buy button on the right.
local function addShopRow(text, buttonText, onClick)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = C(40, 40, 60)
	row.BorderSizePixel = 0
	row.Parent = shopList

	local label = makeLabel("RowLabel", row, text, 17, C(255, 255, 255))
	label.Position = UDim2.new(0, 10, 0, 0)
	label.Size = UDim2.new(0.68, -10, 1, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left

	local button = makeButton("RowButton", row, buttonText, UDim2.new(0.3, 0, 0, 34), UDim2.new(0.69, 0, 0, 5))
	button.TextSize = 16
	button.MouseButton1Click:Connect(onClick)
	return row
end

-- Refresh the Index grid from the latest snapshot's discovered set.
function InterfaceController.refreshIndexPanel()
	if not indexGrid then
		return
	end
	for _, child in ipairs(indexGrid:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local discovered = latestSnapshot and latestSnapshot.discovered or {}
	local ownedIds = {}
	if latestSnapshot then
		for _, owned in ipairs(latestSnapshot.owned) do
			ownedIds[owned.catalogId] = true
		end
	end
	for _, def in ipairs(BrainrotCatalog.BRAINROTS) do
		local cell = Instance.new("Frame")
		cell.BackgroundColor3 = C(40, 40, 60)
		cell.BorderSizePixel = 0
		cell.Parent = indexGrid

		local rarityInfo = BrainrotCatalog.RARITIES[def.rarity]
		local nameLabel = makeLabel("CellName", cell, def.name, 14, C(255, 255, 255))
		nameLabel.Position = UDim2.new(0, 4, 0, 4)
		nameLabel.Size = UDim2.new(1, -8, 0, 34)
		nameLabel.TextWrapped = true
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left

		local stateText = "???"
		local stateColor = C(150, 150, 160)
		if ownedIds[def.id] then
			stateText = "OWNED"
			stateColor = C(120, 255, 140)
		elseif discovered[tostring(def.id)] or discovered[def.id] then
			stateText = "SEEN"
			stateColor = C(255, 220, 90)
		end
		local rarityLabel = makeLabel("CellRarity", cell, def.rarity .. " — " .. stateText, 13, rarityInfo.color)
		rarityLabel.Position = UDim2.new(0, 4, 0, 40)
		rarityLabel.Size = UDim2.new(1, -8, 0, 18)
		rarityLabel.TextXAlignment = Enum.TextXAlignment.Left

		local incomeText = FormatMoney.formatRate(def.income) .. "  •  " .. FormatMoney.format(def.cost)
		local incomeLabel = makeLabel("CellIncome", cell, incomeText, 13, stateColor)
		incomeLabel.Position = UDim2.new(0, 4, 0, 60)
		incomeLabel.Size = UDim2.new(1, -8, 0, 18)
		incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
	end
end

-- Refresh the Shop panel from the latest snapshot.
function InterfaceController.refreshShopPanel()
	if not shopList then
		return
	end
	for _, child in ipairs(shopList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	if not latestSnapshot then
		return
	end
	-- Upgrades.
	for key, def in pairs(GameSettings.UPGRADES) do
		local level = latestSnapshot.upgrades[key] or 0
		local cost = def.baseCost * (2 ^ level)
		local text = def.name .. " Lv " .. level .. "/" .. def.maxLevel .. " — " .. def.desc
		local buttonText = level >= def.maxLevel and "MAXED" or FormatMoney.format(cost)
		addShopRow(text, buttonText, function()
			remotes:WaitForChild("BuyUpgrade"):FireServer(key)
		end)
	end
	-- Extra base slot.
	local slotText = "Extra Base Slot (" .. latestSnapshot.slots .. "/" .. GameSettings.BASE_MAX_SLOTS .. " slots)"
	addShopRow(slotText, FormatMoney.format(latestSnapshot.nextSlotCost), function()
		remotes:WaitForChild("BuySlot"):FireServer()
	end)
	-- Rebirth.
	local rebirthText = "REBIRTH — reset money + brainrots, income x" .. (latestSnapshot.rebirthMultiplier * 2)
		.. " (needs 10 brainrots, costs " .. FormatMoney.format(latestSnapshot.rebirthCost) .. ")"
	addShopRow(rebirthText, "REBIRTH", function()
		remotes:WaitForChild("DoRebirth"):FireServer()
	end)
	-- Sell owned brainrots (50% refund).
	for _, owned in ipairs(latestSnapshot.owned) do
		local refund = math.floor(owned.cost * GameSettings.SELL_FRACTION)
		local text = "SELL " .. owned.name .. " (" .. owned.rarity .. " " .. owned.mutation .. ") — " .. FormatMoney.formatRate(owned.incomePerSec)
		addShopRow(text, "SELL " .. FormatMoney.format(refund), function()
			remotes:WaitForChild("SellBrainrot"):FireServer(owned.uid)
		end)
	end
end

-- Apply a fresh server snapshot to the HUD.
local function applySnapshot(snapshot)
	latestSnapshot = snapshot
	moneyLabel.Text = FormatMoney.format(snapshot.money)
	incomeLabel.Text = FormatMoney.formatRate(snapshot.incomePerSec)
	rebirthLabel.Text = "Rebirth " .. snapshot.rebirths .. " (x" .. snapshot.rebirthMultiplier .. ")"
	if snapshot.lockSecondsLeft > 0 then
		lockLabel.Text = "BASE LOCKED — " .. snapshot.lockSecondsLeft .. "s left"
		lockLabel.TextColor3 = C(120, 255, 140)
	elseif snapshot.lockCooldownLeft > 0 then
		lockLabel.Text = "Lock recharging — " .. snapshot.lockCooldownLeft .. "s"
		lockLabel.TextColor3 = C(255, 200, 90)
	else
		lockLabel.Text = "Base UNLOCKED — anyone can steal! Buy a lock!"
		lockLabel.TextColor3 = C(255, 140, 140)
	end
	if indexPanel.Visible then
		InterfaceController.refreshIndexPanel()
	end
	if shopPanel.Visible then
		InterfaceController.refreshShopPanel()
	end
end

-- Build the whole UI and hook up the remotes. Called once from Game.client.
function InterfaceController.startInterfaceController(localPlayer, playerGui, remoteFolder)
	player = localPlayer
	remotes = remoteFolder

	gui = Instance.new("ScreenGui")
	gui.Name = "BogGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	buildTopBar()
	buildActionButtons()
	buildLockLabel()
	buildWaveBanner()
	buildToast()
	buildIndexPanel()
	buildShopPanel()

	remotes:WaitForChild("ClientSync").OnClientEvent:Connect(applySnapshot)
	remotes:WaitForChild("ToastEvent").OnClientEvent:Connect(showToast)
	remotes:WaitForChild("WaveEvent").OnClientEvent:Connect(function(mode, secondsLeft)
		if mode == "warning" then
			waveBanner.Visible = true
			waveBannerLabel.Text = "TSUNAMI INCOMING IN " .. tostring(secondsLeft) .. "s — GET TO YOUR BASE!"
		elseif mode == "start" then
			waveBanner.Visible = true
			waveBannerLabel.Text = "TSUNAMI! HOLD ON!"
		elseif mode == "end" then
			waveBanner.Visible = false
		end
	end)

	-- Hide toasts a few seconds after they appear.
	task.spawn(function()
		while true do
			task.wait(0.5)
			if toastLabel.Visible and os.clock() > toastUntil then
				toastLabel.Visible = false
			end
		end
	end)
end

return InterfaceController
