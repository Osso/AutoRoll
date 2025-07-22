
local addon, ns = ...;
local L = ns.L;
local addonIcon = "Interface\\Buttons\\UI-GroupLoot-Dice-Up";

ns.LDB = LibStub("LibDataBroker-1.1");
ns.LDBI = LibStub("LibDBIcon-1.0");

--
-- Parts of Broker_Everything's EasyMenu (written by Hizuro)
--
local UIDropDownMenuDelegate = CreateFrame("FRAME");
local UIDROPDOWNMENU_MENU_LEVEL;
local UIDROPDOWNMENU_MENU_VALUE;
local UIDROPDOWNMENU_OPEN_MENU;

local menuFrame = CreateFrame("Frame", addon.."Menu", UIParent,"UIDropDownMenuTemplate");
menuFrame.menuList={};

local function Menu_AddEntry(D,P) -- data, parent
	local entry = {};

	if(type(D)=="table" and #D>0)then
		local childs={};
		for i=1, #D do
			local elem = Menu_AddEntry(D[i],P);
			tinsert(childs,elem);
		end
		return childs;
	
	elseif (D.childs) then
		return Menu_AddEntry(D.childs,Menu_AddEntry({label="|T"..D.icon..":18:18:0:0:64:64:5:59:5:59|t "..D.label, arrow=true},P));

	elseif (D.separator) then
		entry = { text = "", dist = 0, isTitle = true, notCheckable = true, isNotRadio = true, sUninteractable = true, iconOnly = true, icon = "Interface\\Common\\UI-TooltipDivider-Transparent", tCoordLeft = 0, tCoordRight = 1, tCoordTop = 0, tCoordBottom = 1, tFitDropDownSizeX = true, tSizeX = 0, tSizeY = 8 };
		entry.iconInfo = entry; -- looks like stupid? is necessary to work. (thats blizzard)

	else
		entry.text = D.label or "";
		entry.isTitle = D.title or false;
		entry.hasArrow = D.arrow or false;
		entry.disabled = D.disabled or false;
		entry.isNotRadio = D.radio~=true;
		entry.keepShownOnClick = (D.keepShown~=nil) and D.keepShown or nil;

		if (D.checked~=nil) then
			entry.checked = D.checked;
			if (entry.keepShownOnClick==nil) then
				entry.keepShownOnClick = 1;
			end
		else
			entry.notCheckable = true;
		end

		if(D.colorCode)then
			entry.colorCode = "|cff"..D.colorCode;
		end

		if (D.tooltip) and (type(D.tooltip)=="table") then
			entry.tooltipTitle = D.tooltip[1];
			entry.tooltipText = D.tooltip[2];
			entry.tooltipOnButton=1;
		end

		if (D.icon) then
			entry.text = entry.text .. "    "; -- prevent icon overlaying the text
			entry.icon = D.icon;
			entry.tCoordLeft, entry.tCoordRight,entry.tCoordTop, entry.tCoordBottom = 0.05,0.95,0.05,0.95; -- crop
		end

		if (D.func) then
			entry.arg1 = D.arg1;
			entry.arg2 = D.arg2;
			entry.func = function(self,...)
				D.func(self,...);
				if (D.radio) then
					UIDropDownMenu_Refresh(menuFrame, nil, tonumber(self:GetName():match("%d+")));
				end
				if (P) and (not entry.keepShownOnClick) then
					if (_G["DropDownList1"]) then _G["DropDownList1"]:Hide(); end
				end
			end;
		end

		if (not D.title) and (not D.disabled) and (not D.arrow) and (not D.checked) and (not D.func) then
			entry.disabled = true;
		end
	end

	if (P) and (type(P)=="table") then
		if (not P.menuList) then P.menuList = {}; end
		tinsert(P.menuList, entry);
		return P.menuList[#P.menuList];
	end

	tinsert(menuFrame.menuList, entry);
	return menuFrame.menuList[#menuFrame.menuList];
end

local function Menu_Create(parent)
	local anchor, x, y, displayMode = parent or "cursor", nil, nil, "MENU";
	if (parent) then x,y = 0,0; end

	wipe(menuFrame.menuList);

	Menu_AddEntry({
		{label=addon .. " - " .. OPTIONS, icon=addonIcon, title=true},
		{separator=true},
		{
			label=L["Enable AutoRoll"],
			checked=function() return AutoRollDB.enabled; end,
			func=function() AutoRollDB.enabled = not AutoRollDB.enabled; ns.AddOnEnabled(); end,
			tooltip={L["Enable AutoRoll"],L["Enable/Disable automatic rolling on listed items."]}
		},
		{
			label=L["Automaticly confirm all"],
			checked=function() return AutoRollDB.autoConfirmAll; end,
			func=function() AutoRollDB.autoConfirmAll = not AutoRollDB.autoConfirmAll; end,
			tooltip={L["Automaticly confirm all"],L["Automaticly confirm all group roll requests"].."|n|Cffff8800"..L["Not recommented"].."|n|Cff999999"..L["Default:"].." "..L["disabled"].."|r"}
		},
		{
			label=L["Automaticly roll on all"],
			checked=function() return AutoRollDB.autoRollAll; end,
			func=function() AutoRollDB.autoRollAll = not AutoRollDB.autoRollAll; end,
			tooltip={L["Automaticly roll on all"],L["Automaticly roll on all group roll items"].."|n|Cff00CCF2"..L["This function use the item list below. For all over items will be roll on greed."].."|n|Cff999999"..L["Default:"].." "..L["disabled"].."|r"}
		},
		{
			label=L["Print info messages"],
			checked=function() return AutoRollDB.infoMessage; end,
			func=function() AutoRollDB.infoMessage = not AutoRollDB.infoMessage; end,
			tooltip={L["Info message"],L["Print info message on any executed loot roll in chat window."].."|n|Cff999999"..L["Default:"].." "..L["enabled"]}
		},
		{separator=true},
		{label=ITEMS, title=true},
		{separator=true}
	});

	local count,limit,page,pages = 0,10,1,{};
	for id, mode in pairs(AutoRollDB.items)do
		count=count+1;
		if(count>limit)then count,page=1,page+1; end

		local name,_,_,_,_,_,_,_,_,texture=GetItemInfo(id);
		local entry = {label=name,icon=texture,childs={}};

		for modeIndex,modeLabel in pairs(ns.ModeLabels)do
			tinsert(entry.childs,{
				label=modeLabel,
				radio=true,
				checked=function() return AutoRollDB.items[id]==modeIndex; end,
				func=function() AutoRollDB.items[id] = modeIndex; end
			});
		end

		tinsert(entry.childs,{separator=true});
		tinsert(entry.childs,{label=DELETE, colorCode="ff0000", func=function() AutoRollDB.items[id]=nil; end});

		if(not pages[page])then pages[page]={}; end
		tinsert(pages[page], entry);
	end

	if(page==1)then
		Menu_AddEntry(pages[1]);
	elseif(page>limit)then
		local Splits,SplitCount,SplitStep = {},0,1;

		for i=1, #pages do
			SplitCount=SplitCount+1;
			if SplitCount>limit then
				SplitCount=1;
				SplitStep=SplitStep+1;
			end
			if(not Splits[SplitStep]) then
				Splits[SplitStep] = {};
			end
			tinsert(Splits[SplitStep], {label=L["Page %d"]:format(i), childs=pages[i]});
		end

		for i=1, #Splits do
			local _end = limit*i;
			Menu_AddEntry({label=L["Pages %d-%d"]:format(1+(limit*(i-1)), _end>#pages and #pages or _end), childs=Splits[i]});
		end
	else
		for i=1, page do
			Menu_AddEntry({label=L["Page %d"]:format(i), childs=pages[i]});
		end
	end

	Menu_AddEntry({
		{separator=true},
		{label=CANCEL.." / "..CLOSE, func=function() end}
	});

	UIDropDownMenu_Initialize(menuFrame, EasyMenu_Initialize, displayMode, nil, menuFrame.menuList);
	ToggleDropDownMenu(1, nil, menuFrame, anchor, x, y, menuFrame.menuList, nil, nil);
end

ns.LDB_Register = function()
	ns.LDB_Object = ns.LDB:NewDataObject(addon, {
		type="launcher",
		label=L[addon],
		text=L[addon],
		icon=addonIcon,
		staticIcon=addonIcon,
		iconCoords={0.1,0.9,0.1,0.9},
		OnClick = function(self,button)
			if(button=="LeftButton")then
				Menu_Create(self);
			elseif(button=="RightButton")then
				InterfaceOptionsFrame_OpenToCategory(AutoRollPanel);
				InterfaceOptionsFrame_OpenToCategory(AutoRollPanel);
			end
		end,
		OnTooltipShow = function(tt)
			tt:AddLine(addon);
			tt:AddLine(" ");
			--- last 5 rolls with result
			tt:AddLine(L["Left-click"].." - "..L["Open option menu"]);
			tt:AddLine(L["Right-click"].." - "..L["Open option panel"]);
		end
	});
	if(AutoRollDB.LDB_Icon and AutoRollDB.LDB_Icon.enabled)then
		ns.LDBI:Register(addon, ns.LDB_Object, AutoRollDB.LDB_Icon);
	end
end

