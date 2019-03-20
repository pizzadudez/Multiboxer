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

function Post:FindItemInInventory()
	local partialStack = {nil, nil}
	self.postCache = self.postCache or {}

	self:CombineStacks()

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

function Post:CombineStacks()
	local partialMap = {}

	-- find {bag, slot} of every partial stack
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			if GetContainerItemID(bag, slot) == self.itemID then
				local itemCount = select(2, GetContainerItemInfo(bag, slot))
				if itemCount < self.stackSize then
					tinsert(partialMap, {bag, slot, itemCount})
				end
			end
		end
	end

	if #partialMap <= 1 then return end

	-- combine partials
	while #partialMap > 1 do
		local stack1, stack2 = {}, {}
		stack1.bag, stack1.slot, stack1.count = unpack(partialMap[1])
		stack2.bag, stack2.slot, stack2.count = unpack(partialMap[#partialMap])

		-- the 2 stacks complete eachother -> remove 1st and last from list
		if stack1.count + stack2.count == self.stackSize then
			ClearCursor()
			PickupContainerItem(stack1.bag, stack1.slot)
			PickupContainerItem(stack2.bag, stack2.slot)

			tremove(partialMap, 1)
			tremove(partialMap, #partialMap)

		-- we move the first to the last -> 1st is now empty
		elseif stack1.count + stack2.count < self.stackSize then
			ClearCursor()
			PickupContainerItem(stack1.bag, stack1.slot)
			PickupContainerItem(stack2.bag, stack2.slot)

			tremove(partialMap, 1)
			partialMap[#partialMap].count = stack1.count + stack2.count
		-- place last on 1st -> 1st becomes complete
		elseif stack1.count + stack2.count > self.stackSize then
			ClearCursor()
			PickupContainerItem(stack2.bag, stack2.slot)
			PickupContainerItem(stack1.bag, stack1.slot)

			tremove(partialMap, 1)
			partialMap[#partialMap].count = stack1.count + stack2.count - self.stackSize
		end
	end
end

