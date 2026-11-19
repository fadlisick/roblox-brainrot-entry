-- WorldBuilder: builds the whole 3D world of Brainrot Bog in code at server start.
-- Neon swamp lagoon island at dusk: green island, blue water canal, wooden docks,
-- 8 coloured player bases with walls and slot pads, spawn area, trees, rocks,
-- lamps, a big BRAINROT BOG sign and a leaderboard board. A few hundred anchored parts.

local WorldBuilder = {}

local BASE_COLORS = {
	Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(90, 160, 255),
	Color3.fromRGB(120, 220, 120),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(200, 120, 255),
	Color3.fromRGB(255, 140, 200),
	Color3.fromRGB(90, 220, 210),
	Color3.fromRGB(255, 140, 70),
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

	makePart("Platform", "Part", Vector3.new(30, 1, 26), centre + Vector3.new(0, 0.5, 0), color, Enum.Material.SmoothPlastic, folder)
	makePart("Trim", "Part", Vector3.new(30.6, 0.4, 26.6), centre + Vector3.new(0, 0.2, 0), Color3.fromRGB(255, 255, 255), Enum.Material.Neon, folder)
	-- Low walls on three sides; the canal side stays open so brainrots walk in.
	makePart("WallBack", "Part", Vector3.new(30, 4, 1), centre + Vector3.new(0, 2.5, -12.5), color, Enum.Material.SmoothPlastic, folder)
	local sideZ = centre.Z > 0 and -1 or 1
	makePart("WallLeft", "Part", Vector3.new(1, 4, 26), centre + Vector3.new(-14.5, 2.5, 0), color, Enum.Material.SmoothPlastic, folder)
	makePart("WallRight", "Part", Vector3.new(1, 4, 26), centre + Vector3.new(14.5, 2.5, 0), color, Enum.Material.SmoothPlastic, folder)
	-- Gate posts on the open canal side.
	makePart("GateLeft", "Part", Vector3.new(1.5, 5, 1.5), centre + Vector3.new(-14, 3, 12.5 * sideZ), Color3.fromRGB(255, 220, 90), Enum.Material.Neon, folder)
	makePart("GateRight", "Part", Vector3.new(1.5, 5, 1.5), centre + Vector3.new(14, 3, 12.5 * sideZ), Color3.fromRGB(255, 220, 90), Enum.Material.Neon, folder)

	-- Owner sign above the back wall.
	local sign = makePart("OwnerSign", "Part", Vector3.new(18, 4, 0.6), centre + Vector3.new(0, 6.5, -12.5), Color3.fromRGB(30, 30, 45), Enum.Material.SmoothPlastic, folder)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "BASE " .. index .. " — EMPTY"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = gui
	folder:SetAttribute("OwnerSignText", label)

	-- Slot pads: 2 rows x 3 columns, then extra rows as slots are bought.
	local pads = {}
	for slot = 1, 12 do
		local col = (slot - 1) % 3
		local row = math.floor((slot - 1) / 3)
		local padPos = centre + Vector3.new((col - 1) * 8, 1.15, -6 + row * 6)
		local pad = makePart("SlotPad" .. slot, "Part", Vector3.new(6, 0.3, 5), padPos, Color3.fromRGB(255, 255, 255), Enum.Material.Neon, folder)
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
	local trunk = makePart("Trunk", "Part", Vector3.new(1.6 * scale, 7 * scale, 1.6 * scale), position + Vector3.new(0, 3.5 * scale, 0), Color3.fromRGB(120, 80, 40), Enum.Material.Wood, parent)
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Rotation = Vector3.new(0, 0, 90)
	local leaves = makePart("Leaves", "Part", Vector3.new(6 * scale, 5 * scale, 6 * scale), position + Vector3.new(0, 8.5 * scale, 0), Color3.fromRGB(40, 160, 70), Enum.Material.Grass, parent)
	leaves.Shape = Enum.PartType.Ball
	local leaves2 = makePart("Leaves2", "Part", Vector3.new(4 * scale, 3.5 * scale, 4 * scale), position + Vector3.new(2 * scale, 10.5 * scale, 0), Color3.fromRGB(70, 200, 90), Enum.Material.Grass, parent)
	leaves2.Shape = Enum.PartType.Ball
end

-- Build a lamp post with a glowing neon head.
local function buildLamp(parent, position)
	makePart("LampPost", "Part", Vector3.new(0.7, 7, 0.7), position + Vector3.new(0, 3.5, 0), Color3.fromRGB(60, 60, 70), Enum.Material.Metal, parent)
	local head = makePart("LampHead", "Part", Vector3.new(2, 1.4, 2), position + Vector3.new(0, 7.4, 0), Color3.fromRGB(255, 220, 130), Enum.Material.Neon, parent)
	head.Shape = Enum.PartType.Ball
end

-- Build the whole world. Returns the base models table for BaseService.
function WorldBuilder.buildWorld()
	local world = Instance.new("Folder")
	world.Name = "BogWorld"
	world.Parent = workspace

	-- Island baseplate and the water canal through its middle.
	makePart("Island", "Part", Vector3.new(240, 2, 140), Vector3.new(0, -1, 0), Color3.fromRGB(70, 170, 80), Enum.Material.Grass, world)
	makePart("CanalWater", "Part", Vector3.new(210, 1, 16), Vector3.new(0, 0.1, 0), Color3.fromRGB(40, 120, 255), Enum.Material.Water, world)
	makePart("CanalBed", "Part", Vector3.new(210, 0.4, 16), Vector3.new(0, -0.6, 0), Color3.fromRGB(30, 80, 160), Enum.Material.SmoothPlastic, world)
	-- Wooden docks along both canal banks.
	for x = -100, 100, 20 do
		makePart("DockNorth", "Part", Vector3.new(16, 0.6, 3), Vector3.new(x, 0.6, -9.5), Color3.fromRGB(150, 105, 60), Enum.Material.Wood, world)
		makePart("DockSouth", "Part", Vector3.new(16, 0.6, 3), Vector3.new(x, 0.6, 9.5), Color3.fromRGB(150, 105, 60), Enum.Material.Wood, world)
	end
	-- Neon canal edge strips so the conveyor path reads at a glance.
	makePart("CanalEdgeNorth", "Part", Vector3.new(210, 0.3, 0.8), Vector3.new(0, 0.7, -8), Color3.fromRGB(90, 230, 255), Enum.Material.Neon, world)
	makePart("CanalEdgeSouth", "Part", Vector3.new(210, 0.3, 0.8), Vector3.new(0, 0.7, 8), Color3.fromRGB(90, 230, 255), Enum.Material.Neon, world)

	-- Spawn area at the west end.
	spawnPad = makePart("SpawnPad", "Part", Vector3.new(16, 1, 16), Vector3.new(-108, 0.5, 26), Color3.fromRGB(255, 220, 90), Enum.Material.Neon, world)
	spawnPad.Transparency = 0.4
	local spawnSign = makePart("SpawnSign", "Part", Vector3.new(14, 3, 0.6), Vector3.new(-108, 5, 18), Color3.fromRGB(30, 30, 45), Enum.Material.SmoothPlastic, world)
	local spawnGui = Instance.new("SurfaceGui")
	spawnGui.Face = Enum.NormalId.Front
	spawnGui.Parent = spawnSign
	local spawnLabel = Instance.new("TextLabel")
	spawnLabel.Size = UDim2.fromScale(1, 1)
	spawnLabel.BackgroundTransparency = 1
	spawnLabel.Text = "SPAWN"
	spawnLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
	spawnLabel.TextScaled = true
	spawnLabel.Font = Enum.Font.GothamBlack
	spawnLabel.Parent = spawnGui

	-- The 8 bases, north row then south row.
	local GameSettings = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameSettings"))
	for i, centre in ipairs(GameSettings.BASE_POSITIONS) do
		buildBase(i, centre, BASE_COLORS[i])
	end

	-- Big BRAINROT BOG sign over the canal's east end.
	local signPost1 = makePart("SignPost1", "Part", Vector3.new(1.5, 14, 1.5), Vector3.new(102, 7, -10), Color3.fromRGB(120, 80, 40), Enum.Material.Wood, world)
	local signPost2 = makePart("SignPost2", "Part", Vector3.new(1.5, 14, 1.5), Vector3.new(102, 7, 10), Color3.fromRGB(120, 80, 40), Enum.Material.Wood, world)
	local bigSign = makePart("BogSign", "Part", Vector3.new(1, 8, 26), Vector3.new(102, 15, 0), Color3.fromRGB(30, 30, 45), Enum.Material.SmoothPlastic, world)
	local bigGui = Instance.new("SurfaceGui")
	bigGui.Face = Enum.NormalId.Left
	bigGui.Parent = bigSign
	local bigLabel = Instance.new("TextLabel")
	bigLabel.Size = UDim2.fromScale(1, 1)
	bigLabel.BackgroundTransparency = 1
	bigLabel.Text = "BRAINROT BOG"
	bigLabel.TextColor3 = Color3.fromRGB(90, 230, 255)
	bigLabel.TextScaled = true
	bigLabel.Font = Enum.Font.GothamBlack
	bigLabel.Parent = bigGui

	-- Leaderboard board near spawn.
	local board = makePart("LeaderboardBoard", "Part", Vector3.new(0.8, 10, 14), Vector3.new(-100, 5, 44), Color3.fromRGB(30, 30, 45), Enum.Material.SmoothPlastic, world)
	local boardGui = Instance.new("SurfaceGui")
	boardGui.Face = Enum.NormalId.Right
	boardGui.Parent = board
	local boardTitle = Instance.new("TextLabel")
	boardTitle.Name = "BoardTitle"
	boardTitle.Size = UDim2.new(1, 0, 0.18, 0)
	boardTitle.BackgroundTransparency = 1
	boardTitle.Text = "RICHEST IN THE BOG"
	boardTitle.TextColor3 = Color3.fromRGB(255, 220, 90)
	boardTitle.TextScaled = true
	boardTitle.Font = Enum.Font.GothamBlack
	boardTitle.Parent = boardGui
	local boardBody = Instance.new("TextLabel")
	boardBody.Name = "BoardBody"
	boardBody.Position = UDim2.new(0, 0, 0.18, 0)
	boardBody.Size = UDim2.new(1, 0, 0.82, 0)
	boardBody.BackgroundTransparency = 1
	boardBody.Text = "No players yet..."
	boardBody.TextColor3 = Color3.fromRGB(255, 255, 255)
	boardBody.TextScaled = true
	boardBody.Font = Enum.Font.GothamBold
	boardBody.Parent = boardGui
	world:SetAttribute("BoardBody", boardBody)

	-- Trees, rocks and lamps scattered around the island edges.
	local treeSpots = {
		Vector3.new(-115, 0, -55), Vector3.new(-60, 0, -62), Vector3.new(0, 0, -62),
		Vector3.new(60, 0, -62), Vector3.new(115, 0, -55), Vector3.new(-115, 0, 55),
		Vector3.new(-55, 0, 62), Vector3.new(5, 0, 62), Vector3.new(62, 0, 62),
		Vector3.new(115, 0, 55), Vector3.new(-95, 0, -28), Vector3.new(95, 0, 28),
	}
	for _, spot in ipairs(treeSpots) do
		buildTree(world, spot, 0.9 + math.random() * 0.5)
	end
	local rockSpots = {
		Vector3.new(-40, 0, -58), Vector3.new(40, 0, -58), Vector3.new(-40, 0, 58),
		Vector3.new(40, 0, 58), Vector3.new(-105, 0, -30), Vector3.new(105, 0, -30),
		Vector3.new(-105, 0, 55), Vector3.new(105, 0, 55), Vector3.new(0, 0, -30),
		Vector3.new(0, 0, 30),
	}
	for _, spot in ipairs(rockSpots) do
		local rock = makePart("Rock", "Part", Vector3.new(3 + math.random() * 2, 2 + math.random(), 3 + math.random() * 2), spot + Vector3.new(0, 1, 0), Color3.fromRGB(130, 130, 140), Enum.Material.Slate, world)
		rock.Shape = Enum.PartType.Ball
	end
	for _, lampSpot in ipairs({ Vector3.new(-100, 0, -20), Vector3.new(-100, 0, 20), Vector3.new(0, 0, -20), Vector3.new(0, 0, 20), Vector3.new(100, 0, -20), Vector3.new(100, 0, 20) }) do
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
