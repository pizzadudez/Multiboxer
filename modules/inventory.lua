-- addon object
local Multiboxer = unpack(select(2, ...))
-- other modules
local Scan = Multiboxer:GetModule('Scan')
-- module object
local Inventory = Multiboxer:NewModule('Inventory', 'AceEvent-3.0')

function Inventory:Enable()
	self.lockedSlots = self.lockedSlots or {}
	self:RegisterEvent('ITEM_UNLOCKED')
end

function Inventory:ITEM_UNLOCKED(event, bag, slot)
	local key = bag .. '-' .. slot
	if self.lockedSlots[key] then
		self.lockedSlots[key] = false
		self.lockedSlots.count = self.lockedSlots.count - 1
		if self.lockedSlots.count == 0 then
			self:CombineStacks(21877)
		end
	end
end

function Inventory:StackItem(itemID)
	self.stackSize = 200

	self.stackTable = self.stackTable or {}
	self.stackTable[itemID] = {}
	self.lockedSlots = self.lockedSlots or {}
	self.lockedSlots.count = self.lockedSlots.count or 0

	self:CreateStackTable(itemID)
	-- less than 2 stacks found means no stacking is needed
	if #self.stackTable[itemID] < 2 then return end

	-- Start the Stacking process
	self:CombineStacks(itemID)
end

function Inventory:CreateStackTable(itemID)
	local stackTable = self.stackTable[itemID]
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local id = GetContainerItemID(bag, slot)
			local count = select(2, GetContainerItemInfo(bag, slot))
			if id == itemID and count < self.stackSize then
				tinsert(stackTable, {['bag'] = bag, ['slot'] = slot, ['count'] = count})
			end
		end
	end
end

function Inventory:CombineStacks(itemID)
	local stackTable = self.stackTable[itemID]
	local newStackTable = {}

	-- Combine all stacks 2 by 2
	local i, n = 1, #stackTable / 2
	while i <= n do
		local stack1 = stackTable[i]
		local stack2 = stackTable[#stackTable - i + 1]
		ClearCursor()
		PickupContainerItem(stack1.bag, stack1.slot)
		PickupContainerItem(stack2.bag, stack2.slot)
		-- if sum is exactly self.stackSize then nothing needs to be done
	
		if stack1.count + stack2.count < self.stackSize then
		-- stack1 is empty, stack2 incomplete
			self.lockedSlots[stack2.bag .. '-' .. stack2.slot] = true
			self.lockedSlots.count = self.lockedSlots.count + 1
			tinsert(newStackTable, {['bag'] = stack2.bag, ['slot'] = stack2.slot, ['count'] = stack1.count + stack2.count})
		elseif stack1.count + stack2.count > self.stackSize then
		-- stack1 is incomplete, stack2 is complete
			self.lockedSlots[stack1.bag .. '-' .. stack1.slot] = true
			self.lockedSlots.count = self.lockedSlots.count + 1
			tinsert(newStackTable, {['bag'] = stack1.bag, ['slot'] = stack1.slot, ['count'] = stack1.count + stack2.count - self.stackSize})
		end
		i = i + 1
	end

	-- For odd number of stacks one will be left out
	-- so we add it to the next sortTable
	if #stackTable % 2 ~= 0 then
		local key = math.floor(#stackTable / 2) + 1
		tinsert(newStackTable, stackTable[key])
	end

	-- sort the new table
	table.sort (newStackTable, function (a, b) 
		return (a.bag < b.bag) or (a.bag == b.bag and a.slot < b.slot)
	end)

	self.stackTable[itemID] = newStackTable
end

function Inventory:AfterCombine()

end

function Inventory:StackCount(itemID, stackSize)
	return math.floor(GetItemCount(itemID) / stackSize)
end