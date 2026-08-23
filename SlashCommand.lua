
local _, ns = ...

local function status(bool)
	return "Status: " .. (bool and "enabled" or "disabled")
end

local function printHelp()
	ns.print("Chat command list for /autoroll")
	ns.print(nil, "toggle - enable/disable AutoRoll in enabled raids", status(AutoRollDB.enabled))
	ns.print(nil, "debug - enable/disable debug messages in chat window", status(AutoRollDB.debugMode))
	ns.print(nil, "raid - show current raid status and enabled raids")
end

local function printRaidStatus()
	local inRaid, _, raidName = ns.isInSupportedRaid()
	if inRaid then
		ns.print("Currently in raid: " .. raidName .. " (AutoRoll enabled)")
		return
	end

	local instanceName, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
	if instanceType ~= "raid" then
		ns.print("Not currently in a raid")
		return
	end

	local supportedText = ns.RaidInstances[instanceID] and "supported but disabled" or "not supported"
	ns.print("Currently in raid: " .. instanceName .. " (ID: " .. tostring(instanceID) .. ", " .. supportedText .. ")")
end

local function toggleAutoRoll()
	AutoRollDB.enabled = not AutoRollDB.enabled
	ns.print("AutoRoll in enabled raids " .. (AutoRollDB.enabled and "enabled" or "disabled"))
	ns.AddOnEnabled()
end

local function toggleDebugMode()
	AutoRollDB.debugMode = not AutoRollDB.debugMode
	ns.print("DebugMode " .. (AutoRollDB.debugMode and "enabled" or "disabled"))
end

SlashCmdList["AUTOROLL"] = function(cmd_str)
	local cmd = strsplit(" ", cmd_str:lower(), 2)

	if cmd == "" then
		printHelp()
	elseif cmd == "toggle" then
		toggleAutoRoll()
	elseif cmd == "debug" then
		toggleDebugMode()
	elseif cmd == "raid" then
		printRaidStatus()
	else
		ns.print("Unknown command: " .. cmd)
	end
end

SLASH_AUTOROLL1 = "/autoroll"
