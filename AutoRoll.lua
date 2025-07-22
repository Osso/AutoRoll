
local addon, ns = ...
local autoConfirm = {}
local version = 1
ns.ModeLabels = {GREED, NEED, ROLL_DISENCHANT, PASS, "Do nothing"}
ns.AutoRollDB_defaults = {
	enabled = true,
	autoConfirmAll = false,
	autoRollAll = false,
	infoMessage = true,
	debugMode = false,
	version = 1,
	items = {
		[120945] = 1, -- Primal Spirit
		[116920] = 5, -- True steel lockbox
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
		main:RegisterEvent("CONFIRM_LOOT_ROLL")
		main:RegisterEvent("LOOT_HISTORY_ROLL_CHANGED")
		updateItemNames()
	else
		main:UnregisterEvent("START_LOOT_ROLL")
		main:UnregisterEvent("CONFIRM_LOOT_ROLL")
		main:UnregisterEvent("LOOT_HISTORY_ROLL_CHANGED")
	end
	ns.print("|cffffff00Addon", (AutoRollDB.enabled and "enabled" or "disabled") .. "...|r")
end

function main:ADDON_LOADED(name)
	if addon ~= name then return end

	ns.print("|Cffffff00Addon loaded...|r")
	if AutoRollDB.version == nil then AutoRollDB.version = 0 end
	if AutoRollDB.version <= 0.91 then
		for i, v in pairs(ns.AutoRollDB_defaults.items) do
			if AutoRollDB.items[i] == nil then
				AutoRollDB.items[i] = v
			end
		end
	end
	AutoRollDB.version = version
	if AutoRollDB.enabled then
		ns.AddOnEnabled()
	end
end

function main:START_LOOT_ROLL(rollID)
	local _, name, _, _, _, canNeed, canGreed, canDisenchant, reasonNeed, reasonGreed, reasonDisenchant = GetLootRollItemInfo(rollID)

	if not rollID or not name then
		ns.debugPrint(
			"Event: START_LOOT_ROLL",
			"rollID: " .. (rollID or "missing roll id"),
			"itemName: " .. (name or "missing item name")
		)
		return
	end

	local rolling = itemNames[name] -- 1, 2, 3, 4, 5
	if not rolling then
		if AutoRollDB.autoRollAll then -- if nil
			rolling = 1 -- auto greed
		else
			rolling = 99
		end
	end

	if (rolling <= 4) and (reasonNeed or reasonGreed or reasonDisenchant) then
		autoConfirm[rollID] = true
	end

	if canNeed and rolling == 2 then
		RollOnLoot(rollID, 1) -- need
	elseif canDisenchant and rolling == 3 then
		RollOnLoot(rollID, 3) -- disenchant
	elseif rolling == 4 then
		RollOnLoot(rollID, 0) -- pass
	elseif canGreed and rolling <= 3 then -- with fallback if you can't roll "need" or "disenchant" an item
		RollOnLoot(rollID, 2) -- greed
	end

	ns.debugPrint(
		"Event: START_LOOT_ROLL",
		"itemName: " .. name or "unknown",
		"rollID: " .. rollID,
		"Action: " .. (ns.ModeLabels[rolling] or "nothing")
	)

	if AutoRollDB.infoMessage and rolling ~= 5 then
		ns.print(name, "=", ns.ModeLabels[rolling])
	end
end

function main:CONFIRM_LOOT_ROLL(rollID, arg2)
	local _, name, _, _, _, _, _, _, reasonNeed, reasonGreed, reasonDisenchant = GetLootRollItemInfo(rollID)
	if autoConfirm[rollID] or AutoRollDB.autoConfirmAll == true then
		ns.debugPrint(
			"Event: CONFIRM_LOOT_ROLL",
			"rollID: " .. rollID,
			"autoConfirm[" .. rollID .. "]: " .. (autoConfirm[rollID] and "1" or "0"),
			"autoConfirmAll: " .. (AutoRollDB.autoConfirmAll and "1" or "0")
		)
		ConfirmLootRoll(rollID, arg2)
		autoConfirm[rollID] = nil
	end
end

function main:LOOT_HISTORY_ROLL_CHANGED(index, player) -- maybe for winner popup frames replacement?
	--local rollID, link, numPlayers, isDone, winner, isMasterLoot = C_LootHistory.GetItem(index);
	--local name, class, rollType, roll, isWinner = C_LootHistory.GetPlayerInfo(item, player);
	
	--[[
	ns.debugPrint(
		"Event: LOOT_HISTORY_ROLL_CHANGED",
		"item index: " .. index or "unknown",
		"player index: ".. player or "unknown"
	);
	]]
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
