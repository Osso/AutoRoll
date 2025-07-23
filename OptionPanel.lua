
local addon, ns = ...

-- local changes

-- local itemIds = {}
-- local function updateItemList(self)
-- 	local offset = HybridScrollFrame_GetOffset(self)

-- 	if not changes.items then
-- 		changes.items = CopyTable(ns.AutoRollDB.items)
-- 		wipe(itemIds)
-- 	end
-- 	if #itemIds == 0 then
-- 		for i, v in pairs(changes.items) do
-- 			if v ~= nil then
-- 				table.insert(itemIds, i)
-- 			end
-- 		end
-- 		table.sort(itemIds, function(a, b) return a > b end)
-- 	end
-- 	local nItems, items = #itemIds, changes.items

-- 	for i = 1, #self.buttons do
-- 		local index = offset + i
-- 		local button = self.buttons[i]

-- 		if itemIds[index] then
-- 			local Id = itemIds[index]
-- 			local Name, _, _, _, _, _, _, _, _, Texture = GetItemInfo(Id)

-- 			button.ItemID:SetText(Id)
-- 			button.ItemIcon:SetTexture(Texture)
-- 			button.ItemName:SetText(Name)
-- 			button.ItemName:SetPoint("RIGHT", button.Mode, "LEFT", -10, 0) -- limit width of font string

-- 			button.Mode.index = Id
-- 			button.Mode.value = items[Id]

-- 			UIDropDownMenu_SetWidth(button.Mode, 94)
-- 			UIDropDownMenu_Initialize(button.Mode, function()
-- 				for v, t in pairs(ns.ModeLabels) do
-- 					local info = UIDropDownMenu_CreateInfo()
-- 					info.value = v
-- 					info.text = t
-- 					info.arg1 = button.Mode
-- 					info.arg2 = v
-- 					info.func = function(dropdownSelf, frame, value)
-- 						UIDropDownMenu_SetSelectedValue(frame, value)
-- 						changes.items[button.Mode.index] = value
-- 						button.Mode.value = value
-- 					end
-- 					UIDropDownMenu_AddButton(info)
-- 				end
-- 			end)
-- 			UIDropDownMenu_SetSelectedValue(button.Mode, items[Id])

-- 			local b = _G[button.Mode:GetName() .. "Button"]
-- 			b:SetHitRectInsets(-(button.Mode:GetWidth() - (b:GetWidth() * 2)), -3, -3, -3)

-- 			button.Delete:SetScript("OnClick", function()
-- 				changes.items[Id] = nil
-- 				wipe(itemIds)
-- 				updateItemList(self)
-- 			end)

-- 			button:SetBackdropColor(1, 1, 1, (index / 2 == floor(index / 2)) and 0 or 0.1)

-- 			button:Show()
-- 		else
-- 			button:Hide()
-- 		end
-- 	end

-- 	HybridScrollFrame_Update(self, nItems * self.buttonHeight, #self.buttons * self.buttonHeight)
-- end

-- local function checkInput(state)
-- 	local obj, objIsNumber, itemName, itemLink, itemTexture, itemId = panel.InputNewItem:GetText()
-- 	local _ -- declare underscore as local variable

-- 	if obj then
-- 		objIsNumber = (tonumber(obj) and true or false)
-- 		itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(obj)
-- 	end

-- 	if (itemLink) then
-- 		itemId = itemLink:match("Hitem:(%d+)");
-- 	end

-- 	if (not itemTexture) then
-- 		itemTexture = "Interface\\ICONS\\inv_misc_questionmark";
-- 	end

-- 	if (itemId and (changes.items[itemId] ~= nil or ns.AutoRollDB.items[itemId] ~= nil)) then
-- 		itemName, itemId = "Item already in list.", nil
-- 	elseif (not itemId) then
-- 		if (objIsNumber and state == "OnUpdate") then
-- 			itemName, itemId = "...", nil;
-- 		elseif (objIsNumber and state == "OnEvent") or (not objIsNumber and state == "OnUpdate") then
-- 			itemName, itemId = "Couldn't find a valid item.", nil
-- 		end
-- 	end

-- 	panel.ItemHelper:SetText(("|T%s:24:24:0:0|t %s"):format(itemTexture, itemName))

-- 	if itemId then
-- 		panel.InputNewItem.itemID = itemId
-- 		panel.AddNewItem:Enable()
-- 	else
-- 		panel.InputNewItem.itemID = nil
-- 		panel.AddNewItem:Disable()
-- 	end

-- 	ns.debugPrint(
-- 		"State: "..state,
-- 		"Obj: "..obj,
-- 		"ItemId: ".. (itemId or "nil"),
-- 		"ItemName: ".. (itemName or "nil")
-- 	);
-- end

-- local function addItem()
-- 	local id = tonumber(panel.InputNewItem.itemID);
-- 	if(id and not ns.AutoRollDB.items[id] and not changes.items[id])then
-- 		changes.items[id] = 1; -- greed is default
-- 		panel.InputNewItem:SetText("");
-- 		panel:refresh(true);
-- 	end
-- end

---------------------------------------------------------------
---------------------------------------------------------------

-- function panel:okay()
-- 	for i, v in pairs(changes) do
-- 		if (i == "items") then
-- 			AutoRollDB.items = CopyTable(changes.items);
-- 		else
-- 			AutoRollDB[i] = v;
-- 			if (i == "enabled") then
-- 				ns.AddOnEnabled();
-- 			end
-- 		end
-- 	end
-- 	changes = {};
-- 	ns.updateItemNames();
-- end

-- function panel:cancel()
-- 	changes = {};
-- end

-- function panel:default()
-- 	AutoRollDB = ns.AutoRollDB_defaults;
-- 	ReloadUI();
-- end

-- function panel:refresh(force)
-- 	if (force == true) then
-- 		wipe(itemIds);
-- 	end
-- 	for _, frame in pairs(panel.controls) do
-- 		if (type(frame.ctrl) == "function") then
-- 			frame.ctrl();
-- 		end
-- 	end
-- end

-- panel.checkInput = false;
-- panel.elapsed = 0;
-- panel:SetScript("OnUpdate", function(self, elapse)
-- 	if (self.checkInput) then
-- 		self.elapsed = self.elapsed + elapse;
-- 		if (self.elapsed > .76) then
-- 			self.checkInput = false;
-- 			checkInput("OnUpdate");
-- 		end
-- 	end
-- end);


-- panel:SetScript("OnEvent", function(self, event, ...)
-- 	if (event == "GET_ITEM_INFO_RECEIVED") then
-- 		local id = ...;
-- 		ns.debugPrint(
-- 			"Event: " .. event,
-- 			"itemId: " .. id
-- 		);
-- 		if (self.InputNewItem and self.InputNewItem:HasFocus()) then
-- 			checkInput("OnEvent");
-- 		end
-- 	end
-- end)


local function OnSettingEnabled(_, _)
	ns.AddOnEnabled()
end

local function OnSettingDebugMode(_, _)
	ns.AddOnEnabled()
end


local function initPanel()
	local category = Settings.RegisterVerticalLayoutCategory(addon)

	do
		local variableKey = "enabled"
		local description = "Enable AutoRoll"
		local tooltip = "Enable/Disable automatic rolling on all items. Uses item list settings when available, otherwise rolls greed."
		local defaultValue = true
			
		local setting = Settings.RegisterAddOnSetting(category, addon.."_"..variableKey, variableKey, ns.AutoRollDB, type(defaultValue), description, defaultValue)
		Settings.CreateCheckbox(category, setting, tooltip)
		setting:SetValueChangedCallback(OnSettingEnabled)
	end
	
	do
		local variableKey = "debug"
		local description = "Enable debug messages"
		local tooltip = "Enable/Disable debug messages in chat window."
		local defaultValue = false
			
		local setting = Settings.RegisterAddOnSetting(category, addon.."_"..variableKey, variableKey, ns.AutoRollDB, type(defaultValue), description, defaultValue)
		Settings.CreateCheckbox(category, setting, tooltip)
		setting:SetValueChangedCallback(OnSettingDebugMode)
	end

	-- --- Inset border frame for itemList (scrollFrame)
	-- local listName = "itemList"
	-- local listFrame = panel:GetName() .. "itemList"
	-- local borderName = "itemListBorder"
	-- panel[borderName] = CreateFrame("Frame", nil, panel)
	-- setPoints(panel[borderName], {"TOPLEFT", panel.title, "BOTTOMLEFT", 0, -66}, {"BOTTOMRIGHT", -14, 105})
	-- panel[borderName]:SetBackdrop({
	-- 	bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground",
	-- 	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	-- 	tile = true, tileSize = 32, edgeSize = 20,
	-- 	insets = {left = 4, right = 4, top = 4, bottom = 4}
	-- })

	-- --- itemList ScrollFrame
	-- panel[listName] = CreateFrame("ScrollFrame", listFrame, panel[borderName], "BasicHybridScrollFrameTemplate")
	-- setPoints(panel[listName], {"TOPLEFT", 8, -7}, {"BOTTOMRIGHT", -28, 7})
	-- setPoints(panel[listName].scrollBar,
	-- 	{"TOPLEFT", panel[listName], "TOPRIGHT", 0, -14},
	-- 	{"BOTTOMLEFT", panel[listName], "BOTTOMRIGHT", 0, 13})
	-- panel[listName].scrollBar.doNotHide = true
	-- panel[listName].update = updateItemList
	-- HybridScrollFrame_CreateButtons(panel[listName], "AutoRoll_ItemButtonTemplate", 0, 0, nil, nil, 0, -3)
	-- setControl(panel[listName], function() updateItemList(panel[listName]) end)

	-- --- add new items
	-- local inputName = "InputNewItem"
	-- panel[inputName] = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
	-- panel[inputName]:SetSize(240, 26)
	-- panel[inputName]:SetAutoFocus(false)
	-- panel[inputName].Label = panel[inputName]:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	-- panel[inputName].Label:SetPoint("BOTTOMLEFT", panel[inputName], "TOPLEFT")
	-- panel[inputName].Label:SetText("Add new item:")
	-- panel[inputName]:SetScript("OnTextChanged", function(self)
	-- 	if strlen(self:GetText()) > 0 then
	-- 		panel.checkInput = true
	-- 		panel.elapsed = 0
	-- 	else
	-- 		panel.checkInput = false
	-- 		panel.elapsed = 0
	-- 		panel.AddNewItem:Disable()
	-- 	end
	-- end)
	-- panel[inputName]:SetScript("OnEnterPressed", addItem)
	-- --- hook ChatFrame_OnHyperlinkShow(frame, link, text, button)

	-- setTooltip(panel[inputName],
	-- 	"Add new Item",
	-- 	"Adding an item by its item id.",
	-- 	{"Add an item by name is only possible for items in your bag.", 1, 1, 0, 1},
	-- 	{"Press enter or push the Add-Button to add the item to the item list", 0, 0.8, 0.95, 1}
	-- )
	-- setPoints(panel[inputName], {"TOPLEFT", panel.itemList, "BOTTOMLEFT", 20, -22})
	-- setControl(panel[inputName], function() panel[inputName]:SetText("") end)

	-- --- little helper to show if item name or id correct.
	-- panel.ItemHelper = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
	-- panel.ItemHelper:SetPoint("TOPLEFT",panel.InputNewItem,"BOTTOMLEFT", -3, -3);
	-- panel.ItemHelper:SetText("|TInterface\\ICONS\\inv_misc_questionmark:24:24:0:0|t");

	-- --- "add new item"-Button
	-- local n = "AddNewItem"
	-- local N = panel:GetName() .. n
	-- panel[n] = CreateFrame("Button", N, panel, "UIPanelButtonTemplate");
	-- panel[n].Text = _G[N.."Text"];
	-- panel[n].Text:SetText(ADD);
	-- panel[n]:SetWidth(panel[n].Text:GetWidth()+24);
	-- panel[n]:SetScript("OnClick",addItem);
	-- panel[n]:Disable();
	-- setPoints(panel[n],{"LEFT", panel.InputNewItem, "RIGHT", 10, 1});

	-- Register the panel with the settings system
	Settings.RegisterAddOnCategory(category)
end

-- Create a frame to handle ADDON_LOADED event
local optionFrame = CreateFrame("Frame")
optionFrame:RegisterEvent("ADDON_LOADED")
optionFrame:SetScript("OnEvent", function(self, event, addonName)
	if addonName == "AutoRoll" then
		initPanel()
		self:UnregisterEvent("ADDON_LOADED")
	end
end)
