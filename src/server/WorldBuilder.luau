-- WorldBuilder: builds the whole 3D world of Brainrot Bog in code at server start.
-- Neon swamp lagoon island at dusk: green island, blue water canal, wooden docks,
-- 8 coloured player bases with walls and slot pads, spawn area, trees, rocks,
-- lamps, a big BRAINROT BOG sign and a leaderboard board. A few hundred anchored parts.

local C = Color3.fromRGB
local V3 = Vector3.new
local WorldBuilder = {}

local BASE_COLORS = {
	C(255, 90, 90),
	C(90, 160, 255),
	C(120, 220, 120),
	C(255, 200, 60),
	C(200, 120, 255),
	C(255, 140, 200),
	C(90, 220, 210),
	C(255, 140, 70),
}

local baseModels = {}
local slotPads = {} -- slotPads[baseIndex][slotIndex] = Part
local spawnPad = nil

-- Make one anchored part with the given shape and put it in the world.
local function makePart(name, className, size, position, color, material, parent)
	local part = Instance.new(className)
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.Parent = parent
	return part
end

-- Build one player base: platform, low walls, an owner sign and slot pads.
local function buildBase(index, centre, color)
	local folder = Instance.new("Model")
	folder.Name = "Base" .. index
	folder.Parent = workspace

	makePart("Platform", "Part", V3(30, 1, 26), centre + V3(0, 0.5, 0), color, Enum.Material.SmoothPlastic, folder)
	makePart("Trim", "Part", V3(30.6, 0.4, 26.6), centre + V3(0, 0.2, 0), C(255, 255, 255), Enum.Material.Neon, folder)
	-- Low walls on three sides; the canal side stays open so brainrots walk in.
	local backZ = centre.Z > 0 and 12.5 or -12.5
	local gateZ = -backZ
	makePart("WallBack", "Part", V3(30, 4, 1), centre + V3(0, 2.5, backZ), color, Enum.Material.SmoothPlastic, folder)
	makePart("WallLeft", "Part", V3(1, 4, 26), centre + V3(-14.5, 2.5, 0), color, Enum.Material.SmoothPlastic, folder)
	makePart("WallRight", "Part", V3(1, 4, 26), centre + V3(14.5, 2.5, 0), color, Enum.Material.SmoothPlastic, folder)
	-- Gate posts on the open canal side.
	makePart("GateLeft", "Part", V3(1.5, 5, 1.5), centre + V3(-14, 3, gateZ), C(255, 220, 90), Enum.Material.Neon, folder)
	makePart("GateRight", "Part", V3(1.5, 5, 1.5), centre + V3(14, 3, gateZ), C(255, 220, 90), Enum.Material.Neon, folder)

	-- Owner sign above the back wall.
	local sign = makePart("OwnerSign", "Part", V3(18, 4, 0.6), centre + V3(0, 6.5, backZ), C(30, 30, 45), Enum.Material.SmoothPlastic, folder)
	local gui = Instance.new("SurfaceGui")
	-- Face the sign toward the canal so players walking it can read it.
	gui.Face = centre.Z > 0 and Enum.NormalId.Back or Enum.NormalId.Front
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "BASE " .. index .. " — EMPTY"
	label.TextColor3 = C(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = gui
	folder:SetAttribute("OwnerLabel", "Base " .. index)

	-- Slot pads: 2 rows x 3 columns, then extra rows as slots are bought.
	local pads = {}
	for slot = 1, 12 do
		local col = (slot - 1) % 3
		local row = math.floor((slot - 1) / 3)
		local padPos = centre + V3((col - 1) * 8, 1.15, -6 + row * 6)
		local pad = makePart("SlotPad" .. slot, "Part", V3(6, 0.3, 5), padPos, C(255, 255, 255), Enum.Material.Neon, folder)
		pad.Transparency = 0.55
		pad.CanCollide = false
		pad:SetAttribute("SlotIndex", slot)
		pads[slot] = pad
	end
	slotPads[index] = pads
	baseModels[index] = folder
	return folder
end

-- Build a swamp tree: trunk cylinder + two leaf spheres.
local function buildTree(parent, position, scale)
	local trunk = makePart("Trunk", "Part", V3(1.6 * scale, 7 * scale, 1.6 * scale), position + V3(0, 3.5 * scale, 0), C(120, 80, 40), Enum.Material.Wood, parent)
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Rotation = V3(0, 0, 90)
	local leaves = makePart("Leaves", "Part", V3(6 * scale, 5 * scale, 6 * scale), position + V3(0, 8.5 * scale, 0), C(40, 160, 70), Enum.Material.Grass, parent)
	leaves.Shape = Enum.PartType.Ball
	local leaves2 = makePart("Leaves2", "Part", V3(4 * scale, 3.5 * scale, 4 * scale), position + V3(2 * scale, 10.5 * scale, 0), C(70, 200, 90), Enum.Material.Grass, parent)
	leaves2.Shape = Enum.PartType.Ball
end

-- Build a lamp post with a glowing neon head.
local function buildLamp(parent, position)
	makePart("LampPost", "Part", V3(0.7, 7, 0.7), position + V3(0, 3.5, 0), C(60, 60, 70), Enum.Material.Metal, parent)
	local head = makePart("LampHead", "Part", V3(2, 1.4, 2), position + V3(0, 7.4, 0), C(255, 220, 130), Enum.Material.Neon, parent)
	head.Shape = Enum.PartType.Ball
end

-- Build the whole world. Returns the base models table for BaseService.
function WorldBuilder.buildWorld()
	local world = Instance.new("Folder")
	world.Name = "BogWorld"
	world.Parent = workspace

	-- Island baseplate and the water canal through its middle.
	makePart("Island", "Part", V3(240, 2, 140), V3(0, -1, 0), C(70, 170, 80), Enum.Material.Grass, world)
	makePart("CanalWater", "Part", V3(210, 1, 16), V3(0, 0.1, 0), C(40, 120, 255), Enum.Material.Water, world)
	makePart("CanalBed", "Part", V3(210, 0.4, 16), V3(0, -0.6, 0), C(30, 80, 160), Enum.Material.SmoothPlastic, world)
	-- Wooden docks along both canal banks.
	for x = -100, 100, 20 do
		makePart("DockNorth", "Part", V3(16, 0.6, 3), V3(x, 0.6, -9.5), C(150, 105, 60), Enum.Material.Wood, world)
		makePart("DockSouth", "Part", V3(16, 0.6, 3), V3(x, 0.6, 9.5), C(150, 105, 60), Enum.Material.Wood, world)
	end
	-- Neon canal edge strips so the conveyor path reads at a glance.
	makePart("CanalEdgeNorth", "Part", V3(210, 0.3, 0.8), V3(0, 0.7, -8), C(90, 230, 255), Enum.Material.Neon, world)
	makePart("CanalEdgeSouth", "Part", V3(210, 0.3, 0.8), V3(0, 0.7, 8), C(90, 230, 255), Enum.Material.Neon, world)

	-- Spawn area at the west end.
	spawnPad = makePart("SpawnPad", "Part", V3(16, 1, 16), V3(-108, 0.5, 26), C(255, 220, 90), Enum.Material.Neon, world)
	spawnPad.Transparency = 0.4
	local spawnSign = makePart("SpawnSign", "Part", V3(14, 3, 0.6), V3(-108, 5, 18), C(30, 30, 45), Enum.Material.SmoothPlastic, world)
	local spawnGui = Instance.new("SurfaceGui")
	spawnGui.Face = Enum.NormalId.Front
	spawnGui.Parent = spawnSign
	local spawnLabel = Instance.new("TextLabel")
	spawnLabel.Size = UDim2.fromScale(1, 1)
	spawnLabel.BackgroundTransparency = 1
	spawnLabel.Text = "SPAWN"
	spawnLabel.TextColor3 = C(255, 220, 90)
	spawnLabel.TextScaled = true
	spawnLabel.Font = Enum.Font.GothamBlack
	spawnLabel.Parent = spawnGui

	-- The 8 bases, north row then south row.
	local GameSettings = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameSettings"))
	for i, centre in ipairs(GameSettings.BASE_POSITIONS) do
		buildBase(i, centre, BASE_COLORS[i])
	end

	-- Big BRAINROT BOG sign over the canal's east end.
	local signPost1 = makePart("SignPost1", "Part", V3(1.5, 14, 1.5), V3(102, 7, -10), C(120, 80, 40), Enum.Material.Wood, world)
	local signPost2 = makePart("SignPost2", "Part", V3(1.5, 14, 1.5), V3(102, 7, 10), C(120, 80, 40), Enum.Material.Wood, world)
	local bigSign = makePart("BogSign", "Part", V3(1, 8, 26), V3(102, 15, 0), C(30, 30, 45), Enum.Material.SmoothPlastic, world)
	local bigGui = Instance.new("SurfaceGui")
	bigGui.Face = Enum.NormalId.Left
	bigGui.Parent = bigSign
	local bigLabel = Instance.new("TextLabel")
	bigLabel.Size = UDim2.fromScale(1, 1)
	bigLabel.BackgroundTransparency = 1
	bigLabel.Text = "BRAINROT BOG"
	bigLabel.TextColor3 = C(90, 230, 255)
	bigLabel.TextScaled = true
	bigLabel.Font = Enum.Font.GothamBlack
	bigLabel.Parent = bigGui

	-- Leaderboard board near spawn.
	local board = makePart("LeaderboardBoard", "Part", V3(0.8, 10, 14), V3(-100, 5, 44), C(30, 30, 45), Enum.Material.SmoothPlastic, world)
	local boardGui = Instance.new("SurfaceGui")
	boardGui.Face = Enum.NormalId.Right
	boardGui.Parent = board
	local boardTitle = Instance.new("TextLabel")
	boardTitle.Name = "BoardTitle"
	boardTitle.Size = UDim2.new(1, 0, 0.18, 0)
	boardTitle.BackgroundTransparency = 1
	boardTitle.Text = "RICHEST IN THE BOG"
	boardTitle.TextColor3 = C(255, 220, 90)
	boardTitle.TextScaled = true
	boardTitle.Font = Enum.Font.GothamBlack
	boardTitle.Parent = boardGui
	local boardBody = Instance.new("TextLabel")
	boardBody.Name = "BoardBody"
	boardBody.Position = UDim2.new(0, 0, 0.18, 0)
	boardBody.Size = UDim2.new(1, 0, 0.82, 0)
	boardBody.BackgroundTransparency = 1
	boardBody.Text = "No players yet..."
	boardBody.TextColor3 = C(255, 255, 255)
	boardBody.TextScaled = true
	boardBody.Font = Enum.Font.GothamBold
	boardBody.Parent = boardGui

	-- Trees, rocks and lamps scattered around the island edges.
	local treeSpots = {
		V3(-115, 0, -55), V3(-60, 0, -62), V3(0, 0, -62),
		V3(60, 0, -62), V3(115, 0, -55), V3(-115, 0, 55),
		V3(-55, 0, 62), V3(5, 0, 62), V3(62, 0, 62),
		V3(115, 0, 55), V3(-95, 0, -28), V3(95, 0, 28),
	}
	for _, spot in ipairs(treeSpots) do
		buildTree(world, spot, 0.9 + math.random() * 0.5)
	end
	local rockSpots = {
		V3(-40, 0, -58), V3(40, 0, -58), V3(-40, 0, 58),
		V3(40, 0, 58), V3(-105, 0, -30), V3(105, 0, -30),
		V3(-105, 0, 55), V3(105, 0, 55), V3(0, 0, -30),
		V3(0, 0, 30),
	}
	for _, spot in ipairs(rockSpots) do
		local rock = makePart("Rock", "Part", V3(3 + math.random() * 2, 2 + math.random(), 3 + math.random() * 2), spot + V3(0, 1, 0), C(130, 130, 140), Enum.Material.Slate, world)
		rock.Shape = Enum.PartType.Ball
	end
	for _, lampSpot in ipairs({ V3(-100, 0, -20), V3(-100, 0, 20), V3(0, 0, -20), V3(0, 0, 20), V3(100, 0, -20), V3(100, 0, 20) }) do
		buildLamp(world, lampSpot)
	end

	return world
end

-- The slot pad part for a base and slot number (1-12).
function WorldBuilder.getSlotPad(baseIndex, slotIndex)
	if slotPads[baseIndex] then
		return slotPads[baseIndex][slotIndex]
	end
	return nil
end

-- The base model folder for a base index.
function WorldBuilder.getBaseModel(baseIndex)
	return baseModels[baseIndex]
end

-- The spawn pad part.
function WorldBuilder.getSpawnPad()
	return spawnPad
end

return WorldBuilder
