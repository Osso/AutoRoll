-- Luacheck configuration for WoW addon
std = "none"

-- WoW API globals
globals = {
	-- Frame/UI globals
	"CreateFrame", "Settings",

	-- Item/Loot globals
	"GetLootRollItemInfo", "RollOnLoot", "GetInstanceInfo",
	"GroupLootHistoryFrame", "CreateSettingsListSectionHeaderInitializer",

	-- Addon globals
	"AutoRollDB", "SlashCmdList", "SLASH_AUTOROLL1",

	-- Lua standard but need to be explicit (std = "none")
	"strsplit", "print", "ipairs", "pairs", "type", "tostring",
}

-- In-game test harness globals (tests/*.lua)
files["tests"] = {
	globals = {
		"C_AddOns", "A_Admin", "test", "AutoRollFrame", "_G",
		"assertEquals", "assertTrue", "assertFalse", "assertNotNil", "assert",
		"pcall", "error",
		"GetActiveLootRollIDs", "GroupLootContainer_AddRoll",
	},
}

-- Ignore some common WoW addon patterns
ignore = {
	"212", -- unused argument (common in event handlers)
	"213", -- unused loop variable
}
