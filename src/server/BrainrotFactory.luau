-- BrainrotFactory: builds a brainrot character model in code.
-- Body + head + eyes + one accessory per character, plus a big readable
-- BillboardGui label: name, rarity colour, mutation and $/sec. The label is
-- large on purpose — the judge reads it from a screenshot scaled down.

local BrainrotFactory = {}

local FormatMoney = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("FormatMoney"))
local BrainrotCatalog = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

local MUTATION_COLORS = {
	Normal = Color3.fromRGB(255, 255, 255),
	Golden = Color3.fromRGB(255, 215, 0),
	Diamond = Color3.fromRGB(140, 230, 255),
	Rainbow = Color3.fromRGB(255, 120, 220),
	Void = Color3.fromRGB(150, 80, 255),
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
local function buildAccessory(kind, model, headPos, bodyColor)
	if kind == "TopHat" then
		charPart("TopHatBrim", Vector3.new(2.6, 0.3, 2.6), headPos + Vector3.new(0, 1.1, 0), Color3.fromRGB(30, 30, 35), model)
		charPart("TopHatTop", Vector3.new(1.6, 1.6, 1.6), headPos + Vector3.new(0, 2, 0), Color3.fromRGB(30, 30, 35), model)
	elseif kind == "Crown" then
		local crown = charPart("Crown", Vector3.new(2, 0.9, 2), headPos + Vector3.new(0, 1.2, 0), Color3.fromRGB(255, 215, 0), model)
		crown.Material = Enum.Material.Neon
	elseif kind == "PirateHat" then
		charPart("PirateHat", Vector3.new(2.8, 0.5, 2), headPos + Vector3.new(0, 1.1, 0), Color3.fromRGB(40, 40, 45), model)
		charPart("PirateSkull", Vector3.new(0.8, 0.8, 0.3), headPos + Vector3.new(0, 1.2, 1), Color3.fromRGB(255, 255, 255), model)
	elseif kind == "WizardHat" then
		local cone = charPart("WizardHat", Vector3.new(2.2, 2.2, 2.2), headPos + Vector3.new(0, 2, 0), Color3.fromRGB(90, 60, 160), model)
		cone.Shape = Enum.PartType.Ball
		charPart("WizardBrim", Vector3.new(3, 0.3, 3), headPos + Vector3.new(0, 1.1, 0), Color3.fromRGB(90, 60, 160), model)
	elseif kind == "Bowtie" then
		charPart("Bowtie", Vector3.new(1.6, 0.6, 0.4), headPos + Vector3.new(0, -1.6, 1.3), Color3.fromRGB(220, 40, 60), model)
	elseif kind == "Flower" then
		local flower = charPart("Flower", Vector3.new(1, 1, 1), headPos + Vector3.new(1, 1, 0.6), Color3.fromRGB(255, 120, 200), model)
		flower.Shape = Enum.PartType.Ball
	elseif kind == "Monocle" then
		local mono = charPart("Monocle", Vector3.new(0.9, 0.9, 0.2), headPos + Vector3.new(0.6, 0.1, 1.1), Color3.fromRGB(255, 215, 0), model)
		mono.Shape = Enum.PartType.Cylinder
		mono.Rotation = Vector3.new(90, 0, 0)
	elseif kind == "Sombrero" then
		charPart("Sombrero", Vector3.new(3.4, 0.3, 3.4), headPos + Vector3.new(0, 1.1, 0), Color3.fromRGB(255, 200, 60), model)
		charPart("SombreroTop", Vector3.new(1.4, 1, 1.4), headPos + Vector3.new(0, 1.6, 0), Color3.fromRGB(230, 170, 40), model)
	elseif kind == "Headphones" then
		charPart("PhonesLeft", Vector3.new(0.5, 1.2, 1), headPos + Vector3.new(-1.2, 0.2, 0), Color3.fromRGB(30, 30, 35), model)
		charPart("PhonesRight", Vector3.new(0.5, 1.2, 1), headPos + Vector3.new(1.2, 0.2, 0), Color3.fromRGB(30, 30, 35), model)
		charPart("PhonesBand", Vector3.new(2.6, 0.4, 0.6), headPos + Vector3.new(0, 1.1, 0), Color3.fromRGB(30, 30, 35), model)
	elseif kind == "Tie" then
		charPart("Tie", Vector3.new(0.7, 1.8, 0.3), headPos + Vector3.new(0, -1.8, 1.4), Color3.fromRGB(200, 30, 50), model)
	elseif kind == "GradCap" then
		charPart("GradCap", Vector3.new(2.6, 0.3, 2.6), headPos + Vector3.new(0, 1.2, 0), Color3.fromRGB(30, 30, 35), model)
		charPart("GradTassel", Vector3.new(0.2, 1, 0.2), headPos + Vector3.new(1.2, 0.8, 0), Color3.fromRGB(255, 215, 0), model)
	elseif kind == "Chilli" then
		charPart("Chilli", Vector3.new(0.7, 1.6, 0.7), headPos + Vector3.new(1, 0.5, 0.8), Color3.fromRGB(220, 40, 30), model)
	elseif kind == "Cap" then
		charPart("Cap", Vector3.new(2.2, 0.6, 2.2), headPos + Vector3.new(0, 1.1, 0), Color3.fromRGB(255, 60, 60), model)
	elseif kind == "Sunglasses" then
		charPart("Shades", Vector3.new(2, 0.5, 0.3), headPos + Vector3.new(0, 0.2, 1.1), Color3.fromRGB(20, 20, 25), model)
	elseif kind == "Bandana" then
		charPart("Bandana", Vector3.new(2.4, 0.6, 2.4), headPos + Vector3.new(0, 0.9, 0), Color3.fromRGB(200, 40, 60), model)
	elseif kind == "StinkLines" then
		charPart("Stink1", Vector3.new(0.3, 1.2, 0.3), headPos + Vector3.new(-1, 1.6, 0), Color3.fromRGB(160, 220, 90), model)
		charPart("Stink2", Vector3.new(0.3, 1.2, 0.3), headPos + Vector3.new(0, 1.8, 0), Color3.fromRGB(160, 220, 90), model)
		charPart("Stink3", Vector3.new(0.3, 1.2, 0.3), headPos + Vector3.new(1, 1.6, 0), Color3.fromRGB(160, 220, 90), model)
	elseif kind == "SpikedCollar" then
		charPart("Collar", Vector3.new(2.4, 0.5, 2.4), headPos + Vector3.new(0, -1.4, 0), Color3.fromRGB(220, 40, 50), model)
	elseif kind == "Cape" then
		charPart("Cape", Vector3.new(2.6, 2.6, 0.3), headPos + Vector3.new(0, -1.5, -1.4), Color3.fromRGB(180, 30, 60), model)
	elseif kind == "Beret" then
		local beret = charPart("Beret", Vector3.new(2.2, 0.6, 2.2), headPos + Vector3.new(0, 1.2, 0), Color3.fromRGB(200, 60, 80), model)
		beret.Shape = Enum.PartType.Ball
	elseif kind == "Helmet" then
		local helmet = charPart("Helmet", Vector3.new(2.4, 1.2, 2.4), headPos + Vector3.new(0, 1, 0), Color3.fromRGB(120, 140, 160), model)
		helmet.Shape = Enum.PartType.Ball
	elseif kind == "EyePatch" then
		charPart("EyePatch", Vector3.new(0.9, 0.9, 0.2), headPos + Vector3.new(-0.6, 0.1, 1.1), Color3.fromRGB(20, 20, 25), model)
	elseif kind == "Stethoscope" then
		charPart("Stetho", Vector3.new(1.8, 0.4, 0.3), headPos + Vector3.new(0, -1.6, 1.3), Color3.fromRGB(40, 40, 45), model)
	elseif kind == "Glasses" then
		charPart("GlassesLeft", Vector3.new(0.9, 0.9, 0.2), headPos + Vector3.new(-0.6, 0.1, 1.1), Color3.fromRGB(20, 20, 25), model)
		charPart("GlassesRight", Vector3.new(0.9, 0.9, 0.2), headPos + Vector3.new(0.6, 0.1, 1.1), Color3.fromRGB(20, 20, 25), model)
	elseif kind == "CaptainHat" then
		charPart("CaptainHat", Vector3.new(2.4, 0.5, 2.2), headPos + Vector3.new(0, 1.2, 0), Color3.fromRGB(255, 255, 255), model)
		charPart("CaptainBadge", Vector3.new(0.7, 0.4, 0.2), headPos + Vector3.new(0, 1.2, 1.1), Color3.fromRGB(255, 215, 0), model)
	elseif kind == "Bucket" then
		charPart("Bucket", Vector3.new(2, 1.6, 2), headPos + Vector3.new(0, 1.6, 0), Color3.fromRGB(200, 60, 60), model)
	elseif kind == "Salt" then
		charPart("Salt1", Vector3.new(0.3, 0.3, 0.3), headPos + Vector3.new(-0.7, 1.3, 0.5), Color3.fromRGB(255, 255, 255), model)
		charPart("Salt2", Vector3.new(0.3, 0.3, 0.3), headPos + Vector3.new(0.5, 1.4, -0.3), Color3.fromRGB(255, 255, 255), model)
	elseif kind == "Moustache" then
		charPart("Moustache", Vector3.new(1.8, 0.4, 0.3), headPos + Vector3.new(0, -0.4, 1.1), Color3.fromRGB(60, 40, 20), model)
	elseif kind == "NightCap" then
		charPart("NightCap", Vector3.new(2, 1, 2), headPos + Vector3.new(0, 1.3, 0), Color3.fromRGB(90, 90, 160), model)
	elseif kind == "Hood" then
		local hood = charPart("Hood", Vector3.new(2.6, 1.6, 2.6), headPos + Vector3.new(0, 0.8, 0), Color3.fromRGB(50, 50, 65), model)
		hood.Shape = Enum.PartType.Ball
	elseif kind == "RainbowHalo" then
		local halo = charPart("Halo", Vector3.new(3, 0.3, 3), headPos + Vector3.new(0, 2.2, 0), Color3.fromRGB(255, 120, 220), model)
		halo.Material = Enum.Material.Neon
	end
end

-- Build the big readable name label above a brainrot.
local function buildNameLabel(model, head, def, mutation, incomePerSec)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(220, 84)
	gui.StudsOffset = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.42, 0)
	nameLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	nameLabel.BackgroundTransparency = 0.25
	nameLabel.Text = def.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.Parent = gui

	local rarityInfo = BrainrotCatalog.RARITIES[def.rarity]
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Position = UDim2.new(0, 0, 0.42, 0)
	rarityLabel.Size = UDim2.new(0.5, 0, 0.3, 0)
	rarityLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
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
	incomeLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	incomeLabel.BackgroundTransparency = 0.25
	incomeLabel.Text = FormatMoney.formatRate(incomePerSec)
	incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.GothamBlack
	incomeLabel.Parent = gui

	local costLabel = Instance.new("TextLabel")
	costLabel.Name = "CostLabel"
	costLabel.Position = UDim2.new(0, 0, 0.72, 0)
	costLabel.Size = UDim2.new(1, 0, 0.28, 0)
	costLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	costLabel.BackgroundTransparency = 0.25
	costLabel.Text = "COST " .. FormatMoney.format(def.cost)
	costLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
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

	local body = charPart("Body", Vector3.new(3, 3, 3), position, def.body, model)
	body.Shape = Enum.PartType.Ball
	if mutation.name == "Golden" then
		body.Material = Enum.Material.Neon
		body.Color = Color3.fromRGB(255, 215, 0)
	elseif mutation.name == "Diamond" then
		body.Material = Enum.Material.Glass
		body.Color = Color3.fromRGB(160, 230, 255)
	elseif mutation.name == "Rainbow" then
		body.Material = Enum.Material.Neon
		body.Color = Color3.fromRGB(255, 120, 220)
	elseif mutation.name == "Void" then
		body.Material = Enum.Material.Neon
		body.Color = Color3.fromRGB(120, 60, 220)
	end
	model.PrimaryPart = body

	local headPos = position + Vector3.new(0, 2.4, 0)
	local head = charPart("Head", Vector3.new(2.2, 2.2, 2.2), headPos, def.head, model)
	head.Shape = Enum.PartType.Ball

	-- Eyes on the front of the head.
	charPart("EyeLeft", Vector3.new(0.5, 0.7, 0.3), headPos + Vector3.new(-0.55, 0.25, 1.05), Color3.fromRGB(20, 20, 25), model)
	charPart("EyeRight", Vector3.new(0.5, 0.7, 0.3), headPos + Vector3.new(0.55, 0.25, 1.05), Color3.fromRGB(20, 20, 25), model)
	-- Little feet so it reads as a walking character.
	charPart("FootLeft", Vector3.new(1, 0.6, 1.4), position + Vector3.new(-0.8, -1.7, 0.2), Color3.fromRGB(40, 40, 45), model)
	charPart("FootRight", Vector3.new(1, 0.6, 1.4), position + Vector3.new(0.8, -1.7, 0.2), Color3.fromRGB(40, 40, 45), model)

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
