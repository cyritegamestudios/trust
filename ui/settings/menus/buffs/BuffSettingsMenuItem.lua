local BuffSettingsEditor = require('ui/settings/BuffSettingsEditor')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local SpellPickerView = require('ui/settings/pickers/SpellPickerView')
local SpellSettingsEditor = require('ui/settings/SpellSettingsEditor')

local BuffSettingsMenuItem = setmetatable({}, {__index = MenuItem })
BuffSettingsMenuItem.__index = BuffSettingsMenuItem

function BuffSettingsMenuItem.new(trustSettings, trustSettingsMode, settingsPrefix, settingsKey, targets, jobNameShort, descriptionText, showJobs)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Conditions', 18),
    }, {}, nil, "Buffs", descriptionText), BuffSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.settingsKey = settingsKey
    self.jobNameShort = jobNameShort
    self.showJobs = showJobs
    self.dispose_bag = DisposeBag.new()

    self.contentViewConstructor = function(menuArgs, infoView)
        local buffs
        if settingsPrefix then
            buffs = T(trustSettings:getSettings())[trustSettingsMode.value][settingsPrefix][settingsKey]
        else
            buffs = T(trustSettings:getSettings())[trustSettingsMode.value][settingsKey]
        end
        self.buffs = buffs

        local buffSettingsView = BuffSettingsEditor.new(trustSettings, buffs, targets)
        buffSettingsView:setShouldRequestFocus(true)

        self.dispose_bag:add(buffSettingsView:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            local item = buffSettingsView:getDataSource():itemAtIndexPath(indexPath)
            if item and not item:getTextItem():getEnabled() then
                infoView:setDescription("Unavailable on current job.")
            else
                local buff = buffs[indexPath.row]
                if buff then
                    local description = buff:get_conditions():map(function(condition)
                        return condition:tostring()
                    end)
                    infoView:setDescription("Use when: "..localization_util.commas(description))
                end
            end
        end, buffSettingsView:getDelegate():didMoveCursorToItemAtIndexPath()))

        return buffSettingsView
    end

    self:reloadSettings()

    return self
end

function BuffSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function BuffSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddBuffMenuItem())
    self:setChildMenuItem("Edit", self:getEditBuffMenuItem())
    self:setChildMenuItem("Conditions", self:getConditionsMenuItem())
end

function BuffSettingsMenuItem:getAddBuffMenuItem()
    local addBuffMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
    function(args)
            local spellSettings = args['spells']
            local targets = args['targets']
            local defaultJobNames = L{}
            if targets:contains('Party') then
                defaultJobNames = job_util.all_jobs()
            end

            local jobId = res.jobs:with('ens', self.jobNameShort).id
            local allBuffs = spell_util.get_spells(function(spell)
                local status = buff_util.buff_for_spell(spell.id)
                return spell.levels[jobId] ~= nil and status ~= nil and not buff_util.is_debuff(status.id) and spell.skill ~= 44 and targets:intersection(S(spell.targets)):length() > 0
            end):map(function(spell) return spell.en end):sort()

            local chooseSpellsView = SpellPickerView.new(self.trustSettings, spellSettings, allBuffs, defaultJobNames, false)
            chooseSpellsView:setTitle("Choose buffs to add.")
            chooseSpellsView:setScrollEnabled(true)
        return chooseSpellsView
    end, "Buffs", "Add a new buff.")
    return addBuffMenuItem
end

function BuffSettingsMenuItem:getEditBuffMenuItem()
    local editBuffMenuItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
        ButtonItem.default('Clear All', 18),
    }, {},
    function(args)
        local spell = args['spell']
        if spell then
            local editSpellView = SpellSettingsEditor.new(self.trustSettings, spell, not self.showJobs)
            editSpellView:setTitle("Edit buff.")
            editSpellView:setShouldRequestFocus(true)
            return editSpellView
        end
        return nil
    end, "Buffs", "Edit buff settings.", false, function()
                return self.buffs and self.buffs:length() > 0
            end)
    return editBuffMenuItem
end

function BuffSettingsMenuItem:getConditionsMenuItem()
    return ConditionSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, nil, nil, function()
        return self.buffs and self.buffs:length() > 0
    end)
end

return BuffSettingsMenuItem