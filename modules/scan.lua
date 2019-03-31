-- addon object
local Multiboxer = unpack(select(2, ...))

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
	self:UnregisterEvent('AUCTION_ITEM_LIST_UPDATE')
	self.queryProgress = false
	--self:UnregisterEvent('AUCTION_MULTISELL_UPDATE')
	--self:UnregisterEvent('UI_ERROR_MESSAGE')
end

function Scan:AUCTION_ITEM_LIST_UPDATE()
	-- first update or previous update was incomplete
	if self.queryProgress then
		self:StorePageData()
		-- no missing auction owners -> we can proceed to next page
		if self.missingOwner == false then
			self.queryProgress = false

			if self:IsLastPage() then
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

	local itemID = table.remove(self.scanList, 1)
	if itemID then
		SortAuctionSetSort('list', 'unitprice')
		SortAuctionApplySort('list')
		self:ScanItem(itemID)
	else
		self.finished:Show()
	end
end

function Scan:ScanItem(itemID)
	self.itemID = itemID
	self.itemString = select(1, GetItemInfo(itemID))
	self.currPage = 0 -- pages start at 0
	self.scanData = {}
	self.scanDataSorted = {}

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

function Scan:IsLastPage()
	return (self.currPage + 1) * 50 > self.numTotalAuctions
end

-- stores temprorary page data, returns true
function Scan:StorePageData()
	self.missingOwner = false
	self.currPageAuctions = {}
	
	self.numPageAuctions, self.numTotalAuctions = GetNumAuctionItems("list")
	local auctionData = {}

	for i = 1, self.numPageAuctions do
		auctionData = {}
		-- name, texture, count, quality, canUse, level, levelColHeader, minBid, minIncrement,
   		-- buyoutPrice, bidAmount, highBidder, bidderFullName, owner, ownerFullName, 
		-- saleStatus, itemId, hasAllInfo = GetAuctionItemInfo("list", i)

		auctionData.owner = select(14, GetAuctionItemInfo("list", i))
		if auctionData.owner == nil then -- incomplete data, not latest update
			self.missingOwner = true
			return
		end

		auctionData.stackSize = select(3, GetAuctionItemInfo("list", i))
		-- take in account price/stack posters
		auctionData.stackPriceCopper = select(10, GetAuctionItemInfo("list", i))
		auctionData.timeLeft = GetAuctionItemTimeLeft("list", i)
		self.currPageAuctions[i] = auctionData
	end

	self:CuratePageData()
	self:UpdateDatabase() -- stores sorted scan data in db and lets the GUI to redraw the scanFrame
	-- temporary integration for MultiboxAuctions
	C_ChatInfo.SendAddonMessage("Multiboxer", "NEW_SCAN_DATA", "WHISPER", Multiboxer.charName) 

	-- prints to chat page progress - will be integrated in ProgressBar
	print('stored ' .. self.itemString .. ' page ' .. tostring(self.currPage))
end

function Scan:CuratePageData()
	local scanData = self.scanData
	for i = 1, self.numPageAuctions do
		local auction = self.currPageAuctions[i]	
		if self:IsValidStackSize(auction.stackSize) then
			-- we only calculate per item buyout (in gold) if validStackSize for efficiency
			auction.price = math.floor(auction.stackPriceCopper / auction.stackSize + 0.5) / 10000
			auction.stackPriceCopper = nil -- not needed anymore

			local hashKey = auction.price .. '_' .. auction.stackSize .. '_' .. 
				auction.owner .. '_' .. auction.timeLeft

			if scanData[hashKey] then
				scanData[hashKey].qty = scanData[hashKey].qty + 1
			else
				local auctionData = auction
				auctionData.qty = 1
				scanData[hashKey] =  auctionData
			end
		end
	end
	
	self:SortScanData()
end

function Scan:SortScanData()
	local n = 0
	for hashKey, auctionData in pairs(self.scanData) do
		n = n + 1
		self.scanDataSorted[n] = auctionData
	end

	table.sort (self.scanDataSorted, function (a, b) return a.price < b.price end)
end

function Scan:IsValidStackSize(stackSize)
	return stackSize == 200 or stackSize == 100
end

function Scan:UpdateDatabase()
	local realmName = Multiboxer.realmName
	local db = Multiboxer.db.scanData[realmName] or {}
	Multiboxer.db.scanData[realmName] = db

	db[self.itemID] = {}
	db[self.itemID].scanData = self.scanDataSorted
	db[self.itemID].scanTime = time()
	
	self:SendMessage('NEW_SCAN_DATA', self.itemID)
end
