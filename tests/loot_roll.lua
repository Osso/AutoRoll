local ROLL_PASS = 0
local ROLL_NEED = 1
local ROLL_GREED = 2
local ROLL_TRANSMOG = 4
local ROLL_DO_NOTHING = 5

if not AutoRollFrame then
	local loaded, reason = C_AddOns.LoadAddOn("AutoRoll")
	assert(loaded, "failed to load AutoRoll: " .. tostring(reason))
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
	for index = 1, 4 do
		local frame = _G["GroupLootFrame" .. index]
		if frame:IsShown() and frame.rollID == rollID then
			return frame
		end
	end
	return nil
end

local function startRollWithoutAutoRoll(rollID)
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

local function fireAutoRoll(rollID, capabilities)
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
	A_Admin.FireEvent("START_LOOT_ROLL", rollID, 30)
	GetLootRollItemInfo = originalGetLootRollItemInfo
end

local function openRollBeforeAutoRollHandlesIt(rollID, capabilities)
	local rollFrame = startRollWithoutAutoRoll(rollID)
	fireAutoRoll(rollID, capabilities)
	return rollFrame
end

local function cleanUpRoll(rollID)
	A_Admin.FireEvent("CANCEL_LOOT_ROLL", rollID)
	A_Admin.EndLootRoll(rollID)
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

test("configured Do Nothing does not invoke Greed fallback", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_DO_NOTHING
	AutoRollDB.fallbackRollMode = ROLL_GREED
	local previousChoice = A_Admin.GetLastLootRollChoice()

	local rollFrame = openRollBeforeAutoRollHandlesIt(8101)

	assertRollWasNotChosen(previousChoice, rollFrame)
	cleanUpRoll(8101)
end)

test("unavailable Transmog falls back to Greed and dismisses the roll", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_TRANSMOG
	AutoRollDB.fallbackRollMode = ROLL_GREED

	local rollFrame = openRollBeforeAutoRollHandlesIt(8102)

	assertEquals(ROLL_GREED, A_Admin.GetLastLootRollChoice())
	assertEquals(0, #GetActiveLootRollIDs())
	assertFalse(rollFrame:IsShown())
end)

test("available Need uses the configured default", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_NEED
	AutoRollDB.fallbackRollMode = ROLL_DO_NOTHING

	local rollFrame = openRollBeforeAutoRollHandlesIt(8103, {
		need = true,
		greed = true,
		disenchant = false,
		transmog = false,
	})

	assertEquals(ROLL_NEED, A_Admin.GetLastLootRollChoice())
	assertEquals(0, #GetActiveLootRollIDs())
	assertFalse(rollFrame:IsShown())
end)

test("Pass uses the configured default", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_PASS
	AutoRollDB.fallbackRollMode = ROLL_DO_NOTHING

	local rollFrame = openRollBeforeAutoRollHandlesIt(8104)

	assertEquals(ROLL_PASS, A_Admin.GetLastLootRollChoice())
	assertEquals(0, #GetActiveLootRollIDs())
	assertFalse(rollFrame:IsShown())
end)

test("unavailable Transmog falls back to Pass", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_TRANSMOG
	AutoRollDB.fallbackRollMode = ROLL_PASS

	local rollFrame = openRollBeforeAutoRollHandlesIt(8105)

	assertEquals(ROLL_PASS, A_Admin.GetLastLootRollChoice())
	assertEquals(0, #GetActiveLootRollIDs())
	assertFalse(rollFrame:IsShown())
end)

test("unavailable Transmog with Do Nothing fallback leaves the roll active", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_TRANSMOG
	AutoRollDB.fallbackRollMode = ROLL_DO_NOTHING
	local previousChoice = A_Admin.GetLastLootRollChoice()

	local rollFrame = openRollBeforeAutoRollHandlesIt(8106)

	assertRollWasNotChosen(previousChoice, rollFrame)
	cleanUpRoll(8106)
end)

test("disabled supported raid does not roll", function()
	useSupportedRaid()
	AutoRollDB.raidSettings[2296] = false
	AutoRollDB.defaultRollMode = ROLL_GREED
	local previousChoice = A_Admin.GetLastLootRollChoice()

	local rollFrame = openRollBeforeAutoRollHandlesIt(8107)

	assertRollWasNotChosen(previousChoice, rollFrame)
	AutoRollDB.raidSettings[2296] = true
	cleanUpRoll(8107)
end)

test("unsupported raid does not roll", function()
	useSupportedRaid()
	setTestInstance("Unsupported Raid", "raid", 9999)
	AutoRollDB.defaultRollMode = ROLL_GREED
	local previousChoice = A_Admin.GetLastLootRollChoice()

	local rollFrame = openRollBeforeAutoRollHandlesIt(8108)

	assertRollWasNotChosen(previousChoice, rollFrame)
	cleanUpRoll(8108)
end)

test("non-raid instance does not roll", function()
	useSupportedRaid()
	setTestInstance("Test Dungeon", "party", 9998)
	AutoRollDB.defaultRollMode = ROLL_GREED
	local previousChoice = A_Admin.GetLastLootRollChoice()

	local rollFrame = openRollBeforeAutoRollHandlesIt(8109)

	assertRollWasNotChosen(previousChoice, rollFrame)
	cleanUpRoll(8109)
end)

test("global toggle unregisters automatic rolling", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_GREED
	SlashCmdList["AUTOROLL"]("toggle")
	local previousChoice = A_Admin.GetLastLootRollChoice()

	local rollFrame = startRollWithoutAutoRoll(8110)

	assertRollWasNotChosen(previousChoice, rollFrame)
	SlashCmdList["AUTOROLL"]("toggle")
	cleanUpRoll(8110)
end)

test("loot history is hidden in an enabled supported raid", function()
	useSupportedRaid()
	AutoRollDB.autoCloseLootWindow = true
	local frame = createLootHistoryFrame()

	AutoRollFrame:SuppressLootHistory(frame)

	assertTrue(frame.wasHidden)
end)

test("loot history remains visible when suppression is disabled", function()
	useSupportedRaid()
	AutoRollDB.autoCloseLootWindow = false
	local frame = createLootHistoryFrame()

	AutoRollFrame:SuppressLootHistory(frame)

	assertFalse(frame.wasHidden)
	AutoRollDB.autoCloseLootWindow = true
end)

test("loot history remains visible outside supported raids", function()
	useSupportedRaid()
	setTestInstance("Unsupported Raid", "raid", 9999)
	AutoRollDB.autoCloseLootWindow = true
	local frame = createLootHistoryFrame()

	AutoRollFrame:SuppressLootHistory(frame)

	assertFalse(frame.wasHidden)
end)
