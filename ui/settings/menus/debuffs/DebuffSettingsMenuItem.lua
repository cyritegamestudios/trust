local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local BuffSettingsEditor = require('ui/settings/BuffSettingsEditor')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local JobAbilityPickerItemMapper = require('ui/settings/pickers/mappers/JobAbilityPickerItemMapper')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local SpellPickerItemMapper = require('ui/settings/pickers/mappers/SpellPickerItemMapper')

local DebuffSettingsMenuItem = setmetatable({}, {__index = MenuItem })
DebuffSettingsMenuItem.__index = DebuffSettingsMenuItem

function DebuffSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, addonSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Abilities', 18),
        ButtonItem.default('Toggle', 18),
        ButtonItem.default('Conditions', 18),
        ButtonItem.localized('Modes', i18n.translate('Button_Modes')),
        ButtonItem.default('Help', 18)
    }, {
        Help = MenuItem.action(function(_)
            windower.open_url(addonSettings:getSettings().help.wiki_base_url..'/Debuffer')
        end, "Debuffs", "Learn more about debuffs in the wiki.")
    },
    nil, "Debuffs", "Choose debuffs to use on enemies."), DebuffSettingsMenuItem)

    self.trust = trust
    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.targets = S{ 'Enemy' }
    self.dispose_bag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        self.debuffs = T(trustSettings:getSettings())[trustSettingsMode.value].Debuffs

        local buffSettingsEditor = BuffSettingsEditor.new(trustSettings, self.debuffs, S{ 'Enemy' })
        self.buffSettingsEditor = buffSettingsEditor

        self.dispose_bag:add(buffSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            local buff = self.debuffs[indexPath.row]

            self.selectedIndexPath = indexPath

            self.buffSettingsEditor.menuArgs['conditions'] = buff:get_conditions()

            local item = buffSettingsEditor:getDataSource():itemAtIndexPath(indexPath)
            if item and not item:getTextItem():getEnabled() then
                local failed_conditions = buff:get_conditions():filter(function(condition)
                    return not condition:is_satisfied(condition:get_target_index() or windower.ffxi.get_player().index)
                end):map(function(condition) return condition:tostring() end)
                infoView:setDescription("Unavailable due to failed conditions: "..localization_util.commas(failed_conditions))
            else
                local buff = self.debuffs[indexPath.row]
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
            self.buffSettingsEditor:setShouldRequestFocus(self.debuffs:length() > 0)
        end
    end), trustSettings:onSettingsChanged())

    return self
end

function DebuffSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function DebuffSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddDebuffMenuItem())
    self:setChildMenuItem("Remove", self:getRemoveBuffMenuItem())
    self:setChildMenuItem("Abilities", self:getEditBuffMenuItem())
    self:setChildMenuItem("Toggle", self:getToggleBuffMenuItem())
    self:setChildMenuItem("Conditions", self:getConditionsMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
    self:setChildMenuItem("Reset", self:getResetMenuItem())
end

function DebuffSettingsMenuItem:getAllDebuffs(targets)
    local targets = targets or self.targets
    local sections = L{
        L(self.trust:get_job():get_spells(function(spellId)
            local spell = res.spells[spellId]
            if spell then
                local status = buff_util.buff_for_spell(spell.id)
                return status ~= nil and buff_util.is_debuff(status.id) and S{ 32, 35, 36, 37, 39, 40, 41, 42 }:contains(spell.skill) and targets:intersection(S(spell.targets)):length() > 0
            end
            return false
        end):map(function(spellId)
            return Spell.new(res.spells[spellId].en)
        end)),
        L(self.trust:get_job():get_job_abilities(function(jobAbilityId)
            local jobAbility = res.job_abilities[jobAbilityId]
            if jobAbility then
                return buff_util.buff_for_job_ability(jobAbility.id) ~= nil and targets:intersection(S(jobAbility.targets)):length() > 0
            end
            return false
        end):map(function(jobAbilityId)
            return JobAbility.new(res.job_abilities[jobAbilityId].en)
        end)),
    }
    return sections
end

function DebuffSettingsMenuItem:getAddDebuffMenuItem()
    local addBuffMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
            function(_, _)
                local allDebuffs = self:getAllDebuffs()

                local configItems = L{
                    MultiPickerConfigItem.new("Spells", L{}, allDebuffs[1], function(buff)
                        return buff:get_localized_name()
                    end, "Spells", nil, function(buff)
                        return AssetManager.imageItemForSpell(buff:get_name())
                    end, function(debuff)
                        local description = debuff:get_localized_description()
                        if description then
                            return "Inflicts: "..description
                        end
                        return nil
                    end),
                    --[[MultiPickerConfigItem.new("JobAbilities", L{}, allDebuffs[2], function(buff)
                        return buff:get_localized_name()
                    end, "Job Abilities", nil, function(buff)
                        return AssetManager.imageItemForJobAbility(buff:get_name())
                    end),]]
                }

                local chooseDebuffView = FFXIPickerView.withConfig(configItems, true)
                chooseDebuffView:on_pick_items():addAction(function(pickerView, selectedDebuffs)
                    pickerView:getDelegate():deselectAllItems()

                    local itemMappers = L{
                        SpellPickerItemMapper.new(L{}),
                        JobAbilityPickerItemMapper.new(),
                    }

                    local debuffs = selectedDebuffs:map(function(debuff)
                        for mapper in itemMappers:it() do
                            if mapper:canMap(debuff) then
                                return mapper:map(debuff)
                            end
                        end
                        return nil
                    end):compact_map()

                    for debuff in debuffs:it() do
                        self.debuffs:append(debuff)
                    end

                    self.trustSettings:saveSettings(true)

                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my debuffs!")
                end)

                return chooseDebuffView
            end, "Debuffs", "Add a new debuff.")
    return addBuffMenuItem
end

function DebuffSettingsMenuItem:getRemoveBuffMenuItem()
    return MenuItem.action(function()
        local cursorIndexPath = self.buffSettingsEditor:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            local item = self.buffSettingsEditor:getDataSource():itemAtIndexPath(cursorIndexPath)
            if item then
                self.debuffs:remove(cursorIndexPath.row)
                self.buffSettingsEditor:getDataSource():removeItem(cursorIndexPath)

                self.trustSettings:saveSettings(true)
            end
        end
    end, "Debuffs", "Remove the selected debuff.")
end

function DebuffSettingsMenuItem:getEditBuffMenuItem()
    local editBuffMenuItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
        ButtonItem.default('Clear All', 18),
    }, {},
            function(_)
                local cursorIndexPath = self.buffSettingsEditor:getDelegate():getCursorIndexPath()
                if cursorIndexPath then
                    local buff = self.debuffs[cursorIndexPath.row]
                    if buff then
                        local allJobAbilities = self:getAllDebuffs(S{'Self'})[2]

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
            end, "Debuffs", "Edit abilities to use with the selected debuff.", false, function()
                return self.debuffs and self.debuffs:length() > 0
            end)
    editBuffMenuItem.enabled = function()
        if self.selectedIndexPath then
            local buff = self.debuffs[self.selectedIndexPath.row]
            if buff and S{ Spell.__class, Buff.__class }:contains(class(buff)) then
                return true
            end
        end
        return false
    end
    return editBuffMenuItem
end

function DebuffSettingsMenuItem:getToggleBuffMenuItem()
    return MenuItem.action(function(menu)
        local selectedIndexPath = self.buffSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath then
            local item = self.buffSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            if item then
                local buff = self.debuffs[selectedIndexPath.row]
                buff:setEnabled(not buff:isEnabled())

                self.buffSettingsEditor:reloadBuffAtIndexPath(selectedIndexPath)
            end
        end
    end, "Debuffs", "Temporarily enable or disable the selected debuff until the addon reloads.")
end

function DebuffSettingsMenuItem:getConditionsMenuItem()
    return ConditionSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, nil, S{ Condition.TargetType.Enemy }, function()
        return self.debuffs and self.debuffs:length() > 0
    end)
end

function DebuffSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for debuffs.",
            L{'AutoDebuffMode', 'AutoDispelMode', 'AutoSilenceMode'})
end

function DebuffSettingsMenuItem:getResetMenuItem()
    return MenuItem.action(function(menu)
        local defaultSettings = T(self.trustSettings:getDefaultSettings()):clone().Default

        local currentSettings = self.trustSettings:getSettings()[self.trustSettingsMode.value]
        currentSettings.Debuffs = defaultSettings.Debuffs

        self.trustSettings:saveSettings(true)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've forgotten any custom settings!")

        menu:showMenu(self)
    end, "Debuffs", "Reset to default settings. WARNING: your settings will be overriden.")
end

return DebuffSettingsMenuItem