local PickerView = require('cylibs/ui/picker/picker_view')

local JobAbilityPickerView = setmetatable({}, {__index = PickerView })
JobAbilityPickerView.__index = JobAbilityPickerView

function JobAbilityPickerView.new(trustSettings, jobAbilities, allJobAbilities)
    local self = setmetatable(PickerView.withItems(allJobAbilities, L{}, true), JobAbilityPickerView)

    self.trustSettings = trustSettings
    self.jobAbilities = jobAbilities

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