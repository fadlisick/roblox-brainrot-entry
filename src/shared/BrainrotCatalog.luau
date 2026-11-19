-- BrainrotCatalog: the 48 original brainrots of Brainrot Bog.
-- Six rarities x eight characters each. Every entry is an original absurd
-- character invented for this game: name, look, price and income per second.
-- Rarity ladder (spawn weight, label colour) lives in RARITIES.
-- Mutations roll on spawn and multiply a brainrot's income.

local C = Color3.fromRGB
local BrainrotCatalog = {}

BrainrotCatalog.RARITIES = {
	Common = { order = 1, weight = 42, color = C(190, 200, 210) },
	Rare = { order = 2, weight = 26, color = C(80, 180, 255) },
	Epic = { order = 3, weight = 16, color = C(190, 90, 255) },
	Legendary = { order = 4, weight = 9, color = C(255, 180, 40) },
	Mythic = { order = 5, weight = 5, color = C(255, 70, 120) },
	Secret = { order = 6, weight = 2, color = C(40, 230, 190) },
}

BrainrotCatalog.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

-- Mutation table: name, income multiplier, roll weight (out of 1000).
BrainrotCatalog.MUTATIONS = {
	{ name = "Normal", mult = 1, weight = 880 },
	{ name = "Golden", mult = 3, weight = 70 },
	{ name = "Diamond", mult = 6, weight = 32 },
	{ name = "Rainbow", mult = 12, weight = 14 },
	{ name = "Void", mult = 25, weight = 4 },
}

-- Each brainrot: id, name, rarity, cost, income ($/sec), body colour, head colour,
-- accessory kind the factory builds, and a one-line joke for the Index.
BrainrotCatalog.BRAINROTS = {
	-- Common
	{ id = 1, name = "Sir Waddlesworth III", rarity = "Common", cost = 50, income = 5, body = C(255, 220, 90), head = C(255, 240, 160), accessory = "TopHat", joke = "A duck in a top hat. He insists on the III." },
	{ id = 2, name = "Toaster King", rarity = "Common", cost = 75, income = 8, body = C(200, 200, 205), head = C(230, 230, 235), accessory = "Crown", joke = "He pops up. He never pops down." },
	{ id = 3, name = "Captain Pickle", rarity = "Common", cost = 100, income = 11, body = C(90, 180, 80), head = C(120, 210, 100), accessory = "PirateHat", joke = "Sailed seven seas. All of them brine." },
	{ id = 4, name = "Banana Wizard", rarity = "Common", cost = 140, income = 15, body = C(255, 235, 60), head = C(255, 245, 130), accessory = "WizardHat", joke = "Peels back reality, one spell at a time." },
	{ id = 5, name = "Sock Puppet Supreme", rarity = "Common", cost = 180, income = 19, body = C(255, 120, 160), head = C(255, 170, 200), accessory = "Bowtie", joke = "Supreme ruler of the laundry basket." },
	{ id = 6, name = "Grandma's Slipper", rarity = "Common", cost = 230, income = 24, body = C(200, 140, 200), head = C(230, 180, 230), accessory = "Flower", joke = "Soft, warm, and impossible to lose." },
	{ id = 7, name = "Sir Hootsworth", rarity = "Common", cost = 290, income = 30, body = C(150, 110, 70), head = C(190, 150, 100), accessory = "Monocle", joke = "An owl. A gentleman. Mostly awake." },
	{ id = 8, name = "The Dancing Cactus", rarity = "Common", cost = 360, income = 38, body = C(60, 180, 90), head = C(90, 220, 120), accessory = "Sombrero", joke = "Dances. Pricks. Never apologises." },
	-- Rare
	{ id = 9, name = "DJ Toilet", rarity = "Rare", cost = 500, income = 48, body = C(240, 240, 245), head = C(255, 255, 255), accessory = "Headphones", joke = "Drops beats. Flushes the competition." },
	{ id = 10, name = "Shark in a Suit", rarity = "Rare", cost = 650, income = 62, body = C(90, 130, 180), head = C(130, 170, 220), accessory = "Tie", joke = "Middle management. Apex predator." },
	{ id = 11, name = "Professor Egg", rarity = "Rare", cost = 800, income = 78, body = C(255, 250, 230), head = C(255, 255, 245), accessory = "GradCap", joke = "Holds a PhD in being hard-boiled." },
	{ id = 12, name = "The Forbidden Burrito", rarity = "Rare", cost = 1000, income = 95, body = C(220, 170, 90), head = C(240, 200, 120), accessory = "Chilli", joke = "Do not eat. Seriously. Do not." },
	{ id = 13, name = "Sneaker Goblin", rarity = "Rare", cost = 1250, income = 115, body = C(120, 200, 90), head = C(160, 230, 120), accessory = "Cap", joke = "Steals one shoe. Always the left one." },
	{ id = 14, name = "Lava Lamp Larry", rarity = "Rare", cost = 1500, income = 135, body = C(255, 120, 60), head = C(255, 170, 100), accessory = "Sunglasses", joke = "Groovy since 1973. Still warming up." },
	{ id = 15, name = "Bubble Gum Bandit", rarity = "Rare", cost = 1800, income = 158, body = C(255, 140, 200), head = C(255, 180, 220), accessory = "Bandana", joke = "Chews gum. Takes names. Blows bubbles." },
	{ id = 16, name = "Sir Stinks-a-Lot", rarity = "Rare", cost = 2100, income = 180, body = C(140, 200, 90), head = C(170, 225, 120), accessory = "StinkLines", joke = "A skunk knight. Smells like victory." },
	-- Epic
	{ id = 17, name = "Sir Barksalot", rarity = "Epic", cost = 3000, income = 210, body = C(180, 130, 80), head = C(210, 165, 110), accessory = "SpikedCollar", joke = "Barks first. Asks questions never." },
	{ id = 18, name = "Count Spatula", rarity = "Epic", cost = 3800, income = 280, body = C(190, 190, 200), head = C(220, 220, 230), accessory = "Cape", joke = "Flips pancakes. Counts them too." },
	{ id = 19, name = "Madame Croissant", rarity = "Epic", cost = 4600, income = 350, body = C(240, 200, 120), head = C(250, 225, 160), accessory = "Beret", joke = "Flaky, buttery, and French about it." },
	{ id = 20, name = "General Noodle", rarity = "Epic", cost = 5500, income = 430, body = C(255, 230, 150), head = C(255, 245, 200), accessory = "Helmet", joke = "Commands the pasta legion. Al dente." },
	{ id = 21, name = "The Left Sock", rarity = "Epic", cost = 6500, income = 520, body = C(120, 140, 255), head = C(160, 175, 255), accessory = "EyePatch", joke = "Escaped the dryer. Never going back." },
	{ id = 22, name = "Doctor Washing Machine", rarity = "Epic", cost = 7600, income = 620, body = C(200, 210, 220), head = C(230, 240, 250), accessory = "Stethoscope", joke = "Spin cycle certified. Rinse and repeat." },
	{ id = 23, name = "The Midnight Librarian", rarity = "Epic", cost = 8800, income = 740, body = C(90, 80, 140), head = C(130, 115, 180), accessory = "Glasses", joke = "Shhh. The books are listening." },
	{ id = 24, name = "Captain Obvious", rarity = "Epic", cost = 10000, income = 880, body = C(255, 200, 60), head = C(255, 220, 120), accessory = "CaptainHat", joke = "Obviously the captain. Obviously." },
	-- Legendary
	{ id = 25, name = "Queen of the Fridge Light", rarity = "Legendary", cost = 15000, income = 1050, body = C(180, 230, 255), head = C(220, 245, 255), accessory = "Crown", joke = "She only appears when the door opens." },
	{ id = 26, name = "Lord Buckethead", rarity = "Legendary", cost = 18000, income = 1300, body = C(200, 60, 60), head = C(220, 90, 90), accessory = "Bucket", joke = "A lord. A bucket. A legend." },
	{ id = 27, name = "The Infinite Pretzel", rarity = "Legendary", cost = 22000, income = 1600, body = C(200, 150, 80), head = C(230, 185, 110), accessory = "Salt", joke = "Twisted forever. Salty about it." },
	{ id = 28, name = "Baron von Baguette", rarity = "Legendary", cost = 26000, income = 1950, body = C(230, 190, 110), head = C(245, 215, 150), accessory = "Moustache", joke = "Long, crusty, and very proud." },
	{ id = 29, name = "Emperor Couch Cushion", rarity = "Legendary", cost = 31000, income = 2350, body = C(140, 90, 180), head = C(175, 125, 210), accessory = "Crown", joke = "Rules the living room. Sits on it too." },
	{ id = 30, name = "The Mayor of Nonsense", rarity = "Legendary", cost = 37000, income = 2800, body = C(90, 200, 160), head = C(130, 225, 190), accessory = "TopHat", joke = "Elected unanimously. Nobody knows why." },
	{ id = 31, name = "The Bureaucrat of Doom", rarity = "Legendary", cost = 44000, income = 3400, body = C(120, 120, 130), head = C(160, 160, 175), accessory = "Tie", joke = "Your form was denied. In triplicate." },
	{ id = 32, name = "Duchess of the Deep Fryer", rarity = "Legendary", cost = 52000, income = 4200, body = C(255, 180, 80), head = C(255, 205, 130), accessory = "Crown", joke = "Golden, crispy, and above the law." },
	-- Mythic
	{ id = 33, name = "Chrono Toaster Prime", rarity = "Mythic", cost = 75000, income = 5200, body = C(180, 180, 195), head = C(210, 210, 225), accessory = "Crown", joke = "Toasts bread yesterday. And tomorrow." },
	{ id = 34, name = "The Unpaid Intern", rarity = "Mythic", cost = 90000, income = 6500, body = C(200, 200, 200), head = C(230, 230, 230), accessory = "Tie", joke = "Works for exposure. Exposure is $6,500/s." },
	{ id = 35, name = "Sir Reginald von Meme", rarity = "Mythic", cost = 110000, income = 8000, body = C(150, 200, 255), head = C(190, 220, 255), accessory = "Monocle", joke = "A meme so old it became nobility." },
	{ id = 36, name = "The Wi-Fi Wizard", rarity = "Mythic", cost = 130000, income = 9800, body = C(90, 140, 255), head = C(130, 175, 255), accessory = "WizardHat", joke = "His password is password. It works." },
	{ id = 37, name = "Grand Admiral Rubber Duck", rarity = "Mythic", cost = 155000, income = 11800, body = C(255, 220, 60), head = C(255, 235, 120), accessory = "CaptainHat", joke = "Commands the bathtub fleet. Squeaks orders." },
	{ id = 38, name = "The Last Slice", rarity = "Mythic", cost = 185000, income = 14000, body = C(255, 200, 80), head = C(255, 220, 140), accessory = "Cape", joke = "Everyone wants it. No one dares take it." },
	{ id = 39, name = "The Overthinker", rarity = "Mythic", cost = 220000, income = 16500, body = C(160, 140, 220), head = C(195, 180, 240), accessory = "Glasses", joke = "Still deciding. Has been since 2019." },
	{ id = 40, name = "Lord of the Lost Remote", rarity = "Mythic", cost = 260000, income = 18000, body = C(80, 80, 90), head = C(120, 120, 135), accessory = "Crown", joke = "It was in the couch all along." },
	-- Secret
	{ id = 41, name = "The One True Brainrot", rarity = "Secret", cost = 400000, income = 21000, body = C(255, 215, 0), head = C(255, 230, 100), accessory = "Crown", joke = "All other brainrots are just fan fiction." },
	{ id = 42, name = "CEO of the Void", rarity = "Secret", cost = 500000, income = 26000, body = C(40, 40, 60), head = C(70, 70, 100), accessory = "Tie", joke = "The void reports record profits." },
	{ id = 43, name = "The Algorithm Itself", rarity = "Secret", cost = 650000, income = 32000, body = C(100, 255, 200), head = C(150, 255, 220), accessory = "Glasses", joke = "It knows what you did. It liked it." },
	{ id = 44, name = "Grandma's Secret Recipe", rarity = "Secret", cost = 800000, income = 38000, body = C(255, 190, 140), head = C(255, 215, 180), accessory = "Flower", joke = "A pinch of this. A dash of that. $38k/s." },
	{ id = 45, name = "The Final Boss of Naps", rarity = "Secret", cost = 1000000, income = 44000, body = C(140, 120, 200), head = C(180, 160, 230), accessory = "NightCap", joke = "You cannot beat him. You can only join him." },
	{ id = 46, name = "He Who Must Not Be Named (Dave)", rarity = "Secret", cost = 1200000, income = 47000, body = C(90, 90, 110), head = C(130, 130, 155), accessory = "Hood", joke = "His name is Dave. Do not say Dave." },
	{ id = 47, name = "The Singularity (a sentient toaster)", rarity = "Secret", cost = 1500000, income = 49000, body = C(220, 220, 235), head = C(245, 245, 255), accessory = "Crown", joke = "It became self-aware. It chose toast." },
	{ id = 48, name = "The Infinite Loop", rarity = "Secret", cost = 2000000, income = 50000, body = C(255, 80, 200), head = C(255, 130, 220), accessory = "RainbowHalo", joke = "This description repeats. This description repeats." },
}

-- Look up a brainrot definition by its numeric id.
function BrainrotCatalog.getById(id)
	for _, entry in ipairs(BrainrotCatalog.BRAINROTS) do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

-- Roll a rarity from the weighted ladder, then pick a random brainrot of it.
function BrainrotCatalog.rollRarity()
	local total = 0
	for _, rarity in ipairs(BrainrotCatalog.RARITY_ORDER) do
		total += BrainrotCatalog.RARITIES[rarity].weight
	end
	local roll = math.random(1, total)
	local running = 0
	for _, rarity in ipairs(BrainrotCatalog.RARITY_ORDER) do
		running += BrainrotCatalog.RARITIES[rarity].weight
		if roll <= running then
			return rarity
		end
	end
	return "Common"
end

-- Roll a mutation from the weighted mutation table.
function BrainrotCatalog.rollMutation()
	local total = 0
	for _, mutation in ipairs(BrainrotCatalog.MUTATIONS) do
		total += mutation.weight
	end
	local roll = math.random(1, total)
	local running = 0
	for _, mutation in ipairs(BrainrotCatalog.MUTATIONS) do
		running += mutation.weight
		if roll <= running then
			return mutation
		end
	end
	return BrainrotCatalog.MUTATIONS[1]
end

-- Roll a full spawn: a random brainrot weighted by rarity, plus a mutation.
function BrainrotCatalog.rollSpawn()
	local rarity = BrainrotCatalog.rollRarity()
	local pool = {}
	for _, entry in ipairs(BrainrotCatalog.BRAINROTS) do
		if entry.rarity == rarity then
			table.insert(pool, entry)
		end
	end
	local picked = pool[math.random(1, #pool)]
	local mutation = BrainrotCatalog.rollMutation()
	return picked, mutation
end

return BrainrotCatalog
