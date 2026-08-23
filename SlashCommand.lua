
local _, ns = ...

local function status(bool)
	return "Status: " .. (bool and "enabled" or "disabled")
end

local function toggle(label, dbVar)
	AutoRollDB[dbVar] = not AutoRollDB[dbVar]
	ns.print(label .. " " .. (AutoRollDB[dbVar] and "enabled" or "disabled"))
end

SlashCmdList["AUTOROLL"] = function(cmd_str)
	local cmd = strsplit(" ", cmd_str:lower(), 2)

	if cmd == "" then
		ns.print("Chat command list for /autoroll")
		ns.print(nil, "toggle - enable/disable AutoRoll in enabled raids", status(AutoRollDB.enabled))
		ns.print(nil, "debug - enable/disable debug messages in chat window", status(AutoRollDB.debugMode))
		ns.print(nil, "raid - show current raid status and enabled raids")

	elseif cmd == "toggle" then
		toggle("AutoRoll in enabled raids", "enabled")
		ns.AddOnEnabled()

	elseif cmd == "debug" then
		toggle("DebugMode", "debugMode")

	elseif cmd == "raid" then
		-- Show current raid status
		local inRaid, _, raidName = ns.isInSupportedRaid()
		if inRaid then
			ns.print("Currently in raid: " .. raidName .. " (AutoRoll enabled)")
		else
			local instanceName, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
			if instanceType == "raid" then
				local supportedText = ns.RaidInstances[instanceID] and "supported but disabled" or "not supported"
				ns.print("Currently in raid: " .. instanceName .. " (ID: " .. tostring(instanceID) .. ", " .. supportedText .. ")")
			else
				ns.print("Not currently in a raid")
			end
		end
	else
		ns.print("Unknown command: " .. cmd)
	end
end

SLASH_AUTOROLL1 = "/autoroll"
