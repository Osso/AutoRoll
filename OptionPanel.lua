
local addon, ns = ...

local function OnSettingEnabled(setting, value)
	ns.AddOnEnabled()
end

function ns.initSettingsPanel()
	local category, layout = Settings.RegisterVerticalLayoutCategory(addon)

	do
		local variableKey = "enabled"
		local name = "Enable AutoRoll"
		local tooltip = "Enables the auto roll functionality"
		local defaultValue = ns.AutoRollDB_defaults[variableKey]
		local setting = Settings.RegisterAddOnSetting(
			category, addon.."_"..variableKey, variableKey, AutoRollDB, type(defaultValue), name, defaultValue
		)
		Settings.CreateCheckbox(category, setting, tooltip)
		setting:SetValueChangedCallback(OnSettingEnabled)
	end

	do
		local variableKey = "debugMode"
		local name = "Debug Mode"
		local tooltip = "Enable debug mode for troubleshooting"
		local defaultValue = ns.AutoRollDB_defaults[variableKey]
		local setting = Settings.RegisterAddOnSetting(
			category, addon.."_"..variableKey, variableKey, AutoRollDB, type(defaultValue), name, defaultValue
		)
		Settings.CreateCheckbox(category, setting, tooltip)
	end

	do
		local variableKey = "defaultRollMode"
		local name = "Default Roll Mode"
		local tooltip = "The default roll mode to use for loot"
		local defaultValue = ns.AutoRollDB_defaults.defaultRollMode

		local function GetOptions()
			local container = Settings.CreateControlTextContainer()
			container:Add(0, "Pass")
			container:Add(2, "Greed")
			container:Add(1, "Need")
			container:Add(3, "Disenchant")
			container:Add(4, "Transmog")
			container:Add(5, "Do nothing")
			return container:GetData()
		end

		local setting = Settings.RegisterAddOnSetting(
			category, addon.."_"..variableKey, variableKey, AutoRollDB, type(defaultValue), name, defaultValue
		)
		Settings.CreateDropdown(category, setting, GetOptions, tooltip)
	end

	do
		local variableKey = "fallbackRollMode"
		local name = "Fallback Roll Mode"
		local tooltip = "The roll mode to use when the default roll mode is not available"
		local defaultValue = ns.AutoRollDB_defaults.fallbackRollMode

		local function GetOptions()
			local container = Settings.CreateControlTextContainer()
			container:Add(5, "Do nothing")
			container:Add(0, "Pass")
			container:Add(2, "Greed")
			return container:GetData()
		end

		local setting = Settings.RegisterAddOnSetting(
			category, addon.."_"..variableKey, variableKey, AutoRollDB, type(defaultValue), name, defaultValue
		)
		Settings.CreateDropdown(category, setting, GetOptions, tooltip)
	end

	do
		local variableKey = "autoCloseLootWindow"
		local name = "Hide Loot History"
		local tooltip = "Hide the loot history window while in an enabled raid"
		local defaultValue = ns.AutoRollDB_defaults[variableKey]
		local setting = Settings.RegisterAddOnSetting(
			category, addon.."_"..variableKey, variableKey, AutoRollDB, type(defaultValue), name, defaultValue
		)
		Settings.CreateCheckbox(category, setting, tooltip)
	end

	-- Add raid settings sections by expansion
	for _, raidGroup in ipairs(ns.RaidGroups) do
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(raidGroup.expansion .. " Raids"))

		for _, raid in ipairs(raidGroup.raids) do
			local variableKey = raid.instanceID
			local tooltip = "Enable AutoRoll in " .. raid.name
			local defaultValue = ns.AutoRollDB_defaults.raidSettings[raid.instanceID]
			local setting = Settings.RegisterAddOnSetting(
				category, addon.."_raid_" .. raid.instanceID, variableKey,
				AutoRollDB.raidSettings, type(defaultValue), raid.name, defaultValue
			)
			Settings.CreateCheckbox(category, setting, tooltip)
		end
	end

	Settings.RegisterAddOnCategory(category)
end
