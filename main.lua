local addonName, addonTable = ...

-- addon object (Ace3)
local Multiboxer = LibStub('AceAddon-3.0'):NewAddon(
	'Multiboxer', 'AceEvent-3.0', 'AceHook-3.0')
addonTable[1] = Multiboxer
_G[addonName] = Multiboxer

-- StdUi Lib
local StdUi = LibStub('StdUi')

function Multiboxer:OnInitialize()
	self:RegisterEvent('PLAYER_STARTED_MOVING')

	self:EnableModule('Scan')
end

function Multiboxer:PLAYER_STARTED_MOVING()
	print('test1')
end






