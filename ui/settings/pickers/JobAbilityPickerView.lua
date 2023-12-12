local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local PickerView = require('cylibs/ui/picker/picker_view')

local JobAbilityPickerView = setmetatable({}, {__index = PickerView })
JobAbilityPickerView.__index = JobAbilityPickerView

function JobAbilityPickerView.new(trustSettings, jobAbilities, allJobAbilities)
    local cursorImageItem = ImageItem.new(windower.addon_path..'assets/backgrounds/menu_selection_bg.png', 37, 24)

    local self = setmetatable(PickerView.withItems(allJobAbilities, L{}, true, cursorImageItem), JobAbilityPickerView)

    self.trustSettings = trustSettings
    self.jobAbilities = jobAbilities

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    return self
end

function JobAbilityPickerView:onSelectMenuItemAtIndexPath(textItem, _)
    if textItem:getText() == 'Confirm' then
        local selectedIndexPaths = self:getDelegate():getSelectedIndexPaths()
        if selectedIndexPaths:length() > 0 then
            for selectedIndexPath in selectedIndexPaths:it() do
                local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
                if item then
                    self.jobAbilities:append(JobAbility.new(item:getText(), L{}, L{}, nil))
                end
            end
            self:getDelegate():deselectAllItems()
            self.trustSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my abilities!")
        end
    elseif textItem:getText() == 'Clear' then
        self:getDelegate():deselectAllItems()
    end
end

return JobAbilityPickerView