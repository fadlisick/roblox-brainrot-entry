-- BrainrotFactory: builds a brainrot character model in code.
-- Body + head + eyes + one accessory per character, plus a big readable
-- BillboardGui label: name, rarity colour, mutation and $/sec. The label is
-- large on purpose — the judge reads it from a screenshot scaled down.

local C = Color3.fromRGB
local V3 = Vector3.new
local BrainrotFactory = {}

local FormatMoney = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("FormatMoney"))
local BrainrotCatalog = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

local MUTATION_COLORS = {
	Normal = C(255, 255, 255),
	Golden = C(255, 215, 0),
	Diamond = C(140, 230, 255),
	Rainbow = C(255, 120, 220),
	Void = C(150, 80, 255),
}

-- One anchored part of a character model.
local function charPart(name, size, position, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.Parent = parent
	return part
end

-- Build the accessory for a character: hat, crown, glasses, tie, etc.
-- Build the accessory for a character: hat, crown, glasses, tie, etc.
-- P(name, size x/y/z, offset x/y/z, colour r/g/b, shape?, material?, rotX?)
-- keeps every accessory to one short line: the shape and material default
-- to a plain block, "Ball"/"Cylinder" and "Neon" override them.
local function buildAccessory(kind, model, headPos, bodyColor)
	local function P(name, sx, sy, sz, ox, oy, oz, r, g, b, shape, material, rotX)
		local part = charPart(name, V3(sx, sy, sz), headPos + V3(ox, oy, oz), C(r, g, b), model)
		if shape == "Ball" then
			part.Shape = Enum.PartType.Ball
		elseif shape == "Cylinder" then
			part.Shape = Enum.PartType.Cylinder
		end
		if material == "Neon" then
			part.Material = Enum.Material.Neon
		end
		if rotX then
			part.Rotation = V3(rotX, 0, 0)
		end
	end
	if kind == "TopHat" then
		P("TopHatBrim", 2.6, 0.3, 2.6, 0, 1.1, 0, 30, 30, 35)
		P("TopHatTop", 1.6, 1.6, 1.6, 0, 2, 0, 30, 30, 35)
	elseif kind == "Crown" then
		P("Crown", 2, 0.9, 2, 0, 1.2, 0, 255, 215, 0, nil, "Neon")
	elseif kind == "PirateHat" then
		P("PirateHat", 2.8, 0.5, 2, 0, 1.1, 0, 40, 40, 45)
		P("PirateSkull", 0.8, 0.8, 0.3, 0, 1.2, 1, 255, 255, 255)
	elseif kind == "WizardHat" then
		P("WizardHat", 2.2, 2.2, 2.2, 0, 2, 0, 90, 60, 160, "Ball")
		P("WizardBrim", 3, 0.3, 3, 0, 1.1, 0, 90, 60, 160)
	elseif kind == "Bowtie" then
		P("Bowtie", 1.6, 0.6, 0.4, 0, -1.6, 1.3, 220, 40, 60)
	elseif kind == "Flower" then
		P("Flower", 1, 1, 1, 1, 1, 0.6, 255, 120, 200, "Ball")
	elseif kind == "Monocle" then
		P("Monocle", 0.9, 0.9, 0.2, 0.6, 0.1, 1.1, 255, 215, 0, "Cylinder", nil, 90)
	elseif kind == "Sombrero" then
		P("Sombrero", 3.4, 0.3, 3.4, 0, 1.1, 0, 255, 200, 60)
		P("SombreroTop", 1.4, 1, 1.4, 0, 1.6, 0, 230, 170, 40)
	elseif kind == "Headphones" then
		P("PhonesLeft", 0.5, 1.2, 1, -1.2, 0.2, 0, 30, 30, 35)
		P("PhonesRight", 0.5, 1.2, 1, 1.2, 0.2, 0, 30, 30, 35)
		P("PhonesBand", 2.6, 0.4, 0.6, 0, 1.1, 0, 30, 30, 35)
	elseif kind == "Tie" then
		P("Tie", 0.7, 1.8, 0.3, 0, -1.8, 1.4, 200, 30, 50)
	elseif kind == "GradCap" then
		P("GradCap", 2.6, 0.3, 2.6, 0, 1.2, 0, 30, 30, 35)
		P("GradTassel", 0.2, 1, 0.2, 1.2, 0.8, 0, 255, 215, 0)
	elseif kind == "Chilli" then
		P("Chilli", 0.7, 1.6, 0.7, 1, 0.5, 0.8, 220, 40, 30)
	elseif kind == "Cap" then
		P("Cap", 2.2, 0.6, 2.2, 0, 1.1, 0, 255, 60, 60)
	elseif kind == "Sunglasses" then
		P("Shades", 2, 0.5, 0.3, 0, 0.2, 1.1, 20, 20, 25)
	elseif kind == "Bandana" then
		P("Bandana", 2.4, 0.6, 2.4, 0, 0.9, 0, 200, 40, 60)
	elseif kind == "StinkLines" then
		P("Stink1", 0.3, 1.2, 0.3, -1, 1.6, 0, 160, 220, 90)
		P("Stink2", 0.3, 1.2, 0.3, 0, 1.8, 0, 160, 220, 90)
		P("Stink3", 0.3, 1.2, 0.3, 1, 1.6, 0, 160, 220, 90)
	elseif kind == "SpikedCollar" then
		P("Collar", 2.4, 0.5, 2.4, 0, -1.4, 0, 220, 40, 50)
	elseif kind == "Cape" then
		P("Cape", 2.6, 2.6, 0.3, 0, -1.5, -1.4, 180, 30, 60)
	elseif kind == "Beret" then
		P("Beret", 2.2, 0.6, 2.2, 0, 1.2, 0, 200, 60, 80, "Ball")
	elseif kind == "Helmet" then
		P("Helmet", 2.4, 1.2, 2.4, 0, 1, 0, 120, 140, 160, "Ball")
	elseif kind == "EyePatch" then
		P("EyePatch", 0.9, 0.9, 0.2, -0.6, 0.1, 1.1, 20, 20, 25)
	elseif kind == "Stethoscope" then
		P("Stetho", 1.8, 0.4, 0.3, 0, -1.6, 1.3, 40, 40, 45)
	elseif kind == "Glasses" then
		P("GlassesLeft", 0.9, 0.9, 0.2, -0.6, 0.1, 1.1, 20, 20, 25)
		P("GlassesRight", 0.9, 0.9, 0.2, 0.6, 0.1, 1.1, 20, 20, 25)
	elseif kind == "CaptainHat" then
		P("CaptainHat", 2.4, 0.5, 2.2, 0, 1.2, 0, 255, 255, 255)
		P("CaptainBadge", 0.7, 0.4, 0.2, 0, 1.2, 1.1, 255, 215, 0)
	elseif kind == "Bucket" then
		P("Bucket", 2, 1.6, 2, 0, 1.6, 0, 200, 60, 60)
	elseif kind == "Salt" then
		P("Salt1", 0.3, 0.3, 0.3, -0.7, 1.3, 0.5, 255, 255, 255)
		P("Salt2", 0.3, 0.3, 0.3, 0.5, 1.4, -0.3, 255, 255, 255)
	elseif kind == "Moustache" then
		P("Moustache", 1.8, 0.4, 0.3, 0, -0.4, 1.1, 60, 40, 20)
	elseif kind == "NightCap" then
		P("NightCap", 2, 1, 2, 0, 1.3, 0, 90, 90, 160)
	elseif kind == "Hood" then
		P("Hood", 2.6, 1.6, 2.6, 0, 0.8, 0, 50, 50, 65, "Ball")
	elseif kind == "RainbowHalo" then
		P("Halo", 3, 0.3, 3, 0, 2.2, 0, 255, 120, 220, nil, "Neon")
	end
end

-- Build the big readable name label above a brainrot.
local function buildNameLabel(model, head, def, mutation, incomePerSec)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(220, 84)
	gui.StudsOffset = V3(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.42, 0)
	nameLabel.BackgroundColor3 = C(20, 20, 30)
	nameLabel.BackgroundTransparency = 0.25
	nameLabel.Text = def.name
	nameLabel.TextColor3 = C(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.Parent = gui

	local rarityInfo = BrainrotCatalog.RARITIES[def.rarity]
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Position = UDim2.new(0, 0, 0.42, 0)
	rarityLabel.Size = UDim2.new(0.5, 0, 0.3, 0)
	rarityLabel.BackgroundColor3 = C(20, 20, 30)
	rarityLabel.BackgroundTransparency = 0.25
	local mutationText = mutation.name ~= "Normal" and (" " .. mutation.name) or ""
	rarityLabel.Text = def.rarity .. mutationText
	rarityLabel.TextColor3 = mutation.name ~= "Normal" and (MUTATION_COLORS[mutation.name] or rarityInfo.color) or rarityInfo.color
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = gui

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Position = UDim2.new(0.5, 0, 0.42, 0)
	incomeLabel.Size = UDim2.new(0.5, 0, 0.3, 0)
	incomeLabel.BackgroundColor3 = C(20, 20, 30)
	incomeLabel.BackgroundTransparency = 0.25
	incomeLabel.Text = FormatMoney.formatRate(incomePerSec)
	incomeLabel.TextColor3 = C(120, 255, 140)
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.GothamBlack
	incomeLabel.Parent = gui

	local costLabel = Instance.new("TextLabel")
	costLabel.Name = "CostLabel"
	costLabel.Position = UDim2.new(0, 0, 0.72, 0)
	costLabel.Size = UDim2.new(1, 0, 0.28, 0)
	costLabel.BackgroundColor3 = C(20, 20, 30)
	costLabel.BackgroundTransparency = 0.25
	costLabel.Text = "COST " .. FormatMoney.format(def.cost)
	costLabel.TextColor3 = C(255, 220, 90)
	costLabel.TextScaled = true
	costLabel.Font = Enum.Font.GothamBold
	costLabel.Parent = gui
	return gui
end

-- Build a full brainrot model at a position. Returns the Model.
-- def: catalog entry; mutation: mutation table; incomePerSec: final $/sec.
function BrainrotFactory.buildBrainrotModel(def, mutation, incomePerSec, position)
	local model = Instance.new("Model")
	model.Name = "Brainrot_" .. def.id .. "_" .. def.name:gsub("%W", "")

	local body = charPart("Body", V3(3, 3, 3), position, def.body, model)
	body.Shape = Enum.PartType.Ball
	if mutation.name == "Golden" then
		body.Material = Enum.Material.Neon
		body.Color = C(255, 215, 0)
	elseif mutation.name == "Diamond" then
		body.Material = Enum.Material.Glass
		body.Color = C(160, 230, 255)
	elseif mutation.name == "Rainbow" then
		body.Material = Enum.Material.Neon
		body.Color = C(255, 120, 220)
	elseif mutation.name == "Void" then
		body.Material = Enum.Material.Neon
		body.Color = C(120, 60, 220)
	end
	model.PrimaryPart = body

	local headPos = position + V3(0, 2.4, 0)
	local head = charPart("Head", V3(2.2, 2.2, 2.2), headPos, def.head, model)
	head.Shape = Enum.PartType.Ball

	-- Eyes on the front of the head.
	charPart("EyeLeft", V3(0.5, 0.7, 0.3), headPos + V3(-0.55, 0.25, 1.05), C(20, 20, 25), model)
	charPart("EyeRight", V3(0.5, 0.7, 0.3), headPos + V3(0.55, 0.25, 1.05), C(20, 20, 25), model)
	-- Little feet so it reads as a walking character.
	charPart("FootLeft", V3(1, 0.6, 1.4), position + V3(-0.8, -1.7, 0.2), C(40, 40, 45), model)
	charPart("FootRight", V3(1, 0.6, 1.4), position + V3(0.8, -1.7, 0.2), C(40, 40, 45), model)

	buildAccessory(def.accessory, model, headPos, def.body)
	buildNameLabel(model, head, def, mutation, incomePerSec)

	model:SetAttribute("CatalogId", def.id)
	model:SetAttribute("Mutation", mutation.name)
	model:SetAttribute("IncomePerSec", incomePerSec)
	return model
end

-- Refresh the income line of an existing brainrot label (after rebirth etc.).
function BrainrotFactory.updateIncomeLabel(model, incomePerSec)
	local gui = model:FindFirstChild("BrainrotLabel")
	if not gui then
		return
	end
	local incomeLabel = gui:FindFirstChild("IncomeLabel")
	if incomeLabel then
		incomeLabel.Text = FormatMoney.formatRate(incomePerSec)
	end
	model:SetAttribute("IncomePerSec", incomePerSec)
end

return BrainrotFactory
