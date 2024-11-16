local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local EntrustSettingsMenuItem = require('ui/settings/menus/buffs/EntrustSettingsMenuItem')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')

local GeomancySettingsMenuItem = setmetatable({}, {__index = MenuItem })
GeomancySettingsMenuItem.__index = GeomancySettingsMenuItem

function GeomancySettingsMenuItem.new(trust, trustSettings, trustModeSettings, geomancySettings, entrustSpells)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Geo', 18),
        ButtonItem.default('Indi', 18),
        ButtonItem.default('Entrust', 18),
        ButtonItem.default('Modes', 18),
    }, {}, function(_, _)
        --local geomancySettings = trustSettings:getSettings()[trustSettingsMode.value]

        local geomancyView = FFXIPickerView.withItems(L{ geomancySettings.Geo:get_spell().en, geomancySettings.Indi:get_spell().en }:extend(entrustSpells:map(function(spell) return spell:description() end)), L{}, false, nil, nil, FFXIClassicStyle.WindowSize.Editor.ConfigEditor, true)
        geomancyView:setShouldRequestFocus(false)
        return geomancyView
    end, "Geomancy", "Configure indicolure and geocolure settings."), GeomancySettingsMenuItem)

    self.trust = trust
    self.trustSettings = trustSettings
    self.trustModeSettings = trustModeSettings
    self.geomancySettings = geomancySettings
    self.entrustSpells = entrustSpells
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function GeomancySettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function GeomancySettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Geo", self:getGeoMenuItem())
    self:setChildMenuItem("Indi", self:getIndiMenuItem())
    self:setChildMenuItem("Entrust", EntrustSettingsMenuItem.new(self.trust, self.trustSettings, self.entrustSpells))
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function GeomancySettingsMenuItem:getGeoMenuItem()
    local editSpellMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {}, function(_, _)
        local allSpells = self.trust:get_job():get_spells(function(spellId)
            local spell = res.spells[spellId]
            return spell and spell.skill == 44 and S{ 'Party', 'Enemy'}:intersection(S(spell.targets)):length() > 0
        end):map(function(spellId) return res.spells[spellId].en end):sort()

        local imageItemForText = function(text)
            return AssetManager.imageItemForSpell(text)
        end

        local chooseSpellsView = FFXIPickerView.withItems(allSpells, L{ self.geomancySettings.Geo:get_spell().en }, false, nil, imageItemForText)
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
    }, {}, function(menuArgs)
        local spell = self.geomancySettings.Geo

        local chooseSpellsView = FFXIPickerView.withItems(spell:get_valid_targets(), L{ self.geomancySettings.Geo.target or "me" }, false)
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
    }, {
        Edit = editSpellMenuItem,
        Targets = spellTargetsMenuItem,
    }, nil, "Geocolures", "Customize geocolures to use on party members and enemies.")

    return geocolureMenuItem
end

function GeomancySettingsMenuItem:getIndiMenuItem()
    local indicolureMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {}, function(menuArgs)
        local allSpells = self.trust:get_job():get_spells(function(spellId)
            local spell = res.spells[spellId]
            return spell and spell.skill == 44 and S{ 'Self' }:equals(S(spell.targets))
        end):map(function(spellId) return res.spells[spellId].en end):sort()

        local imageItemForText = function(text)
            return AssetManager.imageItemForSpell(text)
        end

        local chooseSpellsView = FFXIPickerView.withItems(allSpells, L{ self.geomancySettings.Indi:get_spell().en }, false, nil, imageItemForText)
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
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for geocolures and indicolures.",
            L{'AutoGeoMode', 'AutoIndiMode', 'AutoEntrustMode'})
end

return GeomancySettingsMenuItem