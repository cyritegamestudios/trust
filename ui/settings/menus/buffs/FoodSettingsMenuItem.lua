local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local inventory_util = require('cylibs/util/inventory_util')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/config/ModeConfigEditor')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local FoodSettingsMenuItem = setmetatable({}, {__index = MenuItem })
FoodSettingsMenuItem.__index = FoodSettingsMenuItem

function FoodSettingsMenuItem.new(trustSettings, trustSettingsMode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Modes', 18),
    }, {}, function(_, infoView)
        local allGambits = trustSettings:getSettings()[trustSettingsMode.value].GambitSettings.Gambits

        local foodGambit = allGambits:firstWhere(function(gambit) return gambit:getTags():contains('food') end)
        if not foodGambit then
            foodGambit = Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new(trustSettings.jobNameShort)}, UseItem.new('Grape Daifuku', L{ItemCountCondition.new('Grape Daifuku', 1, ">=")}), "Self", L{"food"})
            allGambits:append(foodGambit)
        end

        local itemSettings = {}
        itemSettings['item_name'] = foodGambit:getAbility():get_item_name()

        local item_names = L{}
        for _, item in pairs(inventory_util.all_food()) do
            item_names:append(item.en)
        end
        item_names = L(S(item_names)):sort()

        local configItems = L{ PickerConfigItem.new('item_name', foodGambit:getAbility():get_item_name(), item_names, nil, "Food Name") }

        local editAbilityEditor = ConfigEditor.new(nil, itemSettings, configItems, infoView)
        editAbilityEditor:onConfigChanged():addAction(function(newAbility, _)
            local newItemName = newAbility['item_name']

            foodGambit:getAbility().item_name = newItemName
            foodGambit:getAbility().conditions = L{ ItemCountCondition.new(newItemName, 1, Condition.Operator.GreaterThanOrEqualTo) }

            trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll eat "..newItemName.." now when I have them in my inventory!")
        end)
        return editAbilityEditor
    end, "Food", "Choose food to eat."), FoodSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function FoodSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function FoodSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function FoodSettingsMenuItem:getModesMenuItem()
    local foodModesMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm')
    }, L{}, function(_, infoView)
        local modesView = ModesView.new(L{ 'AutoFoodMode' }, infoView)
        modesView:setShouldRequestFocus(true)
        modesView:setTitle("Set modes for eating.")
        return modesView
    end, "Modes", "Change eating behavior.")
    return foodModesMenuItem
end

return FoodSettingsMenuItem