local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local FFXITextInputView = require('ui/themes/ffxi/FFXITextInputView')
local Gambit = require('cylibs/gambits/gambit')
local GambitSettingsEditor = require('ui/settings/editors/GambitSettingsEditor')
local GambitTarget = require('cylibs/gambits/gambit_target')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local job_util = require('cylibs/util/job_util')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local Puppetmaster = require('cylibs/entity/jobs/PUP')

local AttachmentSettingsMenuItem = setmetatable({}, {__index = MenuItem })
AttachmentSettingsMenuItem.__index = AttachmentSettingsMenuItem

function AttachmentSettingsMenuItem.new(trustSettings, trustSettingsMode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('View', 18),
        ButtonItem.default('Equip', 18),
        ButtonItem.default('Save As', 18),
        ButtonItem.default('Delete', 18),
    }, {}, nil, "Attachments", "Equip or save attachment sets.", false), AttachmentSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.job = Puppetmaster.new()
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local attachmentSets = trustSettings:getSettings()[trustSettingsMode.value].AttachmentSettings.Sets

        local attachmentSettingsEditor = FFXIPickerView.withItems(L(T(attachmentSets):keyset()):sort(), L{})
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
    self:setChildMenuItem("Save As", self:getCreateSetMenuItem())
    self:setChildMenuItem("Delete", self:getDeleteSetMenuItem())
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
            self.job:equip_attachment_set(self.selectedSet:getHeadName(), self.selectedSet:getFrameName(), self.selectedSet:getAttachments(), action_queue, true)
        end
    end, "Attachments", "Equip the selected attachment set.")
end

function AttachmentSettingsMenuItem:getViewAttachmentsMenuItem()
    return MenuItem.new(L{}, {}, function(menuArgs, infoView)
        local attachmentListEditor = FFXIPickerView.withItems(self.selectedSet:getAttachments(), L{}, true)
        return attachmentListEditor
    end, "Attachments", "View attachments in the set.")
end

function AttachmentSettingsMenuItem:getCreateSetMenuItem()
    local createSetMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{
        Confirm = MenuItem.action(function(menu)
            menu:showMenu(self)
        end)
    }, function(_)
        local createSetView = FFXITextInputView.new('Set', "Attachment set name")
        createSetView:setTitle("Choose a name for the attachment set.")
        createSetView:setShouldRequestFocus(true)
        createSetView:onTextChanged():addAction(function(_, newSetName)
            if newSetName:length() > 1 then
                local newSet = self.job:create_attachment_set()
                if newSet then
                    local attachmentSets = self.trustSettings:getSettings()[self.trustSettingsMode.value].AttachmentSettings.Sets
                    attachmentSets[newSetName] = newSet

                    self.trustSettings:saveSettings(true)

                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've saved a new attachment set called "..newSetName.."!")
                end
            else
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."That name is too short, pick something else?")
            end
        end)
        return createSetView
    end, "Attachments", "Save a new attachment set.")
    return createSetMenuItem
end

function AttachmentSettingsMenuItem:getDeleteSetMenuItem()
    return MenuItem.action(function(menu)
        if self.selectedSetName then
            local attachmentSets = self.trustSettings:getSettings()[self.trustSettingsMode.value].AttachmentSettings.Sets
            attachmentSets[self.selectedSetName] = nil

            self.trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, "..self.selectedSetName.." is no more!")

            menu:showMenu(self)
        end
    end, "Attachments", "Delete the selected attachment set.")
end

return AttachmentSettingsMenuItem