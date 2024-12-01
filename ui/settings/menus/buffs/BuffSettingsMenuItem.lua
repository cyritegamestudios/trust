local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local BuffSettingsEditor = require('ui/settings/BuffSettingsEditor')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local JobAbilityPickerItemMapper = require('ui/settings/pickers/mappers/JobAbilityPickerItemMapper')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local SpellPickerItemMapper = require('ui/settings/pickers/mappers/SpellPickerItemMapper')
local SpellSettingsEditor = require('ui/settings/SpellSettingsEditor')

local BuffSettingsMenuItem = setmetatable({}, {__index = MenuItem })
BuffSettingsMenuItem.__index = BuffSettingsMenuItem

function BuffSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, settingsPrefix, settingsKey, targets, jobNameShort, descriptionText, showJobs)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Abilities', 18),
        ButtonItem.default('Conditions', 18),
        ButtonItem.default('Toggle', 18),
        ButtonItem.default('Reset', 18),
    }, {}, nil, "Buffs", descriptionText), BuffSettingsMenuItem)

    self.trust = trust
    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.settingsKey = settingsKey
    self.targets = targets
    self.jobNameShort = jobNameShort
    self.showJobs = showJobs
    self.dispose_bag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local buffs
        if settingsPrefix then
            buffs = T(trustSettings:getSettings())[trustSettingsMode.value][settingsPrefix][settingsKey]
        else
            buffs = T(trustSettings:getSettings())[trustSettingsMode.value][settingsKey]
        end
        self.buffs = buffs

        local buffSettingsEditor = BuffSettingsEditor.new(trustSettings, buffs, targets)
        self.buffSettingsEditor = buffSettingsEditor

        self.dispose_bag:add(buffSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            local buff = self.buffs[indexPath.row]

            self.selectedIndexPath = indexPath

            self.buffSettingsEditor.menuArgs['conditions'] = buff:get_conditions()

            local item = buffSettingsEditor:getDataSource():itemAtIndexPath(indexPath)
            if item and not item:getTextItem():getEnabled() then
                infoView:setDescription("Unavailable on current job or settings.")
            else
                local buff = buffs[indexPath.row]
                if buff then
                    local description = buff:get_conditions():map(function(condition)
                        return condition:tostring()
                    end)
                    description = "Use when: "..localization_util.commas(description)
                    if buff.get_job_abilities and buff:get_job_abilities():length() > 0 then
                        description = description..", Use with: "..localization_util.commas(buff:get_job_abilities(), 'and')
                    end
                    infoView:setDescription(description)
                end
            end
        end, buffSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath()))

        return buffSettingsEditor
    end

    self:reloadSettings()

    self.dispose_bag:add(trustSettings:onSettingsChanged():addAction(function(_)
        if self.buffSettingsEditor then
            self.buffSettingsEditor:setShouldRequestFocus(self.buffs:length() > 0)
        end
    end), trustSettings:onSettingsChanged())

    return self
end

function BuffSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function BuffSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddBuffMenuItem())
    self:setChildMenuItem("Remove", self:getRemoveBuffMenuItem())
    self:setChildMenuItem("Abilities", self:getEditBuffMenuItem())
    self:setChildMenuItem("Toggle", self:getToggleBuffMenuItem())
    self:setChildMenuItem("Conditions", self:getConditionsMenuItem())
    self:setChildMenuItem("Reset", self:getResetMenuItem())
end

function BuffSettingsMenuItem:getAllBuffs(targets)
    local targets = targets or self.targets
    local sections = L{
        L(self.trust:get_job():get_spells(function(spellId)
            local spell = res.spells[spellId]
            if spell then
                local status = buff_util.buff_for_spell(spell.id)
                return status ~= nil and not buff_util.is_debuff(status.id) and spell.skill ~= 44 and targets:intersection(S(spell.targets)):length() > 0
            end
            return false
        end):map(function(spellId)
            return Spell.new(res.spells[spellId].en)
        end)),--:sort(),
        L(self.trust:get_job():get_job_abilities(function(jobAbilityId)
            local jobAbility = res.job_abilities[jobAbilityId]
            if jobAbility then
                return buff_util.buff_for_job_ability(jobAbility.id) ~= nil and targets:intersection(S(jobAbility.targets)):length() > 0
            end
            return false
        end):map(function(jobAbilityId)
            return JobAbility.new(res.job_abilities[jobAbilityId].en)
        end)),--:sort()
    }
    return sections
end

function BuffSettingsMenuItem:getAddBuffMenuItem()
    local addBuffMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
    function(_, _)
        local allBuffs = self:getAllBuffs()

        local configItems = L{
            MultiPickerConfigItem.new("Spells", L{}, allBuffs[1], function(buff)
                return buff:get_localized_name()
            end, "Spells", nil, function(buff)
                return AssetManager.imageItemForSpell(buff:get_name())
            end),
            MultiPickerConfigItem.new("JobAbilities", L{}, allBuffs[2], function(buff)
                return buff:get_localized_name()
            end, "Job Abilities", nil, function(buff)
                return AssetManager.imageItemForJobAbility(buff:get_name())
            end),
        }

        local chooseBuffView = FFXIPickerView.withConfig(configItems, true)
        chooseBuffView:on_pick_items():addAction(function(pickerView, selectedBuffs)
            pickerView:getDelegate():deselectAllItems()

            local defaultJobNames = L{}
            if self.targets:contains('Party') then
                defaultJobNames = job_util.all_jobs()
            end

            local itemMappers = L{
                SpellPickerItemMapper.new(defaultJobNames),
                JobAbilityPickerItemMapper.new(),
            }

            local buffs = selectedBuffs:map(function(buff)
                for mapper in itemMappers:it() do
                    if mapper:canMap(buff) then
                        return mapper:map(buff)
                    end
                end
                return nil
            end):compact_map()

            for buff in buffs:it() do
                self.buffs:append(buff)
            end

            self.trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my buffs!")
        end)

        return chooseBuffView
    end, "Buffs", "Add a new buff.")
    return addBuffMenuItem
end

function BuffSettingsMenuItem:getRemoveBuffMenuItem()
    return MenuItem.action(function()
        local cursorIndexPath = self.buffSettingsEditor:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            local item = self.buffSettingsEditor:getDataSource():itemAtIndexPath(cursorIndexPath)
            if item then
                self.buffs:remove(cursorIndexPath.row)
                self.buffSettingsEditor:getDataSource():removeItem(cursorIndexPath)

                self.trustSettings:saveSettings(true)
            end
        end
    end, "Buffs", "Remove the selected buff.")
end

function BuffSettingsMenuItem:getEditBuffMenuItem()
    local editBuffMenuItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
        ButtonItem.default('Clear All', 18),
    }, {},
    function(_)
        local cursorIndexPath = self.buffSettingsEditor:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            local buff = self.buffs[cursorIndexPath.row]
            if buff then
                local allJobAbilities = self:getAllBuffs(S{'Self','Party'})[2]

                local jobAbilityConfigItem = MultiPickerConfigItem.new("JobAbilities", (buff:get_job_abilities() or L{}):map(function(jobAbilityName)
                    return JobAbility.new(jobAbilityName)
                end), allJobAbilities, function(buff)
                    return buff:get_localized_name()
                end, "Job Abilities", nil, function(buff)
                    return AssetManager.imageItemForJobAbility(buff:get_name())
                end)

                local chooseAbilitiesView = FFXIPickerView.withConfig(jobAbilityConfigItem, true)
                chooseAbilitiesView:on_pick_items():addAction(function(pickerView, selectedJobAbilities)
                    pickerView:getDelegate():deselectAllItems()

                    local itemMappers = L{
                        JobAbilityPickerItemMapper.new(),
                    }

                    local job_abilty_names = selectedJobAbilities:map(function(jobAbility)
                        for mapper in itemMappers:it() do
                            if mapper:canMap(jobAbility) then
                                return mapper:map(jobAbility)
                            end
                        end
                        return nil
                    end):compact_map():map(function(jobAbility)
                        return jobAbility:get_name()
                    end)

                    buff:set_job_abilities(job_abilty_names)

                    self.trustSettings:saveSettings(true)

                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated the list of job abilities I'll use with "..buff:get_name().."!")
                end)
                return chooseAbilitiesView
            end
        end
        return nil
    end, "Buffs", "Edit abilities to use with the buff.", false, function()
        return self.buffs and self.buffs:length() > 0
    end)
    editBuffMenuItem.enabled = function()
        if self.selectedIndexPath then
            local buff = self.buffs[self.selectedIndexPath.row]
            if buff and S{ Spell.__class, Buff.__class }:contains(class(buff)) then
                return true
            end
        end
        return false
    end
    return editBuffMenuItem
end

function BuffSettingsMenuItem:getToggleBuffMenuItem()
    return MenuItem.action(function(menu)
        local selectedIndexPath = self.buffSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath then
            local item = self.buffSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            if item then
                local buff = self.buffs[selectedIndexPath.row]
                buff:setEnabled(not buff:isEnabled())

                self.buffSettingsEditor:reloadBuffAtIndexPath(selectedIndexPath)
            end
        end
    end, "Gambits", "Temporarily enable or disable the selected spell until the addon reloads.")
end

function BuffSettingsMenuItem:getConditionsMenuItem()
    return ConditionSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, nil, nil, function()
        return self.buffs and self.buffs:length() > 0
    end)
end

function BuffSettingsMenuItem:getResetMenuItem()
    return MenuItem.action(function(menu)
        local defaultSettings = T(self.trustSettings:getDefaultSettings()):clone().Default

        local currentSettings = self.trustSettings:getSettings()[self.trustSettingsMode.value]
        if self.settingsPrefix then
            currentSettings[self.settingsPrefix][self.settingsKey] = defaultSettings[self.settingsPrefix][self.settingsKey]
        else
            currentSettings[self.settingsKey] = defaultSettings[self.settingsKey]
        end
        self.trustSettings:saveSettings(true)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've forgotten any custom settings!")

        menu:showMenu(self)
    end, "Reset", "Reset to default settings. WARNING: your settings will be overriden.")
end

return BuffSettingsMenuItem