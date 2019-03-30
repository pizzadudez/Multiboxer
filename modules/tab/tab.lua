-- addon object
local Multiboxer = unpack(select(2, ...))
-- ui lib
local StdUi = LibStub('StdUi')
-- other modules
local Scan = Multiboxer:GetModule('Scan')
local Post = Multiboxer:GetModule('Post')
local Inventory = Multiboxer:GetModule('Inventory')

-- module object
local Tab = Multiboxer:NewModule('Tab', 'AceEvent-3.0', 'AceHook-3.0')


function Tab:Enable()
	-- never redraw the tab, show/hide the frame instead!
	if self.tabAdded then return end
	
	self.auctionTab = Multiboxer:AddAuctionHouseTab('Multiboxer', 'Multiboxer Auctions', self)
	self.tabAdded = true 
	self.realmName = GetRealmName()
	self.charName = UnitName('player')

	self:SetSettings()
	self:DrawSellFrame()
	self:DrawSettingsFrame()
	self:DrawStatusBar()

	-- ScanFrame
	self:DrawScanFrame()
	self:RegisterMessage('NEW_SCAN_DATA')


	-- for testing purposes not final
	Scan.scanList = {152505,152510,152507,152509,152511,152506,152508} 
	self:DrawScanList()
	self:ScanButton()
	self:Finished()
	
	--self:DrawAuctionsFrame()
end

-- Message from Scan module
function Tab:NEW_SCAN_DATA(message, itemID)
	self:DrawAuctionList(itemID)	
end

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

-- SellFrame
function Tab:DrawSellFrame()
	-- if we don't have an itemList we don't need to draw
	if not self.itemList then return end 

	local itemList = self.itemList
	local auctionTab = self.auctionTab
	local itemFrameHeight = 30
	local itemFrameWidth = 168

	local sellFrame = StdUi:Frame(auctionTab, itemFrameWidth, itemFrameHeight * #itemList)
	sellFrame:SetPoint('BOTTOMLEFT', auctionTab, 'BOTTOMLEFT', 5, 10)

	local itemFrames = {}
	sellFrame.itemFrames = itemFrames
	itemFrames[0] = sellFrame

	for i, item in ipairs(itemList) do
		local itemID = item.itemID
		local itemFrame = StdUi:Panel(sellFrame, itemFrameWidth, itemFrameHeight)

		itemFrame.itemID = itemID
		itemFrame.stackCount = item.stackCount or 0
		itemFrame.stackCountIncrement = item.stackCountIncrement or 
			self.settings.stackCountIncrement

		itemFrames[i] = itemFrame
		itemFrames[itemID] = itemFrame -- so we can access itemFrame by itemID
		itemFrame:SetPoint('TOP', itemFrames[i-1], 'BOTTOM', 0, 0)
		
		-- Icon texture
		local icon = StdUi:Texture(itemFrame, 26, 26, GetItemIcon(itemFrame.itemID))
		icon:SetPoint('LEFT', itemFrame, 'LEFT', 30, 0)
		itemFrame.icon = icon

		-- Number of stacks to post
		local stackCount = StdUi:HighlightButton(itemFrame, 26, 26, itemFrame.stackCount)
		stackCount:SetPoint('RIGHT', icon, 'LEFT', 0, 0)
		stackCount:SetHighlightTexture(nil)
		stackCount.text:SetFontSize(16)
		stackCount:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
		stackCount:SetScript('OnClick', function(self, button)
			local sCount = tonumber(stackCount.text:GetText())
			if button == 'LeftButton' then
				stackCount.text:SetText(sCount + itemFrame.stackCountIncrement)
			elseif button == 'RightButton' then
				stackCount.text:SetText(math.max(sCount - itemFrame.stackCountIncrement, 0))
			end
			-- update settings when value changes
			Tab.itemList[i].stackCount = tonumber(stackCount.text:GetText())
		end)
		itemFrame.stackCount = stackCount

		-- Number of stacks available in inventory + bank
		local inventory = StdUi:Label(itemFrame, nil, 14)
		inventory:SetPoint('LEFT', icon, 'RIGHT', 6, 0)
		inventory:SetText(math.floor(GetItemCount(itemID, true)/200))

		-- Number of stacks cheaper than our price
		local numCheaper = StdUi:Label(itemFrame, nil, 14)
		numCheaper:SetPoint('LEFT', icon, 'RIGHT', 40, 0)
		itemFrame.numCheaper = numCheaper

		-- Price per unit in gold
		local price = StdUi:Label(itemFrame, nil, 12)
		price:SetPoint('LEFT', icon, 'RIGHT', 68, 0)
		itemFrame.price = price
	end

	-- Glue first itemFrame to sellFrame
	if itemFrames[1] then
		itemFrames[1]:SetPoint('TOPLEFT', sellFrame, 'TOPLEFT', 0, 0)
	end

	auctionTab.sellFrame = sellFrame
end

function Tab:CreatePostList()
	local stackSize = 200 -- CHANGEME
	Post.postList = {}
	local itemList = self.itemList
	
	itemList = {
		{itemID = 21877, stackCount = 21},
	}

	for _, item in pairs(itemList) do
		local itemID = item.itemID
		--local price = Multiboxer.db.scanData[GetRealmName()][itemID].postPrice or nil
		price = 2
		-- if we got a posting Price add to Post List
		if price then
			local invStacks = Inventory:StackCount(itemID, stackSize)
			local stackCount = math.min(item.stackCount, invStacks)

			for i = 1, stackCount do
				local postData = {}
				postData.itemID = itemID
				postData.stackSize = stackSize
				-- When posting price must be in coppers so we must *10000
				postData.price = price * 10000
				tinsert(Post.postList, postData)
			end
		end
	end
end

-- ScanFrame
function Tab:DrawScanFrame()
	local auctionTab = self.auctionTab
	local itemList = self.itemList

	local scanFrame = StdUi:Panel(auctionTab)
	scanFrame:SetPoint('TOPLEFT', auctionTab, 'TOPLEFT', 177, -81)
	scanFrame:SetPoint('BOTTOMRIGHT', auctionTab.statusBar, 'TOPRIGHT', 0, 2)
	auctionTab.scanFrame = scanFrame
	-- draw container frame and stop if no profile selected
	if not itemList then return end

	local itemFrames = {}
	local itemFrameWidth = 74
	local itemFrameHeight = scanFrame:GetHeight()
	local itemFrameHeaderHeight = 24
	scanFrame.itemFrames = itemFrames
	
	for i, item in ipairs(itemList) do
		local itemID = item.itemID
		local itemFrame = {}
		itemFrame.panel, itemFrame.scrollFrame, itemFrame.auctionsFrame, itemFrame.scrollBar = 
			self:ScrollFrame(scanFrame, itemFrameWidth, itemFrameHeight-itemFrameHeaderHeight)
		itemFrame.panel:SetPoint('TOP', scanFrame, 'TOP', 0, -itemFrameHeaderHeight+1)
		itemFrame.panel:SetPoint('BOTTOM', scanFrame, 'BOTTOM')

		itemFrame.header = StdUi:Panel(scanFrame, itemFrameWidth, itemFrameHeaderHeight)
		itemFrame.header:SetPoint('BOTTOM', itemFrame.panel, 'TOP', 0, -1)

		if i == 1 then
			itemFrame.panel:SetPoint('LEFT', scanFrame, 'LEFT')
		else
			itemFrame.panel:SetPoint('LEFT', itemFrames[i-1].panel, 'RIGHT', -1, 0)
		end
		-- access this frame by order or itemID
		itemFrames[i], itemFrames[itemID] = itemFrame, itemFrame

		-- no slides drawn yet so hide the scrollbar
		itemFrame.scrollBar.panel:Hide()
		itemFrame.scrollBar:Hide()

		self:DrawAuctionList(itemID)
	end
	
end

function Tab:DrawAuctionList(itemID)
	local itemFrame = self.auctionTab.scanFrame.itemFrames[itemID]
	local auctionsFrame = itemFrame.auctionsFrame
	local itemData = Multiboxer.db.scanData[self.realmName][itemID]
	
	if not itemData then return end -- dont draw anything if we don't have scanData
	local scanData = itemData.scanData
	local scanTime = itemData.scanTime

	local auctions = auctionsFrame.auctions or {}
	auctionsFrame.auctions = auctions

	-- update/create auction slides
	local numCheaper = 0
	for i, data in ipairs(scanData) do
		local auction = auctions[i]
		-- add how many cheaper stacks there are to slide's data table
		if i > 1 then
			numCheaper = numCheaper + auctions[i-1].data.qty * auctions[i-1].data.stackSize / 200
		end
		data.numCheaper = numCheaper
		-- create slide if not already created
		if not auction then
			auction = self:CreateAuctionSlide(auctionsFrame, itemID)
		end
		-- update or initialize it's data
		self:UpdateAuctionSlide(auction, data)
		-- slide anchoring
		if i == 1 then
			auction:SetPoint('TOPLEFT', auctionsFrame, 'TOPLEFT')
		else
			auction:SetPoint('TOP', auctions[i-1], 'BOTTOM')
		end
		auctions[i] = auction
	end

	-- hide excess slides
	for i = #scanData + 1, #auctions do
		auctions[i]:Hide()
	end

	-- hide/show scrollBar
	if #scanData * auctions[1]:GetHeight() < itemFrame.scrollFrame:GetHeight() then
		itemFrame.scrollBar.panel:Hide()
		itemFrame.scrollBar:Hide()
	else
		itemFrame.scrollBar.panel:Show()
		itemFrame.scrollBar:Show()
	end
end

function Tab:CreateAuctionSlide(parent, itemID)
	local slideHeight = 20
	local slideWidth = parent:GetWidth()
	local slide = StdUi:Frame(parent, slideWidth, slideHeight)
	-- clickable price 
	local price = StdUi:HighlightButton(slide, slideWidth*6/10, slideHeight)
	price:SetPoint('TOPRIGHT', slide, 'TOPRIGHT')
	price.text:SetJustifyH('LEFT')
	-- set price and numCheaper for sellFrame
	local this = self
	price:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	price:SetScript('OnClick', function(self, button)
		local sellItemFrame = this.auctionTab.sellFrame.itemFrames[itemID]
		local data = slide.data
		if button == 'RightButton' then
			sellItemFrame.price:SetText(nil)
			sellItemFrame.numCheaper:SetText(nil)
		else
			local sellPrice = math.floor(data.price * 10000) / 10000 - 0.0101
			sellItemFrame.price:SetText(sellPrice)
			sellItemFrame.numCheaper:SetText(data.numCheaper)
		end
	end)
	slide.price = price
	-- qty fontstring
	local qty = StdUi:Label(slide, nil, 12, nil, slideWidth*3.3/10, slideHeight)
	qty:SetPoint('TOPLEFT', slide, 'TOPLEFT')
	qty:SetJustifyH('RIGHT')
	slide.qty = qty

	return slide
end

function Tab:UpdateAuctionSlide(slide, data)
	slide.data = data
	if not slide:IsVisible() then
		slide:Show()
	end

	local price = slide.price
	price.text:SetText(math.floor(data.price * 100) / 100)
	price.text:SetTextColor(self:PriceColor(data))

	local qty = slide.qty
	qty:SetText(data.qty)
	qty:SetTextColor(self:QtyColor(data))
end

function Tab:PriceColor(data)
	if data.owner == self.charName then
		r, g, b, a = 86, 255, 255, 1
	elseif data.timeLeft == 2 then
		r, g, b, a = 160, 160, 160, 1
	elseif data.timeLeft == 1 then
		r, g, b, a = 160, 160, 160, 0.5
	else
		r, g, b, a = 255, 255, 255 , 1
	end
	return r/255, g/255, b/255, a
end

function Tab:QtyColor(data)
	local stackSize = data.stackSize
	if stackSize == 200 or stackSize == 20 then
		r, g, b, a = 244, 209, 66, 1
	elseif stackSize == 100 or stackSize == 10 then
		r, g, b, a = 2552, 134, 67, 1
	end
	return r/255, g/255, b/255, a
end

-- StatusBar
function Tab:DrawStatusBar()
	local auctionTab = self.auctionTab
	local statusBar = StdUi:ProgressBar(auctionTab, 650, 30)
	statusBar:SetPoint('BOTTOMRIGHT', auctionTab, 'BOTTOMRIGHT', -5, 10)
	statusBar:SetMinMaxValues(0, 1000)
	statusBar:SetValue(899)
	statusBar:SetStatusBarColor(0.1, 0.5, 0.2, 1)

	auctionTab.statusBar = statusBar
end

---------------------------------- testing -----------------

function Tab:DrawAuctionsFrame()
	local auctionTab = self.auctionTab
	local cols = {
		{name = 'Qty', width = 24, align = 'LEFT', index = 'qty', format = 'number'},
		{name = 'Price', width = 32, align = 'LEFT', index = 'price', format = 'number'}
	}
	local sTable = StdUi:ScrollTable(auctionTab, cols, 16, 18)
	sTable:SetPoint('TOPLEFT', auctionTab, 'TOPLEFT', 50, -90)
	sTable:EnableSelection(true)

	local data = {}
	local itemData = Multiboxer.db['scanData']['Antonidas'][152509]['scanData']
	for i, auctionData in ipairs(itemData) do
		local auction = {}
		auction.qty = auctionData.qty
		auction.price = math.floor(auctionData.price * 100) / 100
		tinsert(data, auction)
	end

	sTable:SetData(data)
	sTable:Show()
	
	auctionTab.sTable = sTable
end

-- Checkbox list for what items to scan
function Tab:DrawScanList()
	local auctionTab = self.auctionTab
	local scanListFrame = StdUi:Frame(auctionTab, 200, 60)
	scanListFrame:SetPoint('TOPLEFT', auctionTab, 'TOPLEFT', 92, -30)

	scanListFrame.items = scanListFrame.items or {}
	scanListFrame.items[0] = scanListFrame
	for i, itemID in ipairs({152505,152510,152509,152507,152511,152506,152508}) do

		local item = StdUi:Checkbox(scanListFrame, 24, 24)
		scanListFrame.items[i] = item
		item:SetPoint('LEFT', scanListFrame.items[i-1], 'RIGHT', 4, 0)
		item:SetChecked(true)
		item.OnValueChanged = function(self, state, value)
			Tab:CreateScanList()
		end
		
		local textureID = GetItemTextureID(itemID)
		item.texture = StdUi:Texture(item, 24, 24, textureID)
		item.texture:SetPoint("BOTTOM", item, "TOP", 0, 0)
	end
	scanListFrame.items[1]:SetPoint('TOPLEFT', scanListFrame, 'TOPLEFT', 3, -20)

	auctionTab.scanListFrame = scanListFrame
end

function Tab:CreateScanList()
	Scan.scanList = {}

	local scanListFrame = self.auctionTab.scanListFrame
	for i, itemID in ipairs({152505,152510,152507,152509,152511,152506,152508}) do
		if scanListFrame.items[i].isChecked then
			tinsert(Scan.scanList, itemID)
		end
	end

	print(table.concat(Scan.scanList,', '))
end

function Tab:ScanButton()
	local auctionTab = self.auctionTab
	local btn = StdUi:Button(auctionTab, 70, 40, 'Scan List')
	btn:SetPoint('TOPLEFT', auctionTab, 'TOPLEFT', 20, -30)
	btn:SetScript('OnClick', function()
		Scan:ScanList()
	end)
end

-- Temporary
function Tab:StackButton()
	local stackBtn = StdUi:Button(UIParent, 36, 20, 'Stack')
	stackBtn:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -44, -150)
	stackBtn:SetScript('OnClick', function()
		if not self.itemList then return end
		local itemList = {}
		for _, item in ipairs(self.itemList) do
			tinsert(itemList, item.itemID)
		end
		Inventory:StackItems(itemList) 
	end)
end
Tab:StackButton()

-- Scan Finished fontstring
function Tab:Finished()
	local message = StdUi:Label(self.auctionTab, 'SCAN COMPLETE',60)
	message:SetPoint('TOPLEFT', self.auctionTab, 'TOPLEFT', 300, -250)
	message:SetTextColor(0,1,1,1)
	message:Hide()

	Scan.finished = message
end

-- Slash Command List
SLASH_Multiboxer1 = '/mboxer'
SLASH_Multiboxer2 = '/mb'
SlashCmdList['Multiboxer'] = function(argString) Tab:SlashCommand(argString) end

function Tab:SlashCommand(argString)
	local args = {strsplit(" ", argString)}
	local cmd = table.remove(args, 1)

	if cmd == 'post' then
		if not Post.postList or #Post.postList < 1 then
			self:CreatePostList()
		end
		-- Post.itemID = 21877
		-- Post.stackSize = 200
		-- Post:CombineStacks()
		Post:SellItem()
		print(#Post.postList)
	else
		print('Multiboxer:')
	end
end
