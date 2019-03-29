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

	self:SetSettings()
	self:DrawSellFrame()
	self:DrawSettingsFrame()

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
	self:DrawScanData(itemID)	
end

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

function Tab:DrawSellFrame()
	-- if we don't have an itemList we don't need to draw
	if not self.itemList then return end 

	local itemList = self.itemList
	local auctionTab = self.auctionTab
	local itemFrameHeight = 30

	local sellFrame = StdUi:Frame(auctionTab, 160, itemFrameHeight * #itemList)
	sellFrame:SetPoint('TOPLEFT', auctionTab, 'BOTTOMLEFT', 11, 230)

	local itemFrames = {}
	sellFrame.itemFrames = itemFrames
	itemFrames[0] = sellFrame

	for i, item in ipairs(itemList) do
		local itemID = item.itemID
		local itemFrame = StdUi:Panel(sellFrame, 162, itemFrameHeight)

		itemFrame.itemID = itemID
		itemFrame.stackCount = item.stackCount or 0
		itemFrame.stackCountIncrement = item.stackCountIncrement or 
			self.settings.stackCountIncrement

		itemFrames[i] = itemFrame
		itemFrames[itemID] = itemFrame -- so we can access itemFrame by itemID
		itemFrame:SetPoint('TOP', itemFrames[i-1], 'BOTTOM', 0, 0)
		
		-- Icon texture
		local icon = StdUi:Texture(itemFrame, 26, 26, GetItemIcon(itemFrame.itemID))
		icon:SetPoint('LEFT', itemFrame, 'LEFT', 90, 0)
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
		local inventory = StdUi:Label(itemFrame, '89', 14)
		inventory:SetPoint('RIGHT', icon, 'LEFT', -30, 0)

		-- Number of stacks cheaper than our price
		local numCheaper = StdUi:Label(itemFrame, '13', 14)
		numCheaper:SetPoint('RIGHT', icon, 'LEFT', -60, 0)
		itemFrame.numCheaper = numCheaper

		-- Price per unit in gold
		local price = StdUi:Label(itemFrame, '44.99', 12)
		price:SetPoint('LEFT', icon, 'RIGHT', 6, 0)
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

-- ScanData Frame
function Tab:DrawScanFrame()
	local auctionTab = self.auctionTab
	local itemList = self.itemList

	local scanFrame = StdUi:Panel(auctionTab)
	scanFrame:SetPoint('TOPLEFT', auctionTab, 'TOPLEFT', 178, -93)
	scanFrame:SetPoint('BOTTOMRIGHT', auctionTab, 'BOTTOMRIGHT', 0, 10)
	auctionTab.scanFrame = scanFrame
	-- draw container frame and stop if no profile selected
	if not itemList then return end

	local itemFrames = {}
	local itemFrameWidth = 70
	local itemFrameHeight = scanFrame:GetHeight()
	local itemFrameHeaderHeight = 24
	scanFrame.itemFrames = itemFrames
	
	for i, item in ipairs(itemList) do
		local itemID = item.itemID
		local itemFrame = {}
		itemFrame.panel, itemFrame.scrollFrame, itemFrame.auctions = 
			self:ScrollFrame(scanFrame, itemFrameWidth, itemFrameHeight)
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

		self:DrawScanData(itemID)
	end
	
end

function Tab:DrawScanData(itemID)
	local scrollChild = self.auctionTab.scanFrame.itemFrames[itemID].auctions

	local createSlide = function(parent, data, i)
		return Tab:CreateSlide(parent, data)
	end

	local updateSlide = function(parent, itemFrame, data, i)
		Tab:UpdateSlide(itemFrame, data)
		itemFrame.itemIndex = i
	end

	if not scrollChild.items then
		scrollChild.items = {}
	end

	local realmName = GetRealmName()
	local scanData = Multiboxer.db.scanData[realmName][itemID].scanData

	Tab:ObjectList(scrollChild, scrollChild.items, createSlide, updateSlide, scanData, 0, 14, -1)
end

function Tab:CreateSlide(parent, data)
	local slide = StdUi:HighlightButton(parent, 50, 20)
	slide.text:SetText(math.floor(data.price * 100) / 100)
	slide.qty = StdUi:FontString(slide, data.qty)
	slide.qty:SetPoint('RIGHT', slide, 'LEFT', 8, 0)
	return slide
end

function Tab:UpdateSlide(slide, data)
	slide.text:SetText(math.floor(data.price * 100) / 100)
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
