local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CursorItem = require('ui/themes/FFXI/CursorItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local GeomancySettingsEditor = require('ui/settings/editors/GeomancySettingsEditor')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local SpellPickerView = require('ui/settings/pickers/SpellPickerView')

local EntrustSettingsMenuItem = setmetatable({}, {__index = MenuItem })
EntrustSettingsMenuItem.__index = EntrustSettingsMenuItem

function EntrustSettingsMenuItem.new(trustSettings, entrustSpells)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Targets', 18),
    }, {}, function(_)
        local geomancyView = GeomancySettingsEditor.new(trustSettings, entrustSpells, L{})
        geomancyView:setTitle("Indicolure spells to entrust on party members.")
        geomancyView:setShouldRequestFocus(true)
        return geomancyView
    end, "Entrust", "Customize indicolures to entrust on party members."), EntrustSettingsMenuItem)

    self.trustSettings = trustSettings
    self.entrustSpells = entrustSpells
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function EntrustSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()

    self.viewFactory = nil
end

function EntrustSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddMenuItem())
    --self:setChildMenuItem("Remove", self:getRemoveMenuItem())
    self:setChildMenuItem("Targets", self:getTargetsMenuItem())
end

function EntrustSettingsMenuItem:getAddMenuItem()
    local addSpellMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(menuArgs)
        local allSpells = spell_util.get_spells(function(spell)
            return spell.skill == 44 and S{ 'Self' }:equals(S(spell.targets))
        end):map(function(spell) return spell.en end)

        local chooseSpellsView = FFXIPickerView.withItems(allSpells, self.entrustSpells:map(function(spell) return spell.en  end), false)
        chooseSpellsView:setTitle("Choose an indi spell to entrust.")
        chooseSpellsView:setShouldRequestFocus(true)
        chooseSpellsView:on_pick_items():addAction(function(_, selectedItems)
            local spell = Spell.new(selectedItems[1]:getText(), L{ 'Entrust' }, job_util.all_jobs())
            self.entrustSpells:append(spell)

            self.trustSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll use "..spell:get_name().." now!")
        end)
        return chooseSpellsView
    end, "Entrust", "Add indicolures to entrust on party members.")
    return addSpellMenuItem
end

function EntrustSettingsMenuItem:getTargetsMenuItem()
    local spellTargetsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(menuArgs)
        local spell = menuArgs['spell']

        local chooseSpellsView = FFXIPickerView.withItems(job_util.all_jobs(), spell:get_job_names() or L{}, true)
        chooseSpellsView:setTitle("Choose jobs to target for "..spell:get_name()..".")
        chooseSpellsView:setShouldRequestFocus(true)
        chooseSpellsView:on_pick_items():addAction(function(_, selectedItems)
            spell:set_job_names(selectedItems:map(function(item) return item:getText()  end))

            self.trustSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated the jobs to entrust with "..spell:get_name()..".")
        end)
        return chooseSpellsView
    end, "Entrust", "Choose which jobs to entrust with this indicolure.")

    return spellTargetsMenuItem
end

return EntrustSettingsMenuItem