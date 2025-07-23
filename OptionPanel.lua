
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
		local setting = Settings.RegisterAddOnSetting(category, addon.."_"..variableKey, variableKey, AutoRollDB, type(defaultValue), name, defaultValue)
		Settings.CreateCheckbox(category, setting, tooltip)
		setting:SetValueChangedCallback(OnSettingEnabled)
	end

	do
		local variableKey = "debugMode"
		local name = "Debug Mode"
		local tooltip = "Enable debug mode for troubleshooting"
		local defaultValue = ns.AutoRollDB_defaults[variableKey]
		local setting = Settings.RegisterAddOnSetting(category, addon.."_"..variableKey, variableKey, AutoRollDB, type(defaultValue), name, defaultValue)
		Settings.CreateCheckbox(category, setting, tooltip)
	end

	do
		local variableKey = "defaultRollMode"
		local name = "Default Roll Mode"
		local tooltip = "The default roll mode for items not in the item list"
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
		
		local setting = Settings.RegisterAddOnSetting(category, addon.."_"..variableKey, variableKey, AutoRollDB, type(defaultValue), name, defaultValue)
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
		
		local setting = Settings.RegisterAddOnSetting(category, addon.."_"..variableKey, variableKey, AutoRollDB, type(defaultValue), name, defaultValue)
		Settings.CreateDropdown(category, setting, GetOptions, tooltip)
	end

	-- Add raid settings sections by expansion
	do
		-- Ensure raidSettings table exists
		if not AutoRollDB.raidSettings then
			AutoRollDB.raidSettings = {}
		end
		
		-- Shadowlands raids
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Shadowlands Raids"))
		
		local shadowlandsRaids = {
			{13224, "Castle Nathria"},
			{13561, "Sanctum of Domination"},
			{13742, "Sepulcher of the First Ones"}
		}
		
		for _, raidData in ipairs(shadowlandsRaids) do
			local instanceID, raidName = raidData[1], raidData[2]
			local variableKey = instanceID
			local tooltip = "Enable AutoRoll in " .. raidName
			local defaultValue = ns.AutoRollDB_defaults.raidSettings[instanceID]
			
			local setting = Settings.RegisterAddOnSetting(category, "raid_" .. instanceID, variableKey, AutoRollDB.raidSettings, type(defaultValue), raidName, defaultValue)
			Settings.CreateCheckbox(category, setting, tooltip)
		end
		
		-- Dragonflight raids
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Dragonflight Raids"))
		
		local dragonflightRaids = {
			{14030, "Vault of the Incarnates"},
			{14663, "Aberrus, the Shadowed Crucible"},
			{14643, "Amirdrassil, the Dream's Hope"}
		}
		
		for _, raidData in ipairs(dragonflightRaids) do
			local instanceID, raidName = raidData[1], raidData[2]
			local variableKey = instanceID
			local tooltip = "Enable AutoRoll in " .. raidName
			
			-- Set default value if not exists
			if AutoRollDB.raidSettings[instanceID] == nil then
				AutoRollDB.raidSettings[instanceID] = ns.AutoRollDB_defaults.raidSettings[instanceID]
			end
			
			local setting = Settings.RegisterAddOnSetting(category, addon.."_raid_" .. instanceID, variableKey, AutoRollDB.raidSettings, type(true), raidName, true)
			Settings.CreateCheckbox(category, setting, tooltip)
		end
		
		-- The War Within raids
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("The War Within Raids"))
		
		local twwRaids = {
			{14980, "Nerub-ar Palace"},
			{15522, "Liberation of Undermine"},
			{99999, "Manaforge: Omega"}
		}
		
		for _, raidData in ipairs(twwRaids) do
			local instanceID, raidName = raidData[1], raidData[2]
			local variableKey = instanceID
			local tooltip = "Enable AutoRoll in " .. raidName
			
			-- Set default value if not exists
			if AutoRollDB.raidSettings[instanceID] == nil then
				AutoRollDB.raidSettings[instanceID] = ns.AutoRollDB_defaults.raidSettings[instanceID]
			end
			
			local setting = Settings.RegisterAddOnSetting(category, addon.."_raid_" .. instanceID, variableKey, AutoRollDB.raidSettings, type(true), raidName, true)
			Settings.CreateCheckbox(category, setting, tooltip)
		end
	end

	Settings.RegisterAddOnCategory(category)
end
