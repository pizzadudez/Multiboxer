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

	self:SetSettings() -- initialises settings for this module
	self:DrawSellFrame()
	self:DrawSettingsFrame()
	self:DrawStatusBar()

	-- ScanFrame
	self:DrawScanFrame()
	self:RegisterMessage('NEW_SCAN_DATA')

	-- for testing purposes not final
	self:DrawScanList()
	self:ScanButton()
	self:Finished()
end

-- SellFrame
function Tab:DrawSellFrame()
	-- if we don't have an itemList we don't need to draw
	if not self.itemList then return end 

	local auctionTab = self.auctionTab
	local itemList = self.itemList
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
		--local price = Multiboxer.db.scanData[Multiboxer.realmName][itemID].postPrice or nil
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

-- Checkbox list for what items to scan
function Tab:DrawScanList()
	if not self.itemList then return end

	local auctionTab = self.auctionTab
	local scanListFrame = StdUi:Frame(auctionTab, 200, 60)
	scanListFrame:SetPoint('TOPLEFT', auctionTab, 'TOPLEFT', 92, -30)

	scanListFrame.items = scanListFrame.items or {}
	scanListFrame.items[0] = scanListFrame
	for i, value in ipairs(self.itemList) do
		itemID = value.itemID
		local item = StdUi:Checkbox(scanListFrame, 24, 24)
		scanListFrame.items[i], scanListFrame.items[itemID] = item
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
	Scan.stackSizeList = self.stackSizeList

	local scanListFrame = self.auctionTab.scanListFrame
	for i, item in ipairs(self.itemList) do
		local itemID = item.itemID
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
		Tab:CreateScanList()
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
