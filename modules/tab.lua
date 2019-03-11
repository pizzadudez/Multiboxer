-- addon object
local Multiboxer = unpack(select(2, ...))
-- ui lib
local StdUi = LibStub('StdUi')
-- Scan module
local Scan = Multiboxer:GetModule('Scan')

-- module object
local Tab = Multiboxer:NewModule('Tab', 'AceEvent-3.0')


function Tab:Enable()
    -- never redraw the tab, show/hide the frame instead!
    if self.tabAdded then return end

    self.auctionTab = Multiboxer:AddAuctionHouseTab('Multiboxer', 'Multiboxer Auctions', self)
    self.tabAdded = true 

    Scan.scanList = {152505,152510,152509,152507,152511,152506,152508} 
    self:DrawScanList()
    self:ScanButton()
end

function Tab:DrawScanList()
    
    local auctionTab = self.auctionTab
    local scanListFrame = StdUi:Frame(auctionTab, 200, 60)
	scanListFrame:SetPoint('TOPLEFT', auctionTab, 'TOPLEFT', 50, -60)

	scanListFrame.items = scanListFrame.items or {}
	scanListFrame.items[0] = scanListFrame
	for i, itemID in ipairs({152505,152510,152509,152507,152511,152506,152508}) do

        local item = StdUi:Checkbox(scanListFrame, 24, 24)
        scanListFrame.items[i] = item
        item:SetPoint('LEFT', scanListFrame.items[i-1], 'RIGHT', 4, 0)
        item:SetChecked(true)
        item.OnValueChanged = function(self, state, value)
            Tab:CreateScanList()
		end
		
		local textureID = GetItemTextureID(itemID)
		item.texture = StdUi:Texture(item, 24, 24, textureID)
		item.texture:SetPoint("BOTTOM", item, "TOP", 0, 0)
	end
    scanListFrame.items[1]:SetPoint('TOPLEFT', scanListFrame, 'TOPLEFT', 3, -20)

    auctionTab.scanListFrame = scanListFrame
end

function Tab:CreateScanList()
    Scan.scanList = {}

    local scanListFrame = self.auctionTab.scanListFrame
    for i, itemID in ipairs({152505,152510,152509,152507,152511,152506,152508}) do
        if scanListFrame.items[i].isChecked then
            tinsert(Scan.scanList, itemID)
        end
    end

    print(table.concat(Scan.scanList,', '))
end

-- Tests Scan functionality
function Tab:ScanButton()
    local auctionTab = self.auctionTab
    local btn = StdUi:Button(auctionTab, 100, 40, 'Scan List')
    btn:SetPoint('TOPLEFT', auctionTab, 'TOPLEFT', 20, -200)
    btn:SetScript('OnClick', function()
	    Scan:ScanList()
    end)
end

