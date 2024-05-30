local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionsSettingsEditor = require('ui/settings/editors/ConditionsSettingsEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')

local ConditionSettingsMenuItem = setmetatable({}, {__index = MenuItem })
ConditionSettingsMenuItem.__index = ConditionSettingsMenuItem

function ConditionSettingsMenuItem.new(trustSettings, trustSettingsMode, conditions, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Edit', 18),
    }, {}, function(args)
        local conditions = args['conditions']
        local editConditionsView = viewFactory(ConditionsSettingsEditor.new(trustSettings, conditions))
        editConditionsView:setTitle("Edit conditions.")
        editConditionsView:setShouldRequestFocus(true)
        return editConditionsView
    end, "Conditions", "Specify when this buff should be used.", true), ConditionSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.conditions = conditions
    self.viewFactory = viewFactory
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function ConditionSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()

    self.viewFactory = nil
end

function ConditionSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddConditionMenuItem())
end

function ConditionSettingsMenuItem:getAddConditionMenuItem()
    local addConditionsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(menuArgs)
        local HasBuffsCondition = require('cylibs/conditions/has_buffs')
        local MaxHitPointsPercentCondition = require('cylibs/conditions/max_hpp')
        local MinHitPointsPercentCondition = require('cylibs/conditions/min_hpp')

        local allConditionClasses = L{
            HasBuffsCondition.__type,
            MaxHitPointsPercentCondition.__type,
            MinHitPointsPercentCondition.__type
        }

        local chooseConditionView = self.viewFactory(FFXIPickerView.withItems(allConditionClasses, L{}, false))
        chooseConditionView:setTitle("Choose a condition.")
        chooseConditionView:setShouldRequestFocus(true)
        chooseConditionView:on_pick_items():addAction(function(_, selectedItems)
            local newCondition = selectedItems[1]:getText()

            --self.conditions:append(newCondition)

            --self.trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've added a new condition!")
        end)
        return chooseConditionView
    end, "Conditions", "Add a new condition.")
    return addConditionsMenuItem
end

return ConditionSettingsMenuItem