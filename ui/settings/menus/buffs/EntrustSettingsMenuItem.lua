local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local localization_util = require('cylibs/util/localization_util')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')

local EntrustSettingsMenuItem = setmetatable({}, {__index = MenuItem })
EntrustSettingsMenuItem.__index = EntrustSettingsMenuItem

function EntrustSettingsMenuItem.new(trust, trustSettings, entrustSpells)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Targets', 18),
    }, {}, nil, "Entrust", "Customize indicolures to entrust on party members."), EntrustSettingsMenuItem)

    self.trust = trust
    self.trustSettings = trustSettings
    self.entrustSpells = entrustSpells
    self.dispose_bag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local configItem = MultiPickerConfigItem.new("Entrust", L{}, self.entrustSpells, function(spell)
            return spell:get_localized_name()
        end, "Entrust", nil, function(spell)
            return AssetManager.imageItemForSpell(spell:get_name())
        end)

        local entrustSettingsEditor = FFXIPickerView.withItems(L{ configItem })
        entrustSettingsEditor:setAllowsCursorSelection(true)

        self.dispose_bag:add(entrustSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(cursorIndexPath)
            local spell = self.entrustSpells[cursorIndexPath.row]
            if spell then
                infoView:setDescription("Use when: Ally job is "..localization_util.commas(spell:get_job_names(), "or"))
            end
        end), entrustSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath())

        self.entrustSettingsEditor = entrustSettingsEditor

        return entrustSettingsEditor
    end

    self:reloadSettings()

    return self
end

function EntrustSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function EntrustSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddMenuItem())
    self:setChildMenuItem("Remove", self:getRemoveMenuItem())
    self:setChildMenuItem("Targets", self:getTargetsMenuItem())
end

function EntrustSettingsMenuItem:getAddMenuItem()
    local addSpellMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(menuArgs)
        local allSpells = self.trust:get_job():get_spells(function(spellId)
            local spell = res.spells[spellId]
            return spell and spell.skill == 44 and S{ 'Self' }:equals(S(spell.targets))
        end):map(function(spellId) return Spell.new(res.spells[spellId].en) end)--:sort()

        local configItem = MultiPickerConfigItem.new("Entrust", L{}, allSpells, function(spell)
            return spell:get_localized_name()
        end, "Entrust", nil, function(spell)
            return AssetManager.imageItemForSpell(spell:get_name())
        end)

        local chooseSpellsView = FFXIPickerView.withItems(L{ configItem }, false)
        chooseSpellsView:on_pick_items():addAction(function(_, selectedItems)
            local spell = Spell.new(selectedItems[1]:get_name(), L{ 'Entrust' }, job_util.all_jobs())
            self.entrustSpells:append(spell)

            self.trustSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll use "..spell:get_name().." now!")
        end)
        return chooseSpellsView
    end, "Entrust", "Add indicolures to entrust on party members.")
    return addSpellMenuItem
end

function EntrustSettingsMenuItem:getRemoveMenuItem()
    return MenuItem.action(function()
        local cursorIndexPath = self.entrustSettingsEditor:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            local item = self.entrustSettingsEditor:getDataSource():itemAtIndexPath(cursorIndexPath)
            if item then
                self.entrustSpells:remove(cursorIndexPath.row)
                self.entrustSettingsEditor:getDataSource():removeItem(cursorIndexPath)

                self.trustSettings:saveSettings(true)
            end
        end
    end, "Gambits", "Remove the selected gambit.")
end

function EntrustSettingsMenuItem:getTargetsMenuItem()
    local spellTargetsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(_)
        local cursorIndexPath = self.entrustSettingsEditor:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            local spell = self.entrustSpells[cursorIndexPath.row]

            local configItem = MultiPickerConfigItem.new("Targets", spell:get_job_names(), job_util.all_jobs(), function(jobNameShort)
                return i18n.resource('jobs', 'ens', jobNameShort)
            end, "Targets")

            local chooseSpellsView = FFXIPickerView.withItems(L{ configItem }, true)
            chooseSpellsView:on_pick_items():addAction(function(_, selectedJobs)
                spell:set_job_names(selectedJobs)

                self.trustSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated the jobs to entrust with "..spell:get_name()..".")
            end)
            return chooseSpellsView
        end
        return nil
    end, "Entrust", "Choose which jobs to entrust with this indicolure.")

    return spellTargetsMenuItem
end

return EntrustSettingsMenuItem