local addonName, addonTable = ...

-- addon object (Ace3)
local Multiboxer = LibStub('AceAddon-3.0'):NewAddon(
	'Multiboxer', 'AceEvent-3.0', 'AceHook-3.0')
addonTable[1] = Multiboxer
_G[addonName] = Multiboxer

-- StdUi Lib
local StdUi = LibStub('StdUi')

function Multiboxer:OnInitialize()
	self:RegisterEvent('AUCTION_HOUSE_SHOW')
	self:RegisterEvent('AUCTION_HOUSE_CLOSED')

	self:EnableModule('Scan')

	Multiboxer.auctionTabs = {}
end

function Multiboxer:AUCTION_HOUSE_SHOW()
	self:EnableModule('Tab')

	if not self.onTabClickHooked then
		self:Hook('AuctionFrameTab_OnClick', true)
		self.onTabClickHooked = true
	end
end

function Multiboxer:AUCTION_HOUSE_CLOSED()
	-- TODO: should I disable tab module(s)?
end

-- Handler func for clicking on ah tabs
function Multiboxer:AuctionFrameTab_OnClick(tab)
	AuctionPortraitTexture:Show() -- ??

	-- Hide our own tabs when changing tab
	for i = 1, #self.auctionTabs do
		self.auctionTabs[i]:Hide()
	end
	
	-- If the tab we change to is ours show it
	if tab.multiboxerTab then
		tab.multiboxerTab:Show()
	end
end

function Multiboxer:AddAuctionHouseTab(buttonText, tabTitle, module)
	-- number of auction house tabs
    local n = AuctionFrame.numTabs + 1 

	-- tab
    local auctionTab = StdUi:PanelWithTitle(AuctionFrame, nil, nil, tabTitle, 160)
    auctionTab.titlePanel:SetBackdrop(nil)
    auctionTab:Hide();
	auctionTab:SetAllPoints();
	auctionTab.tabId = n;
	
	-- tab button
    local tabButton = CreateFrame('Button', 'AuctionFrameTab' .. n, AuctionFrame,' AuctionTabTemplate')
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
    tabButton.multiboxerTab = auctionTab -- used to check if the tabButton references one of our tabs
    tabButton.multiboxerTab.module = module -- this tab's module
    auctionTab.tabButton = tabButton

    -- sets new number of tabs and enables the new tab
    PanelTemplates_SetNumTabs(AuctionFrame, n)
	PanelTemplates_EnableTab(AuctionFrame, n)

	-- store our tabs in a list
	tinsert(self.auctionTabs, auctionTab)

    return auctionTab
end
