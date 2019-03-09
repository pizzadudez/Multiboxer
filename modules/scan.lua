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
	-- first update or previous update was incomplete
	if self.queryProgress then
		self:StorePageData(self.currPage)
		-- no missing auction owners -> we can proceed to next page
		if self.noOwner == false then
			self.queryProgress = false

			if self:IsLastPage(self.currPage) then
				self:ScanList()
			else
				self:ScanNextPage()
			end
		end
	end
end

function Scan:ScanList()
	if not CanSendAuctionQuery() then
		Scan:ScheduleTimer('ScanList', 0.1)
		return
	end

	local itemString = table.remove(self.scanList, 1)
	if itemString then
		self:ScanItem(itemString)
	end
end

function Scan:ScanItem(itemString)
	self.itemString = itemString
	self.currPage = 0 -- pages start at 0

	-- QueryAuctionItems(text, minLevel, maxLevel, page, usable, rarity, getAll, exactMatch, filterData)
	QueryAuctionItems(self.itemString, nil, nil, self.currPage,
			nil, 0, false, true, nil)
	self.queryProgress = true
end

function Scan:ScanNextPage()
	if not CanSendAuctionQuery() then
		Scan:ScheduleTimer('ScanNextPage', 0.05)
		return
	end

	self.currPage = self.currPage + 1
	QueryAuctionItems(self.itemString, nil, nil, self.currPage,
		nil, 0, false, true, nil)
	self.queryProgress = true 
end

function Scan:IsLastPage(pageNum)
	return (self.currPage + 1) * 50 > self.numTotalAuctions
end

-- stores temprorary page data, returns true
function Scan:StorePageData(pageNum)
	self.noOwner = false
	self.currPageInfo = {}
	self.currPageInfo.pageNum = pageNum
	self.currPageInfo.auctionData  = {}

	self.currPageInfo.numPageAuctions, self.numTotalAuctions = GetNumAuctionItems("list")

	local auctionData = {}

	
	for i = 1, self.currPageInfo.numPageAuctions do
		auctionData = {}
		-- name, texture, count, quality, canUse, level, levelColHeader, minBid, minIncrement,
   		-- buyoutPrice, bidAmount, highBidder, bidderFullName, owner, ownerFullName, 
		-- saleStatus, itemId, hasAllInfo = GetAuctionItemInfo("list", i)

		auctionData.owner = select(14, GetAuctionItemInfo("list", i))
		if auctionData.owner == nil then -- incomplete data, not latest update
			self.noOwner = true
			return
		end

		auctionData.buy = select(10, GetAuctionItemInfo("list", i))
		auctionData.count = select(3, GetAuctionItemInfo("list", i))
		auctionData.timeLeft = GetAuctionItemTimeLeft("list", i)
		self.currPageInfo.auctionData[i] = auctionData
	end

	Multiboxer.db.test = Multiboxer.db.test or {}
	Multiboxer.db.test[self.itemString..pageNum] = self.currPageInfo.auctionData

	print('stored ' .. self.itemString .. ' page ' .. tostring(pageNum))
end

