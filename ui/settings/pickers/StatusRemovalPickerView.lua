local buff_util = require('cylibs/util/buff_util')
local IndexPath = require('cylibs/ui/collection_view/index_path')

local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local StatusRemovalBlacklistPickerView = setmetatable({}, {__index = FFXIPickerView })
StatusRemovalBlacklistPickerView.__index = StatusRemovalBlacklistPickerView

function StatusRemovalBlacklistPickerView.new(trustSettings, statusEffectsBlacklist)
    local self = setmetatable(FFXIPickerView.withItems(buff_util.get_all_debuffs():sort(), statusEffectsBlacklist, true), StatusRemovalBlacklistPickerView)

    self.trustSettings = trustSettings
    self.statusEffectsBlacklist = statusEffectsBlacklist

    self:setScrollEnabled(true)

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    return self
end

function StatusRemovalBlacklistPickerView:onSelectMenuItemAtIndexPath(textItem, _)
    if textItem:getText() == 'Confirm' then
        self.statusEffectsBlacklist:clear()
        local selectedIndexPaths = self:getDelegate():getSelectedIndexPaths()
        if selectedIndexPaths:length() > 0 then
            for selectedIndexPath in selectedIndexPaths:it() do
                local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
                if item then
                    local statusEffect = item:getText()
                    if statusEffect then
                        self.statusEffectsBlacklist:append(statusEffect)
                    end
                end
            end
            self:getDelegate():deselectAllItems()
            self.trustSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll ignore these status effects!")
        end
    elseif textItem:getText() == 'Clear' then
        self:getDelegate():deselectAllItems()
        self.statusEffectsBlacklist:clear()
        self.trustSettings:saveSettings(true)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll remove all status effects again!")
    end
end

return StatusRemovalBlacklistPickerView