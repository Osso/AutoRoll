
local addon, ns = ...

local function status(bool, short)
	return "Status: " .. (bool and "enabled" or "disabled")
end

local function toggle(label, dbVar)
	AutoRollDB[dbVar] = not AutoRollDB[dbVar];
	ns.print(label .. " " .. (AutoRollDB[dbVar] and "enabled" or "disabled"))
end

SlashCmdList["AUTOROLL"] = function(_cmd,internal)
	local cmd, arg = strsplit(" ", _cmd:lower(), 2)

	local n, name = tonumber(arg);

	if(n)then
		name=GetItemInfo(n);
		if(not name and internal~=true)then
			ns.GET_ITEM_INFO_RECEIVED={"sc",_cmd,n};
			C_Timer.After(3,function()
				if(ns.GET_ITEM_INFO_RECEIVED)then
					ns.GET_ITEM_INFO_RECEIVED=nil;
					ns.print(("Sorry, it was not able to get more informations to item id %d. Please check the item id."):format(n))
				end
			end);
			return;
		end
	end

	if(cmd=="")then
		ns.print("Chat command list for /ar & /autoroll")
		ns.print(nil,"toggle - enable/disable AutoRoll's functionality",status(AutoRollDB.enabled))
		ns.print(nil,"autorollall - enable/disable AutoRoll on all items (using item list or greed).",status(AutoRollDB.autoRollAll))
		ns.print(nil,"infomessage - enable/disable info message for any executed loot roll in chat window",status(AutoRollDB.infoMessage))
		ns.print(nil,"debugmode - enable/disable debug messages in chat window",status(AutoRollDB.debugMode))
		ns.print(nil,"list - list items")
		ns.print(nil,"add <itemId> - add an item to the item list")
		ns.print(nil,"del <itemId> - delete an item from the item list")
		ns.print(nil,"mode <itemId> - change need/greed/disenchant/pass/do nothing mode for a single item")
		ns.print(nil,"reset - reset the item list to default")

	elseif(cmd=="toggle")then
		toggle("AutoRoll's functionality", "enabled")
		ns.AddOnEnabled();

	elseif(cmd=="debugmode")then
		toggle("DebugMode","debugMode")


	elseif(cmd=="autorollall")then
		toggle("AutoRoll all","autoRollAll")

	elseif(cmd=="infomessage")then
		toggle("Info message","infoMessage")

	elseif(cmd=="list")then
		local requesting;
		-- first run, request item data if not cached
		for i,v in pairs(AutoRollDB.items)do
			if(not GetItemInfo(i))then requesting=true; end
		end

		if(requesting)then
			C_Timer.After(1.2,function() SlashCmdList["AUTOROLL"](_cmd) end);
			return;
		end

		-- second run, print item list
		ns.print("Current item list")
		for i,v in pairs(AutoRollDB.items)do
			local name=GetItemInfo(i);
			print(("Id: %d (%s), Mode: %s"):format(i,name,ns.ModeLabels[v] or "?"))
		end

	elseif(cmd=="add")then
		if(ns.GET_ITEM_INFO_RECEIVED)then
			ns.print("Sorry, that is too fast. This addon request the item name and waiting on answer from blizzards item database.")
		elseif(n~=nil and n>0 and not AutoRollDB.items[n])then
			AutoRollDB.items[n]=1;
			ns.updateItemNames();
			ns.print(("ItemID %d found... %s added to AutoRoll's item list. Mode: %s"):format(n,name,GREED))
		else
			ns.print(("ItemID %d unknown/invalid... please check the given numbers."):format(n))
		end

	elseif(cmd=="del")then
		if(n~=nil and AutoRollDB.items[n])then
			AutoRollDB.items[n] = nil;
			ns.updateItemNames();
			ns.print(("ItemID %d (%s) removed from AutoRoll's item list"):format(n,name))
		else
			ns.print(("Id %d not found in item list."):format(n))
		end

	elseif(cmd=="mode")then
		if(n and n>0 and AutoRollDB.items[n])then
			AutoRollDB.items[n] = AutoRollDB.items[n]==#ns.ModeLabels and 1 or AutoRollDB.items[n]+1;
			if(AutoRollPanel and AutoRollPanel:IsShown())then
				AutoRollPanel.changes.items[n]=AutoRollDB.items[n];
			end
			ns.print(("Changed mode for itemId %d (%s) to %s"):format(n, name, ns.ModeLabels[AutoRollDB.items[n]]))
		else
			ns.print(("ItemId %d not found in item list."):format(n))
		end

	elseif(cmd=="reset")then
		AutoRollDB = ns.AutoRollDB_defaults;
		ns.updateItemNames();
		if(AutoRollPanel and AutoRollPanel:IsShown())then AutoRollPanel:refresh(); end
		ns.print("Item list resetted...")
	end

	if(AutoRollPanel and AutoRollPanel:IsShown())then AutoRollPanel:refresh(true); end
end

SLASH_AUTOROLL1 = "/autoroll";
SLASH_AUTOROLL2 = "/ar";
