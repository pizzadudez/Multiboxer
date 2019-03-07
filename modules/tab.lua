-- addon object
local Multiboxer = unpack(select(2, ...))
-- ui lib
local StdUi = LibStub('StdUi')
-- Scan module
Scan = Multiboxer:GetModule('Scan')

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
	    Scan.scanList = {"Riverbud", "Siren's Pollen", "Akunda's Bite"}
	    Scan:ScanList()
    end)
end

