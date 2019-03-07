-- addon object
local Multiboxer = unpack(select(2, ...))
-- ui lib
local StdUi = LibStub('StdUi')

-- module object
local Tab = Multiboxer:NewModule('Tab', 'AceEvent-3.0')

function Tab:Enable()
    self:AddAuctionHouseTab('Multiboxer', 'Multiboxer Auctions')
end

function Tab:AddAuctionHouseTab(buttonText, tabTitle)
    if self.tabAdded then return end -- already added tab to ah frame

    local n = AuctionFrame.numTabs + 1

    local auctionTab = StdUi:PanelWithTitle(AuctionFrame, nil, nil, tabTitle, 160)
    auctionTab.titlePanel:SetBackdrop(nil)
    
    local tabButton = CreateFrame('Button', 'AuctionFrameTab .. n', AuctionFrame,' AuctionTabTemplate')
    StdUi:StripTextures(tabButton)
	tabButton.backdrop = StdUi:Panel(tabButton)
	tabButton.backdrop:SetFrameLevel(tabButton:GetFrameLevel() - 1)
    StdUi:GlueAcross(tabButton.backdrop, tabButton, 10, -3, -10, 3)
    
    tabButton:Hide()
    tabButton:SetID(n)
    tabButton:SetText(buttonText)
    tabButton:SetNormalFontObject(GameFontHighlightSmall)
    tabButton:SetPoint('LEFT', _G['AuctionFrameTab' .. n - 1], 'RIGHT', -8, 0)
    tabButton:Show()
    -- reference the actual tab
    tabButton.multiboxerTab = auctionTab
    tabButton.multiboxerTab.module = self

    auctionTab.tabButton = tabButton

    -- ??
    PanelTemplates_SetNumTabs(AuctionFrame, n)
	PanelTemplates_EnableTab(AuctionFrame, n)

    return auctionTab
end