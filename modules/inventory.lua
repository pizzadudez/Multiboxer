-- addon object
local Multiboxer = unpack(select(2, ...))

-- module object
local Inventory = Multiboxer:NewModule('Inventory', 'AceEvent-3.0')

function Inventory:Enable()
    --
end

function Inventory:StackCount(itemID, stackSize)
    return math.floor(GetItemCount(itemID) / stackSize)
end