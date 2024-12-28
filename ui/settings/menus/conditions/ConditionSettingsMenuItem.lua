local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionsSettingsEditor = require('ui/settings/editors/ConditionsSettingsEditor')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')

local ConditionSettingsMenuItem = setmetatable({}, {__index = MenuItem })
ConditionSettingsMenuItem.__index = ConditionSettingsMenuItem

function ConditionSettingsMenuItem.new(trustSettings, trustSettingsMode, parentMenuItem, targetTypes, enabled)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Invert', 18),
        ButtonItem.default('Edit', 18),
    }, {}, nil, "Conditions", "Edit conditions.", true, enabled), ConditionSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.targetTypes = targetTypes or Condition.TargetType.AllTargets
    self.dispose_bag = DisposeBag.new()
    self.editableConditionClasses = T{
        [IdleCondition.__type] = "idle",
        [InBattleCondition.__type] = "in_battle",
        [GainDebuffCondition.__type] = "gain_debuff",
        [HasBuffsCondition.__type] = "has_buffs",
        [HasDebuffCondition.__type] = "has_debuff",
        [MaxHitPointsPercentCondition.__type] = "max_hpp",
        [MinHitPointsPercentCondition.__type] = "min_hpp",
        [HitPointsPercentRangeCondition.__type] = "hpp_range",
        [MeleeAccuracyCondition.__type] = "melee_accuracy",
        [MinManaPointsCondition.__type] = "min_mp",
        [MaxManaPointsPercentCondition.__type] = "max_mpp",
        [MinManaPointsPercentCondition.__type] = "min_mpp",
        [MaxTacticalPointsCondition.__type] = "max_tp",
        [MinTacticalPointsCondition.__type] = "min_tp",
        [MaxDistanceCondition.__type] = "max_distance",
        [HasBuffCondition.__type] = "has_buff_condition",
        [ZoneCondition.__type] = "zone",
        [MainJobCondition.__type] = "main_job",
        [JobCondition.__type] = "job",
        [ReadyAbilityCondition.__type] = "ready_ability",
        [FinishAbilityCondition.__type] = "finish_ability",
        [HasRunesCondition.__type] = "has_runes",
        [EnemiesNearbyCondition.__type] = "enemies_nearby",
        [ModeCondition.__type] = "mode",
        [PetHitPointsPercentCondition.__type] = "pet_hpp",
        [PetTacticalPointsCondition.__type] = "pet_tp",
        [HasPetCondition.__type] = "has_pet",
        [NumResistsCondition.__type] = "num_resists",
        [SkillchainPropertyCondition.__type] = "skillchain_property",
        [HasDazeCondition.__type] = "has_daze",
        [TargetNameCondition.__type] = "target_name",
        [CombatSkillsCondition.__type] = "combat_skills",
        [StrategemCountCondition.__type] = "strategem_count",
        [IsAlterEgoCondition.__type] = "is_alter_ego",
        [ReadyChargesCondition.__type] = "ready_charges",
        [ItemCountCondition.__type] = "item_count",
        [SkillchainWindowCondition.__type] = "skillchain_window",
        [SkillchainStepCondition.__type] = "skillchain_step",
        [InTownCondition.__type] = "in_town",
        [BeginCastCondition.__type] = "begin_cast",
        [HasCumulativeMagicEffectCondition.__type] = "has_cumulative_magic_effect",
        [StatusCondition.__type] = "status",
    }
    self.conditionPickerItems = L(self.editableConditionClasses:keyset()):filter(function(c)
        local conditionClass = self:getFileForCondition(c)
        return L(self.targetTypes:intersection(conditionClass.valid_targets())):length() > 0
    end):sort(function(c1, c2)
        c1 = self:getFileForCondition(c1).description()
        c2 = self:getFileForCondition(c2).description()
        return c1 < c2
    end)

    self.contentViewConstructor = function(menuArgs, infoView)
        local conditions = menuArgs and menuArgs['conditions']
        if not conditions then
            conditions = self.conditions
        end
        self.conditions = conditions

        local targetTypes = menuArgs and menuArgs['targetTypes']
        if not targetTypes then
            targetTypes = self.targetTypes
        end
        self.targetTypes = targetTypes or Condition.TargetType.AllTargets

        self.conditionPickerItems = L(self.editableConditionClasses:keyset()):filter(function(c)
            local conditionClass = self:getFileForCondition(c)
            return L(self.targetTypes:intersection(conditionClass.valid_targets())):length() > 0
        end):sort(function(c1, c2)
            c1 = self:getFileForCondition(c1).description()
            c2 = self:getFileForCondition(c2).description()
            return c1 < c2
        end)

        local editConditionsView = ConditionsSettingsEditor.new(trustSettings, conditions, L(self.editableConditionClasses:keyset()))
        editConditionsView:setTitle("Edit conditions.")
        editConditionsView:setShouldRequestFocus(self.conditions:length() > 0)

        self.dispose_bag:add(editConditionsView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            self.selectedCondition = self.conditions[indexPath.row]
            self.selectedConditionIndex = indexPath.row
            if self.selectedCondition then
                infoView:setDescription(self.selectedCondition:tostring())
            end
        end, editConditionsView:getDelegate():didSelectItemAtIndexPath()))

        self.editConditionsView = editConditionsView

        return editConditionsView
    end

    self:reloadSettings(parentMenuItem or self)

    return self
end

function ConditionSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function ConditionSettingsMenuItem:getFileForCondition(conditionClass)
    return require('cylibs/conditions/'..self.editableConditionClasses[conditionClass])
end

function ConditionSettingsMenuItem:reloadSettings(parentMenuItem)
    self:setChildMenuItem("Add", self:getAddConditionMenuItem(parentMenuItem))
    self:setChildMenuItem("Edit", self:getEditConditionMenuItem())
    self:setChildMenuItem("Invert", self:getInvertConditionMenuItem())
end

function ConditionSettingsMenuItem:getAddConditionMenuItem(parentMenuItem)
    local addConditionsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {
        Confirm = MenuItem.action(function(menu)
            if parentMenuItem ~= nil then
                menu:showMenu(parentMenuItem)
            end
        end, "Conditions", "Add a new condition.")
    }, function(_, infoView)
        local conditionClasses = L(self.editableConditionClasses:keyset())
        conditionClasses:sort()

        local configItem = MultiPickerConfigItem.new("Conditions", L{}, self.conditionPickerItems:map(function(conditionClass)
            return self:getFileForCondition(conditionClass).description()
        end), function(conditionName)
            return conditionName
        end)

        local chooseConditionView = FFXIPickerView.new(L{ configItem }, false, FFXIClassicStyle.WindowSize.Editor.ConfigEditor)
        chooseConditionView:on_pick_items():addAction(function(_, _, selectedIndexPaths)
            local conditionClass = self:getFileForCondition(self.conditionPickerItems[selectedIndexPaths[1].row])
            local newCondition = conditionClass.new()

            self.conditions:append(newCondition)

            self.trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've added a new condition!")
        end)
        return chooseConditionView
    end, "Conditions", "Add a new condition.")
    return addConditionsMenuItem
end

function ConditionSettingsMenuItem:getEditConditionMenuItem()
    local editConditionMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(menuArgs, infoView, showMenu)
        local configItems
        if self.selectedCondition and self.selectedCondition.get_config_items ~= nil then
            configItems = self.selectedCondition:get_config_items()
        end
        if configItems then
            local condition = self.selectedCondition
            if condition.__type == NotCondition.__type then
                condition = condition.conditions[1]
            end
            local conditionConfigEditor = ConfigEditor.new(self.trustSettings, condition, configItems, infoView, nil, showMenu)
            conditionConfigEditor:setShouldRequestFocus(true)
            return conditionConfigEditor
        else
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."This condition can't be configured!")
        end
    end, "Conditions", "Edit the selected condition.", false, function()
        return self.selectedCondition ~= nil
    end)
    return editConditionMenuItem
end

function ConditionSettingsMenuItem:getInvertConditionMenuItem()
    local invertConditionMenuItem = MenuItem.new(L{}, L{}, function(menuArgs, _)
        if self.selectedCondition then
            local editedCondition
            if self.selectedCondition.__type == NotCondition.__type then
                editedCondition = self.selectedCondition.conditions[1]
            else
                editedCondition = NotCondition.new(L{ self.selectedCondition })
            end
            self.conditions[self.selectedConditionIndex] = editedCondition

            self.editConditionsView:reloadSettings()

            if self.trustSettings then
                self.trustSettings:saveSettings(true)
            end

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've inverted the condition logic!")
        end
    end, "Conditions", "Invert the selected condition logic.", false, function()
        return self.selectedCondition ~= nil
    end)
    return invertConditionMenuItem
end

return ConditionSettingsMenuItem