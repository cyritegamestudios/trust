local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CursorItem = require('ui/themes/FFXI/CursorItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local EntrustSettingsMenuItem = require('ui/settings/menus/buffs/EntrustSettingsMenuItem')
local GeomancySettingsEditor = require('ui/settings/editors/GeomancySettingsEditor')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('cylibs/modes/ui/modes_view')
local PickerView = require('cylibs/ui/picker/picker_view')

local GeomancySettingsMenuItem = setmetatable({}, {__index = MenuItem })
GeomancySettingsMenuItem.__index = GeomancySettingsMenuItem

function GeomancySettingsMenuItem.new(trustSettings, trust, geomancySettings, entrustSpells, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Geo', 18),
        ButtonItem.default('Indi', 18),
        ButtonItem.default('Entrust', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Geomancy", "Configure indicolure and geocolure settings."), GeomancySettingsMenuItem)

    self.trustSettings = trustSettings
    self.geomancySettings = geomancySettings
    self.entrustSpells = entrustSpells
    self.viewFactory = viewFactory
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function GeomancySettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()

    self.viewFactory = nil
end

function GeomancySettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Geo", self:getGeoMenuItem())
    self:setChildMenuItem("Indi", self:getIndiMenuItem())
    self:setChildMenuItem("Entrust", EntrustSettingsMenuItem.new(self.trustSettings, self.entrustSpells, self.viewFactory))
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function GeomancySettingsMenuItem:getGeoMenuItem()
    local editSpellMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(menuArgs)
        local allSpells = spell_util.get_spells(function(spell)
            return spell.skill == 44 and S{ 'Party', 'Enemy'}:intersection(S(spell.targets)):length() > 0
        end):map(function(spell) return spell.en end)

        local chooseSpellsView = self.viewFactory(PickerView.withItems(allSpells, L{ self.geomancySettings.Geo:get_spell().en }, false))
        chooseSpellsView:setTitle("Choose a geo spell.")
        chooseSpellsView:setShouldRequestFocus(true)
        chooseSpellsView:on_pick_items():addAction(function(_, selectedItems)
            local spell = Spell.new(selectedItems[1]:getText(), L{}, L{})
            if spell then
                if S(spell:get_spell().targets):intersection(S{ 'Enemy' }):length() > 0 then
                    spell.target = 'bt'
                else
                    spell.target = 'me'
                end
                self.geomancySettings.Geo = spell

                self.trustSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll use "..spell:get_name().." now!")
            end
        end)
        return chooseSpellsView
    end, "Geocolures", "Customize geocolures to use on party members and enemies.")

    local spellTargetsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(menuArgs)
        local spell = self.geomancySettings.Geo

        local chooseSpellsView = self.viewFactory(PickerView.withItems(spell:get_valid_targets(), L{ self.geomancySettings.Geo.target or "me" }, false))
        chooseSpellsView:setTitle("Choose a target for "..self.geomancySettings.Geo:get_name()..".")
        chooseSpellsView:setShouldRequestFocus(true)
        chooseSpellsView:on_pick_items():addAction(function(_, selectedItems)
            local target = selectedItems[1]:getText()
            if target then
                self.geomancySettings.Geo.target = target

                self.trustSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll target "..target.." now!")
            end
        end)
        return chooseSpellsView
    end, "Geocolures", "Choose the target of the geocolure.")

    local geocolureMenuItem = MenuItem.new(L{
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Targets', 18)
    }, L{
        Edit = editSpellMenuItem,
        Targets = spellTargetsMenuItem,
    }, function(_)
        local geomancyView = self.viewFactory(GeomancySettingsEditor.new(self.trustSettings, L{ self.geomancySettings.Geo }, L{}))
        geomancyView:setTitle("Geocolures spells to use.")
        geomancyView:setShouldRequestFocus(true)
        return geomancyView
    end, "Geocolures", "Customize geocolures to use on party members and enemies.")

    return geocolureMenuItem
end

function GeomancySettingsMenuItem:getIndiMenuItem()
    local indicolureMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(menuArgs)
        local allSpells = spell_util.get_spells(function(spell)
            return spell.skill == 44 and S{ 'Self' }:equals(S(spell.targets))
        end):map(function(spell) return spell.en end)

        local chooseSpellsView = self.viewFactory(PickerView.withItems(allSpells, L{ self.geomancySettings.Indi:get_spell().en }, false))
        chooseSpellsView:setTitle("Choose an indi spell.")
        chooseSpellsView:setAllowsMultipleSelection(false)
        chooseSpellsView:on_pick_items():addAction(function(_, selectedItems)
            local spell = Spell.new(selectedItems[1]:getText(), L{}, L{}, 'me')
            if spell then
                self.geomancySettings.Indi = spell

                self.trustSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll use "..spell:get_name().." now!")
            end
        end)
        return chooseSpellsView
    end, "Indicolures", "Customize indicolures to use on party members and enemies.")
    return indicolureMenuItem
end

function GeomancySettingsMenuItem:getModesMenuItem()
    local geomancyModesMenuItem = MenuItem.new(L{
        --ButtonItem.default('Save', 18),
    }, L{}, function(_)
        local modesView = self.viewFactory(ModesView.new(L{'AutoGeoMode', 'AutoIndiMode', 'AutoEntrustMode'}))
        modesView:setShouldRequestFocus(true)
        modesView:setTitle("Set modes for geocolures and indicolures.")
        return modesView
    end, "Modes", "Set modes for geocolures and indicolures.")
    return geomancyModesMenuItem
end

return GeomancySettingsMenuItem