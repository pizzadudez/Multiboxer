-- addon object
local Multiboxer = unpack(select(2, ...))
-- ui lib
local StdUi = LibStub('StdUi')

-- module object
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

function Scan:AUCTION_ITEM_LIST_UPDATE()
	-- TODO: find a way to only fire this after a chunk of list updates
	-- so the data is complete
	print('update')
	if self.activeScan and self.queryProgress then
		Scan:StorePageData(self.currPage)
		self.queryProgress = false
		self:ScanNextPage()
	end
end

-- Scans a list of items
function Scan:ScanList()
	local itemString = table.remove(self.scanList, 1)
	if itemString then
		self:ScanItem(itemString)
	end
end

-- Scans a single item
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
		print("waiting")
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

