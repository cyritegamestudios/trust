local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')

local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local PullSettingsEditor = setmetatable({}, {__index = FFXIPickerView })
PullSettingsEditor.__index = PullSettingsEditor


function PullSettingsEditor.new(addon_settings, puller)
    local targetNames = (addon_settings:getSettings().battle.targets or L{}):sort()

    local self = setmetatable(FFXIPickerView.withItems(targetNames, L{}, true, nil, nil, FFXIClassicStyle.WindowSize.Editor.ConfigEditor), PullSettingsEditor)

    self.addon_settings = addon_settings
    self.puller = puller

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function PullSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Remove' then
        local selectedIndexPaths = self:getDelegate():getSelectedIndexPaths()
        if selectedIndexPaths:length() > 0 then
            local targetsToRemove = L{}
            for selectedIndexPath in selectedIndexPaths:it() do
                local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
                if item then
                    targetsToRemove:append(item:getText())
                end
            end
            local targets = S(self.addon_settings:getSettings().battle.targets):filter(function(targetName) return not targetsToRemove:contains(targetName) end)

            self.addon_settings:getSettings().battle.targets = L(targets)
            self.addon_settings:saveSettings()

            if self.puller then
                self.puller:set_target_names(targets)
            end

            self:getDelegate():deselectAllItems()
            self:getDataSource():removeItems(selectedIndexPaths)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I won't pull these mobs anymore.")
        end
    end
end

return PullSettingsEditor