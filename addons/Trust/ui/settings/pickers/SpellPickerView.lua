local BackgroundView = require('cylibs/ui/views/background/background_view')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local Frame = require('cylibs/ui/views/frame')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local PickerItem = require('cylibs/ui/picker/picker_item')
local PickerView = require('cylibs/ui/picker/picker_view')
local Spell = require('cylibs/battle/spell')
local spell_util = require('cylibs/util/spell_util')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local SpellPickerView = setmetatable({}, {__index = PickerView })
SpellPickerView.__index = SpellPickerView

function SpellPickerView.new(trustSettings, spells)
    local allBuffs = spell_util.get_spells(function(spell)
        return spell.status ~= nil and S{'Self', 'Party'}:intersection(S(spell.targets)):length() > 0
    end):map(function(spell) return spell.name end)

    local self = setmetatable(PickerView.withItems(allBuffs, L{}, true), SpellPickerView)

    self.trustSettings = trustSettings
    self.spells = spells

    return self
end

function SpellPickerView:onSelectMenuItemAtIndexPath(textItem, _)
    if textItem:getText() == 'Confirm' then
        local selectedIndexPaths = self:getDelegate():getSelectedIndexPaths()
        if selectedIndexPaths:length() > 0 then
            for selectedIndexPath in selectedIndexPaths:it() do
                local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
                if item then
                    self.spells:append(Spell.new(item:getText(), L{}, L{}))
                end
            end
            self:getDelegate():deselectAllItems()
            self.trustSettings:saveSettings(false)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my buffs!")
        end
    elseif textItem:getText() == 'Clear' then
        self:getDelegate():deselectAllItems()
    end
end

return SpellPickerView