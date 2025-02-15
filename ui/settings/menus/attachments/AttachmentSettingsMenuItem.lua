local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local Puppetmaster = require('cylibs/entity/jobs/PUP')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local AttachmentSettingsMenuItem = setmetatable({}, {__index = MenuItem })
AttachmentSettingsMenuItem.__index = AttachmentSettingsMenuItem

function AttachmentSettingsMenuItem.new(trustSettings, trustSettingsMode, settingsKeyName, isEditable)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('View', 18),
        ButtonItem.default('Equip', 18),
    }, {}, nil, "Attachments", "Equip or save "..settingsKeyName.." attachment sets.", false), AttachmentSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.settingsKeyName = settingsKeyName
    self.isEditable = isEditable
    self.job = Puppetmaster.new()
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local attachmentSets = trustSettings:getSettings()[trustSettingsMode.value].AutomatonSettings.AttachmentSettings[settingsKeyName]

        local configItem = MultiPickerConfigItem.new("AttachmentSets", L{}, L(T(attachmentSets):keyset()):sort(), function(attachmentSetName)
            return tostring(attachmentSetName)
        end)

        local attachmentSettingsEditor = FFXIPickerView.withConfig(configItem)
        attachmentSettingsEditor:setAllowsCursorSelection(true)

        attachmentSettingsEditor:setNeedsLayout()
        attachmentSettingsEditor:layoutIfNeeded()

        self.disposeBag:add(attachmentSettingsEditor:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local item = attachmentSettingsEditor:getDataSource():itemAtIndexPath(indexPath)
            if item then
                self.selectedSet = attachmentSets[item:getText()]
                self.selectedSetName = item:getText()
            end
        end), attachmentSettingsEditor:getDelegate():didSelectItemAtIndexPath())

        if attachmentSets:length() > 0 then
            attachmentSettingsEditor:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
        end

        return attachmentSettingsEditor
    end

    self:reloadSettings()

    return self
end

function AttachmentSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function AttachmentSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("View", self:getViewAttachmentsMenuItem())
    self:setChildMenuItem("Equip", self:getEquipSetMenuItem())
    if self.isEditable then
        self:setChildMenuItem("Save As", self:getCreateSetMenuItem())
        self:setChildMenuItem("Delete", self:getDeleteSetMenuItem())
    end
end

function AttachmentSettingsMenuItem:getEquipSetMenuItem()
    return MenuItem.action(function()
        if self.selectedSet then
            --[[if not pet_util.has_pet() then
                --self.job:remove_all_attachments()
                self.job:equip_attachment_set(self.selectedSet:getHeadName(), self.selectedSet:getFrameName(), self.selectedSet:getAttachments(), action_queue, true)
            else
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."I can't change sets while my Automaton is still out!")
            end]]
            self.job:equip_attachment_set(self.selectedSet:getHeadName(), self.selectedSet:getFrameName(), self.selectedSet:getAttachments(), true)
        end
    end, "Attachments", "Equip the selected attachment set.")
end

function AttachmentSettingsMenuItem:getViewAttachmentsMenuItem()
    return MenuItem.new(L{}, {}, function(menuArgs, infoView)
        local configItem = MultiPickerConfigItem.new("Attachments", L{}, L{ self.selectedSet:getHeadName(), self.selectedSet:getFrameName() } + self.selectedSet:getAttachments(), function(attachmentName)
            return i18n.resource('items', 'en', attachmentName)
        end)
        local attachmentListEditor = FFXIPickerView.withConfig(configItem)
        return attachmentListEditor
    end, "Attachments", "View attachments in the set.")
end

function AttachmentSettingsMenuItem:getCreateSetMenuItem()
    local createSetMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
    }, {
        Confirm = MenuItem.action(function(menu)
            menu:showMenu(self)
        end)
    }, function(_)
        local configItems = L{
            TextInputConfigItem.new('SetName', 'New Set', 'Set Name', function(_) return true  end)
        }

        local attachmentSetConfigEditor = ConfigEditor.new(self.trustSettings, { SetName = '' }, configItems, nil, function(newSettings)
            return newSettings.SetName and newSettings.SetName:length() > 3
        end)
        attachmentSetConfigEditor:setShouldRequestFocus(true)

        self.disposeBag:add(attachmentSetConfigEditor:onConfigChanged():addAction(function(newSettings, _)
            local newSet = self.job:create_attachment_set()
            if newSet then
                local attachmentSets = self.trustSettings:getSettings()[self.trustSettingsMode.value].AutomatonSettings.AttachmentSettings[self.settingsKeyName]
                attachmentSets[newSettings.SetName] = newSet

                self.trustSettings:saveSettings(true)

                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've saved a new attachment set called "..newSettings.SetName.."!")
            end
            self.trustSettings:saveSettings(true)
        end), attachmentSetConfigEditor:onConfigChanged())

        self.disposeBag:add(attachmentSetConfigEditor:onConfigValidationError():addAction(function()
            addon_system_error("Invalid attachment set name.")
        end), attachmentSetConfigEditor:onConfigValidationError())

        return attachmentSetConfigEditor
    end, "Attachments", "Save a new attachment set.")
    return createSetMenuItem
end

function AttachmentSettingsMenuItem:getDeleteSetMenuItem()
    return MenuItem.action(function(menu)
        if self.selectedSetName then
            local attachmentSets = self.trustSettings:getSettings()[self.trustSettingsMode.value].AutomatonSettings.AttachmentSettings[self.settingsKeyName]
            if L(T(attachmentSets):keyset()):length() <= 1 then
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."I can't delete my last set!")
                return
            end

            attachmentSets[self.selectedSetName] = nil

            self.trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, "..self.selectedSetName.." is no more!")

            menu:showMenu(self)
        end
    end, "Attachments", "Delete the selected attachment set.")
end

return AttachmentSettingsMenuItem