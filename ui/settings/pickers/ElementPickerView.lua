local Buff = require('cylibs/battle/spells/buff')
local buff_util = require('cylibs/util/buff_util')
local element_util = require('cylibs/util/element_util')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local PickerView = require('cylibs/ui/picker/picker_view')
local Spell = require('cylibs/battle/spell')
local spell_util = require('cylibs/util/spell_util')

local ElementPickerView = setmetatable({}, {__index = PickerView })
ElementPickerView.__index = ElementPickerView

function ElementPickerView.new(trustSettings, elementBlacklist)
    local cursorImageItem = ImageItem.new(windower.addon_path..'assets/backgrounds/menu_selection_bg.png', 37, 24)

    local allElements = L{
        element_util.Light,
        element_util.Fire,
        element_util.Lightning,
        element_util.Wind,
        element_util.Dark,
        element_util.Earth,
        element_util.Water,
        element_util.Ice,
    }

    local self = setmetatable(PickerView.withItems(allElements:map(function(element) return element:get_name() end):sort(), elementBlacklist:map(function(element) return element:get_name() end), true, cursorImageItem), ElementPickerView)

    self.trustSettings = trustSettings
    self.elementBlacklist = elementBlacklist

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    return self
end

function ElementPickerView:onSelectMenuItemAtIndexPath(textItem, _)
    if textItem:getText() == 'Confirm' then
        self.elementBlacklist:clear()
        local selectedIndexPaths = self:getDelegate():getSelectedIndexPaths()
        if selectedIndexPaths:length() > 0 then
            for selectedIndexPath in selectedIndexPaths:it() do
                local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
                if item then
                    local element = item:getText()
                    if element then
                        self.elementBlacklist:append(Element.new(element))
                    end
                end
            end
            self.trustSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I won't use nukes of these elements!")
        else
            self:clearAll()
        end
    elseif textItem:getText() == 'Clear' then
        self:clearAll()
    end
end

function ElementPickerView:clearAll()
    self:getDelegate():deselectAllItems()
    self.elementBlacklist:clear()
    self.trustSettings:saveSettings(true)
    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll nuke with all elements!")
end

return ElementPickerView