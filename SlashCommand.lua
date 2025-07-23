
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

	if cmd == "" then
		ns.print("Chat command list for /autoroll")
		ns.print(nil, "toggle - enable/disable AutoRoll on all items", status(AutoRollDB.enabled))
		ns.print(nil, "debug - enable/disable debug messages in chat window", status(AutoRollDB.debugMode))
		ns.print(nil, "raid - show current raid status and enabled raids")
		ns.print(nil, "dump - show AutoRollDB contents for debugging")
		ns.print(nil, "reset - reset AutoRollDB to defaults")

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

	elseif cmd == "dump" then
		ns.print("AutoRollDB contents:")
		for k, v in pairs(AutoRollDB) do
			if type(v) == "table" then
				ns.print(k .. ":")
				for k2, v2 in pairs(v) do
					ns.print("  " .. tostring(k2) .. ": " .. tostring(v2))
				end
			else
				ns.print(k .. ": " .. tostring(v))
			end
		end

	elseif cmd == "reset" then
		ns.print("Resetting AutoRollDB to defaults...")
		-- Clear existing data
		for k in pairs(AutoRollDB) do
			ns.print("DEBUG: Clearing " .. k)
			AutoRollDB[k] = nil
		end
		-- Reinitialize with defaults
		for k, v in pairs(ns.AutoRollDB_defaults) do
			ns.print("DEBUG: Setting " .. k .. " (type: " .. type(v) .. ")")
			if type(v) == "table" then
				AutoRollDB[k] = {}
				local count = 0
				for k2, v2 in pairs(v) do
					AutoRollDB[k][k2] = v2
					count = count + 1
					if k == "raidSettings" then
						ns.print("DEBUG: Set raidSettings[" .. k2 .. "] = " .. tostring(v2))
					end
				end
				ns.print("DEBUG: Created table " .. k .. " with " .. count .. " entries")
			else
				AutoRollDB[k] = v
				ns.print("DEBUG: Set " .. k .. " = " .. tostring(v))
			end
		end
		ns.print("AutoRollDB reset to defaults")
		-- Show final raidSettings
		if AutoRollDB.raidSettings then
			ns.print("DEBUG: Final raidSettings has " .. #AutoRollDB.raidSettings .. " entries")
			for k, v in pairs(AutoRollDB.raidSettings) do
				ns.print("DEBUG: raidSettings[" .. k .. "] = " .. tostring(v))
			end
		else
			ns.print("DEBUG: ERROR - raidSettings is nil after reset!")
		end

	else
		ns.print("Unknown command: " .. cmd)
	end
end

SLASH_AUTOROLL1 = "/autoroll"
