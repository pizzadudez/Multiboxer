-- addon object
local Multiboxer = unpack(select(2, ...))
-- ui lib
local StdUi = LibStub('StdUi')

-- module object
local Tab = Multiboxer:GetModule('Tab')

-- change this file to Multiboxer:Method

Tab.ScrollBarEvents = {
	-- UpButtonOnClick = function(self)
	-- 	local scrollBar = self.scrollBar;
	-- 	local scrollStep = scrollBar.ScrollFrame.scrollStep or (scrollBar.ScrollFrame:GetHeight() / 2);
	-- 	scrollBar:SetValue(scrollBar:GetValue() - scrollStep);
	-- end,
	-- DownButtonOnClick = function(self)
	-- 	local scrollBar = self.scrollBar;
	-- 	local scrollStep = scrollBar.ScrollFrame.scrollStep or (scrollBar.ScrollFrame:GetHeight() / 2);
	-- 	scrollBar:SetValue(scrollBar:GetValue() + scrollStep);
	-- end,
	OnValueChanged = function(self, value)
		self.ScrollFrame:SetVerticalScroll(value);
	end
};

Tab.ScrollFrameEvents = {
	OnLoad = function(self)
		local scrollbar = self.ScrollBar;

		scrollbar:SetMinMaxValues(0, 0);
		scrollbar:SetValue(0);
		self.offset = 0;

		--local scrollDownButton = scrollbar.ScrollDownButton;
		--local scrollUpButton = scrollbar.ScrollUpButton;

		--scrollDownButton:Disable();
		--scrollUpButton:Disable();

		if self.scrollBarHideable then
			scrollbar:Hide();
			--scrollDownButton:Hide();
			--scrollUpButton:Hide();
		else
			--scrollDownButton:Disable();
			--scrollUpButton:Disable();
			--scrollDownButton:Show();
			--scrollUpButton:Show();
		end

		if self.noScrollThumb then
			scrollbar.ThumbTexture:Hide();
		end
	end,

	OnMouseWheel = function(self, value, scrollBar)
		scrollBar = scrollBar or self.ScrollBar;
		local scrollStep = scrollBar.scrollStep or scrollBar:GetHeight() / 2;

		if value > 0 then
			scrollBar:SetValue(scrollBar:GetValue() - scrollStep);
		else
			scrollBar:SetValue(scrollBar:GetValue() + scrollStep);
		end
	end,

	OnScrollRangeChanged = function(self, xrange, yrange)
		local scrollbar = self.ScrollBar;
		if ( not yrange ) then
			yrange = self:GetVerticalScrollRange();
		end

		-- Accounting for very small ranges
		yrange = math.floor(yrange);

		local value = math.min(scrollbar:GetValue(), yrange);
		scrollbar:SetMinMaxValues(0, yrange);
		scrollbar:SetValue(value);

		--local scrollDownButton = scrollbar.ScrollDownButton;
		--local scrollUpButton = scrollbar.ScrollUpButton;
		local thumbTexture = scrollbar.ThumbTexture;

		if ( yrange == 0 ) then
			if ( self.scrollBarHideable ) then
				scrollbar:Hide();
				--scrollDownButton:Hide();
				--scrollUpButton:Hide();
				thumbTexture:Hide();
			else
				--scrollDownButton:Disable();
				--scrollUpButton:Disable();
				--scrollDownButton:Show();
				--scrollUpButton:Show();
				if ( not self.noScrollThumb ) then
					thumbTexture:Show();
				end
			end
		else
			--scrollDownButton:Show();
			--scrollUpButton:Show();
			scrollbar:Show();
			if ( not self.noScrollThumb ) then
				thumbTexture:Show();
			end
			-- The 0.005 is to account for precision errors
			if ( yrange - value > 0.005 ) then
				--scrollDownButton:Enable();
			else
				--scrollDownButton:Disable();
			end
		end
	end,

	OnVerticalScroll = function(self, offset)
		local scrollBar = self.ScrollBar;
		scrollBar:SetValue(offset);

		--local min, max = scrollBar:GetMinMaxValues();
		--scrollBar.ScrollUpButton:SetEnabled(offset ~= 0);
		--scrollBar.ScrollDownButton:SetEnabled((scrollBar:GetValue() - max) ~= 0);
	end
}

function Tab:ScrollFrame(parent, width, height, scrollChild)
	local panel = StdUi:Panel(parent, width, height);
	local scrollBarWidth = 6;

	local scrollFrame = CreateFrame('ScrollFrame', nil, panel);
	scrollFrame:SetScript('OnScrollRangeChanged', self.ScrollFrameEvents.OnScrollRangeChanged);
	scrollFrame:SetScript('OnVerticalScroll', self.ScrollFrameEvents.OnVerticalScroll);
	scrollFrame:SetScript('OnMouseWheel', self.ScrollFrameEvents.OnMouseWheel);

	local scrollBar = self:ScrollBar(panel, scrollBarWidth);
	scrollBar:SetScript('OnValueChanged', self.ScrollBarEvents.OnValueChanged);
	--scrollBar.ScrollDownButton:SetScript('OnClick', StdUi.ScrollBarEvents.DownButtonOnClick);
	--scrollBar.ScrollUpButton:SetScript('OnClick', StdUi.ScrollBarEvents.UpButtonOnClick);

	scrollFrame.ScrollBar = scrollBar;
	scrollBar.ScrollFrame = scrollFrame;

	--scrollFrame:SetScript('OnLoad', StdUi.ScrollFrameEvents.OnLoad);-- LOL, no wonder it wasnt working
	Tab.ScrollFrameEvents.OnLoad(scrollFrame);

	scrollFrame.panel = panel;
	scrollFrame:ClearAllPoints();
	scrollFrame:SetSize(width - scrollBarWidth - 1, height); -- scrollbar width and margins
	StdUi:GlueAcross(scrollFrame, panel, 0, 0, -scrollBarWidth, 0, 0);

	scrollBar.panel:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', 0, 0);
	scrollBar.panel:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', 0, 0);

	if not scrollChild then
		scrollChild = CreateFrame('Frame', nil, scrollFrame);
		scrollChild:SetWidth(scrollFrame:GetWidth());
		scrollChild:SetHeight(scrollFrame:GetHeight());
	else
		scrollChild:SetParent(scrollFrame);
	end

	scrollFrame:SetScrollChild(scrollChild);
	scrollFrame:EnableMouse(true);
	scrollFrame:SetClampedToScreen(true);
	scrollFrame:SetClipsChildren(true);

	scrollChild:SetPoint('RIGHT', scrollFrame, 'RIGHT', 0, 0);

	scrollFrame.scrollChild = scrollChild;

	panel.scrollFrame = scrollFrame;
	panel.scrollChild = scrollChild;
	panel.scrollBar = scrollBar;

	return panel, scrollFrame, scrollChild, scrollBar;
end


function Tab:ScrollBar(parent, width, height, horizontal)

	local panel = StdUi:Panel(parent, width, height);
	local scrollBar = StdUi:Slider(parent, width, height, 0, not horizontal);

	--scrollBar.ScrollDownButton = StdUi:SliderButton(parent, width, 6, 'DOWN');
	--scrollBar.ScrollUpButton = StdUi:SliderButton(parent, width, 6, 'UP');
	scrollBar.panel = panel;

	--scrollBar.ScrollUpButton.scrollBar = scrollBar;
	--scrollBar.ScrollDownButton.scrollBar = scrollBar;

	if horizontal then
		--@TODO do this
		--scrollBar.ScrollUpButton:SetPoint('TOPLEFT', panel, 'TOPLEFT', 0, 0);
		--scrollBar.ScrollUpButton:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', 0, 0);
		--
		--scrollBar.ScrollDownButton:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', 0, 0);
		--scrollBar.ScrollDownButton:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', 0, 0);
		--
		--scrollBar:SetPoint('TOPLEFT', scrollBar.ScrollUpButton, 'TOPLEFT', 0, 1);
		--scrollBar:SetPoint('TOPRIGHT', scrollBar.ScrollUpButton, 'TOPRIGHT', 0, 1);
		--scrollBar:SetPoint('BOTTOMLEFT', scrollBar.ScrollDownButton, 'BOTTOMLEFT', 0, -1);
		--scrollBar:SetPoint('BOTTOMRIGHT', scrollBar.ScrollDownButton, 'BOTTOMRIGHT', 0, -1);
	else
		--scrollBar.ScrollUpButton:SetPoint('TOPLEFT', panel, 'TOPLEFT', 0, 0);
		--scrollBar.ScrollUpButton:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', 0, 0);

		--scrollBar.ScrollDownButton:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', 0, 0);
		--scrollBar.ScrollDownButton:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', 0, 0);

		scrollBar:SetPoint('TOPLEFT', scrollBar.panel, 'BOTTOMLEFT', 0, 0);
		scrollBar:SetPoint('TOPRIGHT', scrollBar.panel, 'BOTTOMRIGHT', 0, 0);
		scrollBar:SetPoint('BOTTOMLEFT', scrollBar.panel, 'TOPLEFT', 0, 0);
		scrollBar:SetPoint('BOTTOMRIGHT', scrollBar.panel, 'TOPRIGHT', 0, 0);
	end

	return scrollBar, panel;
end

function Tab:ObjectList(parent, itemsTable, create, update, data, padding, oX, oY)
	oX = oX or 1;
	oY = oY or -1;
	padding = padding or 0;

	if not itemsTable then
		itemsTable = {};
	end

	for i = 1, #itemsTable do
		itemsTable[i]:Hide();
	end

	local totalHeight = -oY;

	for i = 1, #data do
		local itemFrame = itemsTable[i];

		if not itemFrame then
			if type(create) == 'string' then
				-- create a widget and anchor it to
				itemsTable[i] = self[create](self, parent);
			else
				itemsTable[i] = create(parent, data[i], i);
			end
			itemFrame = itemsTable[i];
		end

		-- If you create simple widget you need to handle anchoring yourself
		update(parent, itemFrame, data[i], i);
		itemFrame:Show();

		totalHeight = totalHeight + itemFrame:GetHeight();
		if i == 1 then
			-- glue first item to offset
			StdUi:GlueTop(itemFrame, parent, oX, oY, 'LEFT');
		else
			-- glue next items to previous
			StdUi:GlueBelow(itemFrame, itemsTable[i - 1], 0, -padding);
			totalHeight = totalHeight + padding;
		end
	end

	return itemsTable, totalHeight;
end