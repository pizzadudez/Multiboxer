-- addon object
local Multiboxer = unpack(select(2, ...))
-- ui lib
local StdUi = LibStub('StdUi')
-- other modules
local Scan = Multiboxer:GetModule('Scan')
local Post = Multiboxer:GetModule('Post')

-- module object
local Tab = Multiboxer:NewModule('Tab', 'AceEvent-3.0')


function Tab:Enable()
	-- never redraw the tab, show/hide the frame instead!
	if self.tabAdded then return end

	self.auctionTab = Multiboxer:AddAuctionHouseTab('Multiboxer', 'Multiboxer Auctions', self)
	self.tabAdded = true 

	self:DrawSellFrame()

	-- for testing purposes not final
	Scan.scanList = {152505,152510,152509,152507,152511,152506,152508} 
	self:DrawScanList()
	self:ScanButton()
	self:Finished()
	--self:DrawAuctionsFrame()
end

local sellFrameSettings = {

}

function Tab:DrawSellFrame()
	-- CHANGE source to db
	local itemList = {152505,152510,152509,152507,152511,152506,152508}
	local auctionTab = self.auctionTab
	local itemFrameHeight = 30

	local sellFrame = StdUi:Frame(auctionTab, 160, itemFrameHeight * #itemList)
	sellFrame:SetPoint('TOPLEFT', auctionTab, 'BOTTOMLEFT', 11, 230)

	local itemFrames = {}
	sellFrame.itemFrames = itemFrames
	itemFrames[0] = sellFrame

	for i, itemID in ipairs(itemList) do
		local itemFrame = StdUi:Panel(sellFrame, 162, itemFrameHeight)
		itemFrame.itemID = itemID
		itemFrames[i] = itemFrame
		itemFrames[itemID] = itemFrame -- so we can access itemFrame by itemID
		itemFrame:SetPoint('TOP', itemFrames[i-1], 'BOTTOM', 0, 0)
		
		-- Icon texture
		local icon = StdUi:Texture(itemFrame, 26, 26, GetItemIcon(itemFrame.itemID))
		icon:SetPoint('LEFT', itemFrame, 'LEFT', 90, 0)
		itemFrame.icon = icon

		-- Number of stacks to post
		local stackCount = StdUi:HighlightButton(itemFrame, 26, 26, '48')
		stackCount:SetPoint('RIGHT', icon, 'LEFT', 0, 0)
		stackCount:SetHighlightTexture(nil)
		stackCount.text:SetFontSize(16)
		stackCount:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
		stackCount:SetScript('OnClick', function(self, button)
			local sCount = tonumber(stackCount.text:GetText())
			if button == 'LeftButton' then
				stackCount.text:SetText(sCount + 12)
			elseif button == 'RightButton' then
				stackCount.text:SetText(math.max(sCount - 12, 0))
			end
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
	for i, itemID in ipairs({152505,152510,152509,152507,152511,152506,152508}) do
		if scanListFrame.items[i].isChecked then
			tinsert(Scan.scanList, itemID)
		end
	end

	print(table.concat(Scan.scanList,', '))
end

-- Tests Scan functionality
function Tab:ScanButton()
	local auctionTab = self.auctionTab
	local btn = StdUi:Button(auctionTab, 70, 40, 'Scan List')
	btn:SetPoint('TOPLEFT', auctionTab, 'TOPLEFT', 20, -30)
	btn:SetScript('OnClick', function()
		Scan:ScanList()
	end)
end

function Tab:Finished()
	local message = StdUi:Label(self.auctionTab, 'SCAN COMPLETE',60)
	message:SetPoint('TOPLEFT', self.auctionTab, 'TOPLEFT', 300, -250)
	message:SetTextColor(0,1,1,1)
	message:Hide()

	Scan.finished = message
end

-- create a sell table for selling
function Tab:GeneratePostTable()
	local postTable = {
		[2589] = 2,
		[152509] = 5,
		[52984] = 3,
	}
	local stackSize, price = 2, 150000
	Post.postTable = {}

	for itemID, count in pairs(postTable) do
		local auctionData = {}
		auctionData.itemID = itemID
		auctionData.stackSize = stackSize
		auctionData.price = price

		for i = 1, count do
			tinsert(Post.postTable, auctionData)
		end
	end
end

-- Slash Command List
SLASH_Multiboxer1 = '/mboxer'
SLASH_Multiboxer2 = '/mb'
SlashCmdList['Multiboxer'] = function(argString) Tab:SlashCommand(argString) end

function Tab:SlashCommand(argString)
	local args = {strsplit(" ", argString)}
	local cmd = table.remove(args, 1)

	if cmd == 'post' then
		if not Post.postTable then
			self:GeneratePostTable()
			print(Post.postTable)
		end
		Post:SellItem()
	else
		print('Multiboxer:')
	end
end