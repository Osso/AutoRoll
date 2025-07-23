
local _, ns = ...

local function status(bool, short)
	return "Status: " .. (bool and "enabled" or "disabled")
end

local function toggle(label, dbVar)
	AutoRollDB[dbVar] = not AutoRollDB[dbVar]
	ns.print(label .. " " .. (AutoRollDB[dbVar] and "enabled" or "disabled"))
end

SlashCmdList["AUTOROLL"] = function(cmd_str, internal)
	local cmd, arg = strsplit(" ", cmd_str:lower(), 2)

	local itemId = tonumber(arg)
	local itemName = nil

	if itemId then
		itemName = GetItemInfo(itemId)
		if not itemName and internal ~= true then
			ns.pendingItemInfo = {"sc", cmd_str, itemId}
			C_Timer.After(3, function()
				if ns.pendingItemInfo and ns.pendingItemInfo[3] == itemId then
					ns.pendingItemInfo = nil
					ns.print(("Sorry, could not get information for item id %d. Please check the item id."):format(itemId))
				end
			end)
			return
		end
	end

	if cmd == "" then
		ns.print("Chat command list for /autoroll")
		ns.print(nil, "toggle - enable/disable AutoRoll on all items", status(AutoRollDB.enabled))
		ns.print(nil, "debug - enable/disable debug messages in chat window", status(AutoRollDB.debugMode))
		ns.print(nil, "raid - show current raid status and enabled raids")
		ns.print(nil, "list - list items")
		ns.print(nil, "add <itemId> - add an item to the item list")
		ns.print(nil, "del <itemId> - delete an item from the item list")
		ns.print(nil, "mode <itemId> - change need/greed/disenchant/pass/do nothing mode for a single item")
		ns.print(nil, "reset - reset the item list to default")

	elseif cmd == "toggle" then
		toggle("AutoRoll on all items", "enabled")
		ns.AddOnEnabled()

	elseif cmd == "debug" then
		toggle("DebugMode", "debugMode")

	elseif cmd == "raid" then
		-- Show current raid status
		local inRaid, raidID, raidName = ns.isInSupportedRaid()
		if inRaid then
			ns.print("Currently in raid: " .. raidName .. " (AutoRoll enabled)")
		else
			local instanceName, instanceType = GetInstanceInfo()
			if instanceType == "raid" then
				ns.print("Currently in raid: " .. instanceName .. " (AutoRoll disabled - not a supported raid)")
			else
				ns.print("Not currently in a raid")
			end
		end
		
		-- List enabled raids
		ns.print("\nEnabled raids:")
		for instanceID, raidName in pairs(ns.RaidInstances) do
			local enabled = AutoRollDB.raidSettings and AutoRollDB.raidSettings[instanceID]
			ns.print(nil, raidName .. ":", enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r")
		end

	elseif cmd == "list" then
		local requesting
		-- first run, request item data if not cached
		for i, v in pairs(AutoRollDB.items) do
			if not GetItemInfo(i) then requesting = true end
		end

		if requesting then
			C_Timer.After(1.2, function() SlashCmdList["AUTOROLL"](cmd_str) end)
			return
		end

		-- second run, print item list
		ns.print("Current item list")
		for i, v in pairs(AutoRollDB.items) do
			local name = GetItemInfo(i)
			print(("Id: %d (%s), Mode: %s"):format(i, name, ns.ModeLabels[v] or "?"))
		end

	elseif cmd == "add" then
		if ns.pendingItemInfo then
			ns.print("Sorry, that is too fast. This addon request the item name and waiting on answer " ..
				"from blizzards item database.")
		elseif itemId ~= nil and itemId > 0 and not AutoRollDB.items[itemId] then
			AutoRollDB.items[itemId] = 1
			ns.updateItemNames()
			ns.print(("ItemID %d found... %s added to AutoRoll's item list. Mode: %s"):format(itemId, itemName, GREED))
		else
			ns.print(("ItemID %d unknown/invalid... please check the given numbers."):format(itemId))
		end

	elseif cmd == "del" then
		if itemId ~= nil and AutoRollDB.items[itemId] then
			AutoRollDB.items[itemId] = nil
			ns.updateItemNames()
			ns.print(("ItemID %d (%s) removed from AutoRoll's item list"):format(itemId, itemName))
		else
			ns.print(("Id %d not found in item list."):format(itemId))
		end

	elseif cmd == "mode" then
		if itemId and itemId > 0 and AutoRollDB.items[itemId] then
			AutoRollDB.items[itemId] = AutoRollDB.items[itemId] == #ns.ModeLabels and 1 or AutoRollDB.items[itemId] + 1
			if AutoRollPanel and AutoRollPanel:IsShown() then
				AutoRollPanel.changes.items[itemId] = AutoRollDB.items[itemId]
			end
			ns.print(("Changed mode for itemId %d (%s) to %s"):format(itemId, itemName, ns.ModeLabels[AutoRollDB.items[itemId]]))
		else
			ns.print(("ItemId %d not found in item list."):format(itemId))
		end

	elseif cmd == "reset" then
		-- Reset only the items list to defaults
		AutoRollDB.items = {
			[120945] = 2, -- Primal Spirit - Greed
			[116920] = 5, -- True steel lockbox - Do nothing
		}
		ns.updateItemNames()
		if AutoRollPanel and AutoRollPanel:IsShown() then AutoRollPanel:refresh() end
		ns.print("Item list reset to defaults")
	end

	if AutoRollPanel and AutoRollPanel:IsShown() then AutoRollPanel:refresh(true) end
end

SLASH_AUTOROLL1 = "/autoroll"
