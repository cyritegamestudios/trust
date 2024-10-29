local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local PickerView = require('cylibs/ui/picker/picker_view')

local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local JobAbilityPickerView = setmetatable({}, {__index = FFXIPickerView })
JobAbilityPickerView.__index = JobAbilityPickerView

function JobAbilityPickerView.new(trustSettings, jobAbilities, allJobAbilities, includeCurrentJobOnly)
    local imageItemForText = function(text)
        return AssetManager.imageItemForJobAbility(text)
    end

    if includeCurrentJobOnly then
        allJobAbilities = allJobAbilities:filter(function(jobAbilityName)
            return job_util.knows_job_ability(res.job_abilities:with('en', jobAbilityName).id, res.jobs:with('ens', trustSettings.jobNameShort).id)
        end)
    end

    local self = setmetatable(FFXIPickerView.withItems(allJobAbilities, L{}, true, nil, imageItemForText), JobAbilityPickerView)

    self.trustSettings = trustSettings
    self.jobAbilities = jobAbilities

    self:setScrollEnabled(true)

    if allJobAbilities:length() > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end

    return self
end

function JobAbilityPickerView:onSelectMenuItemAtIndexPath(textItem, _)
    if textItem:getText() == 'Confirm' then
        local selectedIndexPaths = self:getDelegate():getSelectedIndexPaths()
        if selectedIndexPaths:length() > 0 then
            for selectedIndexPath in selectedIndexPaths:it() do
                local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
                if item then
                    local jobAbility = JobAbility.new(item:getText(), L{}, L{}, nil)
                    if self.jobAbilities:contains(jobAbility) then
                        addon_message(260, '('..windower.ffxi.get_player().name..') '.."I'm already using "..jobAbility:get_job_ability_name()..".")
                    else
                        self.jobAbilities:append(jobAbility)
                    end
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