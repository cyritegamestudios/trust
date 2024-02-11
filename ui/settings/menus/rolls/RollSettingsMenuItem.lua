local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CursorItem = require('ui/themes/FFXI/CursorItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local PickerView = require('cylibs/ui/picker/picker_view')

local RollSettingsMenuItem = setmetatable({}, {__index = MenuItem })
RollSettingsMenuItem.__index = RollSettingsMenuItem

function RollSettingsMenuItem.new(addonSettings, trust, rolls, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Roll 1', 18),
        ButtonItem.default('Roll 2', 18),
        ButtonItem.default('Modes', 18),
    }, {

    }, nil, "Rolls", "Configure settings for Phantom Roll."), RollSettingsMenuItem)

    self.all_rolls = trust:get_job():get_all_rolls():sort()
    self.rolls = rolls
    self.addonSettings = addonSettings
    self.viewFactory = viewFactory
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function RollSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()

    self.viewFactory = nil
end

function RollSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Roll 1", self:getRollMenuItem(self.rolls[1], "Choose a primary roll."))
    self:setChildMenuItem("Roll 2", self:getRollMenuItem(self.rolls[2], "Choose a secondary roll."))
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function RollSettingsMenuItem:getRollMenuItem(roll, descriptionText)
    local rollMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(menuArgs)
        local cursorImageItem = CursorItem.new()

        local chooseRollView = self.viewFactory(PickerView.withItems(self.all_rolls, L{ roll:get_roll_name() }, false, cursorImageItem))
        chooseRollView:setTitle(descriptionText)
        chooseRollView:setAllowsCursorSelection(false)
        chooseRollView:on_pick_items():addAction(function(_, selectedItems)
            local roll_name = selectedItems[1]:getText()
            if roll_name then
                roll:set_roll_name(roll_name)

                self.addonSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll use "..roll_name.." now!")
            end
        end)
        return chooseRollView
    end, "Rolling", descriptionText)
    return rollMenuItem
end

function RollSettingsMenuItem:getModesMenuItem()
    local rollModesMenuItem = MenuItem.new(L{
        ButtonItem.default('Manual', 18),
        ButtonItem.default('Auto', 18),
        ButtonItem.default('Off', 18),
    }, L{
        Manual = MenuItem.action(function()
            handle_set('AutoRollMode', 'Manual')
        end, "Rolling", state.AutoRollMode:get_description('Manual')),
        Auto = MenuItem.action(function()
            handle_set('AutoRollMode', 'Auto')
        end, "Rolling", state.AutoRollMode:get_description('Auto')),
        Off = MenuItem.action(function()
            handle_set('AutoRollMode', 'Off')
        end, "Rolling", state.AutoRollMode:get_description('Off')),
    }, nil, "Modes", "Change rolling modes.")
    return rollModesMenuItem
end

return RollSettingsMenuItem