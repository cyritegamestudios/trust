local PickerView = require('cylibs/ui/picker/picker_view')

local WeaponSkillPickerView = setmetatable({}, {__index = PickerView })
WeaponSkillPickerView.__index = WeaponSkillPickerView

function WeaponSkillPickerView.new(trustSettings, weaponSkills, allWeaponSkills)
    local self = setmetatable(PickerView.withItems(allWeaponSkills, L{}, true), WeaponSkillPickerView)

    self.trustSettings = trustSettings
    self.weaponSkills = weaponSkills

    return self
end

function WeaponSkillPickerView:onSelectMenuItemAtIndexPath(textItem, _)
    if textItem:getText() == 'Confirm' then
        local selectedIndexPaths = self:getDelegate():getSelectedIndexPaths()
        if selectedIndexPaths:length() > 0 then
            for selectedIndexPath in selectedIndexPaths:it() do
                local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
                if item then
                    self.weaponSkills:append(item:getText())
                end
            end
            self:getDelegate():deselectAllItems()
            self.trustSettings:saveSettings(false)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my weapon skills!")
        end
    elseif textItem:getText() == 'Clear' then
        self:getDelegate():deselectAllItems()
    end
end

return WeaponSkillPickerView