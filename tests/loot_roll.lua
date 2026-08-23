local ROLL_PASS = 0
local ROLL_NEED = 1
local ROLL_GREED = 2
local ROLL_DISENCHANT = 3
local ROLL_TRANSMOG = 4
local ROLL_DO_NOTHING = 5

local MAX_TEST_ROLL_FRAMES = 4
local ADDON_PREFIX = "[|Cff3388ffAutoRoll|r]"

if not AutoRollFrame then
	local loaded, reason = C_AddOns.LoadAddOn("AutoRoll")
	assert(loaded, "failed to load AutoRoll: " .. tostring(reason))
end

local function copyTable(values)
	local copiedValues = {}
	for key, value in pairs(values) do
		copiedValues[key] = value
	end
	return copiedValues
end

local function replaceTable(target, values)
	for key in pairs(target) do
		target[key] = nil
	end
	for key, value in pairs(values) do
		target[key] = value
	end
end

local function cleanUpActiveRolls()
	for _, rollID in ipairs(GetActiveLootRollIDs()) do
		A_Admin.FireEvent("CANCEL_LOOT_ROLL", rollID)
		A_Admin.EndLootRoll(rollID)
	end
end

local function captureTestState()
	local database = copyTable(AutoRollDB)
	database.raidSettings = copyTable(AutoRollDB.raidSettings)

	return {
		getInstanceInfo = GetInstanceInfo,
		getLootRollItemInfo = GetLootRollItemInfo,
		printFunction = print,
		database = database,
		raidSettings = AutoRollDB.raidSettings,
		rollEventRegistered = AutoRollFrame:IsEventRegistered("START_LOOT_ROLL"),
		lootHistoryShown = GroupLootHistoryFrame:IsShown(),
	}
end

local function restoreLootHistoryVisibility(wasShown)
	if not wasShown then
		GroupLootHistoryFrame:Hide()
		return
	end

	local autoCloseLootWindow = AutoRollDB.autoCloseLootWindow
	AutoRollDB.autoCloseLootWindow = false
	GroupLootHistoryFrame:Show()
	AutoRollDB.autoCloseLootWindow = autoCloseLootWindow
end

local function showLootHistoryThroughHooks()
	local shownDuringOnShow
	GroupLootHistoryFrame:Hide()
	GroupLootHistoryFrame:HookScript("OnShow", function(frame)
		shownDuringOnShow = frame:IsShown()
	end)
	GroupLootHistoryFrame:Show()
	return shownDuringOnShow
end

local function restoreTestState(state)
	GetInstanceInfo = state.getInstanceInfo
	GetLootRollItemInfo = state.getLootRollItemInfo
	print = state.printFunction

	replaceTable(AutoRollDB, state.database)
	AutoRollDB.raidSettings = state.raidSettings
	replaceTable(AutoRollDB.raidSettings, state.database.raidSettings)

	if state.rollEventRegistered then
		AutoRollFrame:RegisterEvent("START_LOOT_ROLL")
	else
		AutoRollFrame:UnregisterEvent("START_LOOT_ROLL")
	end

	cleanUpActiveRolls()
	restoreLootHistoryVisibility(state.lootHistoryShown)
end

local function isolatedTest(name, body)
	test(name, function()
		local state = captureTestState()
		local bodySucceeded, bodyError = pcall(body)
		local restoreSucceeded, restoreError = pcall(restoreTestState, state)

		if not bodySucceeded then
			error(bodyError, 0)
		end
		if not restoreSucceeded then
			error(restoreError, 0)
		end
	end)
end

local function setTestInstance(name, instanceType, instanceID)
	GetInstanceInfo = function()
		return name, instanceType, 16, "Mythic", 20, 0, false, instanceID, 20, nil
	end
end

local function useSupportedRaid()
	setTestInstance("Castle Nathria", "raid", 2296)
	AutoRollDB.enabled = true
	AutoRollDB.raidSettings[2296] = true
	AutoRollFrame:RegisterEvent("START_LOOT_ROLL")
end

local function findRollFrame(rollID)
	for index = 1, MAX_TEST_ROLL_FRAMES do
		local frame = _G["GroupLootFrame" .. index]
		if frame:IsShown() and frame.rollID == rollID then
			return frame
		end
	end
	return nil
end

local function startVisibleRoll(rollID)
	AutoRollFrame:UnregisterEvent("START_LOOT_ROLL")
	A_Admin.StartLootRoll(rollID, 30, "Test Item", "Interface\\Icons\\INV_Sword_04", 4, 639)

	local rollFrame = findRollFrame(rollID)
	if not rollFrame then
		GroupLootContainer_AddRoll(rollID, 30)
		rollFrame = findRollFrame(rollID)
	end

	assertNotNil(rollFrame)
	return rollFrame
end

local function fireAutoRollWithCapabilities(rollID, capabilities)
	local originalGetLootRollItemInfo = GetLootRollItemInfo
	if capabilities then
		GetLootRollItemInfo = function(requestedRollID)
			local texture, name, count, quality, bindOnPickup, _, _, _, disenchantLevel, itemLevel =
				originalGetLootRollItemInfo(requestedRollID)
			return texture, name, count, quality, bindOnPickup,
				capabilities.need, capabilities.greed, capabilities.disenchant,
				disenchantLevel, itemLevel, nil, nil, capabilities.transmog
		end
	end

	AutoRollFrame:RegisterEvent("START_LOOT_ROLL")
	local eventSucceeded, eventError = pcall(A_Admin.FireEvent, "START_LOOT_ROLL", rollID, 30)
	GetLootRollItemInfo = originalGetLootRollItemInfo
	if not eventSucceeded then
		error(eventError, 0)
	end
end

local function startVisibleRollThenAutoRoll(rollID, capabilities)
	local rollFrame = startVisibleRoll(rollID)
	fireAutoRollWithCapabilities(rollID, capabilities)
	return rollFrame
end

local function assertRollWasChosen(expectedChoice, rollFrame)
	assertEquals(expectedChoice, A_Admin.GetLastLootRollChoice())
	assertEquals(0, #GetActiveLootRollIDs())
	assertFalse(rollFrame:IsShown())
end

local function assertRollWasNotChosen(previousChoice, rollFrame)
	assertEquals(previousChoice, A_Admin.GetLastLootRollChoice())
	assertEquals(1, #GetActiveLootRollIDs())
	assertTrue(rollFrame:IsShown())
end

local function createLootHistoryFrame()
	return {
		wasHidden = false,
		Hide = function(self)
			self.wasHidden = true
		end,
	}
end

local function capturePrintCalls(body)
	local originalPrint = print
	local calls = {}
	print = function(...)
		calls[#calls + 1] = {...}
	end

	local bodySucceeded, bodyError = pcall(body)
	print = originalPrint
	if not bodySucceeded then
		error(bodyError, 0)
	end
	return calls
end

isolatedTest("raid defaults enable Shadowlands and Dragonflight only", function()
	for _, instanceID in ipairs({2296, 2450, 2481, 2522, 2569, 2549}) do
		assertTrue(AutoRollDB.raidSettings[instanceID])
	end
	for _, instanceID in ipairs({2657, 2769, 2810}) do
		assertFalse(AutoRollDB.raidSettings[instanceID])
	end
end)

isolatedTest("configured Do Nothing does not invoke Greed fallback", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_DO_NOTHING
	AutoRollDB.fallbackRollMode = ROLL_GREED
	local previousChoice = A_Admin.GetLastLootRollChoice()

	local rollFrame = startVisibleRollThenAutoRoll(8101)

	assertRollWasNotChosen(previousChoice, rollFrame)
end)

isolatedTest("unavailable Transmog falls back to Greed and dismisses the roll", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_TRANSMOG
	AutoRollDB.fallbackRollMode = ROLL_GREED

	local rollFrame = startVisibleRollThenAutoRoll(8102)

	assertRollWasChosen(ROLL_GREED, rollFrame)
end)

isolatedTest("configured Greed uses the configured default", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_GREED
	AutoRollDB.fallbackRollMode = ROLL_DO_NOTHING

	local rollFrame = startVisibleRollThenAutoRoll(8112)

	assertRollWasChosen(ROLL_GREED, rollFrame)
end)

isolatedTest("available Need uses the configured default", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_NEED
	AutoRollDB.fallbackRollMode = ROLL_DO_NOTHING

	local rollFrame = startVisibleRollThenAutoRoll(8103, {
		need = true,
		greed = true,
		disenchant = false,
		transmog = false,
	})

	assertRollWasChosen(ROLL_NEED, rollFrame)
end)

isolatedTest("available Transmog uses the configured default", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_TRANSMOG
	AutoRollDB.fallbackRollMode = ROLL_DO_NOTHING

	local rollFrame = startVisibleRollThenAutoRoll(8113, {
		need = false,
		greed = true,
		disenchant = false,
		transmog = true,
	})

	assertRollWasChosen(ROLL_TRANSMOG, rollFrame)
end)

isolatedTest("available Disenchant uses the configured default", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_DISENCHANT
	AutoRollDB.fallbackRollMode = ROLL_DO_NOTHING

	local rollFrame = startVisibleRollThenAutoRoll(8111, {
		need = false,
		greed = true,
		disenchant = true,
		transmog = false,
	})

	assertRollWasChosen(ROLL_DISENCHANT, rollFrame)
end)

isolatedTest("Pass uses the configured default", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_PASS
	AutoRollDB.fallbackRollMode = ROLL_DO_NOTHING

	local rollFrame = startVisibleRollThenAutoRoll(8104)

	assertRollWasChosen(ROLL_PASS, rollFrame)
end)

isolatedTest("unavailable Transmog falls back to Pass", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_TRANSMOG
	AutoRollDB.fallbackRollMode = ROLL_PASS

	local rollFrame = startVisibleRollThenAutoRoll(8105)

	assertRollWasChosen(ROLL_PASS, rollFrame)
end)

isolatedTest("unavailable Transmog with Do Nothing fallback leaves the roll active", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_TRANSMOG
	AutoRollDB.fallbackRollMode = ROLL_DO_NOTHING
	local previousChoice = A_Admin.GetLastLootRollChoice()

	local rollFrame = startVisibleRollThenAutoRoll(8106)

	assertRollWasNotChosen(previousChoice, rollFrame)
end)

isolatedTest("disabled supported raid does not roll", function()
	useSupportedRaid()
	AutoRollDB.raidSettings[2296] = false
	AutoRollDB.defaultRollMode = ROLL_GREED
	local previousChoice = A_Admin.GetLastLootRollChoice()

	local rollFrame = startVisibleRollThenAutoRoll(8107)

	assertRollWasNotChosen(previousChoice, rollFrame)
end)

isolatedTest("unsupported raid does not roll", function()
	useSupportedRaid()
	setTestInstance("Unsupported Raid", "raid", 9999)
	AutoRollDB.defaultRollMode = ROLL_GREED
	local previousChoice = A_Admin.GetLastLootRollChoice()

	local rollFrame = startVisibleRollThenAutoRoll(8108)

	assertRollWasNotChosen(previousChoice, rollFrame)
end)

isolatedTest("non-raid instance does not roll", function()
	useSupportedRaid()
	setTestInstance("Test Dungeon", "party", 9998)
	AutoRollDB.defaultRollMode = ROLL_GREED
	local previousChoice = A_Admin.GetLastLootRollChoice()

	local rollFrame = startVisibleRollThenAutoRoll(8109)

	assertRollWasNotChosen(previousChoice, rollFrame)
end)

isolatedTest("global toggle unregisters and re-registers automatic rolling", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_GREED
	assertTrue(AutoRollFrame:IsEventRegistered("START_LOOT_ROLL"))

	SlashCmdList["AUTOROLL"]("toggle")
	assertFalse(AutoRollFrame:IsEventRegistered("START_LOOT_ROLL"))
	local previousChoice = A_Admin.GetLastLootRollChoice()
	local rollFrame = startVisibleRoll(8110)
	assertRollWasNotChosen(previousChoice, rollFrame)

	SlashCmdList["AUTOROLL"]("toggle")
	assertTrue(AutoRollFrame:IsEventRegistered("START_LOOT_ROLL"))
end)

isolatedTest("slash help prints exact command list", function()
	local calls = capturePrintCalls(function()
		SlashCmdList["AUTOROLL"]("")
	end)

	assertTableEquals({
		{ADDON_PREFIX, "Chat command list for /autoroll"},
		{"toggle - enable/disable AutoRoll in enabled raids", "Status: enabled"},
		{"debug - enable/disable debug messages in chat window", "Status: disabled"},
		{"raid - show current raid status and enabled raids"},
	}, calls)
end)

isolatedTest("slash debug normalizes case and ignores trailing text", function()
	local calls = capturePrintCalls(function()
		SlashCmdList["AUTOROLL"]("DeBuG ignored text")
	end)

	assertTrue(AutoRollDB.debugMode)
	assertTableEquals({{ADDON_PREFIX, "DebugMode enabled"}}, calls)
end)

isolatedTest("slash raid reports enabled, disabled, and non-raid status", function()
	useSupportedRaid()
	local enabledCalls = capturePrintCalls(function()
		SlashCmdList["AUTOROLL"]("raid")
	end)
	assertTableEquals({{ADDON_PREFIX, "Currently in raid: Castle Nathria (AutoRoll enabled)"}}, enabledCalls)

	AutoRollDB.raidSettings[2296] = false
	local disabledCalls = capturePrintCalls(function()
		SlashCmdList["AUTOROLL"]("raid")
	end)
	assertTableEquals({{
		ADDON_PREFIX,
		"Currently in raid: Castle Nathria (ID: 2296, supported but disabled)",
	}}, disabledCalls)

	setTestInstance("Test Dungeon", "party", 9998)
	local nonRaidCalls = capturePrintCalls(function()
		SlashCmdList["AUTOROLL"]("raid")
	end)
	assertTableEquals({{ADDON_PREFIX, "Not currently in a raid"}}, nonRaidCalls)
end)

isolatedTest("slash unknown command prints exact error", function()
	local calls = capturePrintCalls(function()
		SlashCmdList["AUTOROLL"]("mystery")
	end)

	assertTableEquals({{ADDON_PREFIX, "Unknown command: mystery"}}, calls)
end)

isolatedTest("loot history is hidden in an enabled supported raid", function()
	useSupportedRaid()
	AutoRollDB.autoCloseLootWindow = true
	local frame = createLootHistoryFrame()

	AutoRollFrame:SuppressLootHistory(frame)

	assertTrue(frame.wasHidden)
end)

isolatedTest("loot history remains visible when suppression is disabled", function()
	useSupportedRaid()
	AutoRollDB.autoCloseLootWindow = false
	local frame = createLootHistoryFrame()

	AutoRollFrame:SuppressLootHistory(frame)

	assertFalse(frame.wasHidden)
end)

isolatedTest("loot history remains visible outside supported raids", function()
	useSupportedRaid()
	setTestInstance("Unsupported Raid", "raid", 9999)
	AutoRollDB.autoCloseLootWindow = true
	local frame = createLootHistoryFrame()

	AutoRollFrame:SuppressLootHistory(frame)

	assertFalse(frame.wasHidden)
end)

isolatedTest("loot history OnShow hook hides the real frame in an enabled raid", function()
	useSupportedRaid()
	AutoRollDB.autoCloseLootWindow = true

	assertFalse(showLootHistoryThroughHooks())
end)

isolatedTest("loot history OnShow hook leaves the real frame visible when disabled", function()
	useSupportedRaid()
	AutoRollDB.autoCloseLootWindow = false

	assertTrue(showLootHistoryThroughHooks())
end)
