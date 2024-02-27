local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXITextInputView = require('ui/themes/ffxi/FFXITextInputView')
local JobSettingsMenuItem = require('ui/settings/menus/loading/JobSettingsMenuItem')
local LoadSettingsView = require('ui/settings/LoadSettingsView')
local MenuItem = require('cylibs/ui/menu/menu_item')

local LoadSettingsMenuItem = setmetatable({}, {__index = MenuItem })
LoadSettingsMenuItem.__index = LoadSettingsMenuItem

function LoadSettingsMenuItem.new(addonSettings, trustModeSettings, jobSettings, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Save As', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Job Settings', 18),
    }, {

    }, function(args)
        local loadSettingsView = viewFactory(LoadSettingsView.new(state.TrustMode, addonSettings, trustModeSettings))
        loadSettingsView:setShouldRequestFocus(true)
        return loadSettingsView
    end, "Settings", "Load saved modes and job settings"), LoadSettingsMenuItem)

    self.addonSettings = addonSettings
    self.trustModeSettings = trustModeSettings
    self.jobSettings = jobSettings
    self.viewFactory = viewFactory
    self.disposeBag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function LoadSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()

    self.viewFactory = nil
end

function LoadSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Save As", self:getCreateSetMenuItem())
    self:setChildMenuItem("Edit", self:getEditMenuItem())
    self:setChildMenuItem("Job Settings", JobSettingsMenuItem.new(state.MainTrustSettingsMode, self.jobSettings, self.viewFactory))
end

function LoadSettingsMenuItem:getEditMenuItem()
    local editMenuItem = MenuItem.new(L{
        ButtonItem.default('Delete', 18),
    }, {}, nil, "Edit", "Edit saved sets.", true)
    return editMenuItem
end

function LoadSettingsMenuItem:getCreateSetMenuItem()
    local createSetMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(_)
        local createSetView = self.viewFactory(FFXITextInputView.new('Set'))
        createSetView:setTitle("Choose a name for the mode set.")
        createSetView:setShouldRequestFocus(true)
        createSetView:onTextChanged():addAction(function(_, newSetName)
            if newSetName:length() > 1 then
                self.trustModeSettings:saveSettings(newSetName)

                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll remember what to do for "..newSetName.." now!")
            else
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."That name is too short, pick something else?")
            end
        end)
        return createSetView
    end, "Settings", "Save a new mode set.")
    return createSetMenuItem
end

return LoadSettingsMenuItem