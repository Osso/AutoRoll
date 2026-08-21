local ROLL_GREED = 2
local ROLL_TRANSMOG = 4
local ROLL_DO_NOTHING = 5

if not AutoRollFrame then
	local loaded, reason = C_AddOns.LoadAddOn("AutoRoll")
	assert(loaded, "failed to load AutoRoll: " .. tostring(reason))
end

local function useSupportedRaid()
	GetInstanceInfo = function()
		return "Castle Nathria", "raid", 16, "Mythic", 20, 0, false, 2296, 20, nil
	end
	AutoRollDB.enabled = true
	AutoRollDB.raidSettings[2296] = true
end

local function openRollBeforeAutoRollHandlesIt(rollID)
	AutoRollFrame:UnregisterEvent("START_LOOT_ROLL")
	A_Admin.StartLootRoll(rollID, 30, "Test Item", "Interface\\Icons\\INV_Sword_04", 4, 639)

	local rollFrame
	for index = 1, 4 do
		local frame = _G["GroupLootFrame" .. index]
		if frame:IsShown() and frame.rollID == rollID then
			rollFrame = frame
			break
		end
	end

	if not rollFrame then
		GroupLootContainer_AddRoll(rollID, 30)
		for index = 1, 4 do
			local frame = _G["GroupLootFrame" .. index]
			if frame:IsShown() and frame.rollID == rollID then
				rollFrame = frame
				break
			end
		end
	end

	assertNotNil(rollFrame)
	AutoRollFrame:RegisterEvent("START_LOOT_ROLL")
	A_Admin.FireEvent("START_LOOT_ROLL", rollID, 30)
	return rollFrame
end

local function cleanUpRoll(rollID)
	A_Admin.FireEvent("CANCEL_LOOT_ROLL", rollID)
	A_Admin.EndLootRoll(rollID)
end

test("configured Do Nothing does not invoke Greed fallback", function()
	useSupportedRaid()
	AutoRollDB.defaultRollMode = ROLL_DO_NOTHING
	AutoRollDB.fallbackRollMode = ROLL_GREED
	local previousChoice = A_Admin.GetLastLootRollChoice()

	local rollFrame = openRollBeforeAutoRollHandlesIt(8101)

	assertEquals(previousChoice, A_Admin.GetLastLootRollChoice())
	assertEquals(1, #GetActiveLootRollIDs())
	assertTrue(rollFrame:IsShown())
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
