local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local CreateProfileEditor = require('ui/settings/editors/sets/CreateProfileEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local EquipSetMenuItem = require('ui/views/inventory/equipment/EquipSetMenuItem')
local EquipSet = require('cylibs/inventory/equipment/equip_set')
local EquipSets = require('settings/settings').EquipSet
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local ImportProfileMenuItem = require('ui/settings/menus/loading/ImportProfileMenuItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local Profile = require('ui/settings/profiles/Profile')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')
local TrustSetsConfigEditor = require('ui/settings/editors/TrustSetsConfigEditor')

local EquipmentSettingsMenuItem = setmetatable({}, {__index = MenuItem })
EquipmentSettingsMenuItem.__index = EquipmentSettingsMenuItem

function EquipmentSettingsMenuItem.new()
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Create', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Delete', 18),
        ButtonItem.default('Import', 18),
        ButtonItem.default('Share', 18),
        ButtonItem.default('Help', 18),
    }, {
        Help = MenuItem.action(function(_)
            windower.open_url(windower.trust.settings.get_addon_settings():getSettings().help.wiki_base_url..'/Equipment')
        end, "Equipment", "Learn more about equipment sets in the wiki.")
    }, nil, "Equipment", "Load, create and edit equipment sets."), EquipmentSettingsMenuItem)

    self.equipSetMenuItem = EquipSetMenuItem.new(player.party:get_player():get_current_equip_set())

    self.contentViewConstructor = function(_, _)
        local allSets = EquipSets:all(L{ 'name' })

        local configItem = MultiPickerConfigItem.new("EquipSets", L{ allSets[1].name }, L(allSets:map(function(equipSet) return equipSet.name end)), function(equipSetName)
            return equipSetName
        end)

        local loadSettingsView = FFXIPickerView.withConfig(configItem)

        self.disposeBag:add(loadSettingsView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local item = loadSettingsView:getDataSource():itemAtIndexPath(indexPath)
            if item then
                local setName = item:getText()

                self.equipSetMenuItem:setEquipSet(EquipSet.named(setName))

                self.selectedSetName = setName
            end
        end), loadSettingsView:getDelegate():didSelectItemAtIndexPath())

        self.loadSettingsView = loadSettingsView

        return loadSettingsView
    end

    self.disposeBag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function EquipmentSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function EquipmentSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Create", self:getCreateSetMenuItem())
    self:setChildMenuItem("Edit", self.equipSetMenuItem)
    --self:setChildMenuItem("Delete", self:getDeleteSetMenuItem())
    --self:setChildMenuItem("Import", ImportProfileMenuItem.new(self.trustModeSettings, self.jobSettings, self.weaponSkillSettings, self.subJobSettings))
    --self:setChildMenuItem("Share", self:getShareSetMenuItem())
end

function EquipmentSettingsMenuItem:getCreateSetMenuItem()
    local createSetMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
    }, {
        Confirm = MenuItem.action(function(menu)
            menu:showMenu(self)
        end, "Confirm", "Create a new equipment set.")
    }, function(_)
        local createSetView = CreateProfileEditor.new(self.trustModeSettings, self.jobSettings, self.subJobSettings, self.weaponSkillSettings)
        return createSetView
    end, "Equipment", "Create a new equipment set.")
    return createSetMenuItem
end

function EquipmentSettingsMenuItem:getEditSetMenuItem()
    local editMenuItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
    }, {}, function(_, infoView)
        local loadSettingsView = TrustSetsConfigEditor.new(self.highlightedSetName or 'Default', self.trustModeSettings, self.jobSettings, self.subJobSettings, self.weaponSkillSettings, infoView)
        loadSettingsView:setShouldRequestFocus(true)
        return loadSettingsView
    end, "Equipment", "Edit the selected profile.", true)
    return editMenuItem
end

function EquipmentSettingsMenuItem:getDeleteSetMenuItem()
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
    end, "Equipment", "Delete the selected profile.")
end

function EquipmentSettingsMenuItem:getImportSetMenuItem()
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
    end, "Equipment", "Import a Profile.")
end

function EquipmentSettingsMenuItem:getShareSetMenuItem()
    return MenuItem.action(function(menu)
        local setName = state.TrustMode.value
        if setName == 'Default' then
            setName = 'Shared'
        end

        local modeSettings = T(self.trustModeSettings:getSettings()[state.TrustMode.value]):copy()
        modeSettings['maintrustsettingsmode'] = setName
        modeSettings['subtrustsettingsmode'] = setName
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
    end, "Equipment", "Share the selected profile with friends.")
end

return EquipmentSettingsMenuItem