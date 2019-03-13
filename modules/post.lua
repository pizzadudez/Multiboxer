-- addon object
local Multiboxer = unpack(select(2, ...))

-- module object
local Post = Multiboxer:NewModule('Post', 'AceEvent-3.0')


function Post:OnEnable()
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
	if #self.postTable > 0 then
		auction = table.remove(self.postTable, 1)
	else
		print("No more items to post")
		return
	end
	print(auction.itemID)
	self.itemID = auction.itemID
	self.stackSize = auction.stackSize
	self.stackPrice = auction.price * auction.stackSize
	self.stackBid = self.stackPrice - self.stackSize
	self.duration = 4
	self.count = 1

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

function Post:FindItemInInventory()
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			if GetContainerItemID(bag, slot) == self.itemID then
				return bag, slot
			end
		end
	end

	return nil, nil
end

