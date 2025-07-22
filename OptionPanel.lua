
local addon, ns, panel = ...

---------------------------------------------------------------
---------------------------------------------------------------

local function getValue(a, b)
	if b then
		return (panel.changes[a][b] ~= nil) and panel.changes[a][b] or AutoRollDB[a][b]
	end
	return (panel.changes[a] ~= nil) and panel.changes[a] or AutoRollDB[a]
end

local function setValue(a, b, c)
	if c then
		if panel.changes[a] == nil then panel.changes[a] = {} end
		panel.changes[a][b] = c
	else
		panel.changes[a] = b
	end
end

local function setControl(frame, fnc)
	if not (frame.GetObjectType) then return end
	frame.ctrl = fnc
	table.insert(panel.controls, frame)
end

local function setTooltip(frame,...)
	if(select('#',...)==0)then return end
	frame.tooltip = {...};
	frame:SetScript("OnLeave",function() GameTooltip:Hide(); end);
	frame:SetScript("OnEnter",function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
		GameTooltip:AddLine(self.tooltip[1]);
		for i=2, #self.tooltip do
			if(type(self.tooltip[i])=="table")then
				GameTooltip:AddLine(unpack(self.tooltip[i]))
			else
				GameTooltip:AddLine(self.tooltip[i],1,1,1,1);
			end
		end
		GameTooltip:Show()
	end);
end

local function setPoints(frame,...)
	frame = (type(frame)=="string" and panel[frame]) or (type(frame)=="table" and frame) or nil;
	if(not frame)then return end

	local point1=...;
	if(point1==true)then
		frame:SetAllPoints();
	elseif(#{...}>0)then
		for _,point in ipairs({...})do
			frame:SetPoint(unpack(point))
		end
	else
		frame:SetPoint("TOPLEFT");
	end
end

---------------------------------------------------------------
---------------------------------------------------------------

local itemIds = {};
local function updateItemList(self)
	local offset = HybridScrollFrame_GetOffset(self);

	if(not panel.changes.items)then
		panel.changes.items = CopyTable(AutoRollDB.items);
		wipe(itemIds);
	end
	if(#itemIds==0)then
		for i,v in pairs(panel.changes.items)do
			if(v~=nil)then
				table.insert(itemIds,i);
			end
		end
		table.sort(itemIds,function(a,b) return a>b; end);
	end
	local nItems,items = #itemIds,panel.changes.items;

	for i=1, #self.buttons do
		local index = offset+i;
		local button = self.buttons[i];

		if(itemIds[index])then
			local Id = itemIds[index];
			local Name, _, Rarity, _, _, _, _, _, _, Texture = GetItemInfo(Id);

			button.ItemID:SetText(Id);
			button.ItemIcon:SetTexture(Texture);
			button.ItemName:SetText(Name);
			button.ItemName:SetPoint("RIGHT",button.Mode,"LEFT",-10,0); -- limit width of font string

			button.Mode.index = Id;
			button.Mode.value = items[Id];

			UIDropDownMenu_SetWidth(button.Mode, 94);
			UIDropDownMenu_Initialize(button.Mode, function()
				for v,t in pairs(ns.ModeLabels) do
					local info = UIDropDownMenu_CreateInfo();
					info.value = v; info.text = t;
					info.arg1 = button.Mode; info.arg2 = v;
					info.func = function(self,frame,value)
						UIDropDownMenu_SetSelectedValue(frame, value);
						panel.changes.items[button.Mode.index]=value;
						button.Mode.value=value;
					end
					UIDropDownMenu_AddButton(info);
				end
			end);
			UIDropDownMenu_SetSelectedValue(button.Mode, items[Id]);

			local b=_G[button.Mode:GetName().."Button"];
			b:SetHitRectInsets(-(button.Mode:GetWidth()-(b:GetWidth()*2)),-3,-3,-3)

			button.Delete:SetScript("OnClick",function()
				panel.changes.items[Id] = nil;
				wipe(itemIds);
				updateItemList(self);
			end);

			button:SetBackdropColor(1, 1, 1, (index/2==floor(index/2)) and 0 or .1 );

			button:Show();
		else
			button:Hide();
		end
	end

	HybridScrollFrame_Update(self, nItems * self.buttonHeight, #self.buttons * self.buttonHeight);
end

local function checkInput(state)
	local obj,objIsNumber,itemName,itemLink,itemTexture,itemId = panel.InputNewItem:GetText();

	if (obj) then
		objIsNumber = (tonumber(obj) and true or false);
		itemName,itemLink,_,_,_,_,_,_,_,itemTexture = GetItemInfo(obj);
	end

	if (itemLink) then
		itemId = itemLink:match("Hitem:(%d+)");
	end

	if (not itemTexture) then
		itemTexture = "Interface\\ICONS\\inv_misc_questionmark";
	end

	if (itemId and (panel.changes.items[itemId]~=nil or AutoRollDB.items[itemId]~=nil)) then
		itemName, itemId = "Item already in list.", nil
	elseif (not itemId)then
		if(objIsNumber and state=="OnUpdate")then
			itemName, itemId = "...", nil;
		elseif(objIsNumber and state=="OnEvent") or (not objIsNumber and state=="OnUpdate")then
			itemName, itemId = "Couldn't find a valid item.", nil
		end
	end

	panel.ItemHelper:SetText( ("|T%s:24:24:0:0|t %s"):format(itemTexture,itemName) );

	if(itemId)then
		panel.InputNewItem.itemID = itemId;
		panel.AddNewItem:Enable();
	else
		panel.InputNewItem.itemID = nil;
		panel.AddNewItem:Disable();
	end

	ns.debugPrint(
		"State: "..state,
		"Obj: "..obj,
		"ItemId: ".. (itemId or "nil"),
		"ItemName: ".. (itemName or "nil")
	);
end

local function addItem()
	local id = tonumber(panel.InputNewItem.itemID);
	if(id and not AutoRollDB.items[id] and not panel.changes.items[id])then
		panel.changes.items[id] = 1; -- greed is default
		panel.InputNewItem:SetText("");
		panel:refresh(true);
	end
end

---------------------------------------------------------------
---------------------------------------------------------------

panel = CreateFrame("Frame", "AutoRollPanel", InterfaceOptionsFramePanelContainer);
panel:SetAllPoints();
panel:Hide();
panel.name, panel.controls, panel.changes, panel.temp = addon, {}, {}, {};

function panel:okay()
	for i,v in pairs(panel.changes)do
		if(i=="items")then
			AutoRollDB.items = CopyTable(panel.changes.items);
		else
			AutoRollDB[i] = v;
			if(i=="enabled")then
				ns.AddOnEnabled();
			end
		end
	end
	panel.changes={};
	ns.updateItemNames();
end

function panel:cancel()
	panel.changes={};
end

function panel:default()
	AutoRollDB = ns.AutoRollDB_defaults;
	ReloadUI();
end

function panel:refresh(force)
	if(force==true)then
		wipe(itemIds);
	end
	for _,frame in pairs(panel.controls)do
		if(type(frame.ctrl)=="function")then
			frame.ctrl();
		end
	end
end

panel.checkInput = false;
panel.elapsed=0;
panel:SetScript("OnUpdate", function(self,elapse)
	if(self.checkInput)then
		self.elapsed = self.elapsed + elapse;
		if(self.elapsed>.76)then
			self.checkInput=false;
			checkInput("OnUpdate");
		end
	end
end);

panel:SetScript("OnEvent",function(self,event,...)
	if(event=="GET_ITEM_INFO_RECEIVED")then
		local id=...;
		ns.debugPrint(
			"Event: "..event,
			"itemId: "..id
		);
		if(self.InputNewItem and self.InputNewItem:HasFocus())then
			checkInput("OnEvent");
		end
	end
end);
panel:RegisterEvent("GET_ITEM_INFO_RECEIVED");

panel:SetScript("OnShow", function()
	--- Title
	panel.title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
	setPoints(panel.title,{"TOPLEFT", panel, 12, -12});
	panel.title:SetText("|TInterface\\Buttons\\UI-GroupLoot-Dice-Up:17:17:0:0|t "..addon.. " - "..OPTIONS);

	--- Subtitle
	panel.subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	setPoints(panel.subtitle,{"TOPLEFT", panel.title, "BOTTOMLEFT", 0, -4});
	panel.subtitle:SetText(("Version: %s / Author: %s"):format(GetAddOnMetadata(addon, "Version"),GetAddOnMetadata(addon,"Author")))

	--- Credit
	panel.credit = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	setPoints(panel.credit,{"BOTTOMLEFT", panel, "BOTTOMLEFT", 12, 12});
	panel.credit:SetText("Credit: Azial for initial idea and first piece of code in german WoW forum.")

	--- Checkbutton "Enable <addon>"
	local n,N="EnableAR";
	N=panel:GetName()..n;
	panel[n]=CreateFrame("CheckButton",N,panel,"OptionsCheckButtonTemplate");
	setPoints(panel[n],{"TOPLEFT",panel,"TOPRIGHT",-220,-6});
	_G[N.."Text"]:SetText("Enable AutoRoll")
	panel[n]:SetScript("OnClick",function() setValue("enabled",not getValue("enabled")); end);
	setControl(panel[n],function() panel[n]:SetChecked(getValue("enabled")); end);
	setTooltip(panel[n],"Enable AutoRoll","Enable/Disable automatic rolling on all items. Uses item list settings when available, otherwise rolls greed.")



	--- Checkbutton "Info message"
	local n,N="InfoMessage";
	N=panel:GetName()..n;
	panel[n]=CreateFrame("CheckButton",N,panel,"OptionsCheckButtonTemplate");
	setPoints(panel[n],{"TOPLEFT", panel.EnableAR, "BOTTOMLEFT", 0, 2});
	_G[N.."Text"]:SetText("Print info messages")
	panel[n]:SetScript("OnClick",function() setValue("infoMessage",not getValue("infoMessage")); end);
	setControl(panel[n],function() panel[n]:SetChecked(getValue("infoMessage")); end);
	setTooltip(panel[n],"Info message","Print info message on any executed loot roll in chat window.", {"Default: enabled",.6,.6,.6})

	--- Inset border frame for itemList (scrollFrame)
	local n, N, b="itemList"; N, b=panel:GetName()..n, n.."Border";
	panel[b] = CreateFrame("Frame", nil, panel);
	setPoints(panel[b],{"TOPLEFT", panel.title, "BOTTOMLEFT", 0, -66},{"BOTTOMRIGHT", -14, 105});
	panel[b]:SetBackdrop({ bgFile="Interface\\TutorialFrame\\TutorialFrameBackground", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=32, edgeSize=20, insets={left=4,right=4,top=4,bottom=4}});

	--- itemList ScrollFrame
	panel[n] = CreateFrame("ScrollFrame",N,panel[b],"BasicHybridScrollFrameTemplate");
	setPoints(panel[n],{"TOPLEFT",8,-7},{"BOTTOMRIGHT",-28,7});
	setPoints(panel[n].scrollBar,{"TOPLEFT",panel[n],"TOPRIGHT", 0, -14},{"BOTTOMLEFT",panel[n],"BOTTOMRIGHT", 0, 13});
	panel[n].scrollBar.doNotHide=true;
	panel[n].update = updateItemList;
	HybridScrollFrame_CreateButtons(panel[n],"AutoRoll_ItemButtonTemplate",0,0,nil,nil,0,-3);
	setControl(panel[n],function() updateItemList(panel[n]); end);
	
	--- add new items
	local n="InputNewItem";
	panel[n] = CreateFrame("EditBox", nil, panel, "InputBoxTemplate");
	panel[n]:SetSize(240, 26); panel[n]:SetAutoFocus(false);
	panel[n].Label = panel[n]:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	panel[n].Label:SetPoint("BOTTOMLEFT", panel[n], "TOPLEFT");
	panel[n].Label:SetText("Add new item:")
	panel[n]:SetScript("OnTextChanged",function(self)
		if strlen(self:GetText())>0 then
			panel.checkInput=true;
			panel.elapsed=0;
		else
			panel.checkInput=false;
			panel.elapsed=0;
			panel.AddNewItem:Disable();
		end
	end);
	panel[n]:SetScript("OnEnterPressed",addItem);
	--- hook ChatFrame_OnHyperlinkShow(frame, link, text, button)

	setTooltip(panel[n],
		"Add new Item",
		"Adding an item by its item id.",
		{"Add an item by name is only possible for items in your bag.",1,1,0,1},
		{"Press enter or push the Add-Button to add the item to the item list",0,.8,.95,1}
	)
	setPoints(panel[n],{"TOPLEFT", panel.itemList, "BOTTOMLEFT", 20, -22});
	setControl(panel[n],function() panel[n]:SetText(""); end);

	--- little helper to show if item name or id correct.
	panel.ItemHelper = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
	panel.ItemHelper:SetPoint("TOPLEFT",panel.InputNewItem,"BOTTOMLEFT", -3, -3);
	panel.ItemHelper:SetText("|TInterface\\ICONS\\inv_misc_questionmark:24:24:0:0|t");

	--- "add new item"-Button
	local n,N = "AddNewItem"; N=panel:GetName()..n;
	panel[n] = CreateFrame("Button", N, panel, "UIPanelButtonTemplate");
	panel[n].Text = _G[N.."Text"];
	panel[n].Text:SetText(ADD);
	panel[n]:SetWidth(panel[n].Text:GetWidth()+24);
	panel[n]:SetScript("OnClick",addItem);
	panel[n]:Disable();
	setPoints(panel[n],{"LEFT", panel.InputNewItem, "RIGHT", 10, 1});

	panel:refresh();
	panel:SetScript("OnShow",panel.refresh);
end);

local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name);
Settings.RegisterAddOnCategory(category);
