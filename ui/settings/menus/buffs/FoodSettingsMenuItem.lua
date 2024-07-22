local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')

local FoodSettingsMenuItem = setmetatable({}, {__index = MenuItem })
FoodSettingsMenuItem.__index = FoodSettingsMenuItem

function FoodSettingsMenuItem.new(trustSettings, trustSettingsMode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Food", "Choose food to eat."), FoodSettingsMenuItem)

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
    self:setChildMenuItem("Edit", self:getFoodMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function FoodSettingsMenuItem:getFoodMenuItem()
    local chooseFoodMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(menuArgs)
        local allFood = L{
            'Grape Daifuku',
            'Grape Daifuku +1',
            'Om. Sandwich',
            'Om. Sand. +1',
            'Popo. con Queso',
            'Popo. con Que. +1',
            'Red Curry Bun',
            'R. Curry Bun +1',
            'Hydra Kofte',
            'Hydra Kofte +1',
            'Behemoth Steak',
            'Behe. Steak +1',
            'Marine Stewpot',
            'Prm. Mn. Stewpot',
            'Squid Sushi',
            'Squid Sushi +1',
            'Miso Ramen',
            'Miso Ramen +1',
            'Black Curry Bun',
            'B. Curry Bun +1',
            'Tavnazian Taco',
            'Tropical Crepe',
            'Crepe des rois',
            'Pear Crepe',
            'Crepe Belle Helene'
        }

        local currentFood = self.trustSettings:getSettings()[self.trustSettingsMode.value].AutoFood
        if currentFood == nil then
            currentFood = 'Grape Daifuku'
        end

        local chooseFoodView = FFXIPickerView.withItems(allFood, currentFood, false)
        chooseFoodView:setTitle("Choose a food to eat.")
        chooseFoodView:setShouldRequestFocus(true)
        chooseFoodView:on_pick_items():addAction(function(_, selectedItems)
            local newFood = selectedItems[1]:getText()

            self.trustSettings:getSettings()[self.trustSettingsMode.value].AutoFood = newFood
            self.trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll eat "..newFood.." now when I have them in my inventory!")
        end)
        return chooseFoodView
    end, "Food", "Choose a food to eat.")
    return chooseFoodMenuItem
end

function FoodSettingsMenuItem:getModesMenuItem()
    local foodModesMenuItem = MenuItem.new(L{}, L{}, function(_, infoView)
        local modesView = ModesView.new(L{ 'AutoFoodMode' }, infoView)
        modesView:setShouldRequestFocus(true)
        modesView:setTitle("Set modes for eating.")
        return modesView
    end, "Modes", "Change eating behavior.")
    return foodModesMenuItem
end

return FoodSettingsMenuItem