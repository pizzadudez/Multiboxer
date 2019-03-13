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

	Scan.scanList = {152505,152510,152509,152507,152511,152506,152508} 
	self:DrawScanList()
	self:ScanButton()
	self:Finished()
	
	self:DrawItemFrame()
	self:DrawAuctionsFrame()
end

function Tab:DrawAuctionsFrame()
	local panel, scrollFrame, scrollChild, scrollBar = StdUi:FauxScrollFrame(self.auctionTab, 70, 320, 16, 20)
	panel:SetPoint('TOPLEFT', self.auctionTab, 'TOPLEFT', 30, -80)
	-- scrollBar.panel:Hide()
	-- scrollBar:Hide()
	-- scrollBar.ScrollUpButton:Hide()
	-- scrollBar.ScrollDownButton:Hide()
end

function Tab:DrawItemFrame()
	local itemData = Multiboxer.db.scanData['Antonidas'][152509].scanData

	local auctions = {}
	self.itemFrame = StdUi:Frame(self.auctionTab, 600, 50)

	auctions[0] = self.itemFrame
	--for i, auctionData in ipairs(itemData) do
	for i = 1, 50 do
		auctions[i] = StdUi:Button(self.auctionTab, 50, 20, 'test')
		auctions[i]:SetPoint('TOP', auctions[i-1], 'BOTTOM', 0, 0)
	end

	auctions[1]:SetPoint('TOPLEFT', auctions[0], 'TOPLEFT', 0, 0)
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
