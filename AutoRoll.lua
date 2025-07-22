
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
	[ROLL_GREED] = GREED,
	[ROLL_NEED] = NEED,
	[ROLL_DISENCHANT] = ROLL_DISENCHANT,
	[ROLL_TRANSMOG] = ROLL_TRANSMOG,
	[ROLL_PASS] = PASS,
	[ROLL_DO_NOTHING] = "Do nothing"
}
ns.AutoRollDB_defaults = {
	enabled = true,
	debugMode = false,
	version = 1,
	items = {
		[120945] = ROLL_GREED, -- Primal Spirit
		[116920] = ROLL_DO_NOTHING, -- True steel lockbox
	}
}
AutoRollDB = ns.AutoRollDB_defaults
ns.GET_ITEM_INFO_RECEIVED = nil

function ns.print(arg1, ...)
	if arg1 == nil then
		print(...)
	else
		print("[|Cff3388ff" .. addon .. "|r]", arg1, ...)
	end
end

function ns.debugPrint(...)
	if not AutoRollDB.debugMode then return end
	ns.print("(Debug Message)")
	for i, v in ipairs({...}) do
		print(v)
	end
end

local itemNames = {}
local function updateItemNames()
	wipe(itemNames)
	for i, v in pairs(AutoRollDB.items) do
		local name = GetItemInfo(i)
		if name then
			itemNames[name] = v
		end
	end
end
ns.updateItemNames = updateItemNames

local main = CreateFrame("Frame", "AutoRollFrame")

function ns.AddOnEnabled()
	if AutoRollDB.enabled then
		main:RegisterEvent("START_LOOT_ROLL")
		updateItemNames()
	else
		main:UnregisterEvent("START_LOOT_ROLL")
	end
	ns.print("|cffffff00Addon", (AutoRollDB.enabled and "enabled" or "disabled") .. "...|r")
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
	local _, name, _, _, _, canNeed, canGreed, canDisenchant = GetLootRollItemInfo(rollID)

	if not rollID or not name then
		ns.debugPrint(
			"Event: START_LOOT_ROLL",
			"rollID: " .. (rollID or "missing roll id"),
			"itemName: " .. (name or "missing item name")
		)
		return
	end

	local itemRollMode = itemNames[name] or ROLL_GREED -- auto greed when not in item list

	if canNeed and itemRollMode == ROLL_NEED then
		RollOnLoot(rollID, ROLL_NEED)
	elseif canDisenchant and itemRollMode == ROLL_DISENCHANT then
		RollOnLoot(rollID, ROLL_DISENCHANT)
	elseif canGreed and itemRollMode == ROLL_GREED then
		RollOnLoot(rollID, ROLL_GREED)
	elseif itemRollMode == ROLL_PASS then
		RollOnLoot(rollID, ROLL_PASS)
	-- ROLL_DO_NOTHING means don't roll at all
	end

	ns.debugPrint(
		"Event: START_LOOT_ROLL",
		"itemName: " .. (name or "unknown"),
		"rollID: " .. rollID,
		"Action: " .. (ns.ModeLabels[itemRollMode] or "nothing")
	)

	if itemRollMode ~= ROLL_DO_NOTHING then
		ns.print(name, "=", ns.ModeLabels[itemRollMode])
	end
end



function main:GET_ITEM_INFO_RECEIVED(itemId)
	local d
	if ns.GET_ITEM_INFO_RECEIVED then
		d, ns.GET_ITEM_INFO_RECEIVED = ns.GET_ITEM_INFO_RECEIVED, nil
		if d[1] == "sc" and itemId == d[3] then
			ns.debugPrint(
				"Event: GET_ITEM_INFO_RECEIVED",
				"itemID: " .. itemId,
				"GetItemInfo" .. table.concat({GetItemInfo(itemId)}, ", ")
			)
			SlashCmdList["AUTOROLL"](d[2], true)
		end
	end
end

main:SetScript("OnEvent", function(self, event, ...) if main[event] then main[event](self, ...) end end)
main:RegisterEvent("ADDON_LOADED")
main:RegisterEvent("GET_ITEM_INFO_RECEIVED")
