local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local Event = require('cylibs/events/Luvent')
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local TextConfigItem = require('ui/settings/editors/config/TextConfigItem')

local GambitSettingsEditor = setmetatable({}, {__index = ConfigEditor })
GambitSettingsEditor.__index = GambitSettingsEditor
GambitSettingsEditor.__type = "GambitSettingsEditor"

function GambitSettingsEditor:onGambitChanged()
    return self.gambitChanged
end

function GambitSettingsEditor.new(gambit, trustSettings, trustSettingsMode, abilitiesByTargetType, conditionTargets, showMenu)
    local validTargets = L(GambitTarget.TargetType:keyset()):filter(function(targetType) return abilitiesByTargetType[targetType]:length() > 0 end)
    local validConditionTargets = conditionTargets or L(Condition.TargetType.AllTargets)

    local configItems = GambitSettingsEditor.configItems(gambit, abilitiesByTargetType, validTargets, validConditionTargets)

    local self = setmetatable(ConfigEditor.new(trustSettings, gambit, configItems, nil, function(_) return true end, showMenu), GambitSettingsEditor)

    self.gambit = gambit
    self.abilitiesByTargetType = abilitiesByTargetType
    self.validTargets = validTargets
    self.validConditionTargets = validConditionTargets
    self.menuArgs = {}
    self.gambitChanged = Event.newEvent()

    local numSections = self:getDataSource():numberOfSections() + 1

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        if indexPath.section == numSections then
            self:getDelegate():deselectItemAtIndexPath(indexPath)
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(self:onConfigChanged():addAction(function(newSettings, oldSettings)
        local shouldReload = false

        if newSettings['conditions_target'] ~= oldSettings['conditions_target'] then
            shouldReload = true

            local removed_condition_names = L{}
            local conditions = self.gambit:getConditions():filter(function(condition)
                if condition.valid_targets():contains(newSettings['conditions_target']) then
                    return true
                end
                removed_condition_names:append(condition.description():gsub("%.", ""))
                return false
            end)
            newSettings.conditions = conditions

            if removed_condition_names:length() > 0 then
                addon_system_error("Invalid conditions for conditions target type "..newSettings['conditions_target']..": "..localization_util.commas(removed_condition_names)..".")
            end
        end
        if newSettings['target'] ~= oldSettings['target'] then
            shouldReload = true

            local removed_ability_name = newSettings['ability']:get_localized_name()

            if not abilitiesByTargetType[newSettings['target']]:contains(newSettings['ability']) then
                addon_system_error("Invalid ability "..removed_ability_name.." for ability target type "..newSettings['target']..".")
            end
            newSettings.ability = abilitiesByTargetType[newSettings['target']][1]:copy()
        end

        if newSettings['ability'] ~= oldSettings['ability'] then
            shouldReload = true
        end

        self:onGambitChanged():trigger(newSettings, oldSettings)

        if shouldReload then
            self:reloadSettings()
            self:reloadConfigItems()
        end
    end), self:onConfigChanged())

    return self
end



function GambitSettingsEditor.configItemFromGambit(gambit, abilitiesByTargetType)
    local abilities = abilitiesByTargetType[gambit:getAbilityTarget()]
    if not abilities:contains(gambit:getAbility()) then
        abilities:append(gambit:getAbility())
    end
    local abilityConfigItem = PickerConfigItem.new('ability', gambit:getAbility(), abilities, function(ability)
        return ability:get_localized_name()
    end, "Ability")
    return abilityConfigItem
end

function GambitSettingsEditor.configItems(gambit, abilitiesByTargetType, validTargets, validConditionTargets)
    local abilities = abilitiesByTargetType[gambit:getAbilityTarget()]
    local currentAbility
    if abilities:indexOf(gambit:getAbility()) ~= -1 then
        currentAbility = gambit:getAbility()
    else
        currentAbility = abilities[1]
    end

    local configItems = L{}
    if validTargets:length() > 1 then
        configItems:append(PickerConfigItem.new('target', gambit.target or GambitTarget.TargetType.Self, validTargets, nil, "Ability target"))
    end

    configItems:append(GambitSettingsEditor.configItemFromGambit(gambit, abilitiesByTargetType))

    if validConditionTargets:length() > 1 then
        configItems:append(PickerConfigItem.new('conditions_target', gambit.conditions_target or validConditionTargets[1], validConditionTargets, nil, "Conditions target"))
    end

    if gambit.conditions:length() > 0 then
        local conditionsConfigItem = TextConfigItem.new('conditions', gambit.conditions, function(conditions)
            if conditions:length() > 0 then
                return localization_util.commas(conditions:map(function(c) return c:tostring() end))
            end
            return 'Never'
        end, "Conditions")

        configItems:append(conditionsConfigItem)
    end

    configItems:append(MultiPickerConfigItem.new('tags', gambit.tags, L(gambit.tags + Gambit.Tags.AllTags):unique(), function(tags)
        if tags:length() > 0 then
            return localization_util.commas(tags)
        end
        return 'Default'
    end, "Tags"))

    return configItems
end

function GambitSettingsEditor:reloadConfigItems()
    local configItems = GambitSettingsEditor.configItems(self.gambit, self.abilitiesByTargetType, self.validTargets, self.validConditionTargets)
    self:setConfigItems(configItems)
end

function GambitSettingsEditor:setVisible(visible)
    ConfigEditor.setVisible(self, visible)

    self:reloadSettings()
end

function GambitSettingsEditor:getMenuArgs()
    return self.menuArgs
end

function GambitSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Conditions' then
        self.menuArgs['conditions'] = self.gambit:getConditions()
        self.menuArgs['targetTypes'] = S{ self.gambit:getConditionsTarget() }
    end

    ConfigEditor.onSelectMenuItemAtIndexPath(self, textItem, indexPath)
end

function GambitSettingsEditor:setHasFocus(focus)
    ConfigEditor.setHasFocus(self, focus)

    if focus then
        -- TODO: validate in memory config items
        local selectedIndexPath = self:getDelegate():getCursorIndexPath()
        if selectedIndexPath and selectedIndexPath.section == self:sectionForConfigKey('ability_target') then
            local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
            if item then
                if item:getCurrentValue() ~= self.gambit:getAbilityTarget() then
                    self.gambit.target = item:getCurrentValue()
                    local abilities = self.abilitiesByTargetType[item:getCurrentValue()]
                    local currentAbility
                    if abilities:indexOf(self.gambit:getAbility()) ~= -1 then
                        currentAbility = self.gambit:getAbility()
                    else
                        currentAbility = abilities[1]
                    end
                    local abilityConfigItem = PickerConfigItem.new('ability', currentAbility, abilities, function(ability)
                        return ability:get_name()
                    end, "Ability")
                    self.configItems[2] = abilityConfigItem

                    self:reloadConfigItem(self.configItems[2])
                end
            end
        end
        self:onConfirmClick(true)
    end
end

return GambitSettingsEditor