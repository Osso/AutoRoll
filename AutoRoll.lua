
local addon, ns = ...

-- Roll constants (match WoW API RollOnLoot parameters)
local ROLL_PASS = 0
local ROLL_NEED = 1
local ROLL_GREED = 2
local ROLL_DISENCHANT = 3
local ROLL_TRANSMOG = 4
local ROLL_DO_NOTHING = 5  -- Internal only - don't roll at all

ns.ModeLabels = {
	[ROLL_GREED] = "Greed",
	[ROLL_NEED] = "Need",
	[ROLL_DISENCHANT] = "Disenchant",
	[ROLL_TRANSMOG] = "Transmog",
	[ROLL_PASS] = "Pass",
	[ROLL_DO_NOTHING] = "Do nothing"
}
ns.RaidGroups = {
	{
		expansion = "Shadowlands",
		raids = {
			{instanceID = 2296, name = "Castle Nathria", enabledByDefault = true},
			{instanceID = 2450, name = "Sanctum of Domination", enabledByDefault = true},
			{instanceID = 2481, name = "Sepulcher of the First Ones", enabledByDefault = true},
		},
	},
	{
		expansion = "Dragonflight",
		raids = {
			{instanceID = 2522, name = "Vault of the Incarnates", enabledByDefault = true},
			{instanceID = 2569, name = "Aberrus, the Shadowed Crucible", enabledByDefault = true},
			{instanceID = 2549, name = "Amirdrassil, the Dream's Hope", enabledByDefault = true},
		},
	},
	{
		expansion = "The War Within",
		raids = {
			{instanceID = 2657, name = "Nerub-ar Palace", enabledByDefault = false},
			{instanceID = 2769, name = "Liberation of Undermine", enabledByDefault = false},
			{instanceID = 2810, name = "Manaforge: Omega", enabledByDefault = false},
		},
	},
}

ns.RaidInstances = {}
local raidSettingsDefaults = {}
for _, raidGroup in ipairs(ns.RaidGroups) do
	for _, raid in ipairs(raidGroup.raids) do
		ns.RaidInstances[raid.instanceID] = raid.name
		raidSettingsDefaults[raid.instanceID] = raid.enabledByDefault
	end
end

-- Default database structure
ns.AutoRollDB_defaults = {
	enabled = true,
	debugMode = false,
	defaultRollMode = ROLL_GREED,
	fallbackRollMode = ROLL_DO_NOTHING,
	raidSettings = raidSettingsDefaults,
	autoCloseLootWindow = true,
}

-- Initialize saved variables
if not AutoRollDB then
	AutoRollDB = {}
end

-- Merge defaults with saved data
for k, v in pairs(ns.AutoRollDB_defaults) do
	if AutoRollDB[k] == nil then
		if type(v) == "table" then
			-- Deep copy for nested tables
			AutoRollDB[k] = {}
			for k2, v2 in pairs(v) do
				AutoRollDB[k][k2] = v2
			end
		else
			AutoRollDB[k] = v
		end
	else
		-- For existing tables, merge missing keys
		if type(v) == "table" and type(AutoRollDB[k]) == "table" then
			for k2, v2 in pairs(v) do
				if AutoRollDB[k][k2] == nil then
					AutoRollDB[k][k2] = v2
				end
			end
		end
	end
end

function ns.print(arg1, ...)
	if arg1 == nil then
		print(...)
	else
		print("[|Cff3388ff" .. addon .. "|r]", arg1, ...)
	end
end

function ns.debugPrint(...)
	if not AutoRollDB or not AutoRollDB.debugMode then
		return
	end

	ns.print("(Debug Message)")
	for i, v in ipairs({...}) do
		print(v)
	end
end

-- Check if we're currently in a supported raid
local function isInSupportedRaid()
	local instanceName, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()

	-- Check if we're in a raid instance
	if instanceType ~= "raid" then
		return false, nil
	end

	-- Check if this raid is in our supported list
	if ns.RaidInstances[instanceID] then
		-- Check if this raid is enabled in settings
		if AutoRollDB.raidSettings and AutoRollDB.raidSettings[instanceID] then
			return true, instanceID, instanceName
		end
	end

	return false, nil
end
ns.isInSupportedRaid = isInSupportedRaid

local main = CreateFrame("Frame", "AutoRollFrame")

function ns.AddOnEnabled()
	if AutoRollDB and AutoRollDB.enabled then
		main:RegisterEvent("START_LOOT_ROLL")
	else
		main:UnregisterEvent("START_LOOT_ROLL")
	end
	ns.print("|cffffff00Addon", (AutoRollDB and AutoRollDB.enabled and "enabled" or "disabled") .. "...|r")
end

function main:SuppressLootHistory(frame)
	if AutoRollDB.autoCloseLootWindow and ns.isInSupportedRaid() then
		ns.debugPrint("Suppressing loot history window")
		frame:Hide()
	end
end

if GroupLootHistoryFrame then
	GroupLootHistoryFrame:HookScript("OnShow", function(frame)
		main:SuppressLootHistory(frame)
	end)
end

function main:ADDON_LOADED(name)
	if addon ~= name then
		return
	end

	ns.initSettingsPanel()
	ns.print("|Cffffff00Addon loaded...|r")
	if AutoRollDB.enabled then
		ns.AddOnEnabled()
	end
end

function main:START_LOOT_ROLL(rollID)
	-- Check if we're in a supported raid first
	local inRaid, raidID, raidName = isInSupportedRaid()
	if not inRaid then
		ns.debugPrint("Not in a supported raid or raid is disabled, skipping roll")
		return
	end

	local _, name, _, _, _, canNeed, canGreed, canDisenchant, _, _, _, _, canTransmog = GetLootRollItemInfo(rollID)

	if not rollID or not name then
		ns.debugPrint(
			"Event: START_LOOT_ROLL",
			"rollID: " .. (rollID or "missing roll id"),
			"itemName: " .. (name or "missing item name")
		)
		return
	end

	ns.debugPrint("Rolling in raid:", raidName, "(ID:", raidID, ")")

	local itemRollMode = AutoRollDB.defaultRollMode
	local actualRollMode = nil

	-- Try to use the desired roll mode, fall back if not available
	if itemRollMode == ROLL_NEED and canNeed then
		RollOnLoot(rollID, ROLL_NEED)
		actualRollMode = ROLL_NEED
	elseif itemRollMode == ROLL_DISENCHANT and canDisenchant then
		RollOnLoot(rollID, ROLL_DISENCHANT)
		actualRollMode = ROLL_DISENCHANT
	elseif itemRollMode == ROLL_GREED and canGreed then
		RollOnLoot(rollID, ROLL_GREED)
		actualRollMode = ROLL_GREED
	elseif itemRollMode == ROLL_TRANSMOG and canTransmog then
		RollOnLoot(rollID, ROLL_TRANSMOG)
		actualRollMode = ROLL_TRANSMOG
	elseif itemRollMode == ROLL_PASS then
		RollOnLoot(rollID, ROLL_PASS)
		actualRollMode = ROLL_PASS
	elseif itemRollMode == ROLL_DO_NOTHING then
		actualRollMode = ROLL_DO_NOTHING
	end

	if actualRollMode == nil then
		-- Desired roll mode not available, use fallback
		local fallbackMode = AutoRollDB.fallbackRollMode
		if fallbackMode == ROLL_GREED and canGreed then
			RollOnLoot(rollID, ROLL_GREED)
			actualRollMode = ROLL_GREED
		elseif fallbackMode == ROLL_PASS then
			RollOnLoot(rollID, ROLL_PASS)
			actualRollMode = ROLL_PASS
		-- If fallback is ROLL_DO_NOTHING or also not available, don't roll
		end
	end

	ns.debugPrint(
		"Event: START_LOOT_ROLL",
		"itemName: " .. (name or "unknown"),
		"rollID: " .. rollID,
		"Desired: " .. (ns.ModeLabels[itemRollMode] or "nothing"),
		"Actual: " .. (actualRollMode and ns.ModeLabels[actualRollMode] or "nothing")
	)

	if actualRollMode then
		ns.print(name, "=", ns.ModeLabels[actualRollMode])
	end
end

main:SetScript("OnEvent", function(self, event, ...) if main[event] then main[event](self, ...) end end)
main:RegisterEvent("ADDON_LOADED")
