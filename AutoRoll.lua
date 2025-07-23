
local addon, ns = ...
local version = 1

-- Roll constants (match WoW API RollOnLoot parameters)
local ROLL_PASS = 0
local ROLL_NEED = 1
local ROLL_GREED = 2
local ROLL_DISENCHANT = 3
local ROLL_TRANSMOG = 4
local ROLL_DO_NOTHING = 5  -- Internal only - don't roll at all

-- ModeLabels indexed by our roll constants (0-based indexing won't work for Lua tables, so we adjust)
ns.ModeLabels = {
	[ROLL_GREED] = "Greed",
	[ROLL_NEED] = "Need",
	[ROLL_DISENCHANT] = "Disenchant",
	[ROLL_TRANSMOG] = "Transmog",
	[ROLL_PASS] = "Pass",
	[ROLL_DO_NOTHING] = "Do nothing"
}
-- Raid instance IDs for raids with loot rolls (Shadowlands, Dragonflight, The War Within)
ns.RaidInstances = {
	-- Shadowlands
	[13224] = "Castle Nathria",
	[13561] = "Sanctum of Domination",
	[13742] = "Sepulcher of the First Ones",
	-- Dragonflight
	[14030] = "Vault of the Incarnates",
	[14663] = "Aberrus, the Shadowed Crucible",
	[14643] = "Amirdrassil, the Dream's Hope",
	-- The War Within
	[14980] = "Nerub-ar Palace",
	[15522] = "Liberation of Undermine",
	[99999] = "Manaforge: Omega" -- Placeholder ID, update when available
}

-- Default database structure
ns.AutoRollDB_defaults = {
	enabled = true,
	debugMode = false,
	defaultRollMode = ROLL_GREED,
	fallbackRollMode = ROLL_DO_NOTHING,
	version = 1,
	raidSettings = {
		-- Shadowlands
		[13224] = true, -- Castle Nathria
		[13561] = true, -- Sanctum of Domination
		[13742] = true, -- Sepulcher of the First Ones
		-- Dragonflight
		[14030] = true, -- Vault of the Incarnates
		[14663] = true, -- Aberrus, the Shadowed Crucible
		[14643] = true, -- Amirdrassil, the Dream's Hope
		-- The War Within
		[14980] = false, -- Nerub-ar Palace
		[15522] = false, -- Liberation of Undermine
		[99999] = false  -- Manaforge: Omega (placeholder)
	},
	items = {
		[120945] = ROLL_GREED, -- Primal Spirit
		[116920] = ROLL_DO_NOTHING, -- True steel lockbox
	}
}
ns.pendingItemInfo = nil

-- Initialize saved variables
if not AutoRollDB then
	AutoRollDB = {}
end

-- Merge defaults with saved data
for k, v in pairs(ns.AutoRollDB_defaults) do
	if AutoRollDB[k] == nil then
		AutoRollDB[k] = v
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
	if not AutoRollDB or not AutoRollDB.debugMode then return end
	ns.print("(Debug Message)")
	for i, v in ipairs({...}) do
		print(v)
	end
end

local itemNames = {}
local function updateItemNames()
	wipe(itemNames)
	if not AutoRollDB then return end
	for i, v in pairs(AutoRollDB.items) do
		local name = GetItemInfo(i)
		if name then
			itemNames[name] = v
		end
	end
end
ns.updateItemNames = updateItemNames

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
		updateItemNames()
	else
		main:UnregisterEvent("START_LOOT_ROLL")
	end
	ns.print("|cffffff00Addon", (AutoRollDB and AutoRollDB.enabled and "enabled" or "disabled") .. "...|r")
end

function main:ADDON_LOADED(name)
	if addon ~= name then
		return
	end
	
	ns.print("|Cffffff00Addon loaded...|r")
	AutoRollDB.version = version
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

	local itemRollMode = itemNames[name] or AutoRollDB.defaultRollMode -- use default roll mode when not in item list
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
	elseif itemRollMode ~= ROLL_DO_NOTHING then
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


function main:GET_ITEM_INFO_RECEIVED(itemId)
	if ns.pendingItemInfo then
		local source, originalCommand, expectedItemId = unpack(ns.pendingItemInfo)
		ns.pendingItemInfo = nil
		if source == "sc" and itemId == expectedItemId then
			ns.debugPrint(
				"Event: GET_ITEM_INFO_RECEIVED",
				"itemID: " .. itemId,
				"GetItemInfo" .. table.concat({GetItemInfo(itemId)}, ", ")
			)
			SlashCmdList["AUTOROLL"](originalCommand, true)
		end
	end
end

main:SetScript("OnEvent", function(self, event, ...) if main[event] then main[event](self, ...) end end)
main:RegisterEvent("ADDON_LOADED")
main:RegisterEvent("GET_ITEM_INFO_RECEIVED")
