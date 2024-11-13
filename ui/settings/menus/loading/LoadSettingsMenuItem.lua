local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CreateProfileEditor = require('ui/settings/editors/sets/CreateProfileEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local ImportProfileMenuItem = require('ui/settings/menus/loading/ImportProfileMenuItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local Profile = require('ui/settings/profiles/Profile')
local TrustSetsConfigEditor = require('ui/settings/editors/TrustSetsConfigEditor')

local LoadSettingsMenuItem = setmetatable({}, {__index = MenuItem })
LoadSettingsMenuItem.__index = LoadSettingsMenuItem

function LoadSettingsMenuItem.new(addonSettings, trustModeSettings, jobSettings, weaponSkillSettings, subJobSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Create', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Delete', 18),
        ButtonItem.default('Import', 18),
        ButtonItem.default('Share', 18),
        ButtonItem.default('Help', 18),
    }, {
        Help = MenuItem.action(function(_)
            windower.open_url(addonSettings:getSettings().help.wiki_base_url..'/Profiles')
        end, "Profiles", "Learn more about profiles in the wiki.")
    }, nil, "Profiles", "Load, create and edit profiles."), LoadSettingsMenuItem)

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
    self.subJobSettings = subJobSettings
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
    self:setChildMenuItem("Import", ImportProfileMenuItem.new(self.trustModeSettings, self.jobSettings, self.weaponSkillSettings, self.subJobSettings))
    self:setChildMenuItem("Share", self:getShareSetMenuItem())
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
    end, "Profiles", "Edit the selected profile.", true)
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

function LoadSettingsMenuItem:getImportSetMenuItem()
    return MenuItem.action(function(_)
        local profile = Profile.new(
                _addon.version,
                state.TrustMode.value,
                self.jobSettings.jobNameShort,
                self.trustModeSettings:getSettings().Default,
                self.jobSettings:getSettings().Default,
                self.weaponSkillSettings:getSettings().Default
        )
        profile:saveToFile()

        addon_system_message("Profile saved to "..windower.addon_path..profile:getFilePath())
    end, "Profiles", "Import a Profile.")
end

function LoadSettingsMenuItem:getShareSetMenuItem()
    return MenuItem.action(function(menu)
        local setName = state.TrustMode.value
        if setName == 'Default' then
            setName = 'Shared'
        end

        local modeSettings = T(self.trustModeSettings:getSettings()[state.TrustMode.value]):copy()
        modeSettings['maintrustsettingsmode'] = setName
        modeSettings['weaponskillsettingsmode'] = setName

        local profile = Profile.new(
                _addon.version,
                setName,
                self.jobSettings.jobNameShort,
                modeSettings,
                self.jobSettings:getSettings()[state.MainTrustSettingsMode.value],
                self.weaponSkillSettings:getSettings()[state.WeaponSkillSettingsMode.value],
                self.subJobSettings and self.subJobSettings.jobNameShort,
                self.subJobSettings and self.subJobSettings:getSettings()[state.SubTrustSettingsMode.value]
        )
        profile:saveToFile()

        addon_system_message("Profile saved to "..windower.addon_path..profile:getFilePath())
    end, "Profiles", "Share the selected profile with friends.")
end

return LoadSettingsMenuItem