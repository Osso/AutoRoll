
local addon, ns = ...

ns.RollModes = {
	PASS = 0,
	NEED = 1,
	GREED = 2,
	DISENCHANT = 3,
	TRANSMOG = 4,
	DO_NOTHING = 5, -- Internal only - don't roll at all
}

local ROLL_PASS = ns.RollModes.PASS
local ROLL_NEED = ns.RollModes.NEED
local ROLL_GREED = ns.RollModes.GREED
local ROLL_DISENCHANT = ns.RollModes.DISENCHANT
local ROLL_TRANSMOG = ns.RollModes.TRANSMOG
local ROLL_DO_NOTHING = ns.RollModes.DO_NOTHING

ns.ModeLabels = {
	[ROLL_GREED] = "Greed",
	[ROLL_NEED] = "Need",
	[ROLL_DISENCHANT] = "Disenchant",
	[ROLL_TRANSMOG] = "Transmog",
	[ROLL_PASS] = "Pass",
	[ROLL_DO_NOTHING] = "Do nothing",
}
ns.DefaultRollModeOptions = {
	ROLL_PASS,
	ROLL_GREED,
	ROLL_NEED,
	ROLL_DISENCHANT,
	ROLL_TRANSMOG,
	ROLL_DO_NOTHING,
}
ns.FallbackRollModeOptions = {
	ROLL_DO_NOTHING,
	ROLL_PASS,
	ROLL_GREED,
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

local function mergeMissingDefaults(savedValues, defaultValues)
	for settingName, defaultValue in pairs(defaultValues) do
		if savedValues[settingName] == nil then
			if type(defaultValue) == "table" then
				savedValues[settingName] = {}
			else
				savedValues[settingName] = defaultValue
			end
		end

		local savedValue = savedValues[settingName]
		if type(defaultValue) == "table" and type(savedValue) == "table" then
			for nestedSettingName, nestedDefaultValue in pairs(defaultValue) do
				if savedValue[nestedSettingName] == nil then
					savedValue[nestedSettingName] = nestedDefaultValue
				end
			end
		end
	end
end

if not AutoRollDB then
	AutoRollDB = {}
end
mergeMissingDefaults(AutoRollDB, ns.AutoRollDB_defaults)

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
	for _, value in ipairs({...}) do
		print(value)
	end
end

local function isInSupportedRaid()
	local instanceName, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
	if instanceType ~= "raid" then
		return false, nil
	end
	if not ns.RaidInstances[instanceID] then
		return false, nil
	end
	if not AutoRollDB.raidSettings or not AutoRollDB.raidSettings[instanceID] then
		return false, nil
	end

	return true, instanceID, instanceName
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

function main.SuppressLootHistory(_, frame)
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

function main.ADDON_LOADED(_, name)
	if addon ~= name then
		return
	end

	ns.initSettingsPanel()
	ns.print("|Cffffff00Addon loaded...|r")
	if AutoRollDB.enabled then
		ns.AddOnEnabled()
	end
end

local function getLootRollItemCapabilities(rollID)
	local _, itemName, _, _, _, canNeed, canGreed, canDisenchant, _, _, _, _, canTransmog =
		GetLootRollItemInfo(rollID)

	return itemName, {
		canNeed = canNeed,
		canGreed = canGreed,
		canDisenchant = canDisenchant,
		canTransmog = canTransmog,
	}
end

local function isDesiredRollModeAvailable(rollMode, capabilities)
	if rollMode == ROLL_NEED then
		return capabilities.canNeed
	elseif rollMode == ROLL_GREED then
		return capabilities.canGreed
	elseif rollMode == ROLL_DISENCHANT then
		return capabilities.canDisenchant
	elseif rollMode == ROLL_TRANSMOG then
		return capabilities.canTransmog
	end

	return rollMode == ROLL_PASS or rollMode == ROLL_DO_NOTHING
end

local function selectRollMode(desiredRollMode, fallbackRollMode, capabilities)
	if isDesiredRollModeAvailable(desiredRollMode, capabilities) then
		return desiredRollMode
	end
	if fallbackRollMode == ROLL_GREED and capabilities.canGreed then
		return ROLL_GREED
	end
	if fallbackRollMode == ROLL_PASS then
		return ROLL_PASS
	end

	return nil
end

local function reportMissingLootItem(rollID, itemName)
	ns.debugPrint(
		"Event: START_LOOT_ROLL",
		"rollID: " .. (rollID or "missing roll id"),
		"itemName: " .. (itemName or "missing item name")
	)
end

local function applyAndReportSelectedRoll(rollID, itemName, desiredRollMode, selectedRollMode)
	if selectedRollMode and selectedRollMode ~= ROLL_DO_NOTHING then
		RollOnLoot(rollID, selectedRollMode)
	end

	ns.debugPrint(
		"Event: START_LOOT_ROLL",
		"itemName: " .. (itemName or "unknown"),
		"rollID: " .. rollID,
		"Desired: " .. (ns.ModeLabels[desiredRollMode] or "nothing"),
		"Actual: " .. (selectedRollMode and ns.ModeLabels[selectedRollMode] or "nothing")
	)

	if selectedRollMode then
		ns.print(itemName, "=", ns.ModeLabels[selectedRollMode])
	end
end

function main.START_LOOT_ROLL(_, rollID)
	local inRaid, raidID, raidName = isInSupportedRaid()
	if not inRaid then
		ns.debugPrint("Not in a supported raid or raid is disabled, skipping roll")
		return
	end

	local itemName, capabilities = getLootRollItemCapabilities(rollID)
	if not rollID or not itemName then
		reportMissingLootItem(rollID, itemName)
		return
	end

	ns.debugPrint("Rolling in raid:", raidName, "(ID:", raidID, ")")
	local desiredRollMode = AutoRollDB.defaultRollMode
	local selectedRollMode = selectRollMode(desiredRollMode, AutoRollDB.fallbackRollMode, capabilities)
	applyAndReportSelectedRoll(rollID, itemName, desiredRollMode, selectedRollMode)
end

local function dispatchEvent(self, event, ...)
	local handler = main[event]
	if handler then
		handler(self, ...)
	end
end

main:SetScript("OnEvent", dispatchEvent)
main:RegisterEvent("ADDON_LOADED")
