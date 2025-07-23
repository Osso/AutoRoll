
local addon, ns = ...

-- COMMENTED OUT: New vertical layout code - not working yet
-- TODO: Fix the vertical layout implementation

-- local itemListFrame = nil

-- -- Creates the scrollable item list frame using the new WoW 10.0+ ScrollBox API
-- local function CreateItemListFrame()
-- 	-- Main container frame
-- 	local frame = CreateFrame("Frame")
-- 	frame:SetSize(500, 300)
-- 	
-- 	-- Modern ScrollBox replaces the old ScrollFrame system
-- 	local scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
-- 	scrollBox:SetPoint("TOPLEFT", 10, -10)
-- 	scrollBox:SetPoint("BOTTOMRIGHT", -30, 50)
-- 	
-- 	-- Scrollbar for the ScrollBox
-- 	local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
-- 	scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 8, 0)
-- 	scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 8, 0)
-- 	
-- 	-- Linear view handles the layout of list items
-- 	local view = CreateScrollBoxListLinearView()
-- 	-- Initialize each button element with item data
-- 	view:SetElementInitializer("Button", function(button, itemId)
-- 		local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
-- 		if not itemName then
-- 			itemName = "Item ID: " .. itemId
-- 		end
-- 		if not itemTexture then
-- 			itemTexture = "Interface\\ICONS\\inv_misc_questionmark"
-- 		end
-- 		
-- 		button:SetSize(470, 32)
-- 		
-- 		-- Create icon texture if it doesn't exist
-- 		if not button.icon then
-- 			button.icon = button:CreateTexture(nil, "ARTWORK")
-- 			button.icon:SetSize(24, 24)
-- 			button.icon:SetPoint("LEFT", 5, 0)
-- 		end
-- 		button.icon:SetTexture(itemTexture)
-- 		
-- 		-- Create item name text if it doesn't exist
-- 		if not button.nameText then
-- 			button.nameText = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
-- 			button.nameText:SetPoint("LEFT", button.icon, "RIGHT", 8, 0)
-- 			button.nameText:SetPoint("RIGHT", -200, 0)
-- 			button.nameText:SetJustifyH("LEFT")
-- 		end
-- 		button.nameText:SetText(itemName)
-- 		
-- 		-- Create dropdown for roll type selection
-- 		if not button.dropdown then
-- 			button.dropdown = CreateFrame("DropdownButton", nil, button, "WowStyle1DropdownTemplate")
-- 			button.dropdown:SetPoint("RIGHT", -40, 0)
-- 			button.dropdown:SetWidth(120)
-- 			
-- 			local function SetupDropdown()
-- 				local dropdown = button.dropdown
-- 				dropdown:SetupMenu(function(_, rootDescription)
-- 					for rollType, label in pairs(ns.ModeLabels) do
-- 						rootDescription:CreateButton(label, function()
-- 							AutoRollDB.items[itemId] = rollType
-- 							dropdown:SetText(label)
-- 						end)
-- 					end
-- 				end)
-- 			end
-- 			SetupDropdown()
-- 		end
-- 		
-- 		-- Set current roll type
-- 		local currentRoll = AutoRollDB.items[itemId] or 2
-- 		button.dropdown:SetText(ns.ModeLabels[currentRoll] or "Greed")
-- 		
-- 		-- Create delete button
-- 		if not button.deleteBtn then
-- 			button.deleteBtn = CreateFrame("Button", nil, button, "UIPanelCloseButton")
-- 			button.deleteBtn:SetSize(20, 20)
-- 			button.deleteBtn:SetPoint("RIGHT", -5, 0)
-- 		end
-- 		button.deleteBtn:SetScript("OnClick", function()
-- 			AutoRollDB.items[itemId] = nil
-- 			UpdateItemList()
-- 		end)
-- 		
-- 		-- Style the button
-- 		button:SetNormalTexture(nil)
-- 		button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
-- 	end)
-- 	
-- 	-- Initialize the scroll system
-- 	ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
-- 	
-- 	frame.scrollBox = scrollBox
-- 	return frame
-- end

-- -- Updates the item list with current data
-- function UpdateItemList()
-- 	if not itemListFrame then return end
-- 	
-- 	local dataProvider = CreateDataProvider()
-- 	for itemId in pairs(AutoRollDB.items) do
-- 		dataProvider:Insert(itemId)
-- 	end
-- 	itemListFrame.scrollBox:SetDataProvider(dataProvider)
-- end

-- -- Creates the add item interface
-- local function CreateAddItemFrame()
-- 	local frame = CreateFrame("Frame")
-- 	frame:SetSize(500, 80)
-- 	
-- 	-- Label for the input
-- 	local label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
-- 	label:SetPoint("TOPLEFT", 10, -10)
-- 	label:SetText("Add new item (by Item ID or name):")
-- 	
-- 	-- Input field for item ID or name
-- 	local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
-- 	editBox:SetSize(300, 32)
-- 	editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -5)
-- 	editBox:SetAutoFocus(false)
-- 	
-- 	-- Add button
-- 	local addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
-- 	addButton:SetSize(80, 25)
-- 	addButton:SetPoint("LEFT", editBox, "RIGHT", 10, 0)
-- 	addButton:SetText("Add")
-- 	addButton:Disable()
-- 	
-- 	-- Help text showing validation status
-- 	local helpText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
-- 	helpText:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, -5)
-- 	helpText:SetText("Enter item ID or item name/link")
-- 	helpText:SetTextColor(0.7, 0.7, 0.7)
-- 	
-- 	-- Validates user input and enables/disables add button
-- 	local function ValidateInput()
-- 		local text = editBox:GetText()
-- 		if text and text ~= "" then
-- 			local itemID = tonumber(text)
-- 			if itemID then
-- 				-- Direct item ID input
-- 				if not AutoRollDB.items[itemID] then
-- 					addButton:Enable()
-- 					return itemID
-- 				else
-- 					helpText:SetText("Item already in list")
-- 					helpText:SetTextColor(1, 0.5, 0.5)
-- 				end
-- 			else
-- 				-- Item name or link input
-- 				local itemName, itemLink = GetItemInfo(text)
-- 				if itemLink then
-- 					itemID = itemLink:match("item:(%d+)")
-- 					itemID = tonumber(itemID)
-- 					if itemID and not AutoRollDB.items[itemID] then
-- 						addButton:Enable()
-- 						return itemID
-- 					else
-- 						helpText:SetText("Item already in list")
-- 						helpText:SetTextColor(1, 0.5, 0.5)
-- 					end
-- 				else
-- 					helpText:SetText("Item not found")
-- 					helpText:SetTextColor(1, 0.5, 0.5)
-- 				end
-- 			end
-- 		end
-- 		addButton:Disable()
-- 		return nil
-- 	end
-- 	
-- 	-- Handle text changes with delayed validation
-- 	editBox:SetScript("OnTextChanged", function()
-- 		helpText:SetText("Enter item ID or item name/link")
-- 		helpText:SetTextColor(0.7, 0.7, 0.7)
-- 		C_Timer.After(0.5, ValidateInput)
-- 	end)
-- 	
-- 	-- Add item to the database
-- 	local function AddItem()
-- 		local itemID = ValidateInput()
-- 		if itemID then
-- 			AutoRollDB.items[itemID] = 2 -- Default to Greed
-- 			editBox:SetText("")
-- 			UpdateItemList()
-- 			addButton:Disable()
-- 		end
-- 	end
-- 	
-- 	-- Handle button click and enter key
-- 	addButton:SetScript("OnClick", AddItem)
-- 	editBox:SetScript("OnEnterPressed", AddItem)
-- 	
-- 	return frame
-- end


local function OnSettingEnabled(_, _)
	ns.AddOnEnabled()
end

local function OnSettingDebugMode(_, _)
end


-- COMMENTED OUT: New vertical layout initialization - not working yet
-- local function initOptionsPanel()
-- 	local category, layout = Settings.RegisterVerticalLayoutCategory(addon)

-- 	do
-- 		local variableKey = "enabled"
-- 		local description = "Enable AutoRoll"
-- 		local tooltip = "Enable/Disable automatic rolling on all items. Uses item list settings when available, otherwise rolls greed."
-- 		local defaultValue = true
-- 			
-- 		local setting = Settings.RegisterAddOnSetting(category, addon.."_"..variableKey, variableKey, AutoRollDB, type(defaultValue), description, defaultValue)
-- 		Settings.CreateCheckbox(category, setting, tooltip)
-- 		setting:SetValueChangedCallback(OnSettingEnabled)
-- 	end
-- 	
-- 	do
-- 		local variableKey = "debug"
-- 		local description = "Enable debug messages"
-- 		local tooltip = "Enable/Disable debug messages in chat window."
-- 		local defaultValue = false
-- 			
-- 		local setting = Settings.RegisterAddOnSetting(category, addon.."_"..variableKey, variableKey, AutoRollDB, type(defaultValue), description, defaultValue)
-- 		Settings.CreateCheckbox(category, setting, tooltip)
-- 		setting:SetValueChangedCallback(OnSettingDebugMode)
-- 	end

-- 	-- Add section header for item list
-- 	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Item Roll Settings"))
-- 	
-- 	-- Add custom item list frame
-- 	local itemListInitializer = Settings.CreateElementInitializer("Frame", {
-- 		initFrame = function(frame)
-- 			itemListFrame = CreateItemListFrame()
-- 			itemListFrame:SetParent(frame)
-- 			itemListFrame:SetPoint("TOPLEFT")
-- 			itemListFrame:SetPoint("TOPRIGHT")
-- 			itemListFrame:SetHeight(300)
-- 			UpdateItemList()
-- 		end
-- 	})
-- 	layout:AddInitializer(itemListInitializer)
-- 	
-- 	-- Add custom add item frame
-- 	local addItemInitializer = Settings.CreateElementInitializer("Frame", {
-- 		initFrame = function(frame)
-- 			local addItemFrame = CreateAddItemFrame()
-- 			addItemFrame:SetParent(frame)
-- 			addItemFrame:SetPoint("TOPLEFT")
-- 			addItemFrame:SetPoint("TOPRIGHT")
-- 			addItemFrame:SetHeight(80)
-- 		end
-- 	})
-- 	layout:AddInitializer(addItemInitializer)

-- 	-- Register the panel with the settings system
-- 	Settings.RegisterAddOnCategory(category)
-- end

-- initOptionsPanel()

-- TEMPORARY: Use basic settings registration until vertical layout is fixed
local function initBasicSettings()
	local category = Settings.RegisterVerticalLayoutCategory(addon)
	
	do
		local variableKey = "enabled"
		local name = "Enable AutoRoll"
		local tooltip = "Enables the auto roll functionality"
		local setting = Settings.RegisterAddOnSetting(category, variableKey, variableKey, AutoRollDB, type(AutoRollDB[variableKey]), name, ns.AutoRollDB_defaults[variableKey])
		Settings.CreateCheckbox(category, setting, tooltip)
		setting:SetValueChangedCallback(OnSettingEnabled)
	end

	do
		local variableKey = "debugMode"
		local name = "Debug Mode"
		local tooltip = "Enable debug mode for troubleshooting"
		local setting = Settings.RegisterAddOnSetting(category, variableKey, variableKey, AutoRollDB, type(AutoRollDB[variableKey]), name, ns.AutoRollDB_defaults[variableKey])
		Settings.CreateCheckbox(category, setting, tooltip)
		setting:SetValueChangedCallback(OnSettingDebugMode)
	end

	do
		local variableKey = "defaultRollMode"
		local name = "Default Roll Mode"
		local tooltip = "The default roll mode for items not in the item list"
		local defaultValue = ns.AutoRollDB_defaults.defaultRollMode
		
		local function GetOptions()
			local container = Settings.CreateControlTextContainer()
			container:Add(0, "Pass")
			container:Add(2, "Greed")
			container:Add(1, "Need")
			container:Add(3, "Disenchant")
			container:Add(4, "Transmog")
			container:Add(5, "Do nothing")
			return container:GetData()
		end
		
		local setting = Settings.RegisterAddOnSetting(category, variableKey, variableKey, AutoRollDB, type(defaultValue), name, defaultValue)
		Settings.CreateDropdown(category, setting, GetOptions, tooltip)
	end

	do
		local variableKey = "fallbackRollMode"
		local name = "Fallback Roll Mode"
		local tooltip = "The roll mode to use when the default roll mode is not available"
		local defaultValue = ns.AutoRollDB_defaults.fallbackRollMode
		
		local function GetOptions()
			local container = Settings.CreateControlTextContainer()
			container:Add(5, "Do nothing")
			container:Add(0, "Pass")
			container:Add(2, "Greed")
			return container:GetData()
		end
		
		local setting = Settings.RegisterAddOnSetting(category, variableKey, variableKey, AutoRollDB, type(defaultValue), name, defaultValue)
		Settings.CreateDropdown(category, setting, GetOptions, tooltip)
	end

	Settings.RegisterAddOnCategory(category)
end

initBasicSettings()
