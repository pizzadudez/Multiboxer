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

    -- DELETEME
    self:TestScanButton()
end

-- Tests Scan functionality
function Tab:TestScanButton()
    local auctionTab = self.auctionTab
    local btn = StdUi:Button(auctionTab, 60, 30, 'SCAN TEST')
    btn:SetPoint('TOPLEFT', auctionTab, 'TOPLEFT', 20, -20)
    btn:SetScript('OnClick', function()
	    Scan.scanList = {152505, 152509, 152507, 152510}
	    Scan:ScanList()
    end)
end

