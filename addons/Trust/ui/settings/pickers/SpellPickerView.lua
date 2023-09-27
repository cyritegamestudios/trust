local Buff = require('cylibs/battle/spells/buff')
local PickerView = require('cylibs/ui/picker/picker_view')
local Spell = require('cylibs/battle/spell')
local spell_util = require('cylibs/util/spell_util')


local SpellPickerView = setmetatable({}, {__index = PickerView })
SpellPickerView.__index = SpellPickerView

function SpellPickerView.new(trustSettings, spells, allSpells)
    local self = setmetatable(PickerView.withItems(allSpells, L{}, true), SpellPickerView)

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
                    local spell = res.spells:with('name', item:getText())
                    if spell then
                        if spell.status then
                            self.spells:append(Buff.new(spell_util.base_spell_name(item:getText())))
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