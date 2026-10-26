local captured = {
	settings = {},
	checkboxes = {},
	dropdowns = {},
	sectionLabels = {},
	addonCategories = {},
}

local original = {
	registerVerticalLayoutCategory = Settings.RegisterVerticalLayoutCategory,
	registerAddOnSetting = Settings.RegisterAddOnSetting,
	createCheckbox = Settings.CreateCheckbox,
	createDropdown = Settings.CreateDropdown,
	registerAddOnCategory = Settings.RegisterAddOnCategory,
	createSectionHeader = CreateSettingsListSectionHeaderInitializer,
	createControlTextContainer = Settings.CreateControlTextContainer,
}

local function installRegistrationCapture()
	Settings.RegisterVerticalLayoutCategory = function(...)
		local category, layout = original.registerVerticalLayoutCategory(...)
		captured.category = category
		captured.layout = layout
		return category, layout
	end

	Settings.RegisterAddOnSetting = function(category, settingID, variableKey, storage, valueType, label, defaultValue)
		local setting = original.registerAddOnSetting(
			category, settingID, variableKey, storage, valueType, label, defaultValue
		)
		captured.settings[#captured.settings + 1] = {
			category = category,
			settingID = settingID,
			variableKey = variableKey,
			storage = storage,
			valueType = valueType,
			label = label,
			defaultValue = defaultValue,
			setting = setting,
		}
		return setting
	end

	Settings.CreateCheckbox = function(category, setting, tooltip)
		captured.checkboxes[#captured.checkboxes + 1] = {
			category = category,
			setting = setting,
			tooltip = tooltip,
		}
		return original.createCheckbox(category, setting, tooltip)
	end

	Settings.CreateDropdown = function(category, setting, getOptions, tooltip)
		captured.dropdowns[#captured.dropdowns + 1] = {
			category = category,
			setting = setting,
			getOptions = getOptions,
			tooltip = tooltip,
		}
		return original.createDropdown(category, setting, getOptions, tooltip)
	end

	Settings.RegisterAddOnCategory = function(category)
		captured.addonCategories[#captured.addonCategories + 1] = category
		return original.registerAddOnCategory(category)
	end

	CreateSettingsListSectionHeaderInitializer = function(label)
		captured.sectionLabels[#captured.sectionLabels + 1] = label
		return original.createSectionHeader(label)
	end
end

local function restoreRegistrationFunctions()
	Settings.RegisterVerticalLayoutCategory = original.registerVerticalLayoutCategory
	Settings.RegisterAddOnSetting = original.registerAddOnSetting
	Settings.CreateCheckbox = original.createCheckbox
	Settings.CreateDropdown = original.createDropdown
	Settings.RegisterAddOnCategory = original.registerAddOnCategory
	CreateSettingsListSectionHeaderInitializer = original.createSectionHeader
end

local function loadAutoRollWithRegistrationCapture()
	installRegistrationCapture()
	local callSucceeded, loaded, reason = pcall(C_AddOns.LoadAddOn, "AutoRoll")
	restoreRegistrationFunctions()
	if not callSucceeded then
		error(loaded, 0)
	end
	assertTrue(loaded, "failed to load AutoRoll: " .. tostring(reason))
end

local function findSetting(settingID)
	for _, registeredSetting in ipairs(captured.settings) do
		if registeredSetting.settingID == settingID then
			return registeredSetting
		end
	end
	return nil
end

local function findControl(controls, setting)
	for _, control in ipairs(controls) do
		if control.setting == setting then
			return control
		end
	end
	return nil
end

local function assertSetting(expected)
	local registered = findSetting(expected.settingID)
	assertNotNil(registered)
	assertEquals(captured.category, registered.category)
	assertEquals(expected.variableKey, registered.variableKey)
	assertEquals(expected.storage, registered.storage)
	assertEquals(expected.valueType, registered.valueType)
	assertEquals(expected.label, registered.label)
	assertEquals(expected.defaultValue, registered.defaultValue)

	local controls = expected.controlType == "checkbox" and captured.checkboxes or captured.dropdowns
	local control = findControl(controls, registered.setting)
	assertNotNil(control)
	assertEquals(captured.category, control.category)
	assertEquals(expected.tooltip, control.tooltip)
	return control
end

local function captureDropdownOptions(getOptions)
	local options = {}
	Settings.CreateControlTextContainer = function()
		local container = original.createControlTextContainer()
		return {
			Add = function(_, value, label)
				options[#options + 1] = {value = value, label = label}
				return container:Add(value, label)
			end,
			GetData = function()
				return container:GetData()
			end,
		}
	end

	local callSucceeded, callError = pcall(getOptions)
	Settings.CreateControlTextContainer = original.createControlTextContainer
	if not callSucceeded then
		error(callError, 0)
	end
	return options
end

loadAutoRollWithRegistrationCapture()

local coreSettings = {
	{
		settingID = "AutoRoll_enabled", variableKey = "enabled", storage = AutoRollDB,
		valueType = "boolean", label = "Enable AutoRoll", defaultValue = true,
		tooltip = "Enables the auto roll functionality", controlType = "checkbox",
	},
	{
		settingID = "AutoRoll_debugMode", variableKey = "debugMode", storage = AutoRollDB,
		valueType = "boolean", label = "Debug Mode", defaultValue = false,
		tooltip = "Enable debug mode for troubleshooting", controlType = "checkbox",
	},
	{
		settingID = "AutoRoll_defaultRollMode", variableKey = "defaultRollMode", storage = AutoRollDB,
		valueType = "number", label = "Default Roll Mode", defaultValue = 2,
		tooltip = "The default roll mode to use for loot", controlType = "dropdown",
	},
	{
		settingID = "AutoRoll_fallbackRollMode", variableKey = "fallbackRollMode", storage = AutoRollDB,
		valueType = "number", label = "Fallback Roll Mode", defaultValue = 5,
		tooltip = "The roll mode to use when the default roll mode is not available", controlType = "dropdown",
	},
	{
		settingID = "AutoRoll_autoCloseLootWindow", variableKey = "autoCloseLootWindow", storage = AutoRollDB,
		valueType = "boolean", label = "Hide Loot History", defaultValue = true,
		tooltip = "Hide the loot history window while in an enabled raid", controlType = "checkbox",
	},
}

local raidSettings = {
	{2296, "Castle Nathria", true},
	{2450, "Sanctum of Domination", true},
	{2481, "Sepulcher of the First Ones", true},
	{2522, "Vault of the Incarnates", true},
	{2569, "Aberrus, the Shadowed Crucible", true},
	{2549, "Amirdrassil, the Dream's Hope", true},
	{2657, "Nerub-ar Palace", false},
	{2769, "Liberation of Undermine", false},
	{2810, "Manaforge: Omega", false},
	{2912, "The Voidspire", false},
	{2939, "The Dreamrift", false},
	{2913, "March on Quel'Danas", false},
	{1592, "Sporefall", false},
	{2987, "The Tidebound Grotto", false},
	{3004, "The Venomous Abyss", false},
}

test("registers exact core settings and controls", function()
	for _, expected in ipairs(coreSettings) do
		assertSetting(expected)
	end
	assertEquals(20, #captured.settings)
	assertEquals(18, #captured.checkboxes)
	assertEquals(2, #captured.dropdowns)
end)

test("registers exact raid settings in expansion order", function()
	for index, raid in ipairs(raidSettings) do
		local instanceID, raidName, enabledByDefault = raid[1], raid[2], raid[3]
		local registered = captured.settings[#coreSettings + index]
		assertNotNil(registered)
		assertEquals("AutoRoll_raid_" .. instanceID, registered.settingID)
		assertSetting({
			settingID = "AutoRoll_raid_" .. instanceID,
			variableKey = instanceID,
			storage = AutoRollDB.raidSettings,
			valueType = "boolean",
			label = raidName,
			defaultValue = enabledByDefault,
			tooltip = "Enable AutoRoll in " .. raidName,
			controlType = "checkbox",
		})
	end
	assertTableEquals({
		"Shadowlands Raids", "Dragonflight Raids", "The War Within Raids", "Midnight Raids",
	}, captured.sectionLabels)
end)

test("registers exact dropdown option order and final category", function()
	local defaultSetting = findSetting("AutoRoll_defaultRollMode")
	local fallbackSetting = findSetting("AutoRoll_fallbackRollMode")
	local defaultDropdown = findControl(captured.dropdowns, defaultSetting.setting)
	local fallbackDropdown = findControl(captured.dropdowns, fallbackSetting.setting)

	assertTableEquals({
		{value = 0, label = "Pass"},
		{value = 2, label = "Greed"},
		{value = 1, label = "Need"},
		{value = 3, label = "Disenchant"},
		{value = 4, label = "Transmog"},
		{value = 5, label = "Do nothing"},
	}, captureDropdownOptions(defaultDropdown.getOptions))
	assertTableEquals({
		{value = 5, label = "Do nothing"},
		{value = 0, label = "Pass"},
		{value = 2, label = "Greed"},
	}, captureDropdownOptions(fallbackDropdown.getOptions))
	assertEquals(1, #captured.addonCategories)
	assertEquals(captured.category, captured.addonCategories[1])
end)

test("restores registration wrappers and exposes the addon frame", function()
	assertEquals(original.registerVerticalLayoutCategory, Settings.RegisterVerticalLayoutCategory)
	assertEquals(original.registerAddOnSetting, Settings.RegisterAddOnSetting)
	assertEquals(original.createCheckbox, Settings.CreateCheckbox)
	assertEquals(original.createDropdown, Settings.CreateDropdown)
	assertEquals(original.registerAddOnCategory, Settings.RegisterAddOnCategory)
	assertEquals(original.createSectionHeader, CreateSettingsListSectionHeaderInitializer)
	assertNotNil(AutoRollFrame)
end)
