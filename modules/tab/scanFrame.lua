-- addon object
local Multiboxer = unpack(select(2, ...))
-- ui lib
local StdUi = LibStub('StdUi')

-- module object
local Tab = Multiboxer:GetModule('Tab')

-- Message from Scan to update auctions data
function Tab:NEW_SCAN_DATA(message, itemID)
	self:DrawAuctionList(itemID)	
end

-- ScanFrame
function Tab:DrawScanFrame()
	local auctionTab = self.auctionTab
	
	local scanFrame = StdUi:Panel(auctionTab)
	scanFrame:SetPoint('TOPLEFT', auctionTab, 'TOPLEFT', 177, -81)
	scanFrame:SetPoint('BOTTOMRIGHT', auctionTab.statusBar, 'TOPRIGHT', 0, 2)
	auctionTab.scanFrame = scanFrame
    -- draw container frame and stop if no profile selected
    if not self.itemList then return end 
    local itemList = self.itemList

	local itemFrames = {}
	local itemFrameWidth = 74
	local itemFrameHeight = scanFrame:GetHeight()
	local itemFrameHeaderHeight = 24
	scanFrame.itemFrames = itemFrames
	
	for i, item in ipairs(itemList) do
		local itemID = item.itemID
		local itemFrame = {}
		itemFrame.panel, itemFrame.scrollFrame, itemFrame.auctionsFrame, itemFrame.scrollBar = 
			Multiboxer:ScrollFrame(scanFrame, itemFrameWidth, itemFrameHeight-itemFrameHeaderHeight)
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
	local realmName = Multiboxer.realmName
	local itemData = Multiboxer.db.scanData[realmName][itemID]
	
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
	if not auctions[1] or #scanData * auctions[1]:GetHeight() < itemFrame.scrollFrame:GetHeight() then
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
	if string.find(data.owner, Multiboxer.charName) then
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
		r, g, b, a = 255, 134, 67, 1
	end
	return r/255, g/255, b/255, a
end