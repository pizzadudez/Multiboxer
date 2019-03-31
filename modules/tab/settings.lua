-- addon object
local Multiboxer = unpack(select(2, ...))
-- ui lib
local StdUi = LibStub('StdUi')

-- module object
local Tab = Multiboxer:GetModule('Tab')

-- SettingsFrame
function Tab:DrawSettingsFrame()
	local auctionTab = self.auctionTab
	local settingsFrame = StdUi:PanelWithTitle(auctionTab, 200, 330, 'Settings', 60, 16)
	settingsFrame:SetPoint('TOPRIGHT', auctionTab, 'TOPLEFT', -10, 0)

	-- Open/Close itemList selection Frame
	local itemList = StdUi:Button(settingsFrame, 70, 24, 'Item List')
	itemList:SetPoint('TOPLEFT', settingsFrame, 'TOPLEFT', 7, -32)
	
	-- Wrapper for itemList radio buttons
	local itemListFrame = StdUi:Panel(settingsFrame, 80, 60)
	itemListFrame:SetPoint('TOPLEFT', itemList, 'TOPRIGHT', 5, 0)
	itemListFrame:Hide()

	local function SelectItemList(listName)
		if not self.settings then
			Multiboxer.db.settings[Multiboxer.profileName] = Multiboxer.db.defaultSettings
		end

		self.activeItemList = listName
		self:SetSettings()
		itemListFrame:Hide() -- hide dropDownMenu for itemLists

		if not self.auctionTab.sellFrame then -- first time selecting profile -> draw sellFrame
			self:DrawSellFrame()
		end
		if not self.auctionTab.scanFrame then -- first time selecting profile -> draw scanFrame
			self:DrawScanFrame()
		end
	end

	-- Radio buttons for selecting itemList
	local radioButtons = {}
	radioButtons[0] = itemListFrame
	local rCount = 0

	for listName, _ in pairs(Multiboxer.db.defaultSettings.itemLists) do
		rCount = rCount + 1
		radioButtons[rCount] = StdUi:Radio(itemListFrame, listName, 'itemListsRadios')
		radioButtons[rCount]:SetValue(listName)
		radioButtons[rCount]:SetPoint('TOPLEFT', radioButtons[rCount - 1], 'BOTTOMLEFT', 0, 0)

		-- Set checked if this is the current itemList from settings
		if listName == self.activeItemList then
			radioButtons[rCount]:SetChecked(true)
		end

		-- Hook so we don't overwrite the widget creating hook for OnClick
		self:HookScript(radioButtons[rCount], 'OnClick', function() SelectItemList(listName) end)
	end
	radioButtons[1]:SetPoint('TOPLEFT', radioButtons[0], 'TOPLEFT', 5, -5)

	-- Show/Hide ItemListFrame
	itemList:SetScript('OnClick', function()
		if itemListFrame:IsShown() then
			itemListFrame:Hide()
		else
			itemListFrame:Show()
		end
	end)

	auctionTab.settingsFrame = settingsFrame
	self:ItemListOrder()
end

function Tab:SetSettings()
	-- We only create a profile when the user selects an itemList
	-- by clicking one of the itemList radio buttons
	if not Multiboxer.db.settings[Multiboxer.profileName] then
		self.noProfile = true
		return
	end

	self.noProfile = false
	self.settings = Multiboxer.db.settings[Multiboxer.profileName]

	self.activeItemList = self.activeItemList or self.settings.activeItemList
	self.settings.activeItemList = self.activeItemList
	self.itemList = self.settings.itemLists[self.activeItemList]
end

function Tab:ItemListOrder()
	if not self.itemList then return end

	local settingsFrame = self.auctionTab.settingsFrame
	local itemButtonWidth = 32
	local settingsFrameWidth = (itemButtonWidth + 15) * #self.itemList + 15

	local button = StdUi:Button(settingsFrame, 70, 24, 'Reorder List')
	button:SetPoint('TOPLEFT', settingsFrame, 'TOPLEFT', 7, -70)
	if not self.itemList then
		button:Disable()
	end

	local reorderFrame = StdUi:Panel(settingsFrame, settingsFrameWidth, 100)
	reorderFrame:SetPoint('CENTER', UIParent, 'CENTER')
	reorderFrame:SetFrameStrata('LOW')

	local itemButtons = {}
	reorderFrame.itemButtons = itemButtons
	local moveHereButtons = {}
	reorderFrame.moveHereButtons = moveHereButtons

	local function CreateItemButton(index)
		local button = StdUi:Button(reorderFrame, itemButtonWidth, itemButtonWidth)
		button.text:SetFontSize(7)
		button.index = index
		button:SetScript('OnClick', function()
			for i = 1, #self.itemList + 1 do
				-- show moveHere Buttons except the two near this index
				if i < index or i > index + 1 then
					moveHereButtons[i]:Show()
				end
				-- disable all itemButtons
				if itemButtons[i] then
					itemButtons[i]:Disable()
				end
				-- TODO show cancel button
				self.reorderIndex = index
			end
		end)
		
		return button
	end

	local function UpdateItemButton(button)
		if not self.itemList[button.index] then return end --- ????

		local itemID = self.itemList[button.index].itemID
		local icon = StdUi:Texture(button, button:GetWidth(), button:GetHeight(), GetItemIcon(itemID))
		button:SetNormalTexture(icon)
		icon:SetPoint('TOPLEFT', button, 'TOPLEFT', 1, -1)
		icon:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -1, 1)
	end

	local function CreateMoveHereButtons(parent, index)
		local button = StdUi:Button(parent, 16, 16, '+')
		button.index = index
		button:SetScript('OnClick', function()
			-- here we remove from list and insert in a different position
			local newIndex = index
			if index > self.reorderIndex then
				newIndex = index - 1
			end
			tinsert(self.itemList, newIndex, tremove(self.itemList, self.reorderIndex))

			for i = 1, #self.itemList + 1 do
				moveHereButtons[i]:Hide()
				if itemButtons[i] then	
					UpdateItemButton(itemButtons[i])
					itemButtons[i]:Enable()
				end
			end
		end)
		button:Hide()
		return button
	end

	for i, item in ipairs(self.itemList) do
		local itemID = item.itemID
		local itemButton = CreateItemButton(i)
		UpdateItemButton(itemButton)
		itemButtons[i] = itemButton

		-- Anchor buttons
		if i == 1 then
			itemButton:SetPoint('LEFT', reorderFrame, 'LEFT', 15, 0)
		else
			itemButton:SetPoint('LEFT', itemButtons[i-1], 'RIGHT', 15, 0)
		end
		
		local moveHereButton = CreateMoveHereButtons(itemButton, i)
		moveHereButton:SetPoint('TOPLEFT', itemButton, 'TOPLEFT', -10, 10)
		moveHereButtons[i] = moveHereButton

		if i == #self.itemList then
			moveHereButtons[i+1] = CreateMoveHereButtons(itemButton, i + 1)
			moveHereButtons[i+1]:SetPoint('TOPRIGHT', itemButton, 'TOPRIGHT', 10, 10)
		end
	end

	button:SetScript('OnClick', function()
		if reorderFrame:IsShown() then
			reorderFrame:Hide()
		else
			reorderFrame:Show()
		end
	end)

	reorderFrame:Hide()
	settingsFrame.reorderFrame = reorderFrame
end