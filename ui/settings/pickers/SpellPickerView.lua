local Buff = require('cylibs/battle/spells/buff')
local Debuff = require('cylibs/battle/spells/debuff')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local PickerView = require('cylibs/ui/picker/picker_view')
local Spell = require('cylibs/battle/spell')
local spell_util = require('cylibs/util/spell_util')


local SpellPickerView = setmetatable({}, {__index = PickerView })
SpellPickerView.__index = SpellPickerView

function SpellPickerView.new(trustSettings, spells, allSpells, defaultJobNames)
    local cursorImageItem = ImageItem.new(windower.addon_path..'assets/backgrounds/menu_selection_bg.png', 37, 24)

    local self = setmetatable(PickerView.withItems(allSpells, L{}, true, cursorImageItem), SpellPickerView)

    self.trustSettings = trustSettings
    self.spells = spells
    self.defaultJobNames = defaultJobNames

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end

    return self
end

function SpellPickerView:onSelectMenuItemAtIndexPath(textItem, _)
    if textItem:getText() == 'Confirm' then
        local selectedIndexPaths = self:getDelegate():getSelectedIndexPaths()
        if selectedIndexPaths:length() > 0 then
            for selectedIndexPath in selectedIndexPaths:it() do
                local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
                if item then
                    local spell = res.spells:with('name', item:getText())
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
            self:getDelegate():deselectAllItems()
            self.trustSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my spells!")
        end
    elseif textItem:getText() == 'Clear' then
        self:getDelegate():deselectAllItems()
    end
end

return SpellPickerView