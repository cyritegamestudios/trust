local Buff = require('cylibs/battle/spells/buff')
local buff_util = require('cylibs/util/buff_util')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local PickerView = require('cylibs/ui/picker/picker_view')
local Spell = require('cylibs/battle/spell')
local spell_util = require('cylibs/util/spell_util')


local SettingsPickerView = setmetatable({}, {__index = PickerView })
SettingsPickerView.__index = SettingsPickerView

function SettingsPickerView.new(settings, settingsItemList, selectedTextItems, allTextItems, textToSettingsItem)
    local cursorImageItem = ImageItem.new(windower.addon_path..'assets/backgrounds/menu_selection_bg.png', 37, 24)

    local self = setmetatable(PickerView.withItems(allTextItems:sort(), selectedTextItems, true, cursorImageItem), SettingsPickerView)

    self.settings = settings
    self.settingsItemList = settingsItemList
    self.textToSettingsItem = textToSettingsItem

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    return self
end

function SettingsPickerView:destroy()
    PickerView.destroy(self)

    self.textToSettingsItem = nil
end

function SettingsPickerView:onSelectMenuItemAtIndexPath(textItem, _)
    if textItem:getText() == 'Confirm' then
        self.settingsItemList:clear()
        local selectedIndexPaths = self:getDelegate():getSelectedIndexPaths()
        if selectedIndexPaths:length() > 0 then
            for selectedIndexPath in selectedIndexPaths:it() do
                local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
                if item and item:getText() then
                    local settingsItem = item:getText()
                    if self.textToSettingsItem ~= nil then
                        settingsItem = self.textToSettingsItem(item:getText())
                    end
                    if settingsItem then
                        self.settingsItemList:append(settingsItem)
                    end
                end
            end
            if not self:getAllowsMultipleSelection() then
                self:getDelegate():deselectAllItems()
            end
            self.settings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my settings!")
        end
    elseif textItem:getText() == 'Clear' then
        self:getDelegate():deselectAllItems()
        self.settingsItemList:clear()
        self.settings:saveSettings(true)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've removed all items!")
    end
end

return SettingsPickerView