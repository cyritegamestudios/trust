local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local inventory_util = require('cylibs/util/inventory_util')
local IsStandingCondition = require('cylibs/conditions/is_standing')
local ItemDescription = require('resources/resources').ItemDescription
local Item = require('resources/resources').Item
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

local FoodSettingsMenuItem = setmetatable({}, {__index = MenuItem })
FoodSettingsMenuItem.__index = FoodSettingsMenuItem

function FoodSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        ButtonItem.localized('Modes', i18n.translate('Button_Modes')),
    }, {}, function(_, infoView, showMenu)
        local allGambits = trustSettings:getSettings()[trustSettingsMode.value].GambitSettings.Gambits

        local foodGambit = allGambits:firstWhere(function(gambit) return gambit:getTags():contains('food') end)
        if not foodGambit then
            foodGambit = Gambit.new("Self", L{GambitCondition.new(NotCondition.new(L{HasBuffCondition.new("Food")}), "Self"), GambitCondition.new(ModeCondition.new("AutoFoodMode", "Auto"), "Self"), GambitCondition.new(MainJobCondition.new(trustSettings.jobNameShort), "Self")}, UseItem.new('Grape Daifuku', L{ItemCountCondition.new('Grape Daifuku', 1, ">=")}), "Self", L{"food"})
            allGambits:append(foodGambit)
        end

        local itemSettings = {}
        itemSettings['item_names'] = L{ foodGambit:getAbility():get_item_name() }

        local item_names = L{}
        for _, item in pairs(inventory_util.all_food()) do
            item_names:append(item.en)
        end
        item_names = L(S(item_names)):sort()

        local setFoodItem = function(newItemName)
            itemSettings['item_names'] = L{ newItemName }

            foodGambit:getAbility().item_name = newItemName
            foodGambit:getAbility().conditions = L{
                IsStandingCondition.new(0.5, ">="),
                ItemCountCondition.new(newItemName, 1, Condition.Operator.GreaterThanOrEqualTo),
            }

            trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll eat "..newItemName.." now when I have them in my inventory!")
        end

        local foodPickerConfigItem = MultiPickerConfigItem.new('item_names', L{ foodGambit:getAbility():get_item_name() }, item_names, function(item_names)
            return item_names[1]
        end, "Food", nil, nil, function(item_name)
            local item = Item:where({ en = item_name }, L{ 'id' })
            local item_description = ItemDescription:where({ id = item[1].id }, L{ 'en' })[1].en
            return item_description:gsub("[\r\n]", " ")
        end)
        foodPickerConfigItem:setNumItemsRequired(1)
        foodPickerConfigItem:setPickerTitle("Food")
        foodPickerConfigItem:setPickerDescription("Choose a food to use.")
        foodPickerConfigItem:setPickerTextFormat(function(item_name)
            return item_name
        end)

        foodPickerConfigItem:setOnConfirm(function(newItemNames)
            setFoodItem(newItemNames[1])
        end)
        foodPickerConfigItem:setNumItemsRequired(1, 1)

        local configItems = L{ foodPickerConfigItem }

        local editAbilityEditor = ConfigEditor.new(nil, itemSettings, configItems, infoView, nil, showMenu)
        editAbilityEditor:onConfigChanged():addAction(function(newAbility, _)
            setFoodItem(newAbility['item_names'][1])
        end)
        return editAbilityEditor
    end, "Food", "Choose food to eat."), FoodSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
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
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for eating.",
            L{ 'AutoFoodMode' })
end

return FoodSettingsMenuItem