local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionsSettingsEditor = require('ui/settings/editors/ConditionsSettingsEditor')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local MenuItem = require('cylibs/ui/menu/menu_item')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')

local ConditionSettingsMenuItem = setmetatable({}, {__index = MenuItem })
ConditionSettingsMenuItem.__index = ConditionSettingsMenuItem

function ConditionSettingsMenuItem.new(trustSettings, trustSettingsMode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Edit', 18),
    }, {}, nil, "Conditions", "Specify when this buff should be used.", true), ConditionSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.dispose_bag = DisposeBag.new()
    self.editableConditionClasses = T{
        [IdleCondition.__type] = "idle",
        [InBattleCondition.__type] = "in_battle",
        [HasBuffsCondition.__type] = "has_buffs",
        [MaxHitPointsPercentCondition.__type] = "max_hpp",
        [MinHitPointsPercentCondition.__type] = "min_hpp",
        [HitPointsPercentRangeCondition.__type] = "hpp_range",
        [MinManaPointsCondition.__type] = "min_mp",
        [MinManaPointsPercentCondition.__type] = "min_mpp",
        [MinTacticalPointsCondition.__type] = "min_tp",
        [MaxDistanceCondition.__type] = "max_distance",
        [HasBuffCondition.__type] = "has_buff_condition",
        [ZoneCondition.__type] = "zone",
        [MainJobCondition.__type] = "main_job",
    }

    self.contentViewConstructor = function(menuArgs, _)
        local conditions = menuArgs and menuArgs['conditions']
        if not conditions then
            conditions = self.conditions
        end
        self.conditions = conditions

        local editConditionsView = ConditionsSettingsEditor.new(trustSettings, conditions, L(self.editableConditionClasses:keyset()))
        editConditionsView:setTitle("Edit conditions.")
        editConditionsView:setShouldRequestFocus(true)

        self.dispose_bag:add(editConditionsView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            self.selectedCondition = self.conditions[indexPath.row]
        end, editConditionsView:getDelegate():didSelectItemAtIndexPath()))

        return editConditionsView
    end

    self:reloadSettings()

    return self
end

function ConditionSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function ConditionSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddConditionMenuItem())
    self:setChildMenuItem("Edit", self:getEditConditionMenuItem())
end

function ConditionSettingsMenuItem:getAddConditionMenuItem()
    local addConditionsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(_, infoView)
        local chooseConditionView = FFXIPickerView.withItems(L(self.editableConditionClasses:keyset()), L{}, false, nil, nil, FFXIClassicStyle.WindowSize.Editor.ConfigEditor)
        chooseConditionView:setTitle("Choose a condition.")
        chooseConditionView:setShouldRequestFocus(true)
        chooseConditionView:on_pick_items():addAction(function(_, selectedItems)
            local conditionClass = require('cylibs/conditions/'..self.editableConditionClasses[selectedItems[1]:getText()])
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
    }, L{}, function(menuArgs, _)
        local configItems
        if self.selectedCondition and self.selectedCondition.get_config_items ~= nil then
            configItems = self.selectedCondition:get_config_items()
        end
        if configItems then
            local conditionConfigEditor = ConfigEditor.new(self.trustSettings, self.selectedCondition, configItems)
            conditionConfigEditor:setShouldRequestFocus(true)
            return conditionConfigEditor
        else
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."This condition can't be configured!")
        end
    end, "Conditions", "Edit the selected condition.")
    return editConditionMenuItem
end

return ConditionSettingsMenuItem