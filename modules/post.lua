-- addon object
local Multiboxer = unpack(select(2, ...))

-- module object
local Post = Multiboxer:NewModule('Post', 'AceEvent-3.0')


function Post:Enable()
	self:RegisterEvent('AUCTION_HOUSE_SHOW')
	self:RegisterEvent('AUCTION_HOUSE_CLOSED')
end

function Post:AUCTION_HOUSE_SHOW()
	--self:RegisterEvent('AUCTION_ITEM_LIST_UPDATE');

	--self:RegisterEvent('AUCTION_MULTISELL_UPDATE');
	--self:RegisterEvent('UI_ERROR_MESSAGE');
end

function Post:AUCTION_HOUSE_CLOSED()
	--self:UnregisterEvent('AUCTION_MULTISELL_UPDATE');
	--self:UnregisterEvent('UI_ERROR_MESSAGE');
end

function Post:SellItem()
	local auction
	if #self.postList > 0 then
		auction = table.remove(self.postList, 1)
	else
		print("No more items to post")
		self.postCache = {}
		return
	end

	self.itemID = auction.itemID
	self.stackSize = auction.stackSize
	self.stackPrice = auction.price * auction.stackSize
	self.stackBid = self.stackPrice - self.stackSize
	self.duration = 3
	self.count = 1

	AuctionFrameAuctions.duration = self.duration
	local itemFound = self:PutItemInSellBox()

	if not itemFound then
		print("Could not find item in inventory")
		return
	end

	PostAuction(self.stackBid, self.stackPrice, self.duration, self.stackSize, self.count)
end

function Post:PutItemInSellBox()
	if CursorHasItem() then
		ClearCursor()
	end

	local bag, slot = self:FindItemInInventory()
	if not bag or not slot then
		return false
	end

	PickupContainerItem(bag, slot)
	if not CursorHasItem() then
		print('Could not pick up item from inventory')
		return false
	end

	ClickAuctionSellItemButton()
	ClearCursor()
	return true
end

-- posts unstacked slots last
function Post:FindItemInInventory()
	local partialStack = {nil, nil}
	self.postCache = self.postCache or {}

	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			if GetContainerItemID(bag, slot) == self.itemID then
				local itemCount = select(2, GetContainerItemInfo(bag, slot))
				if itemCount == self.stackSize then
					if not self.postCache[bag..slot] then
						self.postCache[bag..slot] = true
						print('  '..slot)
						return bag, slot
					end
				else 
					partialStack = {bag, slot}
				end
			end
		end
	end
	print('  '..(partialStack.slot or 0))
	return unpack(partialStack)
end



