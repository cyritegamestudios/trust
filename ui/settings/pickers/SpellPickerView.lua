local Buff = require('cylibs/battle/spells/buff')
local Debuff = require('cylibs/battle/spells/debuff')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local PickerView = require('cylibs/ui/picker/picker_view')
local Spell = require('cylibs/battle/spell')
local spell_util = require('cylibs/util/spell_util')

local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local SpellPickerView = setmetatable({}, {__index = FFXIPickerView })
SpellPickerView.__index = SpellPickerView

function SpellPickerView.new(trustSettings, spells, allSpells, defaultJobNames, override, sort)
    local selectedSpells = L{}
    if override then
        selectedSpells = spells:map(function(spell) return spell:get_name() end)
    end
    local self = setmetatable(FFXIPickerView.withItems(allSpells, selectedSpells, true), SpellPickerView)

    self.trustSettings = trustSettings
    self.spells = spells
    self.defaultJobNames = defaultJobNames
    self.override = override
    self.sort = sort

    self:setScrollEnabled(true)

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end

    return self
end

function SpellPickerView:onSelectMenuItemAtIndexPath(textItem, _)
    if textItem:getText() == 'Confirm' then
        local selectedIndexPaths = self:getDelegate():getSelectedIndexPaths()
        if selectedIndexPaths:length() > 0 then
            if self.override then
                self.spells:clear()
            end
            for selectedIndexPath in selectedIndexPaths:it() do
                local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
                if item then
                    local spell = res.spells:with('en', item:getText())
                    if spell then
                        if spell.status and not L{ 40, 41, 42 }:contains(spell.skill) then
                            if spell.targets:contains('Enemy') then
                                self.spells:append(Debuff.new(spell_util.base_spell_name(item:getText())))
                            else
                                self.spells:append(Buff.new(spell_util.base_spell_name(item:getText()), L{}, self.defaultJobNames))
                            end
                        else
                            self.spells:append(Spell.new(item:getText(), L{}, L{}))
                        end
                    end
                end
            end
            if not self.override then
                self:getDelegate():deselectAllItems()
            end
            if self.sort ~= nil then
                self.sort(self.spells)
            else
                self.spells:sort(function(spell1, spell2)
                    return spell1:get_name() < spell2:get_name()
                end)
            end
            self.trustSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my spells!")
        end
    elseif textItem:getText() == 'Clear' then
        self:getDelegate():deselectAllItems()
    end
end

return SpellPickerView