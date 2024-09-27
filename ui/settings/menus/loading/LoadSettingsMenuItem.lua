local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CreateProfileEditor = require('ui/settings/editors/sets/CreateProfileEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local TrustSetsConfigEditor = require('ui/settings/editors/TrustSetsConfigEditor')

local LoadSettingsMenuItem = setmetatable({}, {__index = MenuItem })
LoadSettingsMenuItem.__index = LoadSettingsMenuItem

function LoadSettingsMenuItem.new(addonSettings, trustModeSettings, jobSettings, weaponSkillSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Create', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Delete', 18),
        ButtonItem.default('Share', 18),
    }, {

    }, nil, "Profiles", "Load a saved profile."), LoadSettingsMenuItem)

    self.contentViewConstructor = function(_, _)
        local loadSettingsView = FFXIPickerView.withItems(L(state.TrustMode:options()), state.TrustMode.value)

        loadSettingsView:setShouldRequestFocus(true)

        self.disposeBag:add(loadSettingsView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local item = loadSettingsView:getDataSource():itemAtIndexPath(indexPath)
            if item then
                local setName = item:getText()
                self.selectedSetName = setName
                if setName ~= state.TrustMode.value then
                    handle_set('TrustMode', setName)
                end
            end
        end), loadSettingsView:getDelegate():didSelectItemAtIndexPath())

        self.disposeBag:add(loadSettingsView:getDelegate():didHighlightItemAtIndexPath():addAction(function(indexPath)
            local item = loadSettingsView:getDataSource():itemAtIndexPath(indexPath)
            if item then
                self.highlightedSetName = item:getText()
            end
        end), loadSettingsView:getDelegate():didHighlightItemAtIndexPath())

        self.loadSettingsView = loadSettingsView

        self.selectedSetName = state.TrustMode.value
        self.highlightedSetName = state.TrustMode.value

        return loadSettingsView
    end

    self.addonSettings = addonSettings
    self.trustModeSettings = trustModeSettings
    self.jobSettings = jobSettings
    self.weaponSkillSettings = weaponSkillSettings
    self.weaponSkillSettings = weaponSkillSettings
    self.disposeBag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function LoadSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function LoadSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Create", self:getCreateSetMenuItem())
    self:setChildMenuItem("Edit", self:getEditSetMenuItem())
    self:setChildMenuItem("Delete", self:getDeleteSetMenuItem())
end

function LoadSettingsMenuItem:getCreateSetMenuItem()
    local createSetMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {
        Confirm = MenuItem.action(function(menu)
            menu:showMenu(self)
        end, "Confirm", "Create a new profile.")
    }, function(_)
        local createSetView = CreateProfileEditor.new(self.trustModeSettings, self.jobSettings, self.weaponSkillSettings)
        return createSetView
    end, "Profiles", "Create a new profile.")
    return createSetMenuItem
end

function LoadSettingsMenuItem:getEditSetMenuItem()
    local editMenuItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
    }, {}, function(_, _)
        local loadSettingsView = TrustSetsConfigEditor.new(self.highlightedSetName or 'Default', self.trustModeSettings, self.jobSettings, self.weaponSkillSettings, nil)
        loadSettingsView:setShouldRequestFocus(true)
        return loadSettingsView
    end, "Profiles", "Edit saved profiles.", true)
    return editMenuItem
end

function LoadSettingsMenuItem:getDeleteSetMenuItem()
    return MenuItem.action(function(menu)
        if self.selectedSetName then
            if self.selectedSetName == 'Default' then
                addon_message(123, "You cannot delete the Default profile.")
                return
            end
            self.trustModeSettings:deleteSettings(self.selectedSetName)

            menu:showMenu(self)
            --self.loadSettingsView:setItems(L(state.TrustMode:options()), state.TrustMode.value)
        end
    end, "Profiles", "Delete the selected profile.")
end

return LoadSettingsMenuItem