-- addon object
local Multiboxer = unpack(select(2, ...))
-- other modules
local Scan = Multiboxer:GetModule('Scan')
-- module object
local Inventory = Multiboxer:NewModule('Inventory', 'AceEvent-3.0')

function Inventory:Enable()
	self:RegisterEvent('ITEM_UNLOCKED')
end

function Inventory:ITEM_UNLOCKED(event, bag, slot)
	local key = bag .. '-' .. slot

	if self.lockedSlots[key] then
		self.lockedSlots[key] = false
		self.lockedSlotsCount = self.lockedSlotsCount - 1
		-- last lockedSlot unlocked
		if self.lockedSlotsCount == 0 then
			if self.finished then
				self.stacking = false
			else
				self:CombineStacks()
			end
		end
	end
end

-- Takes array of itemIDs as argument
function Inventory:StackItems(itemList)
	-- already in stacking process
	if self.stacking then return end

	--self.stacking = true
	self.stackTable = {}
	self.lockedSlots = {}
	self.lockedSlotsCount = 0
	self.itemList = {}
	self.stackSize = {}

	-- itemList hashtable + stackSize table for convenience
	for _, itemID in ipairs(itemList) do
		self.itemList[itemID] = true
		self.stackSize[itemID] = select(8, GetItemInfo(itemID))
	end

	self:CreateStackTable()
	self:CombineStacks()
end

function Inventory:CreateStackTable()
	local stackTable = self.stackTable

	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemID = GetContainerItemID(bag, slot)
			if self.itemList[itemID] then
				local count = select(2, GetContainerItemInfo(bag, slot))
				local stackSize = self.stackSize[itemID]
				if count < stackSize then
					stackTable[itemID] = stackTable[itemID] or {}
					tinsert(stackTable[itemID], {['bag'] = bag, ['slot'] = slot, ['count'] = count})
				end
			end
		end
	end

	-- if we didn't find more than 1 partial Stack
	for itemID, _ in pairs(self.itemList) do
		if stackTable[itemID] and #stackTable[itemID] <= 1 then 
			stackTable[itemID] = nil
		end
	end
end

function Inventory:CombineStacks()
	self.finished = true
	
	for itemID, stackTable in pairs(self.stackTable) do
		self.finished = false
		local newStackTable = {}
		local stackSize = self.stackSize[itemID]
		
		-- Combine all stacks 2 by 2
		local i, n = 1, #stackTable / 2
		while i <= n do
			local stack1 = stackTable[i]
			local stack2 = stackTable[#stackTable - i + 1]
			ClearCursor()
			PickupContainerItem(stack1.bag, stack1.slot)
			PickupContainerItem(stack2.bag, stack2.slot)
			-- if sum is exactly stackSize then nothing needs to be done
		
			if stack1.count + stack2.count < stackSize then
			-- stack1 is empty, stack2 incomplete
				self.lockedSlots[stack2.bag .. '-' .. stack2.slot] = true
				self.lockedSlotsCount = self.lockedSlotsCount + 1
				tinsert(newStackTable, {['bag'] = stack2.bag, ['slot'] = stack2.slot, ['count'] = stack1.count + stack2.count})
			elseif stack1.count + stack2.count > stackSize then
			-- stack1 is incomplete, stack2 is complete
				self.lockedSlots[stack1.bag .. '-' .. stack1.slot] = true
				self.lockedSlotsCount = self.lockedSlotsCount + 1
				tinsert(newStackTable, {['bag'] = stack1.bag, ['slot'] = stack1.slot, ['count'] = stack1.count + stack2.count - stackSize})
			end
			i = i + 1
		end

		-- For odd number of stacks - add middle stack to newStackTable
		if #stackTable % 2 ~= 0 then
			local middle = math.floor(#stackTable / 2) + 1
			tinsert(newStackTable, stackTable[middle])
		end

		-- Sort the new table (this makes last partial stacks be at the end of the bag)
		table.sort (newStackTable, function (a, b) 
			return (a.bag < b.bag) or (a.bag == b.bag and a.slot < b.slot)
		end)

		self.stackTable[itemID] = newStackTable
	end
end

function Inventory:StackCount(itemID, stackSize)
	return math.floor(GetItemCount(itemID) / stackSize)
end