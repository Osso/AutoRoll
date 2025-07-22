-- Luacheck configuration for WoW addon
std = "none"

-- WoW API globals
globals = {
    -- Frame/UI globals
    "CreateFrame", "GameTooltip", "InterfaceOptionsFramePanelContainer",
    "UIDropDownMenu_SetWidth", "UIDropDownMenu_Initialize", "UIDropDownMenu_CreateInfo",
    "UIDropDownMenu_AddButton", "UIDropDownMenu_SetSelectedValue", "UIDropDownMenu_Refresh",
    "HybridScrollFrame_GetOffset", "HybridScrollFrame_Update", "HybridScrollFrame_CreateButtons",
    "EasyMenu_Initialize", "ToggleDropDownMenu", "Settings", "_G", "AutoRollPanel",
    
    -- Item/Loot globals
    "GetItemInfo", "GetLootRollItemInfo", "RollOnLoot", "ConfirmLootRoll",
    "C_LootHistory", "C_Timer",
    
    -- Constants
    "GREED", "NEED", "ROLL_DISENCHANT", "PASS", "OPTIONS", "ADD", "ITEMS", "DELETE", "CANCEL", "CLOSE",
    
    -- Addon globals
    "AutoRollDB", "SlashCmdList", "SLASH_AUTOROLL1", "SLASH_AUTOROLL2",
    
    -- Utility functions
    "GetAddOnMetadata", "CopyTable", "wipe", "strsplit", "ReloadUI",
    
    -- Lua standard but need to be explicit
    "print", "tinsert", "floor", "strlen", "table", "ipairs", "pairs",
    "type", "tostring", "tonumber", "rawset", "setmetatable", "select"
}

-- Ignore some common WoW addon patterns
ignore = {
    "212", -- unused argument (common in event handlers)
    "213", -- unused loop variable
}