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
	-- first update 
	if self.scanningItem and self.queryProgress then
		print('update1')
		Scan:StorePageData(self.currPage)
		self.queryProgress = false
		self:ScanNextPage()		
	-- any further updates before next query
	elseif not self.queryProgress then
		print('UPDATE')
	end

	-- TODO: find a way to only fire this after a chunk of list updates
	-- so the data is complete
end

function Scan:ScanList()
	local itemString = table.remove(self.scanList, 1)
	if itemString then
		self:ScanItem(itemString)
	end
end

function Scan:ScanItem(itemString)
	if self.scanningItem then return end -- don't disrupt current scan

	self.itemString = itemString
	self.currPage = 0 -- pages start at 0
	self.scanningItem = true

	-- QueryAuctionItems(text, minLevel, maxLevel, page, usable, rarity, getAll, exactMatch, filterData)
	QueryAuctionItems(self.itemString, nil, nil, self.currPage,
			nil, 0, false, true, nil)

	self.queryProgress = true
end

function Scan:ScanNextPage()
	if not self.scanningItem then -- scan complete
		self:ScanList()
	end 

	local canQuery = CanSendAuctionQuery()
	if not canQuery then
		Scan:ScheduleTimer('ScanNextPage', 0.05)
	else
		print('qry')
		self.currPage = self.currPage + 1
		QueryAuctionItems(self.itemString, nil, nil, self.currPage,
			nil, 0, false, true, nil)
		self.queryProgress = true 
	end
end

function Scan:StorePageData(pageNum)
	self.currPageInfo = {}
	self.currPageInfo.pageNum = pageNum
	self.currPageInfo.auctionInfo  = {}

	self.currPageInfo.numPageAuctions, self.numTotalAuctions = GetNumAuctionItems("list")

	self.name = select(1, GetAuctionItemInfo('list', 1))
	print('test capture data for page' .. tostring(pageNum).. ' '.. self.name)

	if (self.currPage + 1) * 50 > self.numTotalAuctions then
		self.scanningItem = false
		print('finished scanning '.. self.name)
	end
end

