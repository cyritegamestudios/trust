local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')
local FFXITextInputView = require('ui/themes/ffxi/FFXITextInputView')

local ModesMenuItem = setmetatable({}, {__index = MenuItem })
ModesMenuItem.__index = ModesMenuItem

function ModesMenuItem.new(trustSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Save', 18),
        ButtonItem.default('Save As', 18),
    }, {},
        function(_, infoView)
            local modesView = ModesView.new(L(T(state):keyset()):sort(), infoView)
            modesView:setShouldRequestFocus(true)
            return modesView
        end, "Modes", "View and change Trust modes."), ModesMenuItem)

    self.disposeBag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function ModesMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function ModesMenuItem:reloadSettings()
    self:setChildMenuItem("Save", MenuItem.action(function()
        windower.send_command('trust save '..state.TrustMode.value)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."You got it! I'll remember what to do.")
    end), "Save", "Override the current mode set.")
    self:setChildMenuItem("Save As", self:getSaveAsMenuItem())
end

function ModesMenuItem:getSaveAsMenuItem()
    local onRenameSet = function(newModeSetName)
        windower.send_command('trust save '..newModeSetName)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."You got it! I'll remember what to do.")
    end

    local saveAsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
    function()
        local modesView = FFXITextInputView.new('Default', "Mode set name")
        modesView:setShouldRequestFocus(true)
        self.disposeBag:add(modesView:onTextChanged():addAction(function(_, modeSetName)
            onRenameSet(modeSetName)
        end), modesView:onTextChanged())
        return modesView
    end, "Modes", "Save as a new mode set.")
    return saveAsMenuItem
end

return ModesMenuItem