
local addon, ns = ...

local function onSettingEnabled()
	ns.AddOnEnabled()
end

local function registerTopLevelCheckbox(category, variableKey, name, tooltip, callback)
	local defaultValue = ns.AutoRollDB_defaults[variableKey]
	local setting = Settings.RegisterAddOnSetting(
		category, addon .. "_" .. variableKey, variableKey,
		AutoRollDB, type(defaultValue), name, defaultValue
	)
	Settings.CreateCheckbox(category, setting, tooltip)
	if callback then
		setting:SetValueChangedCallback(callback)
	end
end

local function createRollOptions(rollModes)
	local container = Settings.CreateControlTextContainer()
	for _, rollMode in ipairs(rollModes) do
		container:Add(rollMode, ns.ModeLabels[rollMode])
	end
	return container:GetData()
end

local function registerDropdown(category, variableKey, name, tooltip, rollModes)
	local defaultValue = ns.AutoRollDB_defaults[variableKey]
	local function getOptions()
		return createRollOptions(rollModes)
	end

	local setting = Settings.RegisterAddOnSetting(
		category, addon .. "_" .. variableKey, variableKey,
		AutoRollDB, type(defaultValue), name, defaultValue
	)
	Settings.CreateDropdown(category, setting, getOptions, tooltip)
end

local function registerRaidCheckbox(category, raid)
	local variableKey = raid.instanceID
	local tooltip = "Enable AutoRoll in " .. raid.name
	local defaultValue = ns.AutoRollDB_defaults.raidSettings[raid.instanceID]
	local setting = Settings.RegisterAddOnSetting(
		category, addon .. "_raid_" .. raid.instanceID, variableKey,
		AutoRollDB.raidSettings, type(defaultValue), raid.name, defaultValue
	)
	Settings.CreateCheckbox(category, setting, tooltip)
end

local function registerCoreSettings(category)
	registerTopLevelCheckbox(
		category, "enabled", "Enable AutoRoll",
		"Enables the auto roll functionality", onSettingEnabled
	)
	registerTopLevelCheckbox(
		category, "debugMode", "Debug Mode",
		"Enable debug mode for troubleshooting"
	)
	registerDropdown(
		category, "defaultRollMode", "Default Roll Mode",
		"The default roll mode to use for loot", ns.DefaultRollModeOptions
	)
	registerDropdown(
		category, "fallbackRollMode", "Fallback Roll Mode",
		"The roll mode to use when the default roll mode is not available", ns.FallbackRollModeOptions
	)
	registerTopLevelCheckbox(
		category, "autoCloseLootWindow", "Hide Loot History",
		"Hide the loot history window while in an enabled raid"
	)
end

local function registerRaidSettings(category, layout)
	for _, raidGroup in ipairs(ns.RaidGroups) do
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(raidGroup.expansion .. " Raids"))
		for _, raid in ipairs(raidGroup.raids) do
			registerRaidCheckbox(category, raid)
		end
	end
end

function ns.initSettingsPanel()
	local category, layout = Settings.RegisterVerticalLayoutCategory(addon)
	registerCoreSettings(category)
	registerRaidSettings(category, layout)
	Settings.RegisterAddOnCategory(category)
end
