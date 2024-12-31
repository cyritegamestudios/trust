local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local GambitTarget = require('cylibs/gambits/gambit_target')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local SectionHeaderItem = require('cylibs/ui/collection_view/items/section_header_item')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local GambitSettingsEditor = setmetatable({}, {__index = ConfigEditor })
GambitSettingsEditor.__index = GambitSettingsEditor
GambitSettingsEditor.__type = "GambitSettingsEditor"

function GambitSettingsEditor.new(gambit, trustSettings, trustSettingsMode, abilitiesByTargetType, conditionTargets)
    local validTargets = L(GambitTarget.TargetType:keyset()):filter(function(targetType) return abilitiesByTargetType[targetType]:length() > 0 end)
    local validConditionTargets = conditionTargets or L(Condition.TargetType.AllTargets)

    local configItems = L{
        PickerConfigItem.new('target', gambit.target or GambitTarget.TargetType.Self, validTargets, nil, "Ability target"),
        GambitSettingsEditor.configItemFromGambit(gambit, abilitiesByTargetType),
        PickerConfigItem.new('conditions_target', gambit.conditions_target or validConditionTargets[1], validConditionTargets, nil, "Conditions target"),
    }

    local self = setmetatable(ConfigEditor.new(trustSettings, gambit, configItems), GambitSettingsEditor)

    self.gambit = gambit
    self.abilitiesByTargetType = abilitiesByTargetType
    self.validTargets = validTargets
    self.menuArgs = {}

    local conditionsSectionHeaderItem = SectionHeaderItem.new(
            TextItem.new("Conditions", TextStyle.Default.SectionHeader),
            ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
            16
    )
    self:getDataSource():setItemForSectionHeader(4, conditionsSectionHeaderItem)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        if indexPath.section == 4 then
            self:getDelegate():deselectItemAtIndexPath(indexPath)
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(self:onConfigChanged():addAction(function(newSettings, oldSettings)
        if newSettings['conditions_target'] ~= oldSettings['conditions_target'] then
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
                self:reloadSettings()
            end
        end
        self:reloadConfigItems()
    end), self:onConfigChanged())

    return self
end

function GambitSettingsEditor.configItemFromGambit(gambit, abilitiesByTargetType)
    local abilityConfigItem = PickerConfigItem.new('ability', gambit:getAbility(), abilitiesByTargetType[gambit:getAbilityTarget()], function(ability)
        return ability:get_localized_name()
    end, "Ability")
    return abilityConfigItem
end

function GambitSettingsEditor:reloadSettings()
    ConfigEditor.reloadSettings(self)

    local conditionsItems = IndexedItem.fromItems(self.gambit:getConditions():map(function(condition)
        return TextItem.new(condition:tostring(), TextStyle.Default.TextSmall)
    end), 4)

    if conditionsItems:length() > 0 then
        self:getDataSource():addItems(conditionsItems)
    end

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

function GambitSettingsEditor:reloadConfigItems()
    local abilities = self.abilitiesByTargetType[self.gambit:getAbilityTarget()]
    local currentAbility
    if abilities:indexOf(self.gambit:getAbility()) ~= -1 then
        currentAbility = self.gambit:getAbility()
    else
        currentAbility = abilities[1]
    end
    local configItems = L{
        PickerConfigItem.new('target', self.gambit.target or GambitTarget.TargetType.Self, self.validTargets, nil, "Ability target"),
        GambitSettingsEditor.configItemFromGambit(self.gambit, self.abilitiesByTargetType),
        PickerConfigItem.new('conditions_target', self.gambit.conditions_target or GambitTarget.TargetType.Self, L(GambitTarget.TargetType:keyset()), nil, "Conditions target"),
    }
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
        if selectedIndexPath and selectedIndexPath.section == 1 then
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