-- addon object
local Multiboxer = unpack(select(2, ...))
local StdUi = LibStub('StdUi')

-- this module
local Scan = Multiboxer:NewModule('Scan', 'AceEvent-3.0', 'AceTimer-3.0')

function Scan:Enable()
	self:RegisterEvent('AUCTION_HOUSE_SHOW')
	self:RegisterEvent('AUCTION_HOUSE_CLOSED')
end

function Scan:AUCTION_HOUSE_SHOW()
	self:RegisterEvent('AUCTION_ITEM_LIST_UPDATE')

	--self:RegisterEvent('AUCTION_MULTISELL_UPDATE')
	--self:RegisterEvent('UI_ERROR_MESSAGE')
end

function Scan:AUCTION_HOUSE_CLOSED()
	--self:UnregisterEvent('AUCTION_MULTISELL_UPDATE')
	--self:UnregisterEvent('UI_ERROR_MESSAGE')
end

function Scan:TestTimer()
	QueryAuctionItems("Riverbud",nil,nil, 1, 0,0,false, true, nil)
end

local btn = StdUi:Button(UIParent, 60, 30, 'SCAN TEST')
btn:SetPoint('TOPLEFT', UIParent, 'CENTER', -300, 200)
btn:SetScript('OnClick', function()
	--QueryAuctionItems("Riverbud",nil,nil, 0, 0,0,false, true, nil)
	--Scan:ScheduleTimer('TestTimer', 8)
	Scan.scanList = {"Riverbud", "Siren's Pollen", "Akunda's Bite"}
	Scan:ScanList()
end)

function Scan:ScanList()
	local itemString = table.remove(self.scanList, 1)
	if itemString then
		self:ScanItem(itemString)
	end
end

function Scan:AUCTION_ITEM_LIST_UPDATE()
	-- TODO: find a way to only fire this after a chunk of list updates
	-- so the data is complete
	if self.activeScan and self.queryProgress then
		Scan:StorePageData(self.currPage)
		self.queryProgress = false
		self:ScanNextPage()
	end
end

function Scan:ScanItem(itemString)
	--TODO: if already scanning dont scan
	self.itemString = itemString
	self.currPage = 0

	self.activeScan = true
	self.queryProgress = false

	-- QueryAuctionItems(text, minLevel, maxLevel, page, usable, rarity, false, exactMatch, filterData)
	QueryAuctionItems(
		self.itemString, -- item name
		nil, -- minLevel
		nil, -- maxLevel
		self.currPage, -- page
		nil, -- usable
		0, -- rarity
		false, -- getAll
		true, -- exactMatch
		nil -- filterData
	)

	self.queryProgress = true
end

function Scan:ScanNextPage()
	if not self.activeScan then -- scan complete
		self:ScanList()
	end 
	local canQuery = CanSendAuctionQuery()

	if not canQuery then
		Scan:ScheduleTimer('ScanNextPage', 0.05)
	else
		self.currPage = self.currPage + 1
		QueryAuctionItems(self.itemString, nil, nil, self.currPage,
			nil, 0, false, true, nil)
		self.queryProgress = true 
	end
end

function Scan:StorePageData(pageNum)
	self.curPageInfo = {}
	self.curPageInfo.pagenum = pagenum
	self.curPageInfo.auctionInfo  = {}

	self.curPageInfo.numOnPage, self.totalAuctions = GetNumAuctionItems("list")

	self.name = select(1, GetAuctionItemInfo('list', 1))
	print('test capture data for page' .. tostring(pageNum).. ' '.. self.name)

	if (self.currPage + 1) * 50 > self.totalAuctions then
		self.activeScan = false
		print('finish')
	end
end

