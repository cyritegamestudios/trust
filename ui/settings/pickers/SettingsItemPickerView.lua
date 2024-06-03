local Buff = require('cylibs/battle/spells/buff')
local buff_util = require('cylibs/util/buff_util')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local PickerView = require('cylibs/ui/picker/picker_view')
local Spell = require('cylibs/battle/spell')
local spell_util = require('cylibs/util/spell_util')

local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local SettingsPickerView = setmetatable({}, {__index = FFXIPickerView })
SettingsPickerView.__index = SettingsPickerView

function SettingsPickerView.new(settings, selectedTextItems, allTextItems, onPickItems, imageItemForText)
    local self = setmetatable(FFXIPickerView.withItems(allTextItems:sort(), selectedTextItems, true, nil, imageItemForText), SettingsPickerView)

    self.settings = settings
    self.onPickItems = onPickItems

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    return self
end

function SettingsPickerView:destroy()
    PickerView.destroy(self)

    self.onPickItems = nil
end

function SettingsPickerView:onSelectMenuItemAtIndexPath(textItem, _)
    if textItem:getText() == 'Confirm' then
        local selectedIndexPaths = self:getDelegate():getSelectedIndexPaths()

        local selectedItems = L(selectedIndexPaths:map(function(indexPath)
            local item = self:getDataSource():itemAtIndexPath(indexPath)
            return item
        end)):compact_map()

        self.onPickItems(selectedItems)

        if not self:getAllowsMultipleSelection() then
            self:getDelegate():deselectAllItems()
        end
        self.settings:saveSettings(true)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my settings!")
    elseif textItem:getText() == 'Clear' then
        self:getDelegate():deselectAllItems()

        self.onPickItems(L{})

        self.settings:saveSettings(true)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've removed all items!")
    end
end

return SettingsPickerView