-- GameSettings: every tuning number for Brainrot Bog in one place.
-- Economy, timers, world layout and progression costs. Services read these;
-- nothing else hard-codes a price or a timer.

local GameSettings = {}

-- Economy
GameSettings.START_MONEY = 100
GameSettings.SELL_FRACTION = 0.5 -- selling a brainrot refunds half its cost
GameSettings.REBIRTH_MONEY_MULTIPLIER = 2 -- each rebirth doubles all income
GameSettings.REBIRTH_MIN_BRAINROTS = 10 -- brainrots you must own to rebirth
GameSettings.REBIRTH_BASE_COST = 50000 -- x2 per rebirth already owned

-- Conveyor: the canal brainrots walk along.
GameSettings.CONVEYOR_SPAWN_INTERVAL = 4 -- seconds between spawns
GameSettings.CONVEYOR_MAX_ACTIVE = 10 -- brainrots walking at once
GameSettings.CONVEYOR_WALK_SPEED = 6 -- studs per second along the canal
GameSettings.CONVEYOR_START_X = -95
GameSettings.CONVEYOR_END_X = 95
GameSettings.CONVEYOR_Z = 0
GameSettings.CONVEYOR_Y = 3.2 -- model pivot height above the water
GameSettings.CONVEYOR_DESPAWN_SECONDS = 60 -- unsold brainrots sink away

-- Bases: 8 plots around the canal, 4 north and 4 south.
GameSettings.BASE_COUNT = 8
GameSettings.BASE_START_SLOTS = 6
GameSettings.BASE_MAX_SLOTS = 12
GameSettings.BASE_SLOT_COST = 2500 -- per extra slot, x2 per slot already bought
GameSettings.BASE_LOCK_DURATION = 60 -- seconds a bought lock lasts
GameSettings.BASE_LOCK_COOLDOWN = 30 -- seconds after a lock ends before re-locking
GameSettings.BASE_LOCK_COST = 1000 -- x2 per lock bought this life

-- Tsunami: the wave event that sweeps the map.
GameSettings.WAVE_INTERVAL = 180 -- seconds between waves
GameSettings.WAVE_WARNING_SECONDS = 15 -- banner time before the wave hits
GameSettings.WAVE_SWEEP_SECONDS = 10 -- how long the wall takes to cross the map
GameSettings.WAVE_HEIGHT = 26

-- Stealing and slapping.
GameSettings.SLAP_RANGE = 9 -- studs
GameSettings.SLAP_COOLDOWN = 2 -- seconds between slaps
GameSettings.SLAP_BASE_POWER = 1 -- drops a carried brainrot
GameSettings.CARRY_FOLLOW_HEIGHT = 1 -- studs above the carrier's head

-- Upgrades (each level costs base * 2 ^ level).
GameSettings.UPGRADES = {
	WalkSpeed = { name = "Walk Speed", baseCost = 800, maxLevel = 5, desc = "+15% walk speed per level" },
	SlapPower = { name = "Slap Power", baseCost = 1200, maxLevel = 5, desc = "Slap knocks victims back further" },
	IncomeBoost = { name = "Income Boost", baseCost = 5000, maxLevel = 10, desc = "+25% income per level" },
}

-- World layout (studs). Bases sit north (z = -42) and south (z = +42).
GameSettings.BASE_POSITIONS = {
	Vector3.new(-75, 0, -42),
	Vector3.new(-25, 0, -42),
	Vector3.new(25, 0, -42),
	Vector3.new(75, 0, -42),
	Vector3.new(-75, 0, 42),
	Vector3.new(-25, 0, 42),
	Vector3.new(25, 0, 42),
	Vector3.new(75, 0, 42),
}
GameSettings.BASE_SIZE = Vector3.new(30, 1, 26)
GameSettings.SPAWN_POSITION = Vector3.new(-108, 4, 26)
GameSettings.ISLAND_SIZE = Vector3.new(240, 2, 140)
GameSettings.CANAL_SIZE = Vector3.new(210, 1, 16)

return GameSettings
